# Environment & Secrets Management

## Overview

This project uses environment-specific `.env` files for configuration.
Secret files are **never committed to git** — only `.example` templates are tracked.

## File Structure

music-stream-app/
├── .env.dev              # Local dev secrets      (git-ignored)
├── .env.dev.example      # Dev template           (committed ✅)
├── .env.prod             # Production secrets     (git-ignored)
├── .env.prod.example     # Production template    (committed ✅)
└── scripts/
├── check-env.sh      # Validates required vars before startup
└── smoke-prod.sh     # Post-deploy end-to-end smoke tests

clean

## Quickstart

### Development
```bash
cp .env.dev.example .env.dev
# Edit .env.dev with your local values
make dev-up
Production
bash
cp .env.prod.example .env.prod
# Generate a real SECRET_KEY:
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
# Set DEBUG=False, paste the key, then:
make prod-up
Required Variables
Variable	Description	Example
SECRET_KEY	Django secret key (50+ chars)	python3 -c "import secrets; print(secrets.token_urlsafe(50))"
DEBUG	Must be False in production	False
DJANGO_SETTINGS_MODULE	Django settings module	config.settings.production
DB_NAME	PostgreSQL database name	musicdb
DB_USER	PostgreSQL username	musicuser
DB_PASSWORD	PostgreSQL password	changeme
REDIS_URL	Redis connection string	redis://redis:6379/1
AWS_ACCESS_KEY_ID	MinIO/S3 access key	minioadmin
AWS_SECRET_ACCESS_KEY	MinIO/S3 secret key	minioadmin123
AWS_STORAGE_BUCKET_NAME	MinIO bucket name	music-media
Security Rules
Never commit .env.prod or .env.dev — they contain real secrets
Always commit .env.*.example — safe placeholder values only
Generate a unique SECRET_KEY per environment — never reuse
Rotate credentials immediately if accidentally exposed
Validate with ./scripts/check-env.sh before every deploy
Validation
bash
# Validate all required variables are set
./scripts/check-env.sh

# Run full production smoke test
./scripts/smoke-prod.sh
Adding a New Secret Variable
Add real value to .env.prod / .env.dev (not committed)
Add placeholder to .env.prod.example / .env.dev.example (committed)
Add to REQUIRED list in scripts/check-env.sh
Document in the table above
Rotating Secrets
bash
# 1. Generate new Django secret key
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# 2. Update .env.prod with new value

# 3. Restart backend to pick up new key
docker compose --env-file .env.prod \
  -f docker-compose.yml -f docker-compose.prod.yml \
  up -d --force-recreate backend celery_worker

# 4. Verify everything still works
./scripts/smoke-prod.sh
```

## MinIO security (production)

- Port 9000 (S3 API): internal only, never published to host.
  The frontend reaches media exclusively through nginx at `/music-media/`.
- Port 9001 (admin console): intentionally not exposed in production.
  Access it temporarily via a docker network port-forward when needed.
