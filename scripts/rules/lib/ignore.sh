#!/usr/bin/env bash

GUIDELINES_DEFAULT_EXCLUDE="${GUIDELINES_DEFAULT_EXCLUDE:-(^|/)(vendor|node_modules|storage|\.git|\.next|\.svelte-kit|dist|build|\.dart_tool|coverage|tests|test|__tests__|__mocks__|cypress|e2e|playwright|k6|load-tests)(/|$)|(^|/)(bootstrap/cache|public/build|public/hot|public/vendor|resources/views/vendor|resources/views/errors|resources/views/mail|resources/views/emails|database/factories)(/|$)|\.(test|spec|d)\.[a-zA-Z0-9]+$|\.(config|setup)\.(js|cjs|mjs|ts|mts)$|(^|/)artisan$|(^|/)public/index\.php$|(^|/)bootstrap/(app|providers)\.php$}"

check_guard_file() {
    local f="$1"
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local st
        st=$(git status --porcelain -- "$f" 2>/dev/null || true)
        if [ -n "$st" ]; then
            echo -e "\033[0;33m[WARNING]\033[0m Uncommitted change in '$f' detected and IGNORED (only committed HEAD version is active)."
            if [[ "$st" == \?\?* ]]; then
                head -n 5 "$f" 2>/dev/null | sed 's/^/  + /' || true
            else
                { git diff --unified=0 -- "$f" 2>/dev/null; git diff --cached --unified=0 -- "$f" 2>/dev/null; } | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | head -n 5 | sed 's/^/  /' || true
            fi
        fi
    elif [ -f "$f" ]; then
        echo -e "\033[0;33m[WARNING]\033[0m '$f' found outside Git repo and ignored (commit inside Git to activate)."
    fi
}

compile_guidelines_ignore() {
    python3 - "$1" << 'PYEOF'
import sys, re
pats = []
for raw in sys.argv[1].splitlines():
    line = raw.strip()
    if not line or line.startswith('#'):
        continue
    anchored = line.startswith('/')
    if anchored:
        line = line[1:]
    if line.endswith('/'):
        line = line[:-1]
    has_slash = '/' in line
    rx, i = '', 0
    while i < len(line):
        if line[i:i+2] == '**':
            if i + 2 < len(line) and line[i+2] == '/':
                rx += '(.*/)?'; i += 3; continue
            rx += '.*'; i += 2; continue
        c = line[i]
        rx += '[^/]*' if c == '*' else ('[^/]' if c == '?' else re.escape(c))
        i += 1
    prefix = '^' if (anchored or has_slash) else '(^|/)'
    pats.append(f'({prefix}{rx}(/.*)?$)')
print('|'.join(pats))
PYEOF
}

init_guidelines_guard() {
    [ "${GUIDELINES_GUARD_INIT:-0}" = "1" ] && return 0
    GUIDELINES_GUARD_INIT=1
    check_guard_file ".guidelines.env"
    check_guard_file ".guidelinesignore"
    GUIDELINES_IGNORE_REGEX=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local env_data ignore_data count
        env_data=$(git show HEAD:.guidelines.env 2>/dev/null || true)
        if [ -n "$env_data" ]; then
            set -a
            eval "$env_data"
            set +a
        fi
        ignore_data=$(git show HEAD:.guidelinesignore 2>/dev/null || true)
        if [ -n "$ignore_data" ]; then
            GUIDELINES_IGNORE_REGEX=$(compile_guidelines_ignore "$ignore_data")
            count=$(printf '%s\n' "$ignore_data" | grep -cvE '^[[:space:]]*(#|$)' || echo 0)
            [ "$count" -gt 0 ] && echo -e "\033[0;34m[IGNORE-AUDIT]\033[0m Active HEAD:.guidelinesignore ($count pattern(s))."
        fi
    fi
    export GUIDELINES_GUARD_INIT GUIDELINES_DEFAULT_EXCLUDE GUIDELINES_IGNORE_REGEX
}

is_ignored() {
    local p="${1#./}"
    [[ "$p" =~ $GUIDELINES_DEFAULT_EXCLUDE ]] && return 0
    [ -n "${GUIDELINES_IGNORE_REGEX:-}" ] && [[ "$p" =~ $GUIDELINES_IGNORE_REGEX ]] && return 0
    return 1
}
