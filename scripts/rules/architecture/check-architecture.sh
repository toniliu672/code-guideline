#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_DIR="$SCRIPT_DIR/.."
[ -f "$RULES_DIR/config.env" ] && source "$RULES_DIR/config.env"

ARCHITECTURE_APPROACH="${ARCHITECTURE_APPROACH:-auto}"
RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

if [ "$ARCHITECTURE_APPROACH" = "auto" ]; then
    if [ -d "modules" ] || [ -d "src/modules" ] || [ -d "src/features" ]; then
        ARCHITECTURE_APPROACH="modular"
    elif [ -d "app/Services" ] || [ -d "src/services" ]; then
        ARCHITECTURE_APPROACH="service-layer"
    elif [ -d "app/Http/Controllers" ] || [ -d "controllers" ]; then
        ARCHITECTURE_APPROACH="mvc"
    else
        ARCHITECTURE_APPROACH="none"
    fi
fi

case "$ARCHITECTURE_APPROACH" in
    mvc)
        bash "$SCRIPT_DIR/check-mvc.sh" "$@"
        ;;
    modular)
        bash "$SCRIPT_DIR/check-modular.sh" "$@"
        ;;
    service-layer|service)
        bash "$SCRIPT_DIR/check-service-layer.sh" "$@"
        ;;
    microservices|microservice)
        bash "$SCRIPT_DIR/check-microservices.sh" "$@"
        ;;
    none)
        echo -e "${YELLOW}[INFO]${NC} No specific architecture pattern specified. Skipping architecture audit."
        exit 0
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown ARCHITECTURE_APPROACH: $ARCHITECTURE_APPROACH"
        echo "Valid options: auto | mvc | modular | service-layer | microservices | none"
        exit 1
        ;;
esac
