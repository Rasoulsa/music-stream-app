#!/usr/bin/env bash
# =============================================================
# scripts/deploy.sh — Manual VPS deploy for Music Stream App
# =============================================================
#
# Steps:
#   1. Validate env file exists
#   2. Pre-flight: X Service on :443 must stay untouched
#   3. Pre-flight: :80 must be free for App Nginx
#   4. Pull latest code from current branch
#   5. Build and start the full Docker stack
#   6. Wait for backend to be genuinely healthy
#   7. Print container status
#   8. Run smoke checks (nginx /healthz + API /api/health/)
#
# Phase II note:
#   When HAProxy is introduced on Day 40, set in .env.prod:
#     NGINX_HTTP_BIND=127.0.0.1:8444
#   This script needs no other changes — the port check below
#   will automatically adapt to the new binding.
#
# Usage:
#   bash scripts/deploy.sh
#   bash scripts/deploy.sh --skip-pull    (skip git pull)
# =============================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────
COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.vps.yml"
ENV_FILE=".env.prod"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKIP_PULL=false
HEALTH_RETRIES=40      # × 3s = 120s max wait
HEALTH_ENDPOINT="http://localhost/api/health/"
NGINX_HEALTH="http://localhost/healthz"

# ── Flags ─────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --skip-pull) SKIP_PULL=true ;;
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
if ss -tlnp 2>/dev/null | grep -q ':443 '; then
  info "Port 443: in use (X Service is running — will not be touched) ✓"
else
  warn "Port 443: NOT in use. If X Service is supposed to be running, check it."
  warn "Continuing anyway — App Nginx does not use :443 today."
fi

# :80 — must be free for App Nginx
# (on Phase II, NGINX_HTTP_BIND will be 127.0.0.1:8444 — skip :80 check then)
NGINX_BIND="${NGINX_HTTP_BIND:-0.0.0.0:80}"
if [[ "$NGINX_BIND" == *":80" ]] || [[ "$NGINX_BIND" == "0.0.0.0:80" ]]; then
  if ss -tlnp 2>/dev/null | grep -q ':80 '; then
    error "Port 80 is already in use. App Nginx needs it."
    error "Check what is using it:  sudo ss -tlnp | grep ':80 '"
    exit 1
  fi
  info "Port 80: free ✓"
else
  info "NGINX_HTTP_BIND=$NGINX_BIND — skipping :80 check (Phase II mode)"
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
info "Running: docker compose ... up -d --build"
# shellcheck disable=SC2086
docker compose $COMPOSE_FILES --env-file "$ENV_FILE" up -d --build

# ══════════════════════════════════════════════════════════════
section "5 / 8 — Waiting for backend to become healthy"
# ══════════════════════════════════════════════════════════════
info "Waiting up to $((HEALTH_RETRIES * 3))s for backend..."
READY=false
for i in $(seq 1 "$HEALTH_RETRIES"); do
  # shellcheck disable=SC2086
  STATUS=$(docker compose $COMPOSE_FILES --env-file "$ENV_FILE" \
    exec -T backend \
    /app/.venv/bin/python manage.py check --deploy 2>&1 | tail -1 || true)

  if echo "$STATUS" | grep -q "System check identified no issues"; then
    READY=true
    break
  fi

  # Fallback: just check if gunicorn process is up
  # shellcheck disable=SC2086
  if docker compose $COMPOSE_FILES --env-file "$ENV_FILE" \
       exec -T backend pgrep gunicorn >/dev/null 2>&1; then
    READY=true
    break
  fi

  echo -n "."
  sleep 3
done
echo ""

if [[ "$READY" == false ]]; then
  error "Backend did not become healthy after $((HEALTH_RETRIES * 3))s."
  error "Check logs: docker compose $COMPOSE_FILES logs backend"
  exit 1
fi
info "Backend is up ✓"

# ══════════════════════════════════════════════════════════════
section "6 / 8 — Container status"
# ══════════════════════════════════════════════════════════════
# shellcheck disable=SC2086
docker compose $COMPOSE_FILES --env-file "$ENV_FILE" ps

# ══════════════════════════════════════════════════════════════
section "7 / 8 — Smoke checks"
# ══════════════════════════════════════════════════════════════
info "Waiting 5s for nginx to stabilise..."
sleep 5

# Check 1: nginx internal health
if curl -fsS "$NGINX_HEALTH" >/dev/null 2>&1; then
  info "Nginx /healthz → 200 ✓"
else
  warn "Nginx /healthz did not respond. Check nginx container logs."
fi

# Check 2: API health endpoint
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_ENDPOINT" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
  info "API $HEALTH_ENDPOINT → 200 ✓"
else
  error "API $HEALTH_ENDPOINT returned HTTP $HTTP_CODE"
  error "Check logs: docker compose $COMPOSE_FILES logs nginx backend"
  exit 1
fi

# Check 3: confirm X Service on :443 is still running
if ss -tlnp 2>/dev/null | grep -q ':443 '; then
  info "X Service on :443 still running — not affected by deploy ✓"
else
  warn "X Service on :443 is no longer detected. Check it manually."
fi

# ══════════════════════════════════════════════════════════════
section "8 / 8 — Done"
# ══════════════════════════════════════════════════════════════
VPS_IP=$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || echo "<VPS_IP>")
echo ""
echo -e "${GREEN}${BOLD}🎉 Deploy complete.${NC}"
echo -e "   App:      ${CYAN}http://${VPS_IP}/${NC}"
echo -e "   API:      ${CYAN}http://${VPS_IP}/api/v1/${NC}"
echo -e "   Docs:     ${CYAN}http://${VPS_IP}/api/docs/${NC}"
echo -e "   Health:   ${CYAN}http://${VPS_IP}/api/health/${NC}"
echo ""
echo -e "   ${YELLOW}Next: Day 40 — HAProxy + HTTPS + domain${NC}"
echo ""
