#!/usr/bin/env bash
#
# lib.sh — shared helpers for backup/restore scripts.
# Source it:  source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
set -euo pipefail

# ---- Resolve project root (scripts/backup/ -> project root) -------------
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${LIB_DIR}/../.." && pwd)"

# ---- Config defaults (overridable via env / .env.prod) ------------------
: "${BACKUP_ROOT:=${ROOT_DIR}/backups}"
: "${COMPOSE_PROJECT:=music-stream-app}"
: "${ENV_FILE:=${ROOT_DIR}/.env.prod}"

# Retention
: "${KEEP_DAILY:=7}"
: "${KEEP_WEEKLY:=4}"

# Compose service names
: "${DB_SERVICE:=db}"
: "${MINIO_SERVICE:=minio}"

# Timestamps
TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
DATE_ONLY="$(date -u +%Y%m%d)"
DOW="$(date -u +%u)"   # 1=Mon .. 7=Sun (weekly backup taken on Sunday=7)

# ---- Logging ------------------------------------------------------------
_ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
log()  { echo "[$(_ts)] $*"; }
warn() { echo "[$(_ts)] WARN: $*" >&2; }
err()  { echo "[$(_ts)] ERROR: $*" >&2; }
die()  { err "$*"; exit 1; }

# ---- Dependency check ---------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

check_common_deps() {
  need docker
  need gzip
  need find
  need sort
  need sha256sum 2>/dev/null || need shasum   # macOS fallback handled below
}

# Cross-platform sha256 (Linux: sha256sum, macOS: shasum -a 256)
sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1"
  else
    shasum -a 256 "$1"
  fi
}
sha256_check() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$1"
  else
    shasum -a 256 -c "$1"
  fi
}

# ---- Load env file ------------------------------------------------------
load_env() {
  if [[ -f "${ENV_FILE}" ]]; then
    log "Loading environment from ${ENV_FILE}"
    # shellcheck disable=SC1090
    set -a; source "${ENV_FILE}"; set +a
  else
    warn "Env file ${ENV_FILE} not found; relying on existing environment."
  fi
}

# ---- Ensure backup dirs -------------------------------------------------
ensure_dirs() {
  # Guard against an empty BACKUP_ROOT (e.g. blank line in .env.prod).
  if [[ -z "${BACKUP_ROOT:-}" ]]; then
    BACKUP_ROOT="${ROOT_DIR}/backups"
    warn "BACKUP_ROOT was empty; falling back to ${BACKUP_ROOT}"
  fi
  mkdir -p \
    "${BACKUP_ROOT}/db/daily"    "${BACKUP_ROOT}/db/weekly" \
    "${BACKUP_ROOT}/media/daily" "${BACKUP_ROOT}/media/weekly" \
    "${BACKUP_ROOT}/logs"
}

# ---- Compose wrapper (full prod invocation) -----------------------------
dc() {
  docker compose \
    --project-name "${COMPOSE_PROJECT}" \
    --env-file "${ENV_FILE}" \
    -f "${ROOT_DIR}/docker-compose.yml" \
    -f "${ROOT_DIR}/docker-compose.prod.yml" \
    "$@"
}

# ---- Verify the stack is up before backing up ---------------------------
require_stack_up() {
  local svc="$1"
  if ! dc ps --status running --services 2>/dev/null | grep -qx "${svc}"; then
    die "Service '${svc}' is not running. Start the stack first (make prod-up-d)."
  fi
}
