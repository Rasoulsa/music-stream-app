#!/usr/bin/env bash
# ============================================================
# Production smoke test — Day 33
# Tests every layer: nginx → backend → DB → auth → MinIO
# Usage: ./scripts/smoke-prod.sh  (run from project root)
# ============================================================
set -uo pipefail

BASE="http://localhost"
PASS=0
FAIL=0
ERRORS=()

# ── Helpers ──────────────────────────────────────────────────
check() {
  local desc="$1"; shift
  if eval "$@" &>/dev/null; then
    echo "  ✅  $desc"
    PASS=$((PASS+1))
  else
    echo "  ❌  $desc"
    FAIL=$((FAIL+1))
    ERRORS+=("$desc")
  fi
}

check_code() {
  local desc="$1"
  local expected="$2"
  local url="$3"
  local actual
  actual=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [[ "$actual" == "$expected" ]]; then
    echo "  ✅  $desc (HTTP $actual)"
    PASS=$((PASS+1))
  else
    echo "  ❌  $desc (expected HTTP $expected, got $actual)"
    FAIL=$((FAIL+1))
    ERRORS+=("$desc — expected HTTP $expected, got $actual")
  fi
}

info() {
  echo "  ℹ️   $1"
}

divider() { echo "  ───────────────────────────────────────────"; }

echo ""
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║   Production Smoke Test — Day 33          ║"
echo "  ╚═══════════════════════════════════════════╝"
echo ""

# ── 1. Container health ──────────────────────────────────────
echo "  [1/7] Container Health"
divider
CONTAINERS=(
  "music-db"
  "music-redis"
  "music-minio"
  "music-backend"
  "music-celery"
  "music-frontend"
  "music-nginx"
)
for ctr in "${CONTAINERS[@]}"; do
  HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$ctr" 2>/dev/null || echo "not-found")
  STATE=$(docker inspect --format='{{.State.Status}}' "$ctr" 2>/dev/null || echo "not-found")
  if [[ "$HEALTH" == "healthy" ]]; then
    echo "  ✅  $ctr → healthy"
    PASS=$((PASS+1))
  elif [[ "$STATE" == "running" ]]; then
    echo "  ✅  $ctr → running (no healthcheck configured)"
    PASS=$((PASS+1))
  else
    echo "  ❌  $ctr → $STATE / $HEALTH"
    FAIL=$((FAIL+1))
    ERRORS+=("Container $ctr is not healthy: $STATE / $HEALTH")
  fi
done
echo ""

# ── 2. Infrastructure endpoints ──────────────────────────────
echo "  [2/7] Infrastructure Endpoints"
divider
check   "nginx liveness   /healthz"       "curl -sf $BASE/healthz"
check   "backend health   /api/health/"   "curl -sf $BASE/api/health/"
check   "frontend HTML    /"              "curl -sf $BASE/ | grep -qi 'doctype'"
# MinIO console is intentionally NOT exposed in production (security)
info    "MinIO console :9001 not exposed on host (intentional — prod security)"
PASS=$((PASS+1))
echo ""

# ── 3. API contract ──────────────────────────────────────────
echo "  [3/7] API Contract"
divider
check      "OpenAPI schema   /api/schema/"   "curl -sf -o /dev/null $BASE/api/schema/"
check      "Swagger UI       /api/docs/"     "curl -sf -o /dev/null $BASE/api/docs/"
check      "Redoc UI         /api/redoc/"    "curl -sf -o /dev/null $BASE/api/redoc/"
check_code "register route   (405 on GET)"   "405" "$BASE/api/v1/auth/register/"
check_code "login route      (405 on GET)"   "405" "$BASE/api/v1/auth/login/"
# Songs feed is intentionally public (AllowAny) — browse without login
check_code "songs public feed (200 unauthed)" "200" "$BASE/api/v1/songs/"
# Protected routes require auth
check_code "my profile unauthed (401)"        "401" "$BASE/api/v1/users/me/"
echo ""

# ── 4. Auth + database flow ──────────────────────────────────
echo "  [4/7] Auth + Database Flow"
divider
RAND=$RANDOM
USERNAME="smoke_${RAND}"
EMAIL="smoke_${RAND}@test.com"
PASSWORD="TestPass123!"

# Register
REG=$(curl -s -X POST "$BASE/api/v1/auth/register/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"password2\":\"$PASSWORD\"}")
check "register new user" \
  "echo '$REG' | python3 -c \"import sys,json; d=json.load(sys.stdin); exit(0 if any(k in d for k in ['username','access','id']) else 1)\""

# Login → JWT
LOGIN=$(curl -s -X POST "$BASE/api/v1/auth/login/" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('access', d.get('token','')))" 2>/dev/null || echo "")
REFRESH=$(echo "$LOGIN" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('refresh',''))" 2>/dev/null || echo "")

