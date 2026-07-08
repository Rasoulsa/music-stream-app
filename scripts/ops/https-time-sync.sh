#!/usr/bin/env bash
set -euo pipefail

# https-time-sync.sh
#
# One-file manager for fallback HTTPS Date-header based time synchronization.
#
# Actions:
#   install    Install/update systemd service + timer, run once, verify
#   uninstall  Remove systemd service + timer + installed sync script
#   status     Show timer/service status
#   run        Run one sync attempt immediately
#   logs       Show recent service logs
#
# Why:
#   Standard NTP uses UDP/123. In restricted regions/networks, UDP/123 may be
#   blocked. This fallback uses HTTPS/TCP/443 Date headers to reduce clock drift.
#
# Important:
#   This is NOT a full replacement for NTP/Chrony.
#   Prefer real NTP whenever UDP/123 is available.
#   Make it executable: chmod +x scripts/ops/https-time-sync.sh

ACTION="${1:-install}"

SYNC_SCRIPT="/usr/local/sbin/sync-time-https.sh"
SERVICE_FILE="/etc/systemd/system/sync-time-https.service"
TIMER_FILE="/etc/systemd/system/sync-time-https.timer"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: This action must be run as root."
    echo
    echo "Use:"
    echo "  sudo bash scripts/ops/https-time-sync.sh ${ACTION}"
    exit 1
  fi
}

print_usage() {
  cat <<EOF
Usage:
  sudo bash scripts/ops/https-time-sync.sh install
  sudo bash scripts/ops/https-time-sync.sh uninstall
  bash scripts/ops/https-time-sync.sh status
  sudo bash scripts/ops/https-time-sync.sh run
  bash scripts/ops/https-time-sync.sh logs

Default action:
  install

Examples:
  sudo bash scripts/ops/https-time-sync.sh
  sudo bash scripts/ops/https-time-sync.sh install
  sudo bash scripts/ops/https-time-sync.sh uninstall
EOF
}

check_dependencies() {
  local missing=()

  for cmd in curl date awk sort systemctl journalctl timedatectl; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
      missing+=("${cmd}")
    fi
  done

  if ! command -v hwclock >/dev/null 2>&1; then
    missing+=("hwclock")
  fi

  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "ERROR: Missing required commands: ${missing[*]}" >&2
    echo "On Ubuntu/Debian, try:" >&2
    echo "  sudo apt update" >&2
    echo "  sudo apt install -y curl util-linux" >&2
    exit 1
  fi
}

write_sync_script() {
  cat > "${SYNC_SCRIPT}" <<'SYNC_EOF'
#!/usr/bin/env bash
set -euo pipefail

# sync-time-https.sh
#
# Fallback time correction using HTTPS Date headers.
# Useful when NTP UDP/123 is blocked.
#
# It queries multiple HTTPS sources, converts Date headers to Unix epochs,
# chooses a median-ish value, and adjusts system time only if the offset
# is above MAX_ALLOWED_OFFSET_SECONDS.

URLS=(
  "https://www.google.com"
  "https://www.cloudflare.com"
  "https://github.com"
  "https://ubuntu.com"
)

MAX_ALLOWED_OFFSET_SECONDS=2
MAX_REASONABLE_OFFSET_SECONDS=86400

epochs=()

echo "Starting HTTPS fallback time sync..."
echo "Current UTC time: $(date -u '+%Y-%m-%d %H:%M:%S %Z')"

for url in "${URLS[@]}"; do
  date_header="$(
    curl -fsSI --max-time 8 "$url" 2>/dev/null \
      | awk 'tolower($0) ~ /^date:/ { sub(/^[Dd][Aa][Tt][Ee]:[[:space:]]*/, ""); print; exit }'
  )" || true

  if [[ -z "${date_header:-}" ]]; then
    echo "WARN: No Date header from ${url}" >&2
    continue
  fi

  epoch="$(date -u -d "$date_header" +%s 2>/dev/null || true)"

  if [[ -n "${epoch:-}" ]]; then
    epochs+=("$epoch")
    echo "Source: ${url} -> ${date_header} -> ${epoch}"
  else
    echo "WARN: Could not parse Date header from ${url}: ${date_header}" >&2
  fi
done

if [[ "${#epochs[@]}" -lt 2 ]]; then
  echo "ERROR: Not enough HTTPS time sources responded." >&2
  exit 1
fi

# Sort epochs and use median-ish value.
IFS=$'\n' sorted=($(sort -n <<<"${epochs[*]}"))
unset IFS

