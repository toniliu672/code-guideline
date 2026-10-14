#!/usr/bin/env bash
set -euo pipefail

VIEWS_DIR="${VIEWS_DIR:-resources/views}"
ATOMIC_EXEMPT_DIRS="${ATOMIC_EXEMPT_DIRS:-resources/views/components/atoms resources/views/components/layouts resources/views/atoms}"

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [FRONTEND-BLADE] Enforcing Strict Atomic Components Architecture..."

if [ ! -d "$VIEWS_DIR" ]; then
    echo -e "${YELLOW}[INFO]${NC} Blade views directory ($VIEWS_DIR) not found. Skipping audit."
    exit 0
fi

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    is_exempt=false
    for exempt_dir in $ATOMIC_EXEMPT_DIRS; do
        if [[ "$file" =~ $exempt_dir ]]; then
            is_exempt=true
            break
        fi
    done
    [ "$is_exempt" = true ] && continue

    CHECKED=$((CHECKED + 1))
    violating=$(grep -n -E '<(form|input|button|select|textarea)[[:space:]>]' "$file" 2>/dev/null || true)
    if [ -n "$violating" ]; then
        echo -e "${RED}[FAIL]${NC} Raw HTML element found outside atomic components in: $file"
        echo "$violating" | head -n 3
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$VIEWS_DIR" -type f -name "*.blade.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null || true)

if [ "$CHECKED" -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No non-atomic Blade views to audit in $VIEWS_DIR."
    exit 0
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED Blade views strictly adhere to Atomic Component Architecture."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS Blade view(s) containing forbidden raw HTML elements!"
    exit 1
fi
