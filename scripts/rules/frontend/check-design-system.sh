#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

MAX_CHARS="${MAX_CLASS_CHARS:-100}"
MAX_WORDS="${MAX_CLASS_WORDS:-10}"
CHECK_COLORS="${CHECK_COLOR_TOKENS:-true}"
CHECK_TRAIN_TRACK="${CHECK_TRAIN_TRACK:-true}"

ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [FRONTEND-DESIGN] Enforcing Global Color Tokens & Anti-Train-Track Classes..."

EXCLUDE="vendor|node_modules|storage|\.git|\.next|\.svelte-kit|dist|build"
EXTS="tsx|jsx|js|svelte|blade\.php|vue|html"

# 1. Audit Global Color Tokens: Prohibit hardcoded arbitrary color classes
if [ "$CHECK_COLORS" = "true" ]; then
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        violating=$(grep -nE "(bg|text|border|fill|stroke|ring|accent|from|to|via)-\[#|(bg|text|border)-\[(rgb|hsl)|style=[\"'][^\"']*(color|background):[[:space:]]*#" "$f" 2>/dev/null || true)
        if [ -n "$violating" ]; then
            echo -e "${RED}[FAIL]${NC} Arbitrary hardcoded color found in: $f"
            echo -e "       Colors must be defined globally in app.css / globals.css (CSS variables/theme tokens)."
            echo "$violating" | head -n 2
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find . -type f 2>/dev/null | grep -E "\.($EXTS)$" | grep -vE "($EXCLUDE|app\.css|globals\.css|tailwind\.config)" || true)
fi

# 2. Audit Anti-Train-Track Class Strings: Prohibit monolithic class-soup in page files
if [ "$CHECK_TRAIN_TRACK" = "true" ]; then
    PAGE_FILES=()
    while IFS= read -r p; do
        [[ -n "$p" ]] && PAGE_FILES+=("$p")
    done < <(find . -type f 2>/dev/null | grep -E "(app/.*/page\.(tsx|jsx|js)|pages/.*\.(tsx|jsx|js)|src/routes/.*\+page\.svelte|resources/views/.*\.blade\.php)" | grep -v "resources/views/components" | grep -vE "($EXCLUDE)" || true)

    for page in "${PAGE_FILES[@]}"; do
        [ ! -f "$page" ] && continue
        track_violations=$(awk -v max_c="$MAX_CHARS" -v max_w="$MAX_WORDS" '
        match($0, /class(Name)?=["`{]+([^"`}]+)["`}]/, arr) {
            str = arr[2]
            n = split(str, words, " ")
            if (length(str) > max_c || n > max_w) {
                print NR "|" n "|" length(str) "|" substr(str, 1, 45) "..."
            }
        }' "$page" 2>/dev/null || true)

        if [ -n "$track_violations" ]; then
            echo -e "${RED}[FAIL]${NC} Train-track class string detected in page: $page"
            echo -e "       Avoid long utility class strings in pages; extract to a reusable component / CVA variant."
            echo "$track_violations" | head -n 2
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} Design system styling validated (Global color tokens & clean page classes)."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS design system / styling violation(s)!"
    exit 1
fi
