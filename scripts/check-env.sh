#!/usr/bin/env bash
# ============================================================
# Validate an env file before deploying.
# Compatible with bash 3.x (macOS default shell).
#
# Usage:
#   ./scripts/check-env.sh              (checks .env.prod)
#   ./scripts/check-env.sh .env.staging (checks custom file)
#
# Exit codes (relied upon by CI — see .github/workflows/deploy.yml):
#   0 = valid, safe to deploy
#   1 = missing file OR one or more validation failures
# ============================================================

ENV_FILE="${1:-.env.prod}"
FAIL=0

if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌  $ENV_FILE not found."
    echo "    Run: cp .env.prod.example .env.prod"
    exit 1
fi

echo ""
echo "🔍  Checking $ENV_FILE ..."
echo ""

# Load vars without polluting the current shell permanently
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# ── Required vars ─────────────────────────────────────────────────────────────
REQUIRED=(
    DJANGO_SETTINGS_MODULE
    DJANGO_SECRET_KEY
    DEBUG
    DJANGO_ALLOWED_HOSTS
    POSTGRES_DB
    POSTGRES_USER
    POSTGRES_PASSWORD
    POSTGRES_HOST
    AWS_ACCESS_KEY_ID
    AWS_SECRET_ACCESS_KEY
    AWS_STORAGE_BUCKET_NAME
    REDIS_URL
    CELERY_BROKER_URL
    CELERY_RESULT_BACKEND
)

for var in "${REQUIRED[@]}"; do
    val="${!var:-}"
    if [[ -z "$val" ]]; then
        echo "❌  $var is empty or missing"
        FAIL=1
    elif [[ "$val" == CHANGE_ME* ]]; then
        echo "❌  $var still has a placeholder value"
        FAIL=1
    fi
done

# ── Safety rules ──────────────────────────────────────────────────────────────
DEBUG_VAL="${DEBUG:-}"
SECRET_KEY_VAL="${DJANGO_SECRET_KEY:-}"
ALLOWED_HOSTS_VAL="${DJANGO_ALLOWED_HOSTS:-}"

# bash 3.x compatible lowercase: use tr instead of ${VAR,,}
DEBUG_LOWER=$(echo "$DEBUG_VAL" | tr '[:upper:]' '[:lower:]')
SECRET_LOWER=$(echo "$SECRET_KEY_VAL" | tr '[:upper:]' '[:lower:]')

if [[ "$DEBUG_LOWER" == "true" ]]; then
    echo "❌  DEBUG=true — must be false in production"
    FAIL=1
fi

if [[ ${#SECRET_KEY_VAL} -lt 40 ]]; then
    echo "❌  DJANGO_SECRET_KEY is too short (${#SECRET_KEY_VAL} chars, min 40)"
    FAIL=1
fi

# Check for suspicious substrings (bash 3.x compatible)
#
# NOTE: DJANGO_SECRET_KEY is base64url-random (from
# secrets.token_urlsafe(64) in generate-secrets.sh), so there's a small
# (~0.02%) chance a genuinely strong random key coincidentally contains
# one of these substrings and gets flagged as a false positive. If that
# ever happens, just regenerate with ./scripts/generate-secrets.sh — this
# check has caught more real "insecure-dev-key"-style mistakes than it
# has ever false-flagged a random key, so it stays as-is.
for substring in "insecure" "change_me" "changeme" "change-me" "placeholder" "dev"; do
    if echo "$SECRET_LOWER" | grep -q "$substring"; then
        echo "❌  DJANGO_SECRET_KEY contains suspicious substring: '$substring'"
        FAIL=1
        break
    fi
done

if [[ "$ALLOWED_HOSTS_VAL" == *"*"* ]]; then
    echo "❌  DJANGO_ALLOWED_HOSTS contains '*' — not safe for production"
    FAIL=1
fi

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
if [[ "$FAIL" -eq 0 ]]; then
    echo "✅  $ENV_FILE is valid for production."
    echo ""
    exit 0
else
    echo "════════════════════════════════════════"
    echo "  Fix the issues above before deploying."
    echo "  Run: ./scripts/generate-secrets.sh"
    echo "════════════════════════════════════════"
    echo ""
    exit 1
fi
