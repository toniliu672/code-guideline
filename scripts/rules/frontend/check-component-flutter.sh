#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [FRONTEND-FLUTTER] Enforcing Widget & Component-Based Modularity..."

if [ ! -f "pubspec.yaml" ] && [ ! -d "lib" ]; then
    echo -e "${YELLOW}[INFO]${NC} Neither 'pubspec.yaml' nor 'lib/' directory found. Skipping Flutter audit."
    exit 0
fi

HAS_WIDGETS=false
for w in "lib/widgets" "lib/components" "lib/src/widgets" "lib/ui/widgets"; do
    [ -d "$w" ] && HAS_WIDGETS=true
done

if [ "$HAS_WIDGETS" = false ]; then
    echo -e "${RED}[FAIL]${NC} 'lib/widgets/' or 'lib/components/' not found! Flutter architecture requires extracted modular custom widgets."
    exit 1
fi

SCREEN_DIRS=()
for s in "lib/screens" "lib/pages" "lib/views" "lib/ui/views"; do
    [ -d "$s" ] && SCREEN_DIRS+=("$s")
done

if [ ${#SCREEN_DIRS[@]} -gt 0 ]; then
    while IFS= read -r screen; do
        [[ -z "$screen" ]] && continue
        CHECKED=$((CHECKED + 1))
        lines=$(wc -l < "$screen")
        if [ "$lines" -gt 90 ]; then
            if ! grep -qE "import .*(widgets|components)" "$screen" 2>/dev/null; then
                echo -e "${RED}[FAIL]${NC} Monolithic Flutter screen detected without modular widget imports: $screen ($lines lines)"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done < <(find "${SCREEN_DIRS[@]}" -type f -name "*.dart" 2>/dev/null || true)
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED Flutter UI file(s) strictly adhere to Component-Based modularity."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS Flutter UI file(s) violating modular widget architecture!"
    exit 1
fi
