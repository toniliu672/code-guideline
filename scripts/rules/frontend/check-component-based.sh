#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/.."
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

FRONTEND_APPROACH="${FRONTEND_APPROACH:-auto}"
RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

if [ "$FRONTEND_APPROACH" = "auto" ]; then
    if [ -d "resources/views" ]; then
        FRONTEND_APPROACH="blade"
    elif [ -f "pubspec.yaml" ]; then
        FRONTEND_APPROACH="flutter"
    elif [ -f "svelte.config.js" ] || grep -q "svelte" package.json 2>/dev/null; then
        FRONTEND_APPROACH="svelte"
    elif [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || grep -q "next" package.json 2>/dev/null || grep -q "react" package.json 2>/dev/null; then
        FRONTEND_APPROACH="react"
    else
        FRONTEND_APPROACH="none"
    fi
fi

case "$FRONTEND_APPROACH" in
    blade)
        bash "$SCRIPT_DIR/check-atomic-blade.sh" "$@"
        ;;
    react|next)
        bash "$SCRIPT_DIR/check-component-react.sh" "$@"
        ;;
    svelte)
        bash "$SCRIPT_DIR/check-component-svelte.sh" "$@"
        ;;
    flutter)
        bash "$SCRIPT_DIR/check-component-flutter.sh" "$@"
        ;;
    none)
        echo -e "${YELLOW}[INFO]${NC} No frontend framework detected (or 'none' specified). Skipping frontend audit."
        exit 0
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown FRONTEND_APPROACH: $FRONTEND_APPROACH"
        echo "Valid options: auto | blade | react | next | svelte | flutter | none"
        exit 1
        ;;
esac
