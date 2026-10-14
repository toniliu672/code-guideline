#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [FRONTEND-SVELTE] Enforcing Component-Based Architecture..."

if [ ! -d "src/routes" ] && [ ! -d "src/components" ]; then
    echo -e "${YELLOW}[INFO]${NC} Svelte/SvelteKit directory structure not found. Skipping audit."
    exit 0
fi

HAS_SVELTE_COMPONENTS=false
for d in "src/lib/components" "src/components" "src/lib"; do
    [ -d "$d" ] && HAS_SVELTE_COMPONENTS=true
done

if [ "$HAS_SVELTE_COMPONENTS" = false ]; then
    echo -e "${RED}[FAIL]${NC} 'src/lib/components/' not found! Svelte projects require isolated modular components."
    exit 1
fi

if [ -d "src/routes" ]; then
    while IFS= read -r page; do
        [[ -z "$page" ]] && continue
        CHECKED=$((CHECKED + 1))
        lines=$(wc -l < "$page")
        if [ "$lines" -gt 80 ]; then
            if ! grep -qE "(from ['\"](\$lib/components|\.\./components)|\.svelte)" "$page" 2>/dev/null; then
                echo -e "${RED}[FAIL]${NC} Monolithic Svelte route detected without modular components: $page ($lines lines)"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done < <(find src/routes -type f -name "+page.svelte" 2>/dev/null || true)
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED Svelte route(s) adhere to modular Component-Based architecture."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS Svelte route(s) violating component-based architecture!"
    exit 1
fi
