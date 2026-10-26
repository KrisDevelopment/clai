#!/usr/bin/env bash
set -euo pipefail

APP=/opt/Bionic/bionic
LMS=/opt/Bionic/resources/app/.webpack-bionic/lms
USER_NAME="${SUDO_USER:-${USER:-kris}}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
DISPLAY_VAL="${DISPLAY:-:0}"
XAUTH="${XAUTHORITY:-$USER_HOME/.Xauthority}"
PORT="${PORT:-1234}"
BIND="${BIND:-0.0.0.0}"
MODEL="${MODEL:-}"
WRAPPER=/usr/local/bin/lmstudio-server-start.sh
SERVICE=/etc/systemd/system/lmstudio-server.service

require_root() { [ "$EUID" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }; }

install_svc() {
  require_root
  [ -x "$APP" ] || { echo "LM Studio not installed. Run install/install-lmstudio.sh" >&2; exit 1; }
  cat > "$WRAPPER" <<WRAP
#!/usr/bin/env bash
set -euo pipefail
export DISPLAY="$DISPLAY_VAL"
export XAUTHORITY="$XAUTH"
export HOME="$USER_HOME"
nohup "$APP" >/tmp/lmstudio.log 2>&1 &
APP_PID=\$!
for i in \$(seq 60); do
  if "$LMS" server status >/dev/null 2>&1; then break; fi
  sleep 1
done
"$LMS" server start --bind "$BIND" --port "$PORT" || true
if [ -n "$MODEL" ]; then
  "$LMS" load "$MODEL" --gpu max -y || true
fi
wait "\$APP_PID"
WRAP
  chmod +x "$WRAPPER"
  cat > "$SERVICE" <<SVC
[Unit]
Description=LM Studio (Bionic) coding LLM server
After=graphical.target

[Service]
Type=simple
User=$USER_NAME
Environment=DISPLAY=$DISPLAY_VAL
Environment=XAUTHORITY=$XAUTH
Environment=HOME=$USER_HOME
ExecStart=$WRAPPER
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVC
  systemctl daemon-reload
  systemctl enable --now lmstudio-server.service
  echo "Installed & started (port $PORT)."
}

uninstall_svc() {
  require_root
  systemctl disable --now lmstudio-server.service 2>/dev/null || true
  rm -f "$SERVICE" "$WRAPPER"
  systemctl daemon-reload
  echo "Uninstalled."
}

if [ $# -eq 0 ]; then
  echo "LM Studio server control"
  echo "1) install  2) uninstall  3) start  4) stop  5) restart  6) status"
  read -rp "Choose [1-6]: " c
  case "$c" in
    1) set -- install ;; 2) set -- uninstall ;; 3) set -- start ;;
    4) set -- stop ;; 5) set -- restart ;; 6) set -- status ;;
    *) echo "Invalid"; exit 1 ;;
  esac
fi

case "${1:-install}" in
  install) install_svc ;;
  uninstall) uninstall_svc ;;
  start) systemctl start lmstudio-server.service ;;
  stop) systemctl stop lmstudio-server.service ;;
  restart) systemctl restart lmstudio-server.service ;;
  status) systemctl status lmstudio-server.service --no-pager ;;
  download) shift; /opt/Bionic/resources/app/.webpack-bionic/lms get "$1" -y ;;
  load) shift; /opt/Bionic/resources/app/.webpack-bionic/lms load "$1" --gpu max -y ;;
  *) echo "Usage: $0 {install|uninstall|start|stop|restart|status|download <model>|load <model>}"; exit 1 ;;
esac
