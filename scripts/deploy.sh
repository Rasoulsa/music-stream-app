#!/usr/bin/env bash
# =============================================================
# scripts/deploy.sh — Manual + CI VPS deploy for Music Stream App
# =============================================================
#
# Steps:
#   0. Acquire a deploy lock (prevents two deploys running at once —
#      see Day 41 note below)
#   1. Validate env file exists AND passes full check-env.sh validation
#   2. Pre-flight: X Service on :443 must stay untouched
#   3. Pre-flight: App Nginx bind port must be free OR already owned by app nginx
#   4. Pull latest code from current branch
#   5. Build and start the full Docker stack
#   6. Wait for backend to become healthy
#   7. Refresh App Nginx to avoid stale upstream/Docker DNS issues
#   8. Print container status and run smoke checks
#
# Why Nginx is refreshed:
#   During redeploys, backend/frontend containers may be recreated and receive
#   new Docker network IPs. Recreating the app nginx container after backend is
#   healthy makes the reverse proxy start with fresh upstream/DNS state and
#   avoids temporary 502 Bad Gateway responses caused by stale upstream targets.
#
# Phase II note:
#   When HAProxy is introduced on Day 40, set in .env.prod:
#     NGINX_HTTP_BIND=127.0.0.1:8444
#
# Day 41 note (CI/CD auto-deploy):
#   This script now has TWO callers: you, running it manually over SSH,
#   and GitHub Actions (.github/workflows/deploy.yml), running it
#   automatically on every push to main. Two changes support that:
#     - A flock-based lock (section 0) so a manual run and an automated
#       run can never execute concurrently and race each other.
#     - Full scripts/check-env.sh validation (not just "file exists") in
#       section 1, so BOTH callers get the same safety net — previously
#       only a separate CI step had the strong check; now it's here once,
#       for everyone, which is the whole point of having one script.
#   ANSI colors are also now skipped automatically when stdout isn't a
#   real terminal (e.g. inside a GitHub Actions log), so CI logs don't
#   fill up with raw escape codes like \033[0;32m.
#
# Usage:
#   bash scripts/deploy.sh
#   bash scripts/deploy.sh --skip-pull
# =============================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────
ENV_FILE=".env.prod"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_PULL=false

BACKEND_HEALTH_RETRIES=40      # × 3s = 120s max wait
HTTP_RETRIES=20                # × 3s = 60s max wait for HTTP smoke checks
HTTP_RETRY_SLEEP=3

HEALTH_ENDPOINT="http://localhost/api/health/"
NGINX_HEALTH="http://localhost/healthz"

# Day 41: lock file + fd used to serialize deploys. A fixed path under
# /tmp is fine here — this app has exactly one deploy target (this VPS),
# so there's no risk of colliding with some other project's lock.
LOCK_FILE="/tmp/music-stream-app.deploy.lock"
LOCK_FD=200

COMPOSE_FILES=(
  -f docker-compose.yml
  -f docker-compose.prod.yml
  -f docker-compose.vps.yml
)

COMPOSE_CMD=(
  docker compose
  --env-file "$ENV_FILE"
  "${COMPOSE_FILES[@]}"
)

# ── Flags ─────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --skip-pull)
      SKIP_PULL=true
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash scripts/deploy.sh [--skip-pull]"
      exit 1
      ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────
# Day 41: only enable ANSI colors when attached to a real terminal.
# GitHub Actions' SSH log output is not a tty, so without this check
# every line would be prefixed with raw \033[...m escape sequences.
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN=''
  YELLOW=''
  RED=''
  CYAN=''
  BOLD=''
  NC=''
fi

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
section() { echo -e "\n${CYAN}${BOLD}▶ $*${NC}"; }

cd "$PROJECT_DIR"

# ── Helpers ───────────────────────────────────────────────────
compose_for_message() {
  echo "docker compose --env-file $ENV_FILE -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.vps.yml"
}

read_env_value() {
  local key="$1"
  local line

  if [[ ! -f "$ENV_FILE" ]]; then
    return 1
  fi

  line="$(
    grep -E "^[[:space:]]*${key}=" "$ENV_FILE" 2>/dev/null \
      | tail -n 1 \
      || true
  )"

  if [[ -z "$line" ]]; then
    return 1
  fi

  echo "$line" \
    | cut -d '=' -f2- \
    | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | sed -E 's/^"//; s/"$//' \
    | sed -E "s/^'//; s/'$//"
}

extract_bind_port() {
  local bind="$1"

  # Examples:
  #   80                -> 80
  #   0.0.0.0:80        -> 80
  #   127.0.0.1:8444    -> 8444
  #   [::1]:8444        -> 8444
  if [[ "$bind" == *":"* ]]; then
    echo "${bind##*:}"
  else
    echo "$bind"
  fi
}

port_in_use() {
  local port="$1"

  # Uses listening TCP sockets only.
  # Matches examples like:
  #   0.0.0.0:80
  #   127.0.0.1:8444
  #   [::]:80
  ss -H -tln 2>/dev/null | grep -Eq "[:.]${port}[[:space:]]"
}

