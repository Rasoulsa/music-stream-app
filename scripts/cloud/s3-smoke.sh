#!/usr/bin/env bash
#
# s3-smoke.sh — Prove S3 compatibility of the storage layer.
#
# Uploads, lists, downloads, verifies, and deletes a test object using the
# same S3 API the application uses. Works against MinIO (local) or real AWS S3.
#
# Usage:
#   bash scripts/cloud/s3-smoke.sh
#
# Reads config from .env.prod (or ENV_FILE). Required:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_STORAGE_BUCKET_NAME
# Optional:
#   AWS_S3_ENDPOINT_URL   (set for MinIO; UNSET for real AWS S3)
#   AWS_S3_REGION_NAME    (default: us-east-1)
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env.prod}"

log()  { echo "[s3-smoke] $*"; }
err()  { echo "[s3-smoke] ERROR: $*" >&2; }
die()  { err "$*"; exit 1; }

# ---- Load env ----
if [[ -f "${ENV_FILE}" ]]; then
  log "Loading environment from ${ENV_FILE}"
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
else
  log "No env file at ${ENV_FILE}; relying on exported vars."
fi

: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY required}"
: "${AWS_STORAGE_BUCKET_NAME:?AWS_STORAGE_BUCKET_NAME required}"
: "${AWS_S3_REGION_NAME:=us-east-1}"

ENDPOINT="${AWS_S3_ENDPOINT_URL:-}"

# ---- Pick a client: prefer aws CLI, fall back to mc via docker ----
have() { command -v "$1" >/dev/null 2>&1; }

TEST_KEY="s3-smoke/test-$(date -u +%Y%m%dT%H%M%SZ)-$$.txt"
TEST_CONTENT="s3-smoke-$(date -u +%s)-$RANDOM"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
echo "${TEST_CONTENT}" > "${TMP_DIR}/upload.txt"

log "Target bucket:  ${AWS_STORAGE_BUCKET_NAME}"
log "Endpoint:       ${ENDPOINT:-<AWS default>}"
log "Region:         ${AWS_S3_REGION_NAME}"
log "Test object:    ${TEST_KEY}"

run_with_aws_cli() {
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION="${AWS_S3_REGION_NAME}"

  local ep=()
  [[ -n "${ENDPOINT}" ]] && ep=(--endpoint-url "${ENDPOINT}")

  log "Using aws CLI"

  log "1/5 Upload..."
  aws "${ep[@]}" s3 cp "${TMP_DIR}/upload.txt" \
    "s3://${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}" >/dev/null

  log "2/5 List..."
  aws "${ep[@]}" s3 ls "s3://${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}" >/dev/null \
    || die "List failed — object not found"

  log "3/5 Download..."
  aws "${ep[@]}" s3 cp \
    "s3://${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}" \
    "${TMP_DIR}/download.txt" >/dev/null

  log "4/5 Verify content..."
  [[ "$(cat "${TMP_DIR}/download.txt")" == "${TEST_CONTENT}" ]] \
    || die "Content mismatch after round-trip"

  log "5/5 Delete..."
  aws "${ep[@]}" s3 rm "s3://${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}" >/dev/null
}

run_with_mc_docker() {
  log "aws CLI not found — using minio/mc via docker"

  local host_url
  if [[ -n "${ENDPOINT}" ]]; then
    # Convert http://host:port into mc alias
    host_url="${ENDPOINT}"
  else
    host_url="https://s3.${AWS_S3_REGION_NAME}.amazonaws.com"
  fi

  # Strip scheme for MC_HOST embedding
  local scheme="${host_url%%://*}"
  local hostport="${host_url#*://}"
  local mc_host="${scheme}://${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}@${hostport}"

  docker run --rm \
    --network "${DOCKER_NETWORK:-bridge}" \
    -v "${TMP_DIR}:/data" \
    -e MC_HOST_s3="${mc_host}" \
    --entrypoint /bin/sh \
    minio/mc:latest -c "
      set -e
      echo '[mc] Upload...'
      mc cp /data/upload.txt s3/${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}
      echo '[mc] List...'
      mc ls s3/${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}
      echo '[mc] Download...'
      mc cp s3/${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY} /data/download.txt
      echo '[mc] Delete...'
      mc rm s3/${AWS_STORAGE_BUCKET_NAME}/${TEST_KEY}
    "

  log "Verify content..."
  [[ "$(cat "${TMP_DIR}/download.txt")" == "${TEST_CONTENT}" ]] \
    || die "Content mismatch after round-trip"
}

if have aws; then
  run_with_aws_cli
elif have docker; then
  run_with_mc_docker
else
  die "Neither 'aws' CLI nor 'docker' available. Install one to run the smoke test."
fi

log "✅ S3 compatibility smoke test PASSED"
log "   The storage layer works against: ${ENDPOINT:-AWS S3}"
