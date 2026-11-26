#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/.."
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"
[ -f "$RULES_DIR/lib/ignore.sh" ] && source "$RULES_DIR/lib/ignore.sh" && init_guidelines_guard
[ -f "$(pwd)/scripts/rules/config.env" ] && source "$(pwd)/scripts/rules/config.env"

BASE_URL="${RUNTIME_BASE_URL:-}"
RUNTIME_CONFIG="${RUNTIME_CONFIG:-.guidelines.runtime.json}"
FAIL_ON_4XX="${RUNTIME_FAIL_ON_4XX:-false}"
FAIL_ON_CONSOLE="${RUNTIME_FAIL_ON_CONSOLE_ERROR:-true}"
RUNTIME_ROUTES="${RUNTIME_ROUTES:-/}"
RUNTIME_LOG_FILE="${RUNTIME_LOG_FILE:-}"
RUNTIME_MAX_PAGES="${RUNTIME_MAX_PAGES:-50}"
RUNTIME_TIMEOUT_MS="${RUNTIME_TIMEOUT_MS:-15000}"

for arg in "$@"; do
    case "$arg" in
        --url=*) BASE_URL="${arg#*=}" ;;
        --config=*) RUNTIME_CONFIG="${arg#*=}" ;;
        --routes=*) RUNTIME_ROUTES="${arg#*=}" ;;
        --log=*) RUNTIME_LOG_FILE="${arg#*=}" ;;
        --fail-on-4xx) FAIL_ON_4XX="true" ;;
        --no-console-fail) FAIL_ON_CONSOLE="false" ;;
    esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
echo "==> [RUNTIME-GUARD] Auditing Live Runtime, HTTP 5xx & Browser Console Errors..."

if [ -z "$BASE_URL" ] && [ -f "$RUNTIME_CONFIG" ] && command -v python3 >/dev/null 2>&1; then
    BASE_URL=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('baseUrl',''))" "$RUNTIME_CONFIG" 2>/dev/null || true)
fi

if [ -z "$BASE_URL" ]; then
    echo -e "${YELLOW}[INFO]${NC} RUNTIME_BASE_URL not configured. Pass --url=http://127.0.0.1:8000 or set RUNTIME_BASE_URL in .guidelines.env."
    exit 0
fi

BASE_URL="${BASE_URL%/}"
if ! curl -sS -o /dev/null --max-time 5 "$BASE_URL" 2>/dev/null; then
    echo -e "${RED}[FAIL]${NC} Target server unreachable at $BASE_URL. Start your dev/test server before running runtime guard."
    exit 1
fi

LOG_LINES_BEFORE=0
if [ -n "$RUNTIME_LOG_FILE" ] && [ -f "$RUNTIME_LOG_FILE" ]; then
    LOG_LINES_BEFORE=$(wc -l < "$RUNTIME_LOG_FILE")
fi

export RUNTIME_BASE_URL="$BASE_URL"
export RUNTIME_CONFIG RUNTIME_FAIL_ON_4XX="$FAIL_ON_4XX" RUNTIME_FAIL_ON_CONSOLE_ERROR="$FAIL_ON_CONSOLE"
export RUNTIME_ROUTES RUNTIME_MAX_PAGES RUNTIME_TIMEOUT_MS

HAS_PLAYWRIGHT="false"
if command -v node >/dev/null 2>&1; then
    if NODE_PATH="$(pwd)/node_modules:${NODE_PATH:-}:$(npm root -g 2>/dev/null || true)" node -e "require('playwright')" 2>/dev/null; then
        HAS_PLAYWRIGHT="true"
    fi
fi

STATUS=0
if [ "$HAS_PLAYWRIGHT" = "true" ]; then
    echo -e "${BLUE}[INFO]${NC} Playwright detected. Running Chromium headless runtime & console crawler on $BASE_URL..."
    NODE_PATH="$(pwd)/node_modules:${NODE_PATH:-}:$(npm root -g 2>/dev/null || true)" node "$SCRIPT_DIR/crawl-browser.mjs" || STATUS=1
else
    echo -e "${YELLOW}[INFO]${NC} Playwright not found. Running HTTP 5xx smoke probe (install 'playwright' for JS/console detection)."
    bash "$SCRIPT_DIR/crawl-http.sh" || STATUS=1
fi

if [ -n "$RUNTIME_LOG_FILE" ] && [ -f "$RUNTIME_LOG_FILE" ]; then
    NEW_LOG=$(tail -n +"$((LOG_LINES_BEFORE + 1))" "$RUNTIME_LOG_FILE" 2>/dev/null || true)
    BAD_LOG=$(printf '%s\n' "$NEW_LOG" | grep -E "(\.ERROR:|\.CRITICAL:|Exception|Fatal error|UnhandledPromiseRejection|TypeError:)" | head -n 5 || true)
    if [ -n "$BAD_LOG" ]; then
        echo -e "${RED}[FAIL]${NC} Server runtime errors detected in $RUNTIME_LOG_FILE:"
        printf '%s\n' "$BAD_LOG"
        STATUS=1
    fi
fi

if [ "$STATUS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} Runtime guard passed with 0 server 5xx and 0 browser runtime errors."
    exit 0
fi
echo -e "${RED}[ERROR]${NC} Runtime guard blocked due to live runtime / console / HTTP errors!"
exit 1
