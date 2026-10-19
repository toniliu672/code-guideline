#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

MAX_CHARS="${MAX_CLASS_CHARS:-100}"; MAX_WORDS="${MAX_CLASS_WORDS:-10}"
CHECK_COLORS="${CHECK_COLOR_TOKENS:-true}"; CHECK_TRAIN_TRACK="${CHECK_TRAIN_TRACK:-true}"
CHECK_CLASS_CONFLICTS="${CHECK_CLASS_CONFLICTS:-true}"; CHECK_CANONICAL="${CHECK_CANONICAL_CLASSES:-true}"
ERRORS=0; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [FRONTEND-DESIGN] Enforcing Global Tokens, Clean Classes & Tailwind Lint..."
EXCLUDE="vendor|node_modules|storage|\.git|\.next|\.svelte-kit|dist|build|\.test\.|\.spec\.|__tests__"; EXTS="tsx|jsx|js|svelte|blade\.php|vue|html"
SHADES="50|100|200|300|400|500|600|700|800|900|950"; PREFIXES="bg|text|border|ring|fill|stroke|accent|from|to|via|divide|outline|decoration|placeholder"
FAKE_TOKENS="tone|pri|indi|mystic|royal|ruby|mint|aqua|leaf|warmth|warm|neut|err|alert|notice|valid|magenta|soft|mono|ink"
ALLOWED_CSS_TOKENS="background|foreground|surface(-(muted|elevated|alt))?|card(-foreground)?|popover(-foreground)?|primary(-(foreground|soft|hover))?|secondary(-(foreground|soft))?|muted(-foreground)?|accent(-(foreground|soft))?|(success|warning|danger|destructive|info)(-(foreground|soft))?|border(-(subtle|strong))?|input|ring"
COLOR_REGEX="($PREFIXES)-\[(#|rgb|hsl)|($PREFIXES)-[a-zA-Z0-9_-]+-($SHADES)([[:space:]\"'\`}/]|$)|($PREFIXES)-($FAKE_TOKENS)(-[a-zA-Z0-9_-]+)?([[:space:]\"'\`}/]|$)|dark:($PREFIXES)-[a-zA-Z0-9_-]+|($PREFIXES)-(white|black)([[:space:]\"'\`}/]|$)|(text|fill|stroke)-(card|background|surface)([[:space:]\"'\`}/]|$)|bg-foreground([[:space:]\"'\`}/]|$)|style=[\"'][^\"']*(color|background(-color)?):[[:space:]]*(#|rgb|hsl)"

