#!/usr/bin/env bash
# ============================================================
# Validate an env file before deploying.
# Compatible with bash 3.x (macOS default shell).
#
# Usage:
#   ./scripts/check-env.sh
#   ./scripts/check-env.sh .env.prod
#   ./scripts/check-env.sh .env.prod --with-monitoring
#
# Exit codes:
#   0 = valid, safe to deploy
#   1 = missing file OR one or more validation failures
#
# Monitoring:
#   Grafana credentials are required only when --with-monitoring is passed.
# ============================================================

ENV_FILE=".env.prod"
WITH_MONITORING=false
FAIL=0

# ── Args ─────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --with-monitoring)
            WITH_MONITORING=true
            ;;
        *)
            ENV_FILE="$arg"
            ;;
    esac
done

if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌  $ENV_FILE not found."
    echo "    Run: cp .env.prod.example .env.prod"
    exit 1
fi

echo ""
echo "🔍  Checking $ENV_FILE ..."

if [[ "$WITH_MONITORING" == true ]]; then
    echo "📈  Monitoring validation: enabled"
else
    echo "📈  Monitoring validation: disabled"
fi

echo ""

# Load vars without polluting the current shell permanently.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

# ── Required vars ─────────────────────────────────────────────
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

# ── Safety rules ──────────────────────────────────────────────
DEBUG_VAL="${DEBUG:-}"
SECRET_KEY_VAL="${DJANGO_SECRET_KEY:-}"
ALLOWED_HOSTS_VAL="${DJANGO_ALLOWED_HOSTS:-}"

# bash 3.x compatible lowercase.
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

# Check for suspicious substrings.
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

# ── Optional monitoring validation ────────────────────────────
GRAFANA_USER_VAL="${GRAFANA_ADMIN_USER:-}"
GRAFANA_PASSWORD_VAL="${GRAFANA_ADMIN_PASSWORD:-}"
GRAFANA_PASSWORD_LOWER=$(echo "$GRAFANA_PASSWORD_VAL" | tr '[:upper:]' '[:lower:]')

if [[ "$WITH_MONITORING" == true ]]; then
    if [[ -z "$GRAFANA_USER_VAL" ]]; then
        echo "❌  GRAFANA_ADMIN_USER is empty or missing"
        FAIL=1
    fi

    if [[ -z "$GRAFANA_PASSWORD_VAL" ]]; then
        echo "❌  GRAFANA_ADMIN_PASSWORD is empty or missing"
        FAIL=1
    fi

    if [[ "$GRAFANA_PASSWORD_VAL" == CHANGE_ME* ]]; then
        echo "❌  GRAFANA_ADMIN_PASSWORD still has a placeholder value"
        FAIL=1
    fi

    for substring in "change_me" "changeme" "change-me" "placeholder"; do
        if echo "$GRAFANA_PASSWORD_LOWER" | grep -q "$substring"; then
            echo "❌  GRAFANA_ADMIN_PASSWORD contains suspicious substring: '$substring'"
            FAIL=1
            break
        fi
    done

    if [[ ${#GRAFANA_PASSWORD_VAL} -lt 16 ]]; then
        echo "❌  GRAFANA_ADMIN_PASSWORD is too short (${#GRAFANA_PASSWORD_VAL} chars, min 16)"
        FAIL=1
    fi
else
    if [[ -z "$GRAFANA_USER_VAL" || -z "$GRAFANA_PASSWORD_VAL" ]]; then
        echo "⚠️   Grafana credentials not fully set. This is OK for app-only deploys."
        echo "    Set GRAFANA_ADMIN_USER and GRAFANA_ADMIN_PASSWORD before using --with-monitoring."
    elif [[ "$GRAFANA_PASSWORD_VAL" == "change-me" || "$GRAFANA_PASSWORD_VAL" == CHANGE_ME* ]]; then
        echo "⚠️   GRAFANA_ADMIN_PASSWORD looks like a placeholder."
        echo "    This is OK for app-only deploys, but --with-monitoring will fail."
    fi
fi

# ── Result ────────────────────────────────────────────────────
echo ""
if [[ "$FAIL" -eq 0 ]]; then
    echo "✅  $ENV_FILE is valid for this deployment mode."
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
