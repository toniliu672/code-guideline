#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/.."
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

CHECK_SYNTAX="${CHECK_SYNTAX:-true}"
CHECK_STATIC_ANALYSIS="${CHECK_STATIC_ANALYSIS:-true}"
ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo "==> [CORE-LINT] Enforcing Syntax Integrity & Static Analysis..."

EXCLUDE="vendor|node_modules|storage|\.git"
PHP_FILES=()
while IFS= read -r f; do
    [[ -n "$f" ]] && PHP_FILES+=("$f")
done < <(find . -type f -name "*.php" 2>/dev/null | grep -vE "($EXCLUDE)" || true)

if [ ${#PHP_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO]${NC} No PHP source files found. Skipping PHP syntax/lint audit."
    exit 0
fi

if [ "$CHECK_SYNTAX" = "true" ] && command -v php >/dev/null 2>&1; then
    for f in "${PHP_FILES[@]}"; do
        if ! output=$(php -l "$f" 2>&1); then
            echo -e "${RED}[FAIL]${NC} PHP Syntax error in: $f"
            echo "$output"
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

for f in "${PHP_FILES[@]}"; do
    bad_throw=$(grep -nE "throw_(if|unless)[[:space:]]*\([^,]+,[[:space:]]*new[[:space:]]+[A-Za-z0-9_\\\\]*Exception" "$f" 2>/dev/null || true)
    if [ -n "$bad_throw" ]; then
        echo -e "${RED}[FAIL]${NC} Type-unsafe throw_if/throw_unless with 'new Exception()' in: $f"
        echo "$bad_throw" | head -n 2
        echo -e "${YELLOW}[FIX]${NC}  Pass class-string instead: throw_if(\$condition, CustomException::class, 'message')"
        ERRORS=$((ERRORS + 1))
    fi
done

if [ "$CHECK_STATIC_ANALYSIS" = "true" ]; then
    if [ -x "vendor/bin/phpstan" ]; then
        echo -e "${BLUE}[INFO]${NC} PHPStan / Larastan detected. Running static analysis..."
        if ! vendor/bin/phpstan analyse --no-progress 2>&1; then
            echo -e "${RED}[FAIL]${NC} PHPStan static analysis reported errors!"
            ERRORS=$((ERRORS + 1))
        fi
    fi
    if [ -x "vendor/bin/pint" ]; then
        echo -e "${BLUE}[INFO]${NC} Laravel Pint detected. Testing code style..."
        if ! vendor/bin/pint --test 2>&1; then
            echo -e "${RED}[FAIL]${NC} Laravel Pint found style violations!"
            ERRORS=$((ERRORS + 1))
        fi
    fi
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} All ${#PHP_FILES[@]} PHP file(s) passed syntax lint and static analysis checks."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS syntax / static analysis violation(s)!"
    exit 1
fi
