#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [FRONTEND-REACT/NEXT] Enforcing Component-Based Architecture..."

PAGE_DIRS=()
for d in "src/app" "app" "src/pages" "pages"; do
    [ -d "$d" ] && PAGE_DIRS+=("$d")
done

if [ ${#PAGE_DIRS[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No React/Next.js page directories found. Skipping audit."
    exit 0
fi

HAS_COMPONENTS=false
for c in "src/components" "components"; do
    [ -d "$c" ] && HAS_COMPONENTS=true
done

if [ "$HAS_COMPONENTS" = false ]; then
    echo -e "${RED}[FAIL]${NC} 'components/' directory not found! Component-based architecture requires modular UI components."
    exit 1
fi

while IFS= read -r page; do
    [[ -z "$page" ]] && continue
    CHECKED=$((CHECKED + 1))
    
    lines=$(wc -l < "$page")
    if [ "$lines" -gt 80 ]; then
        if ! grep -qE "from ['\"].*(components|\.\./)" "$page" 2>/dev/null; then
            echo -e "${RED}[FAIL]${NC} Monolithic page detected without modular component imports: $page ($lines lines)"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done < <(find "${PAGE_DIRS[@]}" -type f -name "page.tsx" -o -name "page.jsx" -o -name "page.js" -o -name "*.tsx" 2>/dev/null | grep -vE "node_modules|\.next|build|dist" || true)

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED React/Next.js pages comply with modular Component-Based architecture."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS violation(s) in React/Next.js component-based architecture!"
    exit 1
fi
