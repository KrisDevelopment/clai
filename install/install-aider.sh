#!/usr/bin/env bash
set -euo pipefail

APP=aider

MUTED='\033[0;2m'
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    cat <<EOF
Install Aider - AI pair programming in the terminal

Usage: install-aider.sh [options]

Options:
    -h, --help           Display this help
    -d, --dir <path>     Install directory (default: \$HOME/.local/bin)
        --no-modify-path Don't modify shell config files

Examples:
    ./install-aider.sh
    curl -fsSL https://raw.githubusercontent.com/your-user/clai/main/install/install-aider.sh | bash
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

check_deps() {
    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}Error: python3 is required${NC}"; exit 1
    fi
    if ! command -v pip3 &>/dev/null && ! command -v pip &>/dev/null; then
        echo -e "${RED}Error: pip is required${NC}"; exit 1
    fi
}

install_aider() {
    echo -e "${MUTED}Installing ${NC}aider ${MUTED}via pip${NC}"

    pip_cmd=$(command -v pip3 || command -v pip)

    if $pip_cmd show aider-chat &>/dev/null; then
        echo -e "${MUTED}aider already installed, upgrading...${NC}"
        $pip_cmd install --upgrade aider-chat
    else
        $pip_cmd install aider-chat
    fi

    echo -e "${GREEN}✓ aider installed${NC}"
}

add_to_path() {
    local config_file=$1
    local cmd=$2
    if grep -Fxq "$cmd" "$config_file" 2>/dev/null; then
        return
    fi
    if [ -w "$config_file" ]; then
        echo -e "\n# aider" >> "$config_file"
        echo "$cmd" >> "$config_file"
        echo -e "${MUTED}Added aider PATH in ${NC}$config_file"
    fi
}

check_deps
install_aider

if [[ "$no_modify_path" != "true" ]] && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    current_shell=$(basename "$SHELL")
    case $current_shell in
        fish) add_to_path "$HOME/.config/fish/config.fish" "fish_add_path $INSTALL_DIR" ;;
        zsh)  add_to_path "${ZDOTDIR:-$HOME}/.zshrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        bash) add_to_path "$HOME/.bashrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        *)    add_to_path "$HOME/.profile" "export PATH=$INSTALL_DIR:\$PATH" ;;
    esac
fi

pip_dir=$(python3 -m site --user-base 2>/dev/null || echo "$HOME/.local")
bin_dir="$pip_dir/bin"
if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
    echo -e "${MUTED}Note: Add ${bin_dir} to your PATH if 'aider' is not found.${NC}"
fi

echo -e "${GREEN}Done! Run 'aider' to start.${NC}"
echo -e "${MUTED}Get your API key at https://aider.chat/docs/config/llm.html${NC}"
