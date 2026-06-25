#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[38;5;214m'
MUTED='\033[0;2m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/$(git config --get remote.origin.url 2>/dev/null | sed -E 's#^.*(github\.com[:/])([^/]+/[^/.]+)(\.git)?$#\2#' 2>/dev/null || echo "user/clai")/main/install"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS=()
for f in "$SCRIPT_DIR"/install-*.sh; do
    [ -f "$f" ] || continue
    name=$(basename "$f" | sed 's/^install-//' | sed 's/\.sh$//')
    [ "$name" = "install" ] && continue
    SCRIPTS+=("$name")
done

usage() {
    cat <<EOF
CLAI - CLI AI Tools Installer

Install AI coding assistants and CLI tools.

Usage: install.sh [tool] [options]

Available tools:
$(for t in "${SCRIPTS[@]}"; do echo "    $t"; done)

Options:
    -h, --help     Display this help
    -l, --list     List available tools

Examples:
    ./install.sh                  # Interactive menu
    ./install.sh opencode         # Install opencode
    ./install.sh aider            # Install aider
    ./install.sh --all            # Install all tools

Each tool also has its own installer:
    ./install-opencode.sh --help
    curl -fsSL $REPO_URL/install-opencode.sh | bash
EOF
}

install_tool() {
    local tool=$1
    shift
    local script="$SCRIPT_DIR/install-$tool.sh"

    if [ ! -f "$script" ]; then
        echo -e "${RED}Error: No installer for '$tool'${NC}"
        echo -e "${MUTED}Available: ${SCRIPTS[*]}${NC}"
        exit 1
    fi

    echo -e "${MUTED}========================================${NC}"
    echo -e "${MUTED}Installing: ${NC}$tool"
    echo -e "${MUTED}========================================${NC}"

    bash "$script" "$@"
}

list_tools() {
    echo -e "${GREEN}Available CLI code editors / AI tools:${NC}"
    for t in "${SCRIPTS[@]}"; do
        echo "  $t"
    done
}

if [ $# -eq 0 ]; then
    echo -e "${GREEN}CLAI - CLI AI Tools Installer${NC}"
    echo ""
    list_tools
    echo ""
    echo -e "${MUTED}Usage: install.sh <tool> [options]${NC}"
    echo -e "${MUTED}       install.sh --list${NC}"
    echo ""
    exit 0
fi

case "$1" in
    -h|--help) usage; exit 0 ;;
    -l|--list) list_tools; exit 0 ;;
    --all)
        echo -e "${ORANGE}Installing all tools...${NC}"
        for t in "${SCRIPTS[@]}"; do
            install_tool "$t"
            echo ""
        done
        echo -e "${GREEN}All tools installed!${NC}"
        ;;
    *)
        tool="$1"
        shift
        install_tool "$tool" "$@"
        ;;
esac
