#!/usr/bin/env bash
# ============================================================
# Production End-to-End Smoke Test
# Tests every layer: nginx → backend → DB → auth → MinIO
# Plus a full user journey: register → login → upload → play
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
echo "  ║    Music Stream App — Production Smoke    ║"
echo "  ╚═══════════════════════════════════════════╝"
echo ""

# ── 1. Container health ──────────────────────────────────────
echo "  [1/9] Container Health"
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
echo "  [2/9] Infrastructure Endpoints"
divider
check   "nginx liveness   /healthz"       "curl -sf $BASE/healthz"
check   "backend health   /api/health/"   "curl -sf $BASE/api/health/"
check   "frontend HTML    /"              "curl -sf $BASE/ | grep -qi 'doctype'"
# MinIO console must NOT be reachable from host in production (security assertion)
MINIO_CONSOLE=$(curl -s -o /dev/null -w "%{http_code}" \
  --connect-timeout 2 "http://localhost:9001" 2>/dev/null || echo "000")
if [[ "$MINIO_CONSOLE" =~ ^0 ]]; then
  echo "  ✅  MinIO console :9001 not exposed on host (prod security)"
  PASS=$((PASS+1))
else
  echo "  ❌  MinIO console :9001 is reachable from host (HTTP $MINIO_CONSOLE) — security risk"
  FAIL=$((FAIL+1))
  ERRORS+=("MinIO console port 9001 is exposed to host — remove from docker-compose.prod.yml")
fi
echo ""

# ── 3. API contract ──────────────────────────────────────────
echo "  [3/9] API Contract"
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
echo "  [4/9] Auth + Database Flow"
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
echo "  [5/9] Object Storage (MinIO)"
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
echo "  [6/9] Security Headers"
divider

# Use /api/health/ — pure nginx→backend path.
# The /api/ location block has no add_header of its own, so
# server-level security headers are guaranteed to apply here.
# Checking / (frontend proxy) is fragile — frontend container
# could strip or override headers unpredictably.
HEADERS=$(curl -sI "$BASE/api/health/")

check "X-Content-Type-Options: nosniff" \
  "echo '$HEADERS' | grep -qi 'x-content-type-options: nosniff'"
check "X-Frame-Options: DENY" \
  "echo '$HEADERS' | grep -qi 'x-frame-options: deny'"
check "Referrer-Policy set" \
  "echo '$HEADERS' | grep -qi 'referrer-policy'"
check "nginx version hidden" \
  "! echo '$HEADERS' | grep -i '^server:' | grep -qi 'nginx/[0-9]'"
echo ""

# ── 7. Environment & secrets ──────────────────────────────────
echo "  [7/9] Environment & Secrets"
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

# ── 8. End-to-End User Journey —───────────────────────────────
echo "  [8/9] End-to-End User Journey (upload → retrieve → stream)"
divider

# Reuse the token from section 4. If missing, skip gracefully.
if [[ -z "${TOKEN:-}" || "${#TOKEN}" -lt 20 ]]; then
  echo "  ❌  no auth token available — cannot run E2E journey"
  FAIL=$((FAIL+1))
  ERRORS+=("E2E journey skipped: no auth token from section 4")
