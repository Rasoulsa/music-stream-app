#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

ensure_dirs

# Keep newest N files matching pattern; delete older ones (+ their .sha256).
prune_dir() {
  local dir="$1" pattern="$2" keep="$3"
  [[ -d "${dir}" ]] || return 0

  log "Pruning ${dir} (pattern=${pattern}, keep=${keep})"

  # Portable: list files newest-first without GNU-only find -printf / mapfile.
  # ls -t sorts by mtime, newest first. Nullglob-safe via the -1 check.
  local files=()
  local f
  while IFS= read -r f; do
    [[ -n "${f}" ]] && files+=("${f}")
  done < <(ls -1t "${dir}"/${pattern} 2>/dev/null)

  local count="${#files[@]}"
  if (( count <= keep )); then
    log "  nothing to prune (found ${count}, keep ${keep})"
    return 0
  fi

  local i=0
  for f in "${files[@]}"; do
    i=$((i + 1))
    if (( i > keep )); then
      log "  removing $(basename "${f}")"
      rm -f "${f}" "${f}.sha256"
    fi
  done
}

# Daily retention
prune_dir "${BACKUP_ROOT}/db/daily"    "db-*.dump.gz"    "${KEEP_DAILY}"
prune_dir "${BACKUP_ROOT}/media/daily" "media-*.tar.gz"  "${KEEP_DAILY}"

# Weekly retention
prune_dir "${BACKUP_ROOT}/db/weekly"    "db-*.dump.gz"    "${KEEP_WEEKLY}"
prune_dir "${BACKUP_ROOT}/media/weekly" "media-*.tar.gz"  "${KEEP_WEEKLY}"

# Prune old run logs (keep 30).
prune_dir "${BACKUP_ROOT}/logs" "backup-*.log" 30

log "Prune complete."
