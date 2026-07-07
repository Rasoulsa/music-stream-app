#!/usr/bin/env bash
# ============================================================
# Prepare VPS host for HTTPS deployment.
#
# This script is intended to run ON THE VPS.
#
# It performs host-level setup:
#   - installs certbot
#   - creates Let's Encrypt and ACME webroot directories
#   - installs a renewal deploy hook to restart app nginx after cert renewal
#
# It is idempotent and safe to run multiple times.
#
# Usage:
#   ./scripts/vps-prepare-https.sh
#
# Optional:
#   APP_DIR=/opt/music-stream-app ./scripts/vps-prepare-https.sh
# ============================================================

set -Eeuo pipefail

if [[ -f "docker-compose.yml" ]]; then
  APP_DIR="${APP_DIR:-$(pwd)}"
else
  APP_DIR="${APP_DIR:-/opt/music-stream-app}"
fi

ENV_FILE="${ENV_FILE:-${APP_DIR}/.env.prod}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-music-stream-app}"

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "==> Preparing VPS HTTPS prerequisites"
echo "    APP_DIR=${APP_DIR}"
echo "    ENV_FILE=${ENV_FILE}"
echo ""

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: This script currently supports Debian/Ubuntu systems with apt-get." >&2
  exit 1
fi

echo "==> Installing certbot if missing"
if ! command -v certbot >/dev/null 2>&1; then
  ${SUDO} apt-get update
  DEBIAN_FRONTEND=noninteractive ${SUDO} apt-get install -y certbot
else
  echo "    certbot already installed: $(certbot --version)"
fi

echo ""
echo "==> Creating required host directories"
${SUDO} install -d -o root -g root -m 755 /etc/letsencrypt
${SUDO} install -d -o root -g root -m 755 /var/www/certbot

echo ""
echo "==> Installing certbot renewal deploy hook"

sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
HOOK_PATH="/etc/letsencrypt/renewal-hooks/deploy/reload-music-stream-nginx.sh"

${SUDO} tee "${HOOK_PATH}" >/dev/null <<HOOK
#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR}"

if [[ ! -d "\${APP_DIR}" ]]; then
  echo "Music Stream App directory not found: \${APP_DIR}" >&2
  exit 0
fi

cd "\${APP_DIR}"

if [[ ! -f ".env.prod" ]]; then
  echo ".env.prod not found in \${APP_DIR}; skipping nginx reload" >&2
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found; skipping nginx reload" >&2
  exit 0
fi

docker compose \\
  --project-name "$COMPOSE_PROJECT_NAME" \\
  --env-file .env.prod \\
  -f docker-compose.yml \\
  -f docker-compose.prod.yml \\
  -f docker-compose.vps.yml \\
  restart nginx
HOOK

${SUDO} chmod +x "${HOOK_PATH}"

echo ""
echo "==> Checking certbot timer"
if systemctl list-timers --all 2>/dev/null | grep -q certbot; then
  systemctl list-timers --all | grep certbot || true
else
  echo "    Certbot timer not listed. This can be normal depending on package setup."
fi

echo ""
echo "==> HTTPS host preparation complete"
echo ""
echo "Next steps:"
echo "  1. Ensure DNS points APP_DOMAIN to this VPS"
echo "  2. Ensure .env.prod contains APP_DOMAIN and ACME_EMAIL"
echo "  3. Run:"
echo "       ./scripts/vps-issue-cert-standalone.sh"
echo "  4. Then start the HTTPS overlay:"
echo "       make vps-up"
echo ""
