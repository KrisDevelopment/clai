#!/usr/bin/env bash
set -euo pipefail

URL="https://lmstudio.ai/download/bionic/latest/linux/x64?format=deb"
DEB="/tmp/lmstudio.deb"

echo "Downloading LM Studio..."
if command -v curl >/dev/null 2>&1; then
  curl -fL -o "${DEB}" "${URL}"
elif command -v wget >/dev/null 2>&1; then
  wget -O "${DEB}" "${URL}"
else
  echo "Error: curl or wget is required." >&2
  exit 1
fi

echo "Installing LM Studio..."
if [ "$EUID" -ne 0 ]; then
  sudo dpkg -i "${DEB}" || sudo apt-get install -f -y
else
  dpkg -i "${DEB}" || apt-get install -f -y
fi

rm -f "${DEB}"

echo "Done. Launch LM Studio and start its local server (port 1234) to use as a coding LLM server."
