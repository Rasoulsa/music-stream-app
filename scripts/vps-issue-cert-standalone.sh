#!/usr/bin/env bash
# ============================================================
# Issue the initial Let's Encrypt certificate on the VPS.
#
# This uses certbot standalone mode for the first certificate.
# It temporarily requires host port 80 to be free.
#
# Intended flow:
#   1. ./scripts/vps-prepare-https.sh
#   2. ./scripts/vps-issue-cert-standalone.sh
#   3. make vps-up
#   4. configure/reload HAProxy SNI route
#
# Usage:
#   ./scripts/vps-issue-cert-standalone.sh
#
# Optional:
#   APP_DIR=/opt/music-stream-app ./scripts/vps-issue-cert-standalone.sh
# ============================================================

set -Eeuo pipefail

if [[ -f "docker-compose.yml" ]]; then
  APP_DIR="${APP_DIR:-$(pwd)}"
else
  APP_DIR="${APP_DIR:-/opt/music-stream-app}"
fi

ENV_FILE="${ENV_FILE:-${APP_DIR}/.env.prod}"

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

get_env_value() {
  local key="$1"
  if [[ ! -f "${ENV_FILE}" ]]; then
    return 1
  fi

  grep -E "^${key}=" "${ENV_FILE}" | tail -n1 | cut -d '=' -f2- | sed 's/^"//;s/"$//'
}

APP_DOMAIN="${APP_DOMAIN:-$(get_env_value APP_DOMAIN || true)}"
ACME_EMAIL="${ACME_EMAIL:-$(get_env_value ACME_EMAIL || true)}"

if [[ -z "${APP_DOMAIN}" ]]; then
  echo "ERROR: APP_DOMAIN is missing." >&2
  echo "Set APP_DOMAIN in ${ENV_FILE}, for example:" >&2
  echo "  APP_DOMAIN=music.example.com" >&2
  exit 1
fi

if [[ -z "${ACME_EMAIL}" ]]; then
  echo "ERROR: ACME_EMAIL is missing." >&2
  echo "Set ACME_EMAIL in ${ENV_FILE}, for example:" >&2
  echo "  ACME_EMAIL=you@example.com" >&2
  exit 1
fi

if ! command -v certbot >/dev/null 2>&1; then
  echo "ERROR: certbot is not installed." >&2
  echo "Run first:" >&2
  echo "  ./scripts/vps-prepare-https.sh" >&2
  exit 1
fi

echo "==> Issuing Let's Encrypt certificate"
echo "    Domain: ${APP_DOMAIN}"
echo "    Email:  ${ACME_EMAIL}"
echo ""

if [[ -d "${APP_DIR}" ]]; then
  cd "${APP_DIR}"

  echo "==> Stopping app nginx if it is running, to free port 80"
  docker compose \
    --project-name music-stream-prod \
    --env-file .env.prod \
    -f docker-compose.yml \
    -f docker-compose.prod.yml \
    -f docker-compose.vps.yml \
    stop nginx >/dev/null 2>&1 || true
fi

echo ""
echo "==> Checking port 80"
if ss -ltn | awk '{print $4}' | grep -qE '(^|:)80$'; then
  echo "ERROR: Port 80 is still in use." >&2
  echo "Find the process with:" >&2
  echo "  sudo ss -ltnp | grep ':80'" >&2
  echo "" >&2
  echo "Certbot standalone needs port 80 temporarily." >&2
  exit 1
fi

echo ""
echo "==> Running certbot standalone"
${SUDO} certbot certonly --standalone \
  --preferred-challenges http \
  -d "${APP_DOMAIN}" \
  --agree-tos \
  -m "${ACME_EMAIL}" \
  --non-interactive

echo ""
echo "==> Certificate issued successfully"
echo ""
echo "Certificate files:"
echo "  /etc/letsencrypt/live/${APP_DOMAIN}/fullchain.pem"
echo "  /etc/letsencrypt/live/${APP_DOMAIN}/privkey.pem"
echo ""
echo "Next:"
echo "  make vps-up"
echo ""
