#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${RUNTIME_BASE_URL%/}"
RUNTIME_CONFIG="${RUNTIME_CONFIG:-.guidelines.runtime.json}"
FAIL_ON_4XX="${RUNTIME_FAIL_ON_4XX:-false}"
RUNTIME_ROUTES="${RUNTIME_ROUTES:-/}"
TIMEOUT_SEC="$(( ${RUNTIME_TIMEOUT_MS:-15000} / 1000 ))"
[ "$TIMEOUT_SEC" -lt 3 ] && TIMEOUT_SEC=3

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
ROUTES=()

if [ -f "$RUNTIME_CONFIG" ] && command -v python3 >/dev/null 2>&1; then
    while IFS= read -r r; do
        [[ -n "$r" ]] && ROUTES+=("$r")
    done < <(python3 - "$RUNTIME_CONFIG" << 'PYEOF'
import json, sys
cfg = json.load(open(sys.argv[1]))
seen = set()
for role in cfg.get("roles", []):
    for r in role.get("routes", []):
        if r not in seen:
            seen.add(r)
            print(r)
PYEOF
)
fi

if [ ${#ROUTES[@]} -eq 0 ]; then
    IFS=',' read -ra RAW <<< "$RUNTIME_ROUTES"
    for r in "${RAW[@]}"; do
        r="${r#"${r%%[![:space:]]*}"}"
        r="${r%"${r##*[![:space:]]}"}"
        [ -n "$r" ] && ROUTES+=("$r")
    done
fi

ERRORS=0
CHECKED=0

for route in "${ROUTES[@]}"; do
    [[ "$route" == http* ]] && url="$route" || url="${BASE_URL}/${route#/}"
    CHECKED=$((CHECKED + 1))
    code=$(curl -sS -L -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT_SEC" "$url" 2>/dev/null || echo "000")
    if [ "$code" = "000" ] || [ "$code" -ge 500 ]; then
        echo -e "${RED}[FAIL]${NC} HTTP $code -> $url"
        ERRORS=$((ERRORS + 1))
    elif [ "$FAIL_ON_4XX" = "true" ] && [[ "$code" =~ ^(403|404|422)$ ]]; then
        echo -e "${RED}[FAIL]${NC} HTTP $code (unexpected 4xx) -> $url"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} HTTP probe verified $CHECKED route(s) with 0 server errors."
    exit 0
fi
echo -e "${RED}[ERROR]${NC} HTTP probe found $ERRORS failing route(s)!"
exit 1
