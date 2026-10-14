#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BLADE_APPROACH="${BLADE_APPROACH:-atomic}"
exec bash "$SCRIPT_DIR/check-blade-components.sh" "$@"
