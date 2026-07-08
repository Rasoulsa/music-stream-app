#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

load_env
: "${BACKUP_S3_BUCKET:?BACKUP_S3_BUCKET is required for remote upload}"
need aws

ENDPOINT_ARG=()
[[ -n "${BACKUP_S3_ENDPOINT:-}" ]] && ENDPOINT_ARG=(--endpoint-url "${BACKUP_S3_ENDPOINT}")

log "Uploading today's backups to s3://${BACKUP_S3_BUCKET}/${DATE_ONLY}/"

aws "${ENDPOINT_ARG[@]}" s3 cp "${BACKUP_ROOT}/db/daily/" \
  "s3://${BACKUP_S3_BUCKET}/${DATE_ONLY}/db/" \
  --recursive --exclude "*" --include "db-*"

aws "${ENDPOINT_ARG[@]}" s3 cp "${BACKUP_ROOT}/media/daily/" \
  "s3://${BACKUP_S3_BUCKET}/${DATE_ONLY}/media/" \
  --recursive --exclude "*" --include "media-*"

log "Remote upload complete."
