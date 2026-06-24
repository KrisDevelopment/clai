#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yaml"
GPU_SERVICE="ollama"
CPU_SERVICE="ollama-cpu"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_BIN=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_BIN=(docker-compose)
else
  echo "Error: docker compose or docker-compose is required." >&2
  exit 1
fi

compose() {
  (cd "${SCRIPT_DIR}" && "${COMPOSE_BIN[@]}" -f "${COMPOSE_FILE}" "$@")
}

compose_supports_profile_flag() {
  if compose --help 2>/dev/null | grep -q -- "--profile"; then
    return 0
  fi
  return 1
}

up_profile() {
  local profile="$1"

  # Keep only one profile active at a time because both map port 11434.
  compose stop "${GPU_SERVICE}" "${CPU_SERVICE}" >/dev/null 2>&1 || true
  compose rm -f "${GPU_SERVICE}" "${CPU_SERVICE}" >/dev/null 2>&1 || true

  if compose_supports_profile_flag; then
    compose --profile "${profile}" up -d
  else
    COMPOSE_PROFILES="${profile}" compose up -d
  fi
}

get_running_services() {
  compose ps --services --filter status=running 2>/dev/null || true
}

pick_active_service() {
  local running
  running="$(get_running_services)"

  if echo "${running}" | grep -qx "${GPU_SERVICE}"; then
    echo "${GPU_SERVICE}"
    return 0
  fi

  if echo "${running}" | grep -qx "${CPU_SERVICE}"; then
    echo "${CPU_SERVICE}"
    return 0
  fi

  return 1
}

require_active_service() {
  local service
  if ! service="$(pick_active_service)"; then
    echo "No Ollama container is running." >&2
    echo "Start one with: ./ollama-manage.sh gpu  or  ./ollama-manage.sh cpu" >&2
    exit 1
  fi
  echo "${service}"
}

show_help() {
  cat <<'EOF'
Usage: ./ollama-manage.sh <command> [args]

Commands:
  gpu                  Start Ollama with GPU profile
  cpu                  Start Ollama with CPU profile
  down                 Stop and remove Ollama containers
  restart-gpu          Restart using GPU profile
  restart-cpu          Restart using CPU profile
  status               Show running status
  logs                 Follow logs from active Ollama service
  cli <ollama args>    Run Ollama CLI in the active container
  shell                Open a shell in the active container
  help                 Show this message

Examples:
  ./ollama-manage.sh gpu
  ./ollama-manage.sh cpu
  ./ollama-manage.sh cli list
  ./ollama-manage.sh cli pull llama3.2
  ./ollama-manage.sh cli run llama3.2
  ./ollama-manage.sh shell
EOF
}

command="${1:-help}"

case "${command}" in
  gpu)
    up_profile gpu
    ;;
  cpu)
    up_profile cpu
    ;;
  restart-gpu)
    compose down
    up_profile gpu
    ;;
  restart-cpu)
    compose down
    up_profile cpu
    ;;
  down)
    compose down
    ;;
  status)
    compose ps
    ;;
  logs)
    service="$(require_active_service)"
    compose logs -f "${service}"
    ;;
  cli)
    shift || true
    if [[ "$#" -eq 0 ]]; then
      echo "Usage: ./ollama-manage.sh cli <ollama args>" >&2
      echo "Example: ./ollama-manage.sh cli list" >&2
      exit 1
    fi
    service="$(require_active_service)"
    compose exec "${service}" ollama "$@"
    ;;
  shell)
    service="$(require_active_service)"
    compose exec "${service}" sh
    ;;
  help|-h|--help)
    show_help
    ;;
  *)
    echo "Unknown command: ${command}" >&2
    show_help
    exit 1
    ;;
esac
