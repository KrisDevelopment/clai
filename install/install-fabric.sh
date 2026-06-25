#!/usr/bin/env bash
set -euo pipefail

APP=fabric

MUTED='\033[0;2m'
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
NC='\033[0m'

INSTALL_DIR=${INSTALL_DIR:-$HOME/.local/bin}
FABRIC_DIR=${FABRIC_DIR:-$HOME/.config/fabric}

usage() {
    cat <<EOF
Install Fabric - AI-powered CLI tool

Usage: install-fabric.sh [options]

Options:
    -h, --help           Display this help
    -d, --dir <path>     Install directory (default: \$HOME/.local/bin)
        --no-modify-path Don't modify shell config files
    -b, --branch <name>  Install from a specific branch (default: main)

Examples:
    ./install-fabric.sh
    curl -fsSL https://raw.githubusercontent.com/your-user/clai/main/install/install-fabric.sh | bash
EOF
}

no_modify_path=false
branch="main"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -d|--dir) INSTALL_DIR="$2"; shift 2 ;;
        --no-modify-path) no_modify_path=true; shift ;;
        -b|--branch) branch="$2"; shift 2 ;;
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
    if ! command -v git &>/dev/null; then
        echo -e "${RED}Error: git is required${NC}"; exit 1
    fi
}

install_fabric() {
    echo -e "${MUTED}Installing ${NC}fabric ${MUTED}from GitHub (branch: ${branch})${NC}"

    local tmp_dir="${TMPDIR:-/tmp}/fabric_install_$$"
    mkdir -p "$tmp_dir"

    git clone --depth 1 --branch "$branch" https://github.com/danielmiessler/fabric.git "$tmp_dir/fabric" 2>/dev/null || {
        echo -e "${RED}Failed to clone fabric repository${NC}"
        rm -rf "$tmp_dir"
        exit 1
    }

    pip_cmd=$(command -v pip3 || command -v pip)
    cd "$tmp_dir/fabric"
    $pip_cmd install -e .

    # Copy client binary
    if [ -f "fabric-client.py" ]; then
        cp "fabric-client.py" "$INSTALL_DIR/$APP"
        chmod 755 "$INSTALL_DIR/$APP"
    elif [ -f "src/fabric/client.py" ]; then
        cp "src/fabric/client.py" "$INSTALL_DIR/$APP"
        chmod 755 "$INSTALL_DIR/$APP"
    fi

    # Setup config directory
    if [ ! -d "$FABRIC_DIR" ]; then
        mkdir -p "$FABRIC_DIR"
        if [ -d "config" ]; then
            cp -r config/* "$FABRIC_DIR/"
        fi
    fi

    cd "$OLDPWD"
    rm -rf "$tmp_dir"
    echo -e "${GREEN}✓ fabric installed${NC}"
}

add_to_path() {
    local config_file=$1
    local cmd=$2
    if grep -Fxq "$cmd" "$config_file" 2>/dev/null; then
        return
    fi
    if [ -w "$config_file" ]; then
        echo -e "\n# fabric" >> "$config_file"
        echo "$cmd" >> "$config_file"
        echo -e "${MUTED}Added fabric PATH in ${NC}$config_file"
    fi
}

check_deps
install_fabric

if [[ "$no_modify_path" != "true" ]] && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    current_shell=$(basename "$SHELL")
    case $current_shell in
        fish) add_to_path "$HOME/.config/fish/config.fish" "fish_add_path $INSTALL_DIR" ;;
        zsh)  add_to_path "${ZDOTDIR:-$HOME}/.zshrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        bash) add_to_path "$HOME/.bashrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        *)    add_to_path "$HOME/.profile" "export PATH=$INSTALL_DIR:\$PATH" ;;
    esac
fi

# The pip install also puts it in the user site bin directory
pip_dir=$(python3 -m site --user-base 2>/dev/null || echo "$HOME/.local")
bin_dir="$pip_dir/bin"
if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
    echo -e "${MUTED}Note: Add ${bin_dir} to your PATH if 'fabric' is not found.${NC}"
fi

echo -e "${GREEN}Done! Run 'fabric' to start.${NC}"
echo -e "${MUTED}Patterns are installed in ${FABRIC_DIR}${NC}"