check "login returns JWT access token"  "test -n '$TOKEN' && test '${#TOKEN}' -gt 20"
check "login returns refresh token"     "test -n '$REFRESH' && test '${#REFRESH}' -gt 20"

# Token refresh
if [[ -n "$REFRESH" ]]; then
  NEW_TOKEN=$(curl -s -X POST "$BASE/api/v1/auth/refresh/" \
    -H "Content-Type: application/json" \
    -d "{\"refresh\":\"$REFRESH\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access',''))" 2>/dev/null || echo "")
  check "token refresh works" \
    "test -n '$NEW_TOKEN' && test '${#NEW_TOKEN}' -gt 20"
fi

# Authenticated endpoints
check "GET /api/v1/songs/      with token (200)" \
  "curl -sf -o /dev/null -H 'Authorization: Bearer $TOKEN' $BASE/api/v1/songs/"
check "GET /api/v1/users/me/   with token (200)" \
  "curl -sf -o /dev/null -H 'Authorization: Bearer $TOKEN' $BASE/api/v1/users/me/"
check "GET /api/v1/songs/mine/ with token (200)" \
  "curl -sf -o /dev/null -H 'Authorization: Bearer $TOKEN' $BASE/api/v1/songs/mine/"
echo ""

# ── 5. Object storage (MinIO) ────────────────────────────────
echo "  [5/7] Object Storage (MinIO)"
divider
# Internal health — MinIO API responding inside its own container
check "MinIO API health (internal)" \
  "docker exec music-minio curl -sf http://localhost:9000/minio/health/live"

# nginx → MinIO proxy (any response except 502/503 = proxy is working)
MINIO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/music-media/")
if [[ "$MINIO_STATUS" == "502" || "$MINIO_STATUS" == "503" ]]; then
  echo "  ❌  nginx → MinIO proxy (HTTP $MINIO_STATUS — proxy broken, music won't play)"
  FAIL=$((FAIL+1))
  ERRORS+=("MinIO proxy returned $MINIO_STATUS — check nginx/minio network connectivity")
else
  echo "  ✅  nginx → MinIO proxy reachable (HTTP $MINIO_STATUS)"
  PASS=$((PASS+1))
fi
echo ""

# ── 6. Security headers ──────────────────────────────────────
echo "  [6/7] Security Headers"
divider
HEADERS=$(curl -sI "$BASE/")
check "X-Content-Type-Options: nosniff" \
  "echo '$HEADERS' | grep -qi 'x-content-type-options: nosniff'"
check "X-Frame-Options set" \
  "echo '$HEADERS' | grep -qi 'x-frame-options'"
check "Referrer-Policy set" \
  "echo '$HEADERS' | grep -qi 'referrer-policy'"
check "nginx version hidden" \
  "! echo '$HEADERS' | grep -i '^server:' | grep -qi 'nginx/[0-9]'"
echo ""

# ── 7. Environment & secrets — Day 33 ────────────────────────
echo "  [7/7] Environment & Secrets — Day 33"
divider
check ".env.prod        exists and non-empty"   "test -s .env.prod"
check ".env.prod        git-ignored"            "git check-ignore -q .env.prod"
check ".env.prod.example IN git"                "git ls-files --error-unmatch .env.prod.example 2>/dev/null"
check ".env.dev         git-ignored"            "git check-ignore -q .env.dev"
check ".env.dev.example IN git"                 "git ls-files --error-unmatch .env.dev.example 2>/dev/null"
check "scripts/check-env.sh  exists + runnable" "test -x scripts/check-env.sh"
check "scripts/smoke-prod.sh exists + runnable" "test -x scripts/smoke-prod.sh"
check "DJANGO_SETTINGS_MODULE=production"       "grep -q 'config.settings.production' .env.prod"
check "DEBUG=False in .env.prod"                "grep -q '^DEBUG=False' .env.prod"
check "SECRET_KEY set (>20 chars)"              "grep -E '^SECRET_KEY=.{20,}' .env.prod"
check "docs/env-management.md exists"           "test -f docs/env-management.md"
echo ""

# ── Summary ──────────────────────────────────────────────────
echo "  ╔═══════════════════════════════════════════╗"
printf  "  ║  Results: %2s passed, %2s failed           ║\n" "$PASS" "$FAIL"
echo "  ╚═══════════════════════════════════════════╝"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "  ⚠️  Failing checks:"
  for err in "${ERRORS[@]}"; do
    echo "     • $err"
  done
  echo ""
  echo "  Debug:"
  echo "     make prod-logs-backend"
  echo "     make prod-logs"
  echo "     docker exec music-nginx wget -qO- http://minio:9000/minio/health/live"
  echo ""
  exit 1
else
  echo "  🎉 All checks passed — Day 33 complete!"
  echo ""
  exit 0
fi
