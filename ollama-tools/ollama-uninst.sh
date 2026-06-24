#!/bin/bash
set -e

echo "Uninstalling Ollama..."

echo "Stopping Ollama..."

sudo systemctl stop ollama 2>/dev/null || true
sudo systemctl disable ollama 2>/dev/null || true

echo "Removing Ollama service..."

sudo rm -f /etc/systemd/system/ollama.service
sudo systemctl daemon-reload

echo "Removing binary..."

sudo rm -f "$(which ollama 2>/dev/null)" || true

echo "Removing user..."

sudo userdel ollama 2>/dev/null || true
sudo groupdel ollama 2>/dev/null || true

echo
echo "Models were NOT deleted."
echo "Check these locations manually:"
echo "  /usr/share/ollama/.ollama"
echo "  ~/.ollama"

echo "Done."
