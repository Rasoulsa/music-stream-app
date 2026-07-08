#!/usr/bin/env bash
#
# upload-rsync.sh — Push today's backups to a remote host via rsync over SSH.
#
# This is an optional offsite strategy (alternative to S3).
# Triggered by backup.sh when BACKUP_RSYNC_UPLOAD=true in .env.prod.
#
# Required env vars:
#   BACKUP_RSYNC_HOST  — e.g. deploy@backup.example.com
#   BACKUP_RSYNC_PATH  — e.g. /opt/backups/music-stream-app
#   BACKUP_RSYNC_KEY   — path to SSH private key
#
# What it does:
#   rsync -az --delete syncs the full BACKUP_ROOT to the remote host.
#   --delete removes files on remote that no longer exist locally,
#   so remote mirrors local retention (keeps same N files).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

load_env
need rsync
need ssh

: "${BACKUP_RSYNC_HOST:?BACKUP_RSYNC_HOST is required for rsync upload}"
: "${BACKUP_RSYNC_PATH:?BACKUP_RSYNC_PATH is required for rsync upload}"
: "${BACKUP_RSYNC_KEY:?BACKUP_RSYNC_KEY is required for rsync upload}"

[[ -f "${BACKUP_RSYNC_KEY}" ]] || die "SSH key not found: ${BACKUP_RSYNC_KEY}"

log "Syncing backups to ${BACKUP_RSYNC_HOST}:${BACKUP_RSYNC_PATH}"
log "  Source: ${BACKUP_ROOT}/"

# Ensure remote directory exists.
ssh -i "${BACKUP_RSYNC_KEY}" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=10 \
    "${BACKUP_RSYNC_HOST}" \
    "mkdir -p ${BACKUP_RSYNC_PATH}"

# Sync backup artifacts only (exclude tmp dir and lock file).
rsync -az \
  --delete \
  --exclude='tmp/' \
  --exclude='.backup.lock' \
  --stats \
  -e "ssh -i ${BACKUP_RSYNC_KEY} -o StrictHostKeyChecking=no -o ConnectTimeout=10" \
  "${BACKUP_ROOT}/" \
  "${BACKUP_RSYNC_HOST}:${BACKUP_RSYNC_PATH}/"

log "Rsync upload complete → ${BACKUP_RSYNC_HOST}:${BACKUP_RSYNC_PATH}"
