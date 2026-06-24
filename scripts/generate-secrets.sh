#!/usr/bin/env bash
# ============================================================
# Generate strong secrets for .env.prod.
# Prints values — does NOT write to files automatically.
#
# Usage:
#   ./scripts/generate-secrets.sh
#   ./scripts/generate-secrets.sh >> .env.prod   (append mode)
# ============================================================
set -euo pipefail

echo ""
echo "🔐  Generated secrets — paste into .env.prod"
echo "══════════════════════════════════════════════"

DJANGO_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
POSTGRES_PASSWORD=$(python3 -c "import secrets; print(secrets.token_hex(16))")
AWS_ACCESS_KEY_ID=$(python3 -c "import secrets; print(secrets.token_hex(10))")
AWS_SECRET_ACCESS_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")

echo "DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"

echo "══════════════════════════════════════════════"
echo ""
echo "⚠️  MinIO root user  = AWS_ACCESS_KEY_ID"
echo "⚠️  MinIO root pass  = AWS_SECRET_ACCESS_KEY"
echo "    Both must match in .env.prod"
echo ""
echo "⚠️  Rotate these immediately if they ever leak."
echo "    git history is permanent — never commit .env.prod"
echo ""
