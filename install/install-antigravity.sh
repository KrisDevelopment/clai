#!/usr/bin/env bash
set -euo pipefail

MUTED='\033[0;2m'
RED='\033[0;31m'
ORANGE='\033[38;5;214m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    cat <<EOF
Install Google Antigravity CLI - AI coding agent for the terminal

Replaces Gemini CLI. Official docs: https://antigravity.google/docs/cli-overview

Usage: install-antigravity.sh [options]

Options:
    -h, --help           Display this help
    -d, --dir <path>     Install directory (default: \$HOME/.local/bin)
        --no-modify-path Don't modify shell config files
    -D, --download-only  Only download the installer, don't run it

Examples:
    ./install-antigravity.sh
    curl -fsSL https://antigravity.google/cli/install.sh | bash
EOF
}

INSTALL_DIR=${INSTALL_DIR:-$HOME/.local/bin}
no_modify_path=false
download_only=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -d|--dir) INSTALL_DIR="$2"; shift 2 ;;
        --no-modify-path) no_modify_path=true; shift ;;
        -D|--download-only) download_only=true; shift ;;
        *) echo -e "${ORANGE}Warning: Unknown option '$1'${NC}" >&2; shift ;;
    esac
done

if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error: curl is required${NC}"; exit 1
fi

echo -e "${MUTED}Installing ${NC}Google Antigravity CLI${NC}"

if [ "$download_only" = true ]; then
    curl -fsSL https://antigravity.google/cli/install.sh -o "$INSTALL_DIR/install-antigravity.sh"
    chmod +x "$INSTALL_DIR/install-antigravity.sh"
    echo -e "${GREEN}✓ Downloaded to ${INSTALL_DIR}/install-antigravity.sh${NC}"
    echo -e "${MUTED}Run it with: bash ${INSTALL_DIR}/install-antigravity.sh${NC}"
    exit 0
fi

# The official installer handles platform detection, download, and path setup
# We just pipe it through, passing supported flags
install_args=()
if [ -n "$INSTALL_DIR" ]; then
    install_args+=(--dir "$INSTALL_DIR")
fi

if echo | curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- "${install_args[@]}"; then
    echo -e "${GREEN}✓ Google Antigravity CLI installed${NC}"
    echo -e "${MUTED}Run 'agy' to start.${NC}"
    echo -e "${MUTED}Docs: https://antigravity.google/docs/cli-overview${NC}"
else
    echo -e "${RED}Installation failed or was cancelled.${NC}"
    echo -e "${MUTED}Try the official command directly:${NC}"
    echo "  curl -fsSL https://antigravity.google/cli/install.sh | bash"
    exit 1
fi
