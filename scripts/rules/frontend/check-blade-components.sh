#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/.."
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

VIEWS_DIR="${VIEWS_DIR:-resources/views}"
BLADE_APPROACH="${BLADE_APPROACH:-standard}"
ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

if [ ! -d "$VIEWS_DIR" ]; then
    echo -e "${YELLOW}[INFO]${NC} Blade views directory ($VIEWS_DIR) not found. Skipping audit."
    exit 0
fi

if [ ! -d "$VIEWS_DIR/components" ]; then
    echo -e "${RED}[FAIL]${NC} '$VIEWS_DIR/components' not found! Blade requires modular component folder."
    exit 1
fi

if [ "$BLADE_APPROACH" = "standard" ]; then
    echo "==> [FRONTEND-BLADE] Auditing Standard Component & Layout Architecture..."
    RAW_TAGS="${BLADE_RAW_TAGS:-input|select|textarea|button}"
    [ -d "$VIEWS_DIR/components/admin" ] && echo -e "${BLUE}[INFO]${NC} Admin component separation detected: $VIEWS_DIR/components/admin"
    [ -d "$VIEWS_DIR/layouts" ] || [ -d "$VIEWS_DIR/layout" ] && echo -e "${BLUE}[INFO]${NC} Layout-based architecture detected: $VIEWS_DIR/layouts"
else
    echo "==> [FRONTEND-BLADE] Auditing Strict Atomic Blade Architecture..."
    RAW_TAGS="${BLADE_RAW_TAGS:-form|input|button|select|textarea}"
fi

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    is_exempt=false
    if [ "$BLADE_APPROACH" = "standard" ]; then
        if [[ "$file" =~ $VIEWS_DIR/components/ ]] || [[ "$file" =~ $VIEWS_DIR/layouts/ ]] || [[ "$file" =~ $VIEWS_DIR/layout/ ]]; then
            is_exempt=true
        fi
    else
        for exempt_dir in "components/atoms" "components/layouts" "atoms"; do
            if [[ "$file" =~ $exempt_dir ]]; then
                is_exempt=true
                break
            fi
        done
    fi
    [ "$is_exempt" = true ] && continue

    CHECKED=$((CHECKED + 1))
    violating=$(grep -n -E "<($RAW_TAGS)[[:space:]>]" "$file" 2>/dev/null || true)
    if [ -n "$violating" ]; then
        echo -e "${RED}[FAIL]${NC} Raw HTML element found outside components in page: $file"
        echo -e "       Delegate UI elements to reusable Blade components (e.g. <x-button>, <x-admin.button>, <x-input>)."
        echo "$violating" | head -n 3
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$VIEWS_DIR" -type f -name "*.blade.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null || true)

if [ "$CHECKED" -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No Blade page views found to audit in $VIEWS_DIR."
    exit 0
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED Blade page(s) strictly adhere to $BLADE_APPROACH Component & Layout Architecture."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS Blade view(s) containing forbidden raw HTML elements!"
    exit 1
fi