app_nginx_container_id() {
  "${COMPOSE_CMD[@]}" ps -q nginx 2>/dev/null || true
}

app_nginx_owns_port() {
  local port="$1"
  local cid

  cid="$(app_nginx_container_id)"

  if [[ -z "$cid" ]]; then
    return 1
  fi

  docker inspect "$cid" \
    --format '{{range $containerPort, $bindings := .NetworkSettings.Ports}}{{range $bindings}}{{if eq .HostPort "'"$port"'"}}yes{{end}}{{end}}{{end}}' \
    2>/dev/null | grep -q "yes"
}

backend_container_id() {
  "${COMPOSE_CMD[@]}" ps -q backend 2>/dev/null || true
}

backend_health_status() {
  local cid

  cid="$(backend_container_id)"

  if [[ -z "$cid" ]]; then
    echo "missing"
    return 0
  fi

  docker inspect "$cid" \
    --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
    2>/dev/null || echo "unknown"
}

wait_for_http_200() {
  local url="$1"
  local label="$2"
  local retries="${3:-$HTTP_RETRIES}"
  local sleep_seconds="${4:-$HTTP_RETRY_SLEEP}"
  local code="000"

  info "Checking $label: $url"

  for _ in $(seq 1 "$retries"); do
    code="$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")"

    if [[ "$code" == "200" ]]; then
      info "$label → 200 ✓"
      return 0
    fi

    echo -n "."
    sleep "$sleep_seconds"
  done

  echo ""
  error "$label returned HTTP $code after $((retries * sleep_seconds))s"
  return 1
}

refresh_app_nginx() {
  info "Refreshing app nginx reverse proxy..."

  # Force recreate only the app nginx service.
  #
  # This does NOT touch X Service on :443.
  # It only recreates the Docker Compose nginx container for this app.
  #
  # Purpose:
  #   - refresh Docker DNS/upstream state
  #   - avoid stale backend/frontend container IPs after redeploy
  #   - reduce transient 502 Bad Gateway responses
  "${COMPOSE_CMD[@]}" up -d --no-deps --force-recreate nginx

  sleep 3
  info "App nginx refreshed ✓"
}

# ══════════════════════════════════════════════════════════════
section "0 — Acquiring deploy lock"
# ══════════════════════════════════════════════════════════════
# Day 41: opens (or creates) the lock file on a dedicated file
# descriptor, then tries a non-blocking exclusive flock on it.
# If another deploy (manual OR CI-triggered) is already holding it,
# this fails immediately with a clear message instead of racing it.
# The lock is released automatically when this script's process exits,
# for any reason — success, failure, or Ctrl-C.
exec 200>"$LOCK_FILE"

if ! flock -n "$LOCK_FD"; then
  error "Another deploy is already in progress (lock: $LOCK_FILE)."
  error "If you're sure nothing is actually running, remove the lock file:"
  error "  rm -f $LOCK_FILE"
  exit 1
fi

info "Lock acquired ✓"

# ══════════════════════════════════════════════════════════════
section "1 / 8 — Validating environment"
# ══════════════════════════════════════════════════════════════
if [[ ! -f "$ENV_FILE" ]]; then
  error "Missing $ENV_FILE."
  error "Run: cp .env.prod.example .env.prod  then fill in your secrets."
  exit 1
fi

info "Found $ENV_FILE ✓"

# Day 41: run the FULL validation (placeholder values, DEBUG=true guard,
# secret-key length/entropy, wildcard ALLOWED_HOSTS), not just an
# existence check. This used to only run as a separate step in CI —
# it's here now so a manual `bash scripts/deploy.sh` gets the exact
# same protection as an automated one.
if ! bash "$PROJECT_DIR/scripts/check-env.sh" "$ENV_FILE"; then
  error "$ENV_FILE failed validation (see output above)."
  error "Fix the issues, or run: ./scripts/generate-secrets.sh"
  exit 1
fi

# ══════════════════════════════════════════════════════════════
section "2 / 8 — Port pre-flight checks"
# ══════════════════════════════════════════════════════════════

# :443 — X Service must keep running. We never touch it.
if port_in_use 443; then
  info "Port 443: in use (X Service is running — will not be touched) ✓"
else
  warn "Port 443: NOT in use. If X Service is supposed to be running, check it."
  warn "Continuing anyway — App Nginx does not use :443 today."
fi

# App Nginx bind port.
# Read from shell env first, then .env.prod, then default.
NGINX_BIND="${NGINX_HTTP_BIND:-}"

if [[ -z "$NGINX_BIND" ]]; then
  NGINX_BIND="$(read_env_value NGINX_HTTP_BIND || true)"
fi

NGINX_BIND="${NGINX_BIND:-0.0.0.0:80}"
NGINX_BIND_PORT="$(extract_bind_port "$NGINX_BIND")"

if [[ -z "$NGINX_BIND_PORT" ]]; then
  error "Could not parse NGINX_HTTP_BIND=$NGINX_BIND"
  exit 1
