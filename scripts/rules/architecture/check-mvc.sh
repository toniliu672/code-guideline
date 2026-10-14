#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [ARCH-MVC] Enforcing MVC (Model-View-Controller) Separation of Concerns..."

CONTROLLER_DIRS=()
for d in "app/Http/Controllers" "src/controllers" "controllers"; do
    [ -d "$d" ] && CONTROLLER_DIRS+=("$d")
done

if [ ${#CONTROLLER_DIRS[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} MVC Controller directories not found. Skipping MVC audit."
    exit 0
fi

while IFS= read -r ctrl; do
    [[ -z "$ctrl" ]] && continue
    CHECKED=$((CHECKED + 1))
    
    if grep -nE "DB::raw|DB::statement|SELECT \* FROM" "$ctrl" 2>/dev/null; then
        echo -e "${RED}[FAIL]${NC} Raw SQL query detected in Controller: $ctrl (move to Repository or Model)"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "${CONTROLLER_DIRS[@]}" -type f -name "*Controller.php" -o -name "*Controller.ts" -o -name "*Controller.js" 2>/dev/null || true)

VIEW_DIRS=()
for v in "resources/views" "views" "src/views"; do
    [ -d "$v" ] && VIEW_DIRS+=("$v")
done

if [ ${#VIEW_DIRS[@]} -gt 0 ]; then
    while IFS= read -r view_file; do
        [[ -z "$view_file" ]] && continue
        if grep -nE "(App\\\\Models\\\\[A-Za-z]+::|Model::|->query\(\)|DB::table)" "$view_file" 2>/dev/null; then
            echo -e "${RED}[FAIL]${NC} Direct database query detected inside View: $view_file"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find "${VIEW_DIRS[@]}" -type f -name "*.blade.php" -o -name "*.ejs" -o -name "*.hbs" 2>/dev/null || true)
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED MVC file(s) comply with Separation of Concerns."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS MVC architecture violation(s)!"
    exit 1
fi
