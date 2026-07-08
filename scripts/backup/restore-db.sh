#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

check_common_deps
load_env
require_stack_up "${DB_SERVICE}"

: "${POSTGRES_DB:?}"
: "${POSTGRES_USER:?}"

BACKUP_FILE="${1:-}"
if [[ -z "${BACKUP_FILE}" ]]; then
  echo "Usage: $0 <db-backup.dump.gz>"
  echo
  echo "Available DB backups (newest first):"
  ls -1t "${BACKUP_ROOT}/db/daily/"db-*.dump.gz 2>/dev/null | sed 's/^/  /' || echo "  (none)"
  exit 1
fi

# Allow passing the 'latest' symlink.
[[ -f "${BACKUP_FILE}" ]] || die "Backup file not found: ${BACKUP_FILE}"

if [[ -f "${BACKUP_FILE}.sha256" ]]; then
  log "Verifying checksum..."
  ( cd "$(dirname "${BACKUP_FILE}")" && sha256_check "$(basename "${BACKUP_FILE}").sha256" ) \
    || die "Checksum verification failed"
fi

log "Verifying gzip integrity..."
gzip -t "${BACKUP_FILE}" || die "Gzip integrity check failed"

echo
warn "This will DROP and RESTORE database '${POSTGRES_DB}'. All current data will be LOST."
read -r -p "Type 'restore ${POSTGRES_DB}' to continue: " CONFIRM
[[ "${CONFIRM}" == "restore ${POSTGRES_DB}" ]] || die "Aborted by user"

log "Terminating active connections..."
dc exec -T "${DB_SERVICE}" \
  psql --username "${POSTGRES_USER}" --dbname postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   WHERE datname='${POSTGRES_DB}' AND pid <> pg_backend_pid();" >/dev/null || true

log "Dropping & recreating database..."
dc exec -T "${DB_SERVICE}" psql --username "${POSTGRES_USER}" --dbname postgres \
  -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};" \
  -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"

log "Restoring dump (custom format)..."
# pg_restore may emit non-fatal warnings; don't abort the whole script on them.
gunzip -c "${BACKUP_FILE}" \
  | dc exec -T "${DB_SERVICE}" \
      pg_restore --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
                 --no-owner --clean --if-exists \
  || warn "pg_restore reported warnings (often safe with --clean)"

log "Applying migrations to reconcile schema state..."
dc exec -T backend python manage.py migrate --noinput || warn "migrate reported issues"

log "Database restore complete."
