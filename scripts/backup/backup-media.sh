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

# Object-store-native backup:
# 1. Use a throwaway `mc` container to mirror the bucket to a host-mounted temp dir.
# 2. Use host `tar` to create a compressed archive.
#
# This avoids depending on MinIO's internal on-disk layout and works with real S3 later.
#
# IMPORTANT: the mc container runs with the host user's UID/GID (--user) so the
# exported files are owned by the invoking user (e.g. 'deploy'), not root. This
# lets the host clean up the temp dir afterwards without needing sudo. A writable
# MC_CONFIG_DIR under /tmp is provided because a non-root container user cannot
# write to the default /root/.mc config location.
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY required}"
: "${AWS_STORAGE_BUCKET_NAME:=media}"

DOCKER_NETWORK="${COMPOSE_PROJECT}_default"
OUT_DIR="${BACKUP_ROOT}/media/daily"
OUT_FILE="${OUT_DIR}/media-${TIMESTAMP}.tar.gz"

TMP_PARENT="${BACKUP_ROOT}/tmp"
mkdir -p "${TMP_PARENT}"
TMP_DIR="$(mktemp -d "${TMP_PARENT}/media-export.XXXXXX")"

# Tolerant cleanup: the backup artifact is created and verified before cleanup,
# so a cleanup failure must never fail the whole run. Warn if it can't remove
# (e.g. leftover root-owned files from an older run) but keep the exit code clean.
cleanup_tmp() {
  if ! rm -rf "${TMP_DIR}" 2>/dev/null; then
    log "WARNING: could not remove temp dir ${TMP_DIR} (possibly root-owned leftovers)."
    log "         The backup artifact is safe. Remove temp manually if needed:"
    log "         sudo rm -rf ${TMP_DIR}"
  fi
}
trap cleanup_tmp EXIT

log "Starting media backup (bucket: ${AWS_STORAGE_BUCKET_NAME})"
log "  Temp:   ${TMP_DIR}"
log "  Output: ${OUT_FILE}"

# Mirror bucket into a host-mounted temp directory.
# The mc image does not include tar, so archiving is done on the host below.
# --user ensures exported files are owned by the host user (clean removal later).
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --network "${DOCKER_NETWORK}" \
  --entrypoint /bin/sh \
  -v "${TMP_DIR}:/export" \
  -e HOME=/tmp \
  -e MC_CONFIG_DIR=/tmp/.mc \
  -e MC_HOST_minio="http://${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}@${MINIO_SERVICE}:9000" \
  minio/mc:latest \
  -c "
    set -e
    mkdir -p /export/${AWS_STORAGE_BUCKET_NAME}
    mc ls minio/${AWS_STORAGE_BUCKET_NAME} >/dev/null
    mc mirror --quiet --overwrite minio/${AWS_STORAGE_BUCKET_NAME} /export/${AWS_STORAGE_BUCKET_NAME}
  "

# Create tar.gz on the host.
tar -czf "${OUT_FILE}" -C "${TMP_DIR}" .

[[ -s "${OUT_FILE}" ]] || { err "Media backup is empty"; rm -f "${OUT_FILE}"; exit 1; }
gzip -t "${OUT_FILE}"   || { err "Gzip integrity check failed"; rm -f "${OUT_FILE}"; exit 1; }

sha256_file "${OUT_FILE}" > "${OUT_FILE}.sha256"

ln -sf "$(basename "${OUT_FILE}")" "${OUT_DIR}/latest.tar.gz"

if [[ "${DOW}" == "7" ]]; then
  cp -f "${OUT_FILE}"        "${BACKUP_ROOT}/media/weekly/"
  cp -f "${OUT_FILE}.sha256" "${BACKUP_ROOT}/media/weekly/"
  log "Weekly media copy stored."
fi

SIZE="$(du -h "${OUT_FILE}" | cut -f1)"
log "Media backup complete: ${OUT_FILE} (${SIZE})"