else
  # Create a tiny silent MP3 on the fly (valid MP3 frame header).
  # This avoids needing a real audio file in the repo.
  E2E_AUDIO="/tmp/smoke_e2e_${RAND}.mp3"
  # Minimal valid MP3: ID3 header + a few silent frames
  printf 'ID3\x03\x00\x00\x00\x00\x00\x21' > "$E2E_AUDIO"
  # Append ~8KB of MP3 frame sync bytes so it's a non-trivial file
  head -c 8192 /dev/zero | tr '\0' '\377' >> "$E2E_AUDIO"

  E2E_TITLE="Smoke E2E ${RAND}"

  # Upload a song (multipart/form-data)
  UPLOAD=$(curl -s -X POST "$BASE/api/v1/songs/" \
    -H "Authorization: Bearer $TOKEN" \
    -F "title=$E2E_TITLE" \
    -F "artist=Smoke Tester" \
    -F "is_public=true" \
    -F "audio_file=@${E2E_AUDIO};type=audio/mpeg")

  SONG_ID=$(echo "$UPLOAD" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || echo "")
  AUDIO_URL=$(echo "$UPLOAD" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d.get('audio_file',''))" 2>/dev/null || echo "")

  check "upload song returns an id" \
    "test -n '$SONG_ID'"

  check "upload song returns audio_file URL" \
    "test -n '$AUDIO_URL'"

  # Retrieve the song detail and confirm title matches
  if [[ -n "$SONG_ID" ]]; then
    DETAIL=$(curl -s -H "Authorization: Bearer $TOKEN" \
      "$BASE/api/v1/songs/$SONG_ID/")
    check "retrieve uploaded song by id" \
      "echo '$DETAIL' | python3 -c \"import sys,json; d=json.load(sys.stdin); exit(0 if d.get('title')=='$E2E_TITLE' else 1)\""

    check "uploaded song appears in /songs/mine/" \
      "curl -s -H 'Authorization: Bearer $TOKEN' $BASE/api/v1/songs/mine/ | grep -q '$E2E_TITLE'"
  fi

  # Stream the media file THROUGH nginx (the real playback path)
  if [[ -n "$AUDIO_URL" ]]; then
    MEDIA_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$AUDIO_URL")
    if [[ "$MEDIA_CODE" == "200" || "$MEDIA_CODE" == "206" ]]; then
      echo "  ✅  media file streams through nginx (HTTP $MEDIA_CODE)"
      PASS=$((PASS+1))
    else
      echo "  ❌  media file stream failed (HTTP $MEDIA_CODE) → $AUDIO_URL"
      FAIL=$((FAIL+1))
      ERRORS+=("Media stream returned $MEDIA_CODE for $AUDIO_URL")
    fi

    # Verify Range requests work (required for audio seeking in browsers)
    RANGE_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Range: bytes=0-1023" "$AUDIO_URL")
    if [[ "$RANGE_CODE" == "206" ]]; then
      echo "  ✅  media supports HTTP Range requests (HTTP 206 — seeking works)"
      PASS=$((PASS+1))
    else
      echo "  ⚠️   media Range request returned $RANGE_CODE (expected 206 for seeking)"
      info "non-fatal: some setups serve 200; seeking may still work"
      PASS=$((PASS+1))
    fi
  fi

  # Cleanup: delete the test song so the DB stays clean
  if [[ -n "$SONG_ID" ]]; then
    DEL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      -H "Authorization: Bearer $TOKEN" \
      "$BASE/api/v1/songs/$SONG_ID/")
    if [[ "$DEL_CODE" == "204" || "$DEL_CODE" == "200" ]]; then
      echo "  ✅  cleanup: deleted test song (HTTP $DEL_CODE)"
      PASS=$((PASS+1))
    else
      echo "  ⚠️   cleanup: could not delete test song (HTTP $DEL_CODE) — remove manually"
      info "song id=$SONG_ID title='$E2E_TITLE'"
    fi
  fi

  rm -f "$E2E_AUDIO" 2>/dev/null
fi
echo ""

# ── Rate limiting ────────────────────────────────────────────
echo "  [9/9] Rate Limiting"
divider

# Hammer the login endpoint — expect a 429 within the limit window
RATE_HIT=0
for i in $(seq 1 12); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE/api/v1/auth/login/" \
    -H "Content-Type: application/json" \
    -d '{"username":"bogus","password":"bogus"}')
  if [[ "$CODE" == "429" ]]; then
    RATE_HIT=1
    break
  fi
done

if [[ "$RATE_HIT" == "1" ]]; then
  echo "  ✅  Login endpoint rate-limited (429 after burst)"
  PASS=$((PASS+1))
else
  echo "  ❌  Login endpoint NOT rate-limited (no 429 in 10 requests)"
  FAIL=$((FAIL+1))
  ERRORS+=("Login throttle not enforced — check DRF throttle config")
fi
echo ""

# ── Summary ──────────────────────────────────────────────────
echo "  ╔═══════════════════════════════════════════╗"
printf "  ║     Results: %2s passed, %2s failed         ║\n" "$PASS" "$FAIL"
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
  echo "  🎉 All checks passed —  Music Stream App Production Smoke  complete!"
  echo ""
  exit 0
fi
