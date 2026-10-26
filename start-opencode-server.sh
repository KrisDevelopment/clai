#!/usr/bin/env bash
set -euo pipefail

if [ -z "${OPENCODE_SERVER_PASSWORD:-}" ]; then
  if [ -t 0 ]; then
    read -r -s -p "OpenCode server password: " OPENCODE_SERVER_PASSWORD
    echo
    if [ -z "$OPENCODE_SERVER_PASSWORD" ]; then
      echo "Password cannot be empty" >&2
      exit 1
    fi
  else
    echo "OPENCODE_SERVER_PASSWORD is not set and stdin is not interactive" >&2
    exit 1
  fi
fi

if [ -z "${OPENCODE_SERVER_USERNAME:-}" ]; then
  if [ -t 0 ]; then
    read -r -p "OpenCode server username [opencode]: " OPENCODE_SERVER_USERNAME
    OPENCODE_SERVER_USERNAME="${OPENCODE_SERVER_USERNAME:-opencode}"
  else
    OPENCODE_SERVER_USERNAME="opencode"
  fi
fi

export OPENCODE_SERVER_PASSWORD
export OPENCODE_SERVER_USERNAME

opencode web --hostname 0.0.0.0 --port 4096