fi

info "App Nginx bind target: $NGINX_BIND"

if port_in_use "$NGINX_BIND_PORT"; then
  if app_nginx_owns_port "$NGINX_BIND_PORT"; then
    info "Port $NGINX_BIND_PORT: already used by this app's nginx container — redeploy safe ✓"
  else
    error "Port $NGINX_BIND_PORT is already in use by another process/service."
    error "App Nginx needs: $NGINX_BIND"
    error "Check what is using it:"
    error "  sudo ss -tlnp | grep ':$NGINX_BIND_PORT '"
    exit 1
  fi
else
  info "Port $NGINX_BIND_PORT: free ✓"
fi

# ══════════════════════════════════════════════════════════════
section "3 / 8 — Pulling latest code"
# ══════════════════════════════════════════════════════════════
if [[ "$SKIP_PULL" == true ]]; then
  warn "--skip-pull flag set, skipping git pull."
else
  BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  info "Branch: $BRANCH"

  git pull --ff-only origin "$BRANCH" \
    || warn "git pull failed or skipped (detached HEAD / local-only branch). Continuing."
fi

# ══════════════════════════════════════════════════════════════
section "4 / 8 — Building and starting Docker stack"
# ══════════════════════════════════════════════════════════════
info "Running: $(compose_for_message) up -d --build --remove-orphans"
"${COMPOSE_CMD[@]}" up -d --build --remove-orphans

# ══════════════════════════════════════════════════════════════
section "5 / 8 — Waiting for backend to become healthy"
# ══════════════════════════════════════════════════════════════
info "Waiting up to $((BACKEND_HEALTH_RETRIES * 3))s for backend..."

READY=false

for _ in $(seq 1 "$BACKEND_HEALTH_RETRIES"); do
  HEALTH_STATUS="$(backend_health_status)"

  if [[ "$HEALTH_STATUS" == "healthy" ]]; then
    READY=true
    break
  fi

  # Fallback for images without Docker healthcheck.
  if [[ "$HEALTH_STATUS" == "running" ]]; then
    if "${COMPOSE_CMD[@]}" exec -T backend pgrep gunicorn >/dev/null 2>&1; then
      READY=true
      break
    fi
  fi

  echo -n "."
  sleep 3
done

echo ""

if [[ "$READY" == false ]]; then
  error "Backend did not become healthy after $((BACKEND_HEALTH_RETRIES * 3))s."
  error "Backend health status: $(backend_health_status)"
  error "Check logs:"
  error "  $(compose_for_message) logs backend"
  exit 1
fi

info "Backend is healthy ✓"

# Optional Django deploy checks.
if "${COMPOSE_CMD[@]}" exec -T backend /app/.venv/bin/python manage.py check --deploy >/tmp/music_deploy_check.log 2>&1; then
  info "Django deploy check completed ✓"
else
  warn "Django deploy check returned warnings/errors. Output:"
  cat /tmp/music_deploy_check.log || true
fi

# Refresh app nginx after backend/frontend recreation.
# This makes redeploys more reliable and avoids stale upstream/Docker DNS issues.
refresh_app_nginx

# ══════════════════════════════════════════════════════════════
section "6 / 8 — Container status"
# ══════════════════════════════════════════════════════════════
"${COMPOSE_CMD[@]}" ps

# ══════════════════════════════════════════════════════════════
section "7 / 8 — Smoke checks"
# ══════════════════════════════════════════════════════════════
info "Running HTTP smoke checks with retries..."

# Check 1: nginx internal health.
if ! wait_for_http_200 "$NGINX_HEALTH" "Nginx /healthz" 15 2; then
  error "Nginx /healthz failed."
  error "Check nginx logs:"
  error "  $(compose_for_message) logs nginx"
  exit 1
fi

# Check 2: API health endpoint through nginx.
if ! wait_for_http_200 "$HEALTH_ENDPOINT" "API $HEALTH_ENDPOINT" "$HTTP_RETRIES" "$HTTP_RETRY_SLEEP"; then
  error "API smoke check failed."
  error "Check logs:"
  error "  $(compose_for_message) logs nginx backend"
  exit 1
fi

# Check 3: confirm X Service on :443 is still running.
if port_in_use 443; then
  info "X Service on :443 still running — not affected by deploy ✓"
else
  warn "X Service on :443 is no longer detected. Check it manually."
fi

# ══════════════════════════════════════════════════════════════
section "8 / 8 — Done"
# ══════════════════════════════════════════════════════════════
VPS_IP="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || echo "<VPS_IP>")"

echo ""
echo -e "${GREEN}${BOLD}🎉 Deploy complete.${NC}"
echo -e "   App:      ${CYAN}http://${VPS_IP}/${NC}"
echo -e "   API:      ${CYAN}http://${VPS_IP}/api/v1/${NC}"
echo -e "   Docs:     ${CYAN}http://${VPS_IP}/api/docs/${NC}"
echo -e "   Health:   ${CYAN}http://${VPS_IP}/api/health/${NC}"
