#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/.."
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

VIEWS_DIR="${VIEWS_DIR:-resources/views}"
BLADE_APPROACH="${BLADE_APPROACH:-auto}"
STRICTNESS_LEVEL="${STRICTNESS_LEVEL:-standard}"
MAX_PHP_BLOCK_LINES="${MAX_BLADE_PHP_LINES:-3}"
ERRORS=0; CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

if [ ! -d "$VIEWS_DIR" ]; then
    echo -e "${YELLOW}[INFO]${NC} Blade views directory ($VIEWS_DIR) not found. Skipping audit."
    exit 0
fi

if [ ! -d "$VIEWS_DIR/components" ]; then
    echo -e "${RED}[FAIL]${NC} '$VIEWS_DIR/components' not found! Blade requires modular component folder."
    echo -e "${YELLOW}[FIX]${NC}  Create '$VIEWS_DIR/components' and place reusable UI components (<x-...>) inside."
    exit 1
fi

if [ "$BLADE_APPROACH" = "auto" ]; then
    if [ -d "$VIEWS_DIR/components/atoms" ]; then BLADE_APPROACH="atomic"
    elif [ -d "$VIEWS_DIR/components/admin" ]; then BLADE_APPROACH="admin-separated"
    else BLADE_APPROACH="standard"; fi
fi

if [ "$BLADE_APPROACH" = "admin-separated" ] && [ ! -d "$VIEWS_DIR/components/admin" ]; then
    echo -e "${RED}[FAIL]${NC} '$VIEWS_DIR/components/admin' required for admin-separated architecture!"
    echo -e "${YELLOW}[FIX]${NC}  Create '$VIEWS_DIR/components/admin' for admin UI and '$VIEWS_DIR/components' for shared UI."
    exit 1
fi

case "$STRICTNESS_LEVEL" in
    strict)   DEFAULT_TAGS="input|select|textarea|button|form|table|thead|tbody|tr|td|th|svg|img|p|span|h[1-6]|ul|li|a" ;;
    moderate) DEFAULT_TAGS="input|select|textarea|button|form|table|thead|tbody|tr|td|th|svg" ;;
    *)        DEFAULT_TAGS="input|select|textarea|button" ;;
esac
[ "$BLADE_APPROACH" = "atomic" ] && [ "$STRICTNESS_LEVEL" = "standard" ] && DEFAULT_TAGS="form|input|button|select|textarea"
RAW_TAGS="${BLADE_RAW_TAGS:-$DEFAULT_TAGS}"
echo "==> [FRONTEND-BLADE] Auditing Blade ($BLADE_APPROACH | Level: $STRICTNESS_LEVEL)..."

while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    is_exempt=false
    if [ "$BLADE_APPROACH" != "atomic" ]; then
        if [[ "$file" =~ $VIEWS_DIR/components/ ]] || [[ "$file" =~ $VIEWS_DIR/layouts/ ]] || [[ "$file" =~ $VIEWS_DIR/layout/ ]]; then
            is_exempt=true
        fi
    else
        for exempt_dir in "components/atoms" "components/layouts" "atoms"; do
            [[ "$file" =~ $exempt_dir ]] && { is_exempt=true; break; }
        done
    fi
    [ "$is_exempt" = true ] && continue

    CHECKED=$((CHECKED + 1))
    violating=$(grep -n -E "<($RAW_TAGS)[[:space:]>]" "$file" 2>/dev/null || true)
    if [ -n "$violating" ]; then
        echo -e "${RED}[FAIL]${NC} Raw HTML element found outside components in page: $file"
        echo "$violating" | head -n 3
        echo -e "${YELLOW}[FIX]${NC}  Replace raw HTML tags with reusable Blade components (e.g. <x-button>, <x-admin.button>, <x-input>)."
        ERRORS=$((ERRORS + 1))
    fi

    php_blocks=$(awk -v max_l="$MAX_PHP_BLOCK_LINES" '
    /@php/ && /@endphp/ { next }
    /@php/ { in_php=1; start=NR; c=0; next }
    /@endphp/ { if (in_php && c > max_l) print "Lines " start "-" NR " (" c " lines inside @php...@endphp)"; in_php=0; next }
    in_php { c++ }
    ' "$file" 2>/dev/null || true)
    if [ -n "$php_blocks" ]; then
        echo -e "${RED}[FAIL]${NC} Verbose @php data/logic block in page view: $file ($php_blocks)"
        echo -e "${YELLOW}[FIX]${NC}  Move data arrays to Controller/Service, or use compact inline destructuring:"
        echo -e "       @foreach ([['Label', \$val, 'icon', 'primary']] as [\$label, \$val, \$icon, \$variant]) <x-stat-card .../> @endforeach"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$VIEWS_DIR" -type f -name "*.blade.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" 2>/dev/null || true)

[ "$CHECKED" -eq 0 ] && { echo -e "${YELLOW}[INFO]${NC} No Blade page views found to audit in $VIEWS_DIR."; exit 0; }
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED Blade page(s) strictly adhere to $BLADE_APPROACH Component & Layout Architecture."
    exit 0
fi
echo -e "${RED}[ERROR]${NC} Found $ERRORS Blade view violation(s)!"
exit 1
