#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

CHECK_DEBUG_STATEMENTS="${CHECK_DEBUG_STATEMENTS:-true}"

ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [SECURITY] Enforcing Security & Data Privacy Standards..."

if [ -d "app" ]; then
    sensitive_public=$(grep -rnE "toMediaCollection\('(ktp|ktp_document|attachments|dokumen_rahasia|private_docs)[^']*',\s*'public'\)" app/ 2>/dev/null || true)
    if [ -n "$sensitive_public" ]; then
        echo -e "${RED}[FAIL]${NC} Security Violation: Sensitive document uploaded to public disk!"
        echo "$sensitive_public" | head -n 3
        ERRORS=$((ERRORS + 1))
    fi
fi

if git ls-files .env 2>/dev/null | grep -q "^\.env$"; then
    echo -e "${RED}[FAIL]${NC} Critical Security Violation: '.env' file is tracked in Git repository!"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "app/Models/User.php" ]; then
    if ! grep -q "'password'" app/Models/User.php 2>/dev/null; then
        echo -e "${RED}[FAIL]${NC} Privacy Violation: Password attribute is not hidden in User Model!"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ -d "app/Http/Requests" ]; then
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        if grep -qE "document|file|ktp|lampiran|berkas" "$file" 2>/dev/null; then
            if ! grep -qE "mimes:|extensions:|image|mimetypes:" "$file" 2>/dev/null; then
                echo -e "${RED}[FAIL]${NC} Uploaded file input lacks MIME type validation in: $file"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done < <(find app/Http/Requests -type f -name "*.php" 2>/dev/null || true)
fi

if [ "$CHECK_DEBUG_STATEMENTS" = "true" ] && [ -d "app" ]; then
    debug_calls=$(grep -rnE '\b(dd|dump|var_dump)\(' app/ 2>/dev/null || true)
    if [ -n "$debug_calls" ]; then
        echo -e "${RED}[FAIL]${NC} Leftover debug statement(s) found in app/:"
        echo "$debug_calls" | head -n 3
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} Security and data privacy standards 100% validated."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS security and data privacy violation(s)!"
    exit 1
fi
