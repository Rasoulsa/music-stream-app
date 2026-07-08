#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

check_common_deps
load_env
ensure_dirs
require_stack_up "${MINIO_SERVICE}"
need tar

: "${AWS_ACCESS_KEY_ID:?}"
: "${AWS_SECRET_ACCESS_KEY:?}"
: "${AWS_STORAGE_BUCKET_NAME:=media}"

DOCKER_NETWORK="${COMPOSE_PROJECT}_default"

BACKUP_FILE="${1:-}"
if [[ -z "${BACKUP_FILE}" ]]; then
  echo "Usage: $0 <media-backup.tar.gz>"
  echo
  echo "Available media backups (newest first):"
  ls -1t "${BACKUP_ROOT}/media/daily/"media-*.tar.gz 2>/dev/null | sed 's/^/  /' || echo "  (none)"
  exit 1
fi

[[ -f "${BACKUP_FILE}" ]] || die "Backup file not found: ${BACKUP_FILE}"

if [[ -f "${BACKUP_FILE}.sha256" ]]; then
  log "Verifying checksum..."
  ( cd "$(dirname "${BACKUP_FILE}")" && sha256_check "$(basename "${BACKUP_FILE}").sha256" ) \
    || die "Checksum verification failed"
fi

log "Verifying gzip integrity..."
gzip -t "${BACKUP_FILE}" || die "Gzip integrity check failed"

echo
warn "This will OVERWRITE objects in bucket '${AWS_STORAGE_BUCKET_NAME}'."
read -r -p "Type 'restore media' to continue: " CONFIRM
[[ "${CONFIRM}" == "restore media" ]] || die "Aborted by user"

TMP_PARENT="${BACKUP_ROOT}/tmp"
mkdir -p "${TMP_PARENT}"
TMP_DIR="$(mktemp -d "${TMP_PARENT}/media-import.XXXXXX")"
trap 'rm -rf "${TMP_DIR}"' EXIT

log "Extracting media archive to temp dir..."
tar -xzf "${BACKUP_FILE}" -C "${TMP_DIR}"

if [[ ! -d "${TMP_DIR}/${AWS_STORAGE_BUCKET_NAME}" ]]; then
  die "Backup archive does not contain expected bucket directory: ${AWS_STORAGE_BUCKET_NAME}"
fi

log "Restoring media into bucket '${AWS_STORAGE_BUCKET_NAME}'..."

docker run --rm \
  --network "${DOCKER_NETWORK}" \
  --entrypoint /bin/sh \
  -v "${TMP_DIR}:/import:ro" \
  -e MC_HOST_minio="http://${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}@${MINIO_SERVICE}:9000" \
  minio/mc:latest \
  -c "
    set -e
    mc mb --ignore-existing minio/${AWS_STORAGE_BUCKET_NAME} >/dev/null 2>&1 || true
    mc mirror --quiet --overwrite /import/${AWS_STORAGE_BUCKET_NAME} minio/${AWS_STORAGE_BUCKET_NAME}
  "

log "Media restore complete."
