#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [ARCH-SERVICE-LAYER] Enforcing Service Layer & Thin Controllers..."

SERVICE_DIRS=()
for d in "app/Services" "src/services" "services"; do
    [ -d "$d" ] && SERVICE_DIRS+=("$d")
done

if [ ${#SERVICE_DIRS[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} Service Layer directory not found. Skipping Service Layer audit."
    exit 0
fi

EXCLUDE="vendor|node_modules|storage|\.git|\.next|\.svelte-kit|dist|build"
CONTROLLER_DIRS=()
while IFS= read -r d; do
    [[ -n "$d" ]] && CONTROLLER_DIRS+=("$d")
done < <(find . -type d -iname "controllers" 2>/dev/null | grep -vE "($EXCLUDE)" || true)

if [ ${#CONTROLLER_DIRS[@]} -gt 0 ]; then
    while IFS= read -r ctrl; do
        [[ -z "$ctrl" ]] && continue
        CHECKED=$((CHECKED + 1))
        lines=$(wc -l < "$ctrl")
        if [ "$lines" -gt 80 ]; then
            if ! grep -qE "(Service|service)" "$ctrl" 2>/dev/null; then
                echo -e "${RED}[FAIL]${NC} Fat Controller detected without Service Layer delegation: $ctrl ($lines lines)"
                ERRORS=$((ERRORS + 1))
            fi
        fi
        if [ -d "app/Providers" ]; then
            while IFS= read -r iface; do
                [[ -z "$iface" ]] && continue
                if ! grep -rnq "$iface" app/Providers/ bootstrap/ 2>/dev/null; then
                    echo -e "${RED}[FAIL]${NC} Unbound Interface injected: $iface in $ctrl is missing from app/Providers/!"
                    echo -e "${YELLOW}[FIX]${NC}  Register in AppServiceProvider: \$this->app->bind(${iface}::class, Implementation::class);"
                    ERRORS=$((ERRORS + 1))
                fi
            done < <(grep -oE "[A-Za-z0-9_]+Interface\b" "$ctrl" 2>/dev/null | sort -u || true)
        fi
    done < <({ find "${CONTROLLER_DIRS[@]}" -type f \( -name "*.php" -o -name "*.ts" -o -name "*.js" \) 2>/dev/null; find . -type f \( -name "*Controller.php" -o -name "*Controller.ts" -o -name "*Controller.js" \) 2>/dev/null | grep -vE "($EXCLUDE)"; } | sort -u || true)
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED controller(s) comply with Thin Controller & Service Layer architecture."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS controller(s) violating Service Layer standards!"
    exit 1
fi
