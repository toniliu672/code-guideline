#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

echo "==> [SECURITY-ISO] Enforcing ISO 27001/27701 Security & Privacy Standards..."

if ! bash "$SCRIPT_DIR/check-security.sh"; then
    ERRORS=$((ERRORS + 1))
fi

if [ -f "routes/web.php" ]; then
    if grep -q "activity-logs" routes/web.php 2>/dev/null; then
        if ! grep -q "activity-logs.view" routes/web.php 2>/dev/null; then
            echo -e "${RED}[FAIL]${NC} ISO 27001 Annex A.9 Violation: Activity logs route lacks authorization guard!"
            ERRORS=$((ERRORS + 1))
        fi
    fi
fi

if [ -d "app" ]; then
    if grep -rn "toMediaCollection('ktp_document', 'public')" app/ 2>/dev/null; then
        echo -e "${RED}[FAIL]${NC} ISO 27001 Violation: Citizen identity document stored in public disk!"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} ISO Security & Data Privacy standards validated."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS ISO security standard violation(s)!"
    exit 1
fi
