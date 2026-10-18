#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/rules"
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

# MASTER RULES CONFIGURATION (Configure here or via config.env)
ENABLE_CORE="${ENABLE_CORE:-true}"; FRONTEND_APPROACH="${FRONTEND_APPROACH:-auto}"
BLADE_APPROACH="${BLADE_APPROACH:-standard}"; ARCHITECTURE_APPROACH="${ARCHITECTURE_APPROACH:-auto}"
ENABLE_SECURITY="${ENABLE_SECURITY:-true}"

for arg in "$@"; do
    case "$arg" in
        --update|--global|--clean=*) exec bash "$SCRIPT_DIR/install.sh" "$@" ;;
        --frontend=*) FRONTEND_APPROACH="${arg#*=}" ;;
        --blade=*) BLADE_APPROACH="${arg#*=}" ;;
        --arch=*) ARCHITECTURE_APPROACH="${arg#*=}" ;;
        --no-core) ENABLE_CORE=false ;;
        --no-security) ENABLE_SECURITY=false ;;
    esac
done

PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)" | tr '[:lower:]' '[:upper:]')}"
FAILED=0; RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   MASTER AUDIT: ${PROJECT_NAME} (RULES & GUIDELINES ENGINE)     ${NC}"
echo -e "${BLUE}================================================================${NC}"

run_step() {
    local script="$2"
    shift 2
    if [ -f "$script" ] && ! bash "$script" "$@"; then
        FAILED=$((FAILED + 1))
    fi
    [ -f "$script" ] && echo ""
}

TARGET="${1:-all}"
[[ "$TARGET" == --* ]] && TARGET="all"

case "$TARGET" in
    core)
        run_step "Zero Comments" "$RULES_DIR/core/check-comments.sh"
        run_step "Lines Limit" "$RULES_DIR/core/check-lines.sh"
        run_step "Syntax & Lint" "$RULES_DIR/core/check-syntax-lint.sh"
        ;;
    lint|syntax)
        run_step "Syntax & Lint" "$RULES_DIR/core/check-syntax-lint.sh"
        ;;
    frontend|ui)
        export FRONTEND_APPROACH BLADE_APPROACH
        run_step "Frontend" "$RULES_DIR/frontend/check-component-based.sh"
        run_step "Design System" "$RULES_DIR/frontend/check-design-system.sh"
        ;;
    design|colors|styling)
        run_step "Design System" "$RULES_DIR/frontend/check-design-system.sh"
        ;;
    arch|architecture)
        export ARCHITECTURE_APPROACH
        run_step "Architecture" "$RULES_DIR/architecture/check-architecture.sh"
        ;;
    security|iso)
        run_step "ISO Compliance" "$RULES_DIR/security/check-iso-compliance.sh"
        ;;
    all)
        [ "$ENABLE_CORE" = "true" ] && {
            run_step "Zero Comments" "$RULES_DIR/core/check-comments.sh"
            run_step "Lines Limit" "$RULES_DIR/core/check-lines.sh"
            run_step "Syntax & Lint" "$RULES_DIR/core/check-syntax-lint.sh"
        }
        [ "$FRONTEND_APPROACH" != "none" ] && {
            export FRONTEND_APPROACH BLADE_APPROACH
            run_step "Frontend" "$RULES_DIR/frontend/check-component-based.sh"
            run_step "Design System" "$RULES_DIR/frontend/check-design-system.sh"
        }
        [ "$ARCHITECTURE_APPROACH" != "none" ] && {
            export ARCHITECTURE_APPROACH
            run_step "Architecture" "$RULES_DIR/architecture/check-architecture.sh"
        }
        [ "$ENABLE_SECURITY" = "true" ] && run_step "ISO Compliance" "$RULES_DIR/security/check-iso-compliance.sh"
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown module: $TARGET (all | core | lint | frontend | design | arch | security | iso)"
        exit 1
        ;;
esac

echo -e "${BLUE}================================================================${NC}"
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}   AUDIT RESULT: ALL SELECTED RULES PASSED (100%)!             ${NC}"
    echo -e "${BLUE}================================================================${NC}" && exit 0
fi
echo -e "${RED}   AUDIT RESULT: $FAILED AUDIT STEP(S) FAILED!                  ${NC}"
echo -e "${BLUE}================================================================${NC}" && exit 1
