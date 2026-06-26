#!/usr/bin/env bash
# =============================================================
# scripts/deploy.sh — Manual VPS deploy for Music Stream App
# =============================================================
#
# Steps:
#   1. Validate env file exists
#   2. Pre-flight: X Service on :443 must stay untouched
#   3. Pre-flight: App Nginx bind port must be free OR already owned by app nginx
#   4. Pull latest code from current branch
#   5. Build and start the full Docker stack
#   6. Wait for backend to become healthy
#   7. Print container status
#   8. Run smoke checks (nginx /healthz + API /api/health/)
#
# Phase II note:
#   When HAProxy is introduced on Day 40, set in .env.prod:
#     NGINX_HTTP_BIND=127.0.0.1:8444
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
HEALTH_RETRIES=40      # × 3s = 120s max wait
HEALTH_ENDPOINT="http://localhost/api/health/"
NGINX_HEALTH="http://localhost/healthz"

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
    --skip-pull) SKIP_PULL=true ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash scripts/deploy.sh [--skip-pull]"
      exit 1
      ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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

  if [[ ! -f "$ENV_FILE" ]]; then
    return 1
  fi

  grep -E "^[[:space:]]*${key}=" "$ENV_FILE" \
    | tail -n 1 \
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
  ss -tlnp 2>/dev/null | grep -Eq "[:.]${port}[[:space:]]"
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

# ══════════════════════════════════════════════════════════════
section "1 / 8 — Validating environment"
# ══════════════════════════════════════════════════════════════
if [[ ! -f "$ENV_FILE" ]]; then
  error "Missing $ENV_FILE."
  error "Run: cp .env.prod.example .env.prod  then fill in your secrets."
  exit 1
fi

info "Found $ENV_FILE ✓"

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
info "Waiting up to $((HEALTH_RETRIES * 3))s for backend..."

READY=false

for _ in $(seq 1 "$HEALTH_RETRIES"); do
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
  error "Backend did not become healthy after $((HEALTH_RETRIES * 3))s."
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

# ══════════════════════════════════════════════════════════════
section "6 / 8 — Container status"
# ══════════════════════════════════════════════════════════════
"${COMPOSE_CMD[@]}" ps

# ══════════════════════════════════════════════════════════════
section "7 / 8 — Smoke checks"
# ══════════════════════════════════════════════════════════════
info "Waiting 5s for nginx to stabilise..."
sleep 5

# Check 1: nginx internal health
if curl -fsS "$NGINX_HEALTH" >/dev/null 2>&1; then
  info "Nginx /healthz → 200 ✓"
else
  warn "Nginx /healthz did not respond. Check nginx container logs:"
  warn "  $(compose_for_message) logs nginx"
fi

# Check 2: API health endpoint
HTTP_CODE="$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" 2>/dev/null || echo "000")"

if [[ "$HTTP_CODE" == "200" ]]; then
  info "API $HEALTH_ENDPOINT → 200 ✓"
else
  error "API $HEALTH_ENDPOINT returned HTTP $HTTP_CODE"
  error "Check logs:"
  error "  $(compose_for_message) logs nginx backend"
  exit 1
fi

# Check 3: confirm X Service on :443 is still running
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
echo ""
echo -e "   ${YELLOW}Next: Day 40 — HAProxy + HTTPS + domain${NC}"
echo ""
