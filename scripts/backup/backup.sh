#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DO_DB=true
DO_MEDIA=true
for arg in "$@"; do
  case "${arg}" in
    --db-only)    DO_MEDIA=false ;;
    --media-only) DO_DB=false ;;
    -h|--help)
      echo "Usage: $0 [--db-only|--media-only]"; exit 0 ;;
    *) die "Unknown option: ${arg}" ;;
  esac
done

check_common_deps
ensure_dirs

LOG_FILE="${BACKUP_ROOT}/logs/backup-${TIMESTAMP}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

log "==============================================="
log "Backup run started"
log "  Project: ${COMPOSE_PROJECT}"
log "  Root:    ${BACKUP_ROOT}"
log "  Daily keep: ${KEEP_DAILY}  Weekly keep: ${KEEP_WEEKLY}"
log "==============================================="

# Prevent concurrent runs (flock is Linux-only; skip gracefully elsewhere).
LOCK_FILE="${BACKUP_ROOT}/.backup.lock"
if command -v flock >/dev/null 2>&1; then
  exec 9>"${LOCK_FILE}"
  flock -n 9 || die "Another backup is already running (lock: ${LOCK_FILE})"
else
  warn "flock not available (non-Linux host) — skipping concurrency lock."
fi

FAILED=0

if [[ "${DO_DB}" == true ]]; then
  log "--- Database backup ---"
  "${SCRIPT_DIR}/backup-db.sh" || { err "Database backup FAILED"; FAILED=1; }
fi

if [[ "${DO_MEDIA}" == true ]]; then
  log "--- Media backup ---"
  "${SCRIPT_DIR}/backup-media.sh" || { err "Media backup FAILED"; FAILED=1; }
fi

log "--- Prune old backups ---"
"${SCRIPT_DIR}/prune.sh" || warn "Prune step had issues (non-fatal)"

if [[ "${BACKUP_REMOTE_UPLOAD:-false}" == "true" ]]; then
  log "--- Off-site upload ---"
  if [[ -x "${SCRIPT_DIR}/upload-remote.sh" ]]; then
    "${SCRIPT_DIR}/upload-remote.sh" || warn "Remote upload had issues"
  else
    warn "BACKUP_REMOTE_UPLOAD=true but upload-remote.sh not executable"
  fi
fi

if (( FAILED != 0 )); then
  err "Backup run completed WITH ERRORS"
  exit 1
fi
log "Backup run completed successfully"
