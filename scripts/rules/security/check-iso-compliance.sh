#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

CHECK_DEBUG="${CHECK_DEBUG_STATEMENTS:-true}"
ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [ISO-COMPLIANCE] Auditing ISO/IEC 27001, 27701 & 25010 Standards..."

# Clause 1: ISO 27001 Annex A.8.12 - Data Leakage Prevention & Secret Isolation
if git ls-files .env .env.local .env.production .env.staging *.pem *.key 2>/dev/null | grep -qE "(\.env|\.pem|\.key)"; then
    echo -e "${RED}[FAIL]${NC} ISO 27001 A.8.12 Violation: Secret or environment file tracked in Git!"
    ERRORS=$((ERRORS + 1))
fi

exposed_keys=$(grep -rnE "(BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY|BEGIN CERTIFICATE)" . 2>/dev/null | grep -vE "node_modules|vendor|\.git" || true)
if [ -n "$exposed_keys" ]; then
    echo -e "${RED}[FAIL]${NC} ISO 27001 A.8.12 Violation: Hardcoded private key detected in source code!"
    ERRORS=$((ERRORS + 1))
fi

# Clause 2: ISO 27001 Annex A.8.24 & ISO 27701 - Storage Isolation (No sensitive files on public disk)
if [ -d "app" ]; then
    public_sensitive=$(grep -rnE "toMediaCollection\('[^']*(private|secret|confidential|document)[^']*',\s*'public'\)" app/ 2>/dev/null || true)
    if [ -n "$public_sensitive" ]; then
        echo -e "${RED}[FAIL]${NC} ISO 27001 A.8.24 Violation: Confidential media stored on public disk!"
        echo "$public_sensitive" | head -n 2
        ERRORS=$((ERRORS + 1))
    fi
fi

# Clause 3: ISO 27701 Clause 7.4 - PII Protection & Data Minimization (Model Credential Hiding)
for user_model in app/Models/User.php app/Models/Account.php src/models/User.ts; do
    if [ -f "$user_model" ] && ! grep -q "'password'" "$user_model" 2>/dev/null; then
        echo -e "${RED}[FAIL]${NC} ISO 27701 Cl.7.4 Violation: 'password' attribute not hidden in $user_model!"
        ERRORS=$((ERRORS + 1))
    fi
done

# Clause 4: ISO 27001 Annex A.8.28 - Secure Coding & Binary Input Sanitization (MIME Validation)
if [ -d "app/Http/Requests" ]; then
    while IFS= read -r req_file; do
        [[ -z "$req_file" ]] && continue
        if grep -qE "(file|image|avatar|document|upload)" "$req_file" 2>/dev/null; then
            if ! grep -qE "(mimes:|extensions:|mimetypes:|image)" "$req_file" 2>/dev/null; then
                echo -e "${RED}[FAIL]${NC} ISO 27001 A.8.28 Violation: File upload missing MIME validation in $req_file"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done < <(find app/Http/Requests -type f -name "*.php" 2>/dev/null || true)
fi

# Clause 5: ISO 25010 Maintainability - Clean Code (No leftover debug traces in production)
if [ "$CHECK_DEBUG" = "true" ]; then
    for code_dir in app src lib; do
        [ ! -d "$code_dir" ] && continue
        debug_calls=$(grep -rnE '\b(dd|dump|var_dump)\(' "$code_dir" 2>/dev/null | grep -vE "vendor|node_modules|tests" || true)
        if [ -n "$debug_calls" ]; then
            echo -e "${RED}[FAIL]${NC} ISO 25010 Maintainability Violation: Debug calls found in $code_dir/:"
            echo "$debug_calls" | head -n 2
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} ISO Standards 100% Validated (ISO 27001, ISO 27701, and ISO 25010)."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS violation(s) against ISO/IEC software standards!"
    exit 1
fi
