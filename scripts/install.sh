#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:---global}"
REPO_RAW="https://raw.githubusercontent.com/toniliu672/code-guideline/main"
GLOBAL_BIN="/usr/local/bin/guidelines"
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; NC='\033[0m'

sync_global_rule() {
    local tpl="$1"
    [ ! -f "$tpl" ] && return 0
    local targets=("$HOME/.claude/CLAUDE.md" "$HOME/.gemini/GEMINI.md")
    [ -d "/home/dev" ] && [ "$HOME" != "/home/dev" ] && targets+=("/home/dev/.claude/CLAUDE.md" "/home/dev/.gemini/GEMINI.md")
    for gf in "${targets[@]}"; do
        mkdir -p "$(dirname "$gf")"
        [ ! -f "$gf" ] && touch "$gf"
        python3 - "$gf" "$tpl" << 'PYEOF'
import sys, re
gf, tpl = sys.argv[1], sys.argv[2]
content = open(gf, "r", encoding="utf-8", errors="ignore").read()
rules = open(tpl, "r", encoding="utf-8").read().replace("bash guidelines.sh", "guidelines")
block = f"<!-- BEGIN GUIDE-RULES -->\n{rules.strip()}\n<!-- END GUIDE-RULES -->\n"
if "<!-- BEGIN GUIDE-RULES -->" in content:
    content = re.sub(r"<!-- BEGIN GUIDE-RULES -->.*?<!-- END GUIDE-RULES -->\n?", block, content, flags=re.S)
else:
    content = content.rstrip() + ("\n\n" if content.strip() else "") + block
open(gf, "w", encoding="utf-8").write(content)
PYEOF
    done
    echo -e "${GREEN}[OK]${NC} Global AI rules (<RULE[user_global]>) synced without conflict."
}

install_global_binary() {
    if [ -f "$SOURCE_DIR/scripts/build.sh" ]; then
        bash "$SOURCE_DIR/scripts/build.sh"
        cp "$SOURCE_DIR/bin/guidelines" "$GLOBAL_BIN"
    elif [ -f "$SOURCE_DIR/bin/guidelines" ]; then
        cp "$SOURCE_DIR/bin/guidelines" "$GLOBAL_BIN"
    fi
    chmod 755 "$GLOBAL_BIN"
    echo -e "${GREEN}[OK]${NC} Global executable installed: $GLOBAL_BIN"
    sync_global_rule "$SOURCE_DIR/templates/AGENTS.md"
}

if [ "$MODE" = "--update" ]; then
    echo -e "${BLUE}==> Updating Global Guidelines from GitHub...${NC}"
    if [ -d "/home/dev/projects/guide-rules/.git" ]; then
        git -C /home/dev/projects/guide-rules pull --ff-only origin main 2>/dev/null || true
        SOURCE_DIR="/home/dev/projects/guide-rules"
        install_global_binary
    else
        TMP_U="$(mktemp -d)"
        curl -fsSL "$REPO_RAW/bin/guidelines" -o "$GLOBAL_BIN" && chmod 755 "$GLOBAL_BIN"
        curl -fsSL "$REPO_RAW/templates/AGENTS.md" -o "$TMP_U/AGENTS.md"
        sync_global_rule "$TMP_U/AGENTS.md"
        rm -rf "$TMP_U"
    fi
    echo -e "${GREEN}[OK]${NC} Global guidelines updated to latest version!"
    exit 0
fi

if [ "$MODE" = "--global" ]; then
    install_global_binary
    exit 0
fi

TARGET_DIR="${MODE#--clean=}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || true)"
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}[ERROR]${NC} Target directory not found: $MODE"
    exit 1
fi

install_global_binary

if [ "$TARGET_DIR" != "/home/dev/projects/guide-rules" ]; then
    rm -rf "$TARGET_DIR/scripts/rules" "$TARGET_DIR/scripts/guidelines.sh" "$TARGET_DIR/scripts/install.sh" "$TARGET_DIR/guidelines.sh"
    echo -e "${GREEN}[OK]${NC} Removed exposed .sh rule scripts from $TARGET_DIR (Stealth Black-Box Mode)."
fi

if [ -d "$TARGET_DIR/.git" ]; then
    HOOK_FILE="$TARGET_DIR/.git/hooks/pre-commit"
    mkdir -p "$(dirname "$HOOK_FILE")"
    printf "#!/usr/bin/env bash\nset -e\nexec /usr/local/bin/guidelines\n" > "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    echo -e "${GREEN}[OK]${NC} Stealth Git pre-commit hook linked to $GLOBAL_BIN in $TARGET_DIR"
fi
