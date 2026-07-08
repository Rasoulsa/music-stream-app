#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

check_common_deps
load_env
ensure_dirs
require_stack_up "${DB_SERVICE}"

: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"

OUT_DIR="${BACKUP_ROOT}/db/daily"
OUT_FILE="${OUT_DIR}/db-${TIMESTAMP}.dump.gz"

log "Starting PostgreSQL backup"
log "  Database: ${POSTGRES_DB}  User: ${POSTGRES_USER}"
log "  Output:   ${OUT_FILE}"

# Custom format (-Fc) allows selective restore + is compression-friendly.
# We still gzip for consistent handling and integrity checks.
if ! dc exec -T "${DB_SERVICE}" \
      pg_dump --username "${POSTGRES_USER}" --no-owner --format=custom "${POSTGRES_DB}" \
    | gzip -9 > "${OUT_FILE}"; then
  err "pg_dump failed"
  rm -f "${OUT_FILE}"
  exit 1
fi

[[ -s "${OUT_FILE}" ]] || { err "Backup file is empty"; rm -f "${OUT_FILE}"; exit 1; }
gzip -t "${OUT_FILE}"   || { err "Gzip integrity check failed"; rm -f "${OUT_FILE}"; exit 1; }

sha256_file "${OUT_FILE}" > "${OUT_FILE}.sha256"

# Convenience pointer to newest DB backup.
ln -sf "$(basename "${OUT_FILE}")" "${OUT_DIR}/latest.dump.gz"

# Weekly copy (Sundays).
if [[ "${DOW}" == "7" ]]; then
  cp -f "${OUT_FILE}"          "${BACKUP_ROOT}/db/weekly/"
  cp -f "${OUT_FILE}.sha256"   "${BACKUP_ROOT}/db/weekly/"
  log "Weekly DB copy stored."
fi

SIZE="$(du -h "${OUT_FILE}" | cut -f1)"
log "Database backup complete: ${OUT_FILE} (${SIZE})"
