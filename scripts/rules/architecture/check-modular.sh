#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [ARCH-MODULAR] Enforcing Modular & Feature-Driven Architecture Boundaries..."

MODULAR_DIRS=()
for d in "modules" "src/modules" "src/features" "app/Modules"; do
    [ -d "$d" ] && MODULAR_DIRS+=("$d")
done

if [ ${#MODULAR_DIRS[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} Modular architecture directories not found. Skipping modular audit."
    exit 0
fi

for mod_root in "${MODULAR_DIRS[@]}"; do
    for module in "$mod_root"/*; do
        [ ! -d "$module" ] && continue
        mod_name=$(basename "$module")
        CHECKED=$((CHECKED + 1))
        
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            if grep -nE "from ['\"].*/(modules|features)/(?!$mod_name/).*/internal/" "$f" 2>/dev/null; then
                echo -e "${RED}[FAIL]${NC} Module encapsulation violation in: $f (direct access to another module's internal state forbidden)"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(find "$module" -type f -name "*.ts" -o -name "*.js" -o -name "*.php" 2>/dev/null || true)
    done
done

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED module(s) strictly comply with Modular & Feature-Driven boundaries."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS modular encapsulation violation(s)!"
    exit 1
fi
