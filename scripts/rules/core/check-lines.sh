#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

MAX_LINES="${MAX_LINES:-100}"
STRICT_LINES="${STRICT_LINES:-false}"
EXTENSIONS="php|blade\.php|js|jsx|ts|tsx|svelte|dart|py|sh"
EXCLUDE="vendor|node_modules|storage|\.git|\.next|\.svelte-kit|dist|build|\.dart_tool"

ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

CHECK_ALL=false
for arg in "$@"; do
    [ "$arg" == "--all" ] && CHECK_ALL=true
    [ "$arg" == "--strict" ] && STRICT_LINES=true
done

echo "==> [CORE] Enforcing Maximum $MAX_LINES Lines per File Limit..."
TARGET_FILES=()

if [ "$CHECK_ALL" = true ]; then
    while IFS= read -r f; do
        [[ -n "$f" ]] && TARGET_FILES+=("$f")
    done < <(find . -type f 2>/dev/null | grep -E "\.($EXTENSIONS)$" | grep -vE "($EXCLUDE)" || true)
else
    while IFS= read -r f; do
        [[ -n "$f" ]] && TARGET_FILES+=("$f")
    done < <(git status --porcelain 2>/dev/null | awk '{print $2}' | grep -E "\.($EXTENSIONS)$" || true)
fi

if [ ${#TARGET_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No modified git files to check for line limits (Use --all to scan entire project)."
    exit 0
fi

for file in "${TARGET_FILES[@]}"; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file")
        if [ "$lines" -gt "$MAX_LINES" ]; then
            echo -e "${YELLOW}[WARNING]${NC} $file exceeds $MAX_LINES lines limit ($lines lines)."
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All ${#TARGET_FILES[@]} file(s) comply with maximum $MAX_LINES lines limit."
    exit 0
else
    if [ "$STRICT_LINES" = "true" ]; then
        echo -e "${RED}[ERROR]${NC} Found $ERRORS file(s) exceeding $MAX_LINES lines! Refactor into modular units."
        exit 1
    else
        echo -e "${YELLOW}[WARNING]${NC} Found $ERRORS file(s) exceeding $MAX_LINES lines (modular refactoring recommended)."
        exit 0
    fi
fi
