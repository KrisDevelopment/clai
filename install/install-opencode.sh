#!/usr/bin/env bash
set -euo pipefail

APP=opencode

MUTED='\033[0;2m'
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
NC='\033[0m'

INSTALL_DIR=${INSTALL_DIR:-$HOME/.local/bin}
mkdir -p "$INSTALL_DIR"

usage() {
    cat <<EOF
Install OpenCode CLI

Usage: install-opencode.sh [options]

Options:
    -h, --help              Display this help
    -v, --version <version> Install a specific version
    -b, --binary <path>     Install from a local binary
        --no-modify-path    Don't modify shell config files
    -d, --dir <path>        Install directory (default: \$HOME/.local/bin)

Examples:
    curl -fsSL https://opencode.ai/install | bash
    ./install-opencode.sh --version 1.0.180
EOF
}

requested_version=${VERSION:-}
no_modify_path=false
binary_path=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -v|--version) requested_version="$2"; shift 2 ;;
        -b|--binary) binary_path="$2"; shift 2 ;;
        --no-modify-path) no_modify_path=true; shift ;;
        -d|--dir) INSTALL_DIR="$2"; shift 2 ;;
        *) echo -e "${ORANGE}Warning: Unknown option '$1'${NC}" >&2; shift ;;
    esac
done

detect_platform() {
    raw_os=$(uname -s)
    case "$raw_os" in
        Darwin*) os="darwin" ;;
        Linux*) os="linux" ;;
        MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    esac

    arch=$(uname -m)
    [[ "$arch" == "aarch64" ]] && arch="arm64"
    [[ "$arch" == "x86_64" ]] && arch="x64"

    if [ "$os" = "darwin" ] && [ "$arch" = "x64" ]; then
        rosetta_flag=$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)
        [ "$rosetta_flag" = "1" ] && arch="arm64"
    fi

    combo="$os-$arch"
    case "$combo" in
        linux-x64|linux-arm64|darwin-x64|darwin-arm64|windows-x64) ;;
        *) echo -e "${RED}Unsupported: $os/$arch${NC}"; exit 1 ;;
    esac

    archive_ext=".zip"
    [ "$os" = "linux" ] && archive_ext=".tar.gz"

    target="$os-$arch"

    if [ "$arch" = "x64" ] && [ "$os" = "linux" ]; then
        if ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
            target="$target-baseline"
        fi
        if command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
            target="$target-musl"
        fi
    fi
}

download_and_install() {
    detect_platform
    local filename="$APP-$target$archive_ext"

    if [ -z "$requested_version" ]; then
        url="https://github.com/anomalyco/opencode/releases/latest/download/$filename"
        specific_version=$(curl -s https://api.github.com/repos/anomalyco/opencode/releases/latest | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')
        [ -z "$specific_version" ] && { echo -e "${RED}Failed to fetch version${NC}"; exit 1; }
    else
        requested_version="${requested_version#v}"
        url="https://github.com/anomalyco/opencode/releases/download/v${requested_version}/$filename"
        specific_version=$requested_version
    fi

    echo -e "${MUTED}Installing ${NC}opencode ${MUTED}v${specific_version} for ${target}${NC}"
    local tmp_dir="${TMPDIR:-/tmp}/opencode_install_$$"
    mkdir -p "$tmp_dir"

    curl -# -L -o "$tmp_dir/$filename" "$url"

    if [ "$os" = "linux" ]; then
        tar -xzf "$tmp_dir/$filename" -C "$tmp_dir"
    else
        unzip -q "$tmp_dir/$filename" -d "$tmp_dir"
    fi

    mv "$tmp_dir/$APP" "$INSTALL_DIR/"
    chmod 755 "$INSTALL_DIR/$APP"
    rm -rf "$tmp_dir"
    echo -e "${GREEN}✓ opencode installed to ${INSTALL_DIR}/${APP}${NC}"
}

install_from_binary() {
    [ ! -f "$binary_path" ] && { echo -e "${RED}Binary not found: ${binary_path}${NC}"; exit 1; }
    cp "$binary_path" "$INSTALL_DIR/$APP"
    chmod 755 "$INSTALL_DIR/$APP"
    echo -e "${GREEN}✓ opencode installed from ${binary_path}${NC}"
}

add_to_path() {
    local config_file=$1
    local cmd=$2
    if grep -Fxq "$cmd" "$config_file" 2>/dev/null; then
        return
    fi
    if [ -w "$config_file" ]; then
        echo -e "\n# opencode" >> "$config_file"
        echo "$cmd" >> "$config_file"
        echo -e "${MUTED}Added opencode to \$PATH in ${NC}$config_file"
    fi
}

if [ -n "$binary_path" ]; then
    install_from_binary
else
    download_and_install
fi

if [[ "$no_modify_path" != "true" ]] && [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    current_shell=$(basename "$SHELL")
    case $current_shell in
        fish) add_to_path "$HOME/.config/fish/config.fish" "fish_add_path $INSTALL_DIR" ;;
        zsh)  add_to_path "${ZDOTDIR:-$HOME}/.zshrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        bash) add_to_path "$HOME/.bashrc" "export PATH=$INSTALL_DIR:\$PATH" ;;
        *)    add_to_path "$HOME/.profile" "export PATH=$INSTALL_DIR:\$PATH" ;;
    esac
fi

echo -e "${GREEN}Done! Run 'opencode' to start.${NC}"
