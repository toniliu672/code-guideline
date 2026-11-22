#!/usr/bin/env bash
set -euo pipefail

MODE="install"
[ "${1:-}" = "--uninstall" ] && { MODE="uninstall"; shift; }
SKILLS_SRC="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills}"
[ ! -d "$SKILLS_SRC" ] && exit 0

GREEN='\033[0;32m'; NC='\033[0m'
SKILL_ROOTS=("$HOME/.gemini/config/skills" "$HOME/.gemini/antigravity-cli/skills" "/home/dev/.gemini/config/skills" "/home/dev/.gemini/antigravity-cli/skills")
SYNCED=0

for skill_dir in "$SKILLS_SRC"/*; do
    [ ! -d "$skill_dir" ] && continue
    skill_name="$(basename "$skill_dir")"
    for root in "${SKILL_ROOTS[@]}"; do
        base_gemini="$(dirname "$(dirname "$root")")"
        [ ! -d "$base_gemini" ] && continue
        if [ "$MODE" = "uninstall" ]; then
            rm -rf "$root/$skill_name"
        else
            mkdir -p "$root/$skill_name"
            cp -R "$skill_dir/." "$root/$skill_name/"
            SYNCED=$((SYNCED + 1))
        fi
    done
done

if [ "$MODE" = "uninstall" ]; then
    echo -e "${GREEN}[OK]${NC} Global AI skills removed."
elif [ "$SYNCED" -gt 0 ]; then
    echo -e "${GREEN}[OK]${NC} Global AI skills synced from $SKILLS_SRC."
fi
