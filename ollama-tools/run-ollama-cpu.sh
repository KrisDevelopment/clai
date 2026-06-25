#!/usr/bin/env bash
set -euo pipefail

stop_ollama() {
  echo "Stopping existing Ollama..."

  # Stop systemd service if running
  if systemctl is-active --quiet ollama 2>/dev/null; then
    echo "Stopping ollama systemd service..."
    sudo systemctl stop ollama
    sleep 2
  fi

  echo "Stopping any running Ollama containers..."

  # Try graceful shutdown via API
  curl -sf -X POST http://127.0.0.1:11434/api/shutdown >/dev/null 2>&1 || true
  sleep 1

  echo "Killing any remaining Ollama processes..."

  # Kill any remaining ollama processes
  pkill ollama 2>/dev/null || true
  sleep 2

  echo "Stopping any running Ollama Docker containers..."

  # Wait for port to be freed (up to 10s)
  for i in $(seq 10); do
    if ! ss -tlnp 2>/dev/null | grep -q ':11434 '; then
      return 0
    fi
    sleep 1
  done

  echo "Warning: Port 11434 still in use. Attempting to start anyway..." >&2
}

echo "Checking for existing Ollama instances..."

if ss -tlnp 2>/dev/null | grep -q ':11434 '; then
  stop_ollama
fi

export CUDA_VISIBLE_DEVICES=""
export OLLAMA_INTEL_GPU=0
export OLLAMA_VULKAN=0
export OLLAMA_MODELS=/usr/share/ollama/.ollama/models

chmod -R o+rX "$OLLAMA_MODELS" 2>/dev/null || true

echo "Starting Ollama in CPU mode (detached)..."
nohup ollama serve > /dev/null 2>&1 &
disown
echo "Ollama is running in the background (PID $!)."
