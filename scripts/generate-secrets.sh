#!/usr/bin/env bash
# ============================================================
# Generate strong production secrets for .env.prod.
#
# Prints ONLY valid KEY=VALUE lines to stdout.
# Human-readable messages are printed to stderr.
#
# Usage:
#   ./scripts/generate-secrets.sh
#
# Copy/paste mode:
#   ./scripts/generate-secrets.sh
#
# Append mode:
#   ./scripts/generate-secrets.sh >> .env.prod
#
# SECURITY:
#   - This script does NOT commit or upload anything.
#   - .env.prod must stay gitignored.
#   - Rotate secrets immediately if they ever leak.
# ============================================================

set -euo pipefail

echo "" >&2
echo "🔐  Generated secrets — paste into .env.prod" >&2
echo "══════════════════════════════════════════════" >&2

DJANGO_SECRET_KEY="$(python3 -c "import secrets; print(secrets.token_urlsafe(64))")"
POSTGRES_PASSWORD="$(python3 -c "import secrets; print(secrets.token_hex(32))")"
AWS_ACCESS_KEY_ID="$(python3 -c "import secrets; print(secrets.token_hex(10))")"
AWS_SECRET_ACCESS_KEY="$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")"

cat <<VALUES
DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
VALUES

echo "══════════════════════════════════════════════" >&2
echo "" >&2
echo "⚠️  MinIO root user = AWS_ACCESS_KEY_ID" >&2
echo "⚠️  MinIO root pass = AWS_SECRET_ACCESS_KEY" >&2
echo "   Both must match in .env.prod and MinIO's first initialization." >&2
echo "" >&2
echo "⚠️  Rotate these immediately if they ever leak." >&2
echo "   git history is permanent — never commit .env.prod" >&2
echo "" >&2