while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if [ "$CHECK_COLORS" = "true" ]; then
        violating=$(grep -nE -- "$COLOR_REGEX" "$f" 2>/dev/null || true)
        if [ -n "$violating" ]; then
            echo -e "${RED}[FAIL]${NC} Non-canonical color token, shade, or dark: utility in: $f"
            echo "$violating" | head -n 2
            echo -e "${YELLOW}[FIX]${NC}  Use ONLY canonical role tokens: background, foreground, surface, card, primary, secondary, muted, accent, success, warning, danger, info, border (with optional -foreground or -soft). No shades (-50..-950), no dark:text-*, no fake aliases (tone, pri, indi)."
            ERRORS=$((ERRORS + 1))
        fi
    fi
    if [ "$CHECK_CLASS_CONFLICTS" = "true" ]; then
        conflicts=$(awk '
        match($0, /class(Name)?=["\x27]([^"\x27]+)["\x27]/, arr) {
            str = " " arr[2] " "
            if (str ~ / hidden / && str ~ / (flex|block|grid|inline) /) print NR ": Conflicting display (hidden and flex/block): " arr[2]
            if ((str ~ / text-left / && str ~ / text-right /) || (str ~ / text-center / && str ~ / text-right /)) print NR ": Conflicting text alignment: " arr[2]
        }' "$f" 2>/dev/null || true)
        if [ -n "$conflicts" ]; then
            echo -e "${RED}[FAIL]${NC} Tailwind class conflict detected in: $f"
            echo "$conflicts" | head -n 2
            echo -e "${YELLOW}[FIX]${NC}  Remove one of the conflicting classes or add a breakpoint prefix (e.g. 'hidden md:flex')."
            ERRORS=$((ERRORS + 1))
        fi
    fi
    if [ "$CHECK_CANONICAL" = "true" ]; then
        canonical=$(awk '
        BEGIN { split("1 2 3 4 5 6 7 8 9 10 11 12 14 16 20 24 28 32 36 40 44 48 52 56 60 64 72 80 96", s, " "); for (i in s) scale[s[i]]=1 }
        {
            line = $0
            while (match(line, /(w|h|min-w|min-h|max-w|max-h|p|px|py|pt|pr|pb|pl|m|mx|my|mt|mr|mb|ml|gap|top|right|bottom|left|inset)-\[([0-9]+)px\]/, arr)) {
                px = arr[2] + 0
                if (px % 4 == 0 && (px / 4) in scale) print NR ": Class `" arr[0] "` can be written as `" arr[1] "-" (px/4) "` (suggestCanonicalClasses)"
                line = substr(line, RSTART + RLENGTH)
            }
            if (match($0, /(w|h|min-w|min-h|max-w|max-h)-\[100%\]/, arr2)) print NR ": Class `" arr2[0] "` can be written as `" arr2[1] "-full` (suggestCanonicalClasses)"
        }' "$f" 2>/dev/null || true)
        if [ -n "$canonical" ]; then
            echo -e "${RED}[FAIL]${NC} Non-canonical Tailwind arbitrary class in: $f"
            echo "$canonical" | head -n 2
            echo -e "${YELLOW}[FIX]${NC}  Replace arbitrary bracket class directly with the suggested canonical Tailwind class above."
            ERRORS=$((ERRORS + 1))
        fi
    fi
done < <(find . -type f 2>/dev/null | grep -E "\.($EXTS)$" | grep -vE "($EXCLUDE|tailwind\.config)" || true)

if [ "$CHECK_COLORS" = "true" ]; then
    while IFS= read -r cf; do
        [[ -z "$cf" ]] && continue
        css_viol=$(grep -noE -- "--color-[a-zA-Z0-9_-]+[[:space:]]*:" "$cf" 2>/dev/null | grep -vE -- "--color-($ALLOWED_CSS_TOKENS)[[:space:]]*:" || true)
        [ -z "$css_viol" ] && css_viol=$(grep -nE -- "@apply [^;]*(($PREFIXES)-[a-zA-Z0-9_-]+-($SHADES)|dark:($PREFIXES)-|($PREFIXES)-(white|black|$FAKE_TOKENS)|(text|fill|stroke)-(card|background|surface))" "$cf" 2>/dev/null || true)
        if [ -n "$css_viol" ]; then
            echo -e "${RED}[FAIL]${NC} Non-canonical @theme token or @apply shade in CSS: $cf"
            echo "$css_viol" | head -n 2
            echo -e "${YELLOW}[FIX]${NC}  In @theme, ONLY define canonical tokens (--color-background, --color-foreground, --color-surface, --color-card, --color-primary, --color-secondary, --color-muted, --color-accent, --color-success, --color-warning, --color-danger, --color-info, --color-border)."
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find . -type f 2>/dev/null | grep -E "\.css$" | grep -vE "($EXCLUDE)" || true)
fi

if [ "$CHECK_TRAIN_TRACK" = "true" ]; then
    while IFS= read -r page; do
        [ ! -f "$page" ] && continue
        track_violations=$(awk -v max_c="$MAX_CHARS" -v max_w="$MAX_WORDS" '
        match($0, /class(Name)?=["`{]+([^"`}]+)["`}]/, arr) {
            str = arr[2]; n = split(str, words, " ")
            if (length(str) > max_c || n > max_w) print NR "|" n " classes|" length(str) " chars|" substr(str, 1, 45) "..."
        }' "$page" 2>/dev/null || true)
        if [ -n "$track_violations" ]; then
            echo -e "${RED}[FAIL]${NC} Train-track class string in page: $page"
            echo "$track_violations" | head -n 2
            echo -e "${YELLOW}[FIX]${NC}  Extract element into a reusable component (<x-...> / components/) or @layer components in app.css."
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find . -type f 2>/dev/null | grep -E "(app/.*/page\.(tsx|jsx|js)|pages/.*\.(tsx|jsx|js)|src/routes/.*\+page\.svelte|resources/views/.*\.blade\.php)" | grep -vE "resources/views/(components|layouts|layout)" | grep -vE "($EXCLUDE)" || true)
fi

[ "$ERRORS" -eq 0 ] && { echo -e "${GREEN}[OK]${NC} Design system & Tailwind styling validated 100%."; exit 0; }
echo -e "${RED}[ERROR]${NC} Found $ERRORS design system / styling violation(s)!"
exit 1
