#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   GUIDELINES & CODE RULES SUITE INSTALLER                      ${NC}"
echo -e "${BLUE}================================================================${NC}"

if [ -z "$TARGET_DIR" ]; then
    echo -e "${RED}[ERROR]${NC} Target project directory is required!"
    echo "Usage:   bash scripts/install.sh <target_project_path>"
    echo "Example: bash scripts/install.sh /home/dev/projects/my-new-project"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || true)"
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}[ERROR]${NC} Target directory not found: $1"
    exit 1
fi

echo -e "Installing guidelines module to: ${GREEN}$TARGET_DIR${NC}"

mkdir -p "$TARGET_DIR/scripts/rules"
cp -r "$SOURCE_DIR/scripts/"* "$TARGET_DIR/scripts/"
cp "$SOURCE_DIR/guidelines.sh" "$TARGET_DIR/guidelines.sh"

chmod +x "$TARGET_DIR/guidelines.sh"
chmod +x "$TARGET_DIR/scripts/guidelines.sh"
chmod +x "$TARGET_DIR/scripts/install.sh"
find "$TARGET_DIR/scripts/rules" -type f -name "*.sh" -exec chmod +x {} +

if [ ! -f "$TARGET_DIR/scripts/rules/config.env" ] && [ -f "$TARGET_DIR/scripts/rules/config.env.example" ]; then
    cp "$TARGET_DIR/scripts/rules/config.env.example" "$TARGET_DIR/scripts/rules/config.env"
    echo -e "${GREEN}[OK]${NC} Configuration file created: 'scripts/rules/config.env'"
fi

# Copy AI Agent instruction templates into target project root
if [ -d "$SOURCE_DIR/templates" ]; then
    [ ! -f "$TARGET_DIR/AGENTS.md" ] && cp "$SOURCE_DIR/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md" && echo -e "${GREEN}[OK]${NC} AI Agent instructions installed: 'AGENTS.md'"
    [ ! -f "$TARGET_DIR/CLAUDE.md" ] && cp "$SOURCE_DIR/templates/CLAUDE.md" "$TARGET_DIR/CLAUDE.md" && echo -e "${GREEN}[OK]${NC} AI Agent instructions installed: 'CLAUDE.md'"
fi

if [ -d "$TARGET_DIR/.git" ]; then
    HOOK_DIR="$TARGET_DIR/.git/hooks"
    mkdir -p "$HOOK_DIR"
    PRE_COMMIT_FILE="$HOOK_DIR/pre-commit"

    cat << 'EOF' > "$PRE_COMMIT_FILE"
#!/usr/bin/env bash
set -e
if [ -f "guidelines.sh" ]; then
    echo "==> Running pre-commit code guidelines audit..."
    bash guidelines.sh
elif [ -f "scripts/guidelines.sh" ]; then
    echo "==> Running pre-commit code guidelines audit..."
    bash scripts/guidelines.sh
fi
EOF

    chmod +x "$PRE_COMMIT_FILE"
    echo -e "${GREEN}[OK]${NC} Git pre-commit hook installed at: $PRE_COMMIT_FILE"
fi

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}   INSTALLATION SUCCESSFUL! CODE RULES SUITE IS READY TO USE    ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo "Run the audit in your target project with:"
echo -e "  ${YELLOW}cd $TARGET_DIR && bash guidelines.sh${NC}"
echo "Or via RTK (Rust Token Killer):"
echo -e "  ${YELLOW}cd $TARGET_DIR && rtk bash guidelines.sh${NC}\n"
