#!/usr/bin/env bash
set -euo pipefail
#
# install-backups.sh — install/uninstall/status for the daily backup timer.
#   sudo bash scripts/ops/install-backups.sh install
#   sudo bash scripts/ops/install-backups.sh uninstall
#   bash scripts/ops/install-backups.sh status
#
ACTION="${1:-install}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_ENTRY="${PROJECT_DIR}/scripts/backup/backup.sh"
SERVICE_FILE="/etc/systemd/system/music-backup.service"
TIMER_FILE="/etc/systemd/system/music-backup.timer"
RUN_USER="${SUDO_USER:-$(whoami)}"

require_root() { [[ "${EUID}" -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }; }

install_action() {
  require_root
  [[ -f "${BACKUP_ENTRY}" ]] || { echo "Missing: ${BACKUP_ENTRY}"; exit 1; }

  cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Music Stream App daily backup (database + media)
Wants=network-online.target
After=network-online.target docker.service
Requires=docker.service

[Service]
Type=oneshot
User=${RUN_USER}
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/env bash ${BACKUP_ENTRY}
EOF

  cat > "${TIMER_FILE}" <<'EOF'
[Unit]
Description=Run Music Stream App backup daily

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now music-backup.timer
  echo "Installed. Timers:"
  systemctl list-timers --all | grep -E 'music-backup|NEXT' || true
  echo "Run now:  sudo systemctl start music-backup.service"
  echo "Logs:     journalctl -u music-backup.service -n 50 --no-pager"
}

uninstall_action() {
  require_root
  systemctl disable --now music-backup.timer 2>/dev/null || true
  systemctl stop music-backup.service 2>/dev/null || true
  rm -f "${TIMER_FILE}" "${SERVICE_FILE}"
  systemctl daemon-reload
  systemctl reset-failed music-backup.service 2>/dev/null || true
  systemctl reset-failed music-backup.timer 2>/dev/null || true
  echo "Uninstalled."
}

status_action() {
  systemctl status music-backup.timer --no-pager || true
  echo
  systemctl list-timers --all | grep -E 'music-backup|NEXT' || true
  echo
  journalctl -u music-backup.service -n 50 --no-pager || true
}

case "${ACTION}" in
  install)   install_action ;;
  uninstall) uninstall_action ;;
  status)    status_action ;;
  *) echo "Usage: $0 {install|uninstall|status}"; exit 1 ;;
esac
