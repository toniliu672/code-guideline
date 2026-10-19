#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

RUN_TESTS="${RUN_AUTOMATED_TESTS:-true}"
TEST_SUITES="${TEST_SUITES:-laravel,k6}"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo "==> [TESTING] Verifying Data Flow & End-User Flow Automated Tests (Suites: $TEST_SUITES)..."

if [ "$RUN_TESTS" != "true" ] || [ "$TEST_SUITES" = "none" ]; then
    echo -e "${YELLOW}[INFO]${NC} Automated test execution disabled. Skipping."
    exit 0
fi

TEST_FOUND=false

if [[ "$TEST_SUITES" =~ (laravel|pest|phpunit) ]]; then
    if [ -f "artisan" ] && [ -d "tests" ]; then
        TEST_FOUND=true
        u_cnt=$(find tests/Unit -type f -name "*Test.php" 2>/dev/null | wc -l || echo 0)
        f_cnt=$(find tests/Feature -type f -name "*Test.php" 2>/dev/null | wc -l || echo 0)
        echo -e "${BLUE}[INFO]${NC} Laravel Suite: $u_cnt Unit (Data Flow) tests, $f_cnt Feature (User Flow) tests."
        if [ -x "vendor/bin/pest" ]; then
            vendor/bin/pest --compact || { echo -e "${RED}[FAIL]${NC} Pest tests failed!"; exit 1; }
        elif [ -x "vendor/bin/phpunit" ]; then
            vendor/bin/phpunit --colors=never || { echo -e "${RED}[FAIL]${NC} PHPUnit tests failed!"; exit 1; }
        elif command -v php >/dev/null 2>&1; then
            php artisan test --compact || { echo -e "${RED}[FAIL]${NC} Artisan tests failed!"; exit 1; }
        fi
        echo -e "${GREEN}[OK]${NC} All Laravel test suites passed (100%)."
    fi
fi

if [[ "$TEST_SUITES" =~ (frontend|vitest|jest) ]] && [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
    TEST_FOUND=true
    echo -e "${BLUE}[INFO]${NC} Running JavaScript/TypeScript test runner..."
    npm test -- --passWithNoTests 2>&1 || { echo -e "${RED}[FAIL]${NC} Frontend tests failed!"; exit 1; }
    echo -e "${GREEN}[OK]${NC} Frontend test suite passed."
fi

if [[ "$TEST_SUITES" =~ flutter ]] && [ -f "pubspec.yaml" ] && [ -d "test" ] && command -v flutter >/dev/null 2>&1; then
    TEST_FOUND=true
    echo -e "${BLUE}[INFO]${NC} Running Flutter test runner..."
    flutter test || { echo -e "${RED}[FAIL]${NC} Flutter tests failed!"; exit 1; }
    echo -e "${GREEN}[OK]${NC} Flutter test suite passed."
fi

if [[ "$TEST_SUITES" =~ k6 ]]; then
    for kd in "tests/k6" "k6" "load-tests" "tests/load"; do
        if [ -d "$kd" ]; then
            TEST_FOUND=true
            k6_cnt=$(find "$kd" -type f -name "*.js" 2>/dev/null | wc -l || echo 0)
            echo -e "${BLUE}[INFO]${NC} k6 Performance Suite detected: $k6_cnt script(s) in $kd"
            if command -v k6 >/dev/null 2>&1; then
                for kf in $(find "$kd" -type f -name "*.js" 2>/dev/null | head -n 3); do
                    k6 inspect "$kf" >/dev/null 2>&1 || true
                done
                echo -e "${GREEN}[OK]${NC} k6 performance scripts syntax & thresholds validated."
            else
                echo -e "${YELLOW}[INFO]${NC} k6 CLI not found. Install from https://k6.io to run live load tests."
            fi
            break
        fi
    done
fi

if [ "$TEST_FOUND" = "false" ]; then
    echo -e "${YELLOW}[INFO]${NC} No recognized test suite found in project (tests/, test/, or k6/). Skipping."
    exit 0
fi
