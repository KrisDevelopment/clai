#!/usr/bin/env bash
set -euo pipefail

APP=claude

MUTED='\033[0;2m'
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    cat <<EOF
Install Claude Code - Anthropic's CLI coding agent

Usage: install-claude-code.sh [options]

Options:
    -h, --help           Display this help
    -d, --dir <path>     Install directory (default: \$HOME/.local/bin)
        --no-modify-path Don't modify shell config files

Prerequisites:
    - Node.js 18+ (will check or attempt to install via nvm/fnm)
    - npm

Examples:
    ./install-claude-code.sh
EOF
}

INSTALL_DIR=${INSTALL_DIR:-$HOME/.local/bin}
no_modify_path=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -d|--dir) INSTALL_DIR="$2"; shift 2 ;;
        --no-modify-path) no_modify_path=true; shift ;;
        *) echo -e "${ORANGE}Warning: Unknown option '$1'${NC}" >&2; shift ;;
    esac
done

mkdir -p "$INSTALL_DIR"

ensure_node() {
    if ! command -v node &>/dev/null; then
        echo -e "${ORANGE}Node.js not found. Attempting to install via nvm...${NC}"
        if command -v curl &>/dev/null; then
            export NVM_DIR="$HOME/.nvm"
            if [ ! -d "$NVM_DIR" ]; then
                curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
            fi
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            nvm install --lts
            nvm use --lts
        else
            echo -e "${RED}Please install Node.js 18+ manually: https://nodejs.org${NC}"
            exit 1
        fi
    fi

    node_version=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$node_version" -lt 18 ]; then
        echo -e "${RED}Node.js 18+ required. Found: $(node -v)${NC}"
        exit 1
    fi
    echo -e "${MUTED}Node.js $(node -v) detected${NC}"
}

install_claude_code() {
    echo -e "${MUTED}Installing ${NC}@anthropic-ai/claude-code ${MUTED}globally via npm${NC}"

    if npm ls -g @anthropic-ai/claude-code &>/dev/null; then
        echo -e "${MUTED}Claude Code already installed, upgrading...${NC}"
        npm update -g @anthropic-ai/claude-code
    else
        npm install -g @anthropic-ai/claude-code
    fi

    # Symlink to INSTALL_DIR if npm global bin isn't in PATH
    npm_global=$(npm bin -g 2>/dev/null || echo "")
    if [ -n "$npm_global" ] && [ -f "$npm_global/$APP" ]; then
        ln -sf "$npm_global/$APP" "$INSTALL_DIR/$APP" 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ Claude Code installed${NC}"
}

add_to_path() {
    local config_file=$1
    local cmd=$2
    if grep -Fxq "$cmd" "$config_file" 2>/dev/null; then
        return
    fi
    if [ -w "$config_file" ]; then
        echo -e "\n# claude-code" >> "$config_file"
        echo "$cmd" >> "$config_file"
        echo -e "${MUTED}Added claude PATH in ${NC}$config_file"
    fi
}

ensure_node
install_claude_code

if [[ "$no_modify_path" != "true" ]] && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    current_shell=$(basename "$SHELL")
    case $current_shell in
        fish) add_to_path "$HOME/.config/fish/config.fish" "fish_add_path $INSTALL_DIR" ;;
        zsh)  add_to_path "${ZDOTDIR:-$HOME}/.zshrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        bash) add_to_path "$HOME/.bashrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        *)    add_to_path "$HOME/.profile" "export PATH=$INSTALL_DIR:\$PATH" ;;
    esac
fi

npm_global_dir=$(npm bin -g 2>/dev/null || echo "")
if [ -n "$npm_global_dir" ] && [[ ":$PATH:" != *":$npm_global_dir:"* ]]; then
    echo -e "${MUTED}Note: Add ${npm_global_dir} to your PATH if 'claude' is not found.${NC}"
fi

echo -e "${GREEN}Done! Run 'claude' to start.${NC}"
echo -e "${MUTED}Authenticate with: claude login${NC}"