median_index=$((${#sorted[@]} / 2))
remote_epoch="${sorted[$median_index]}"
local_epoch="$(date -u +%s)"

offset=$((remote_epoch - local_epoch))
abs_offset="${offset#-}"

echo "Local epoch:  ${local_epoch}"
echo "Remote epoch: ${remote_epoch}"
echo "Offset:       ${offset}s"

if (( abs_offset > MAX_REASONABLE_OFFSET_SECONDS )); then
  echo "ERROR: Offset is too large; refusing to set time." >&2
  exit 1
fi

if (( abs_offset <= MAX_ALLOWED_OFFSET_SECONDS )); then
  echo "Clock offset <= ${MAX_ALLOWED_OFFSET_SECONDS}s; no change needed."
  exit 0
fi

echo "Updating system time from HTTPS Date header..."
date -u -s "@${remote_epoch}"

echo "Syncing hardware clock..."
hwclock --systohc --utc

echo "Done."
timedatectl
SYNC_EOF

  chmod 0755 "${SYNC_SCRIPT}"
}

write_systemd_units() {
  cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Fallback HTTPS time synchronization
Documentation=man:date(1) man:curl(1)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=${SYNC_SCRIPT}
PrivateTmp=true
EOF

  cat > "${TIMER_FILE}" <<'TIMER_EOF'
[Unit]
Description=Run fallback HTTPS time synchronization periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
AccuracySec=30s
Persistent=true

[Install]
WantedBy=timers.target
TIMER_EOF
}

show_status() {
  echo
  echo "=============================="
  echo "Timer status"
  echo "=============================="
  systemctl status sync-time-https.timer --no-pager || true

  echo
  echo "=============================="
  echo "Timer schedule"
  echo "=============================="
  systemctl list-timers --all | grep -E 'sync-time|NEXT|n/a' || true

  echo
  echo "=============================="
  echo "Recent service logs"
  echo "=============================="
  journalctl -u sync-time-https.service -n 50 --no-pager || true
}

install_action() {
  require_root
  check_dependencies

  echo "Installing/updating HTTPS time sync fallback..."

  write_sync_script
  write_systemd_units

  systemctl daemon-reload
  systemctl enable --now sync-time-https.timer

  echo
  echo "Running one immediate sync attempt..."
  systemctl start sync-time-https.service || true

  show_status

  echo
  echo "Installed successfully."
  echo
  echo "Useful commands:"
  echo "  sudo bash scripts/ops/https-time-sync.sh run"
  echo "  bash scripts/ops/https-time-sync.sh status"
  echo "  bash scripts/ops/https-time-sync.sh logs"
  echo "  sudo bash scripts/ops/https-time-sync.sh uninstall"
}

uninstall_action() {
  require_root

  echo "Uninstalling HTTPS time sync fallback..."

  systemctl disable --now sync-time-https.timer 2>/dev/null || true
  systemctl stop sync-time-https.service 2>/dev/null || true

  rm -f "${TIMER_FILE}"
  rm -f "${SERVICE_FILE}"
  rm -f "${SYNC_SCRIPT}"

  systemctl daemon-reload
  systemctl reset-failed sync-time-https.service 2>/dev/null || true
  systemctl reset-failed sync-time-https.timer 2>/dev/null || true

  echo "Removed:"
  echo "  ${TIMER_FILE}"
  echo "  ${SERVICE_FILE}"
  echo "  ${SYNC_SCRIPT}"
  echo
  echo "Uninstalled successfully."
}

run_action() {
  require_root

  if [[ ! -f "${SERVICE_FILE}" ]]; then
    echo "ERROR: Service is not installed."
    echo "Install first:"
    echo "  sudo bash scripts/ops/https-time-sync.sh install"
    exit 1
  fi

  systemctl start sync-time-https.service
  journalctl -u sync-time-https.service -n 50 --no-pager
}

logs_action() {
  journalctl -u sync-time-https.service -n 50 --no-pager || true
}

case "${ACTION}" in
  install)
    install_action
    ;;
  uninstall|remove)
    uninstall_action
    ;;
  status)
    show_status
    ;;
  run|sync)
    run_action
    ;;
  logs)
    logs_action
    ;;
  help|-h|--help)
    print_usage
    ;;
  *)
    echo "ERROR: Unknown action: ${ACTION}" >&2
    echo
    print_usage
    exit 1
    ;;
esac
