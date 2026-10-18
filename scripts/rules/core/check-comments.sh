#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

CODE_DIRS="${CODE_DIRS:-app src lib routes database components pages}"
ERRORS=0
CHECKED=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [CORE] Enforcing Zero Inline Comments Rule..."

EXISTING_DIRS=()
for d in $CODE_DIRS resources/views; do
    [ -d "$d" ] && EXISTING_DIRS+=("$d")
done

if [ ${#EXISTING_DIRS[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No source code directories found. Skipping comments audit."
    exit 0
fi

EXTENSIONS="php|blade\.php|js|jsx|ts|tsx|svelte|dart"
EXCLUDE_DIRS="vendor|node_modules|storage|\.git|\.next|\.svelte-kit|dist|build|\.dart_tool"

while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    CHECKED=$((CHECKED + 1))
    
    violating=$(grep -n -E '^[[:space:]]*//|<!--|{{--' "$file" 2>/dev/null || true)
    if [ -n "$violating" ]; then
        echo -e "${RED}[FAIL]${NC} Forbidden inline comment found in: $file"
        echo "$violating" | head -n 3
        echo -e "${YELLOW}[FIX]${NC}  Remove inline comments (//, <!--, {{-- ) and use descriptive variable/function names instead."
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "${EXISTING_DIRS[@]}" -type f 2>/dev/null | grep -E "\.($EXTENSIONS)$" | grep -vE "($EXCLUDE_DIRS)" || true)

if [ "$CHECKED" -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No code files matched for comments audit."
    exit 0
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All $CHECKED code file(s) are clean of inline comments (Zero Inline Comments)."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS file(s) violating the Zero Inline Comments rule!"
    exit 1
fi
