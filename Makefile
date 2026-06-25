# =============================================================================
# Music Stream App — Makefile
# =============================================================================
#
# Usage:
#   make dev-up          Build and start dev stack (foreground)
#   make dev-up-d        Build and start dev stack (detached/background)
#   make dev-down        Stop dev stack
#   make dev-logs        Follow dev logs
#   make dev-shell       Open bash shell in backend container (dev)
#   make dev-test        Run pytest in backend container (dev)
#   make dev-test-cov    Run pytest with coverage (dev)
#   make dev-migrate     Run migrations (dev)
#   make dev-createsuperuser   Create Django superuser (dev)
#
#   make prod-up         Build and start prod stack (detached/background)
#   make prod-down       Stop prod stack
#   make prod-logs       Follow prod logs
#   make prod-ps         Show prod service status
#   make prod-shell      Open bash shell in backend container (prod)
#
#   make test-db-up      Start disposable local PostgreSQL test DB
#   make test-backend    Run backend pytest locally
#   make test-backend-cov Run backend pytest locally with coverage
#   make test-db-down    Stop disposable local PostgreSQL test DB
#
#   make test-backend-perf Run backend performance tests only
#
#   make secrets         Generate strong secrets for .env.prod
#   make check-env       Validate .env.prod before deploying
#
#   make smoke-prod      Run end-to-end smoke tests against prod stack
#   make prod-restart    Restart prod stack safely without deleting volumes
#   make clean           Stop dev stack + wipe ALL volumes (fresh start)
#   make clean-prod      Stop prod stack + wipe ALL volumes
#   make help            Show this help message
#
# =============================================================================

# -----------------------------------------------------------------------------
# Compose command aliases
# --env-file  → tells Compose which file to use for ${VAR} interpolation
# -f base     → shared services
# -f override → environment-specific settings
# -----------------------------------------------------------------------------
DEV  = docker compose --env-file .env.dev  -f docker-compose.yml -f docker-compose.dev.yml
PROD = docker compose --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml

# -----------------------------------------------------------------------------
# Default target — running just `make` shows help
# -----------------------------------------------------------------------------
.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Development
# -----------------------------------------------------------------------------
.PHONY: dev-up
dev-up:			## Build and start dev stack (foreground — Ctrl+C to stop)
	$(DEV) up --build

.PHONY: dev-up-d
dev-up-d:		## Build and start dev stack (detached/background)
	$(DEV) up --build -d --remove-orphans

.PHONY: dev-ps
dev-ps:			## Show status of all dev services
	$(DEV) ps

.PHONY: dev-down
dev-down:		## Stop dev stack (keeps volumes)
	$(DEV) down

.PHONY: dev-logs
dev-logs:		## Follow logs for all dev services
	$(DEV) logs -f

.PHONY: dev-logs-backend
dev-logs-backend:	## Follow logs for backend only (dev)
	$(DEV) logs -f backend

.PHONY: dev-logs-celery
dev-logs-celery:	## Follow logs for celery worker only (dev)
	$(DEV) logs -f celery_worker

.PHONY: dev-logs-frontend
dev-logs-frontend:	## Follow logs for frontend only (dev)
	$(DEV) logs -f frontend

.PHONY: dev-shell
dev-shell:		## Open bash shell inside backend container (dev)
	$(DEV) exec backend /bin/bash

.PHONY: dev-shell-db
dev-shell-db:		## Open psql shell inside db container (dev)
	$(DEV) exec db psql -U $${POSTGRES_USER} -d $${POSTGRES_DB}

.PHONY: dev-shell-frontend
dev-shell-frontend:	## Open shell inside frontend container (dev)
	$(DEV) exec frontend /bin/sh

.PHONY: dev-test
dev-test:		## Run pytest in backend container (dev)
	$(DEV) exec backend /app/.venv/bin/pytest -v

.PHONY: dev-test-cov
dev-test-cov:		## Run pytest with coverage report (dev)
	$(DEV) exec backend /app/.venv/bin/pytest -v --cov --cov-report=term-missing

.PHONY: dev-migrate
dev-migrate:		## Run Django migrations (dev)
	$(DEV) exec backend /app/.venv/bin/python manage.py migrate

.PHONY: dev-createsuperuser
dev-createsuperuser:	## Create Django superuser (dev)
	$(DEV) exec backend /app/.venv/bin/python manage.py createsuperuser

.PHONY: dev-collectstatic
dev-collectstatic:	## Run collectstatic (dev)
	$(DEV) exec backend /app/.venv/bin/python manage.py collectstatic --noinput

.PHONY: schema-freeze
schema-freeze:		## Regenerate & freeze the OpenAPI schema
	$(DEV) exec backend /app/.venv/bin/python manage.py spectacular \
		--file api/schema.yml --validate
	@echo "✅ Schema frozen to backend/api/schema.yml"

.PHONY: schema-check
schema-check:		## Verify live schema matches frozen schema
	$(DEV) exec backend /app/.venv/bin/python -m pytest \
		music/tests/test_api_contract.py -v

# -----------------------------------------------------------------------------
# Production
# -----------------------------------------------------------------------------
.PHONY: prod-up
prod-up: check-env	## Build and start prod stack (always detached)
	$(PROD) up --build -d --remove-orphans

.PHONY: prod-down
prod-down:		## Stop prod stack (keeps volumes)
	$(PROD) down

.PHONY: prod-logs
prod-logs:		## Follow logs for all prod services
	$(PROD) logs -f

.PHONY: prod-logs-backend
prod-logs-backend:	## Follow logs for backend only (prod)
	$(PROD) logs -f backend

.PHONY: prod-logs-celery
prod-logs-celery:	## Follow logs for celery worker only (prod)
	$(PROD) logs -f celery_worker

.PHONY: prod-logs-nginx
prod-logs-nginx:	## Follow logs for nginx only (prod)
	$(PROD) logs -f nginx

.PHONY: prod-logs-frontend
prod-logs-frontend:	## Follow logs for frontend only (prod)
	$(PROD) logs -f frontend

.PHONY: prod-ps
prod-ps:		## Show status of all prod services
	$(PROD) ps

.PHONY: prod-shell
prod-shell:		## Open bash shell inside backend container (prod)
	$(PROD) exec backend /bin/bash

.PHONY: prod-shell-frontend
prod-shell-frontend:	## Open shell inside frontend container (prod)
	$(PROD) exec frontend /bin/sh

.PHONY: prod-shell-nginx
prod-shell-nginx:	## Open shell inside nginx container (prod)
	$(PROD) exec nginx /bin/sh

.PHONY: prod-migrate
prod-migrate:		## Run Django migrations (prod)
	$(PROD) exec backend /app/.venv/bin/python manage.py migrate

.PHONY: prod-createsuperuser
prod-createsuperuser:	## Create Django superuser (prod)
	$(PROD) exec backend /app/.venv/bin/python manage.py createsuperuser

.PHONY: prod-collectstatic
prod-collectstatic:	## Run collectstatic manually (prod)
	$(PROD) exec backend /app/.venv/bin/python manage.py collectstatic --noinput

.PHONY: prod-check
prod-check:		## Run Django system checks in prod container
	$(PROD) exec backend /app/.venv/bin/python manage.py check --deploy

# -----------------------------------------------------------------------------
# Secrets & environment
# -----------------------------------------------------------------------------
.PHONY: secrets
secrets:		## Generate strong secrets — paste output into .env.prod
	@./scripts/generate-secrets.sh

.PHONY: check-env
check-env:		## Validate .env.prod before deploying
	@./scripts/check-env.sh

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
.PHONY: clean
clean:			## Stop dev stack and wipe ALL volumes (full fresh start)
	$(DEV) down -v --remove-orphans

.PHONY: clean-prod
clean-prod:		## DANGER: Stop prod stack and DELETE prod database/media volumes
	@echo "⚠️  WARNING: This will DELETE production database/media volumes."
	@echo "⚠️  Users, songs, uploaded files, and MinIO data may be removed."
	@read -p "Type 'delete-prod-data' to continue: " confirm; \
	if [ "$$confirm" = "delete-prod-data" ]; then \
		$(PROD) down -v --remove-orphans; \
	else \
		echo "Aborted."; \
	fi

# -----------------------------------------------------------------------------
# Help — auto-generated from ## comments above
# -----------------------------------------------------------------------------
.PHONY: help
help:			## Show all available make commands
	@echo ""
	@echo "Music Stream App — available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36mmake %-26s\033[0m %s\n", $$1, $$2}'
	@echo ""

# -----------------------------------------------------------------------------
# Local backend tests
# -----------------------------------------------------------------------------
.PHONY: test-db-up
test-db-up:		## Start disposable local PostgreSQL test DB on localhost:5433
	docker rm -f music-test-db 2>/dev/null || true
	docker run -d \
		--name music-test-db \
		-e POSTGRES_DB=musicdb \
		-e POSTGRES_USER=musicuser \
		-e POSTGRES_PASSWORD=musicuser123 \
		-p 5433:5432 \
		postgres:16-alpine
	@echo "Waiting for test database..."
	@until docker exec music-test-db pg_isready -U musicuser -d musicdb >/dev/null 2>&1; do \
		sleep 1; \
	done
	@echo "✅ Test database is ready on localhost:5433"

.PHONY: test-db-down
test-db-down:		## Stop and remove disposable local PostgreSQL test DB
	docker rm -f music-test-db 2>/dev/null || true

.PHONY: test-backend
test-backend:		## Run backend pytest locally against disposable test DB
	cd backend && \
	POSTGRES_HOST=localhost \
	POSTGRES_PORT=5433 \
	POSTGRES_DB=musicdb \
	POSTGRES_USER=musicuser \
	POSTGRES_PASSWORD=musicuser123 \
	uv run pytest -v --ds=config.settings.ci --no-cov --create-db

.PHONY: test-backend-cov
test-backend-cov:	## Run backend pytest with coverage locally against disposable test DB
	cd backend && \
	POSTGRES_HOST=localhost \
	POSTGRES_PORT=5433 \
	POSTGRES_DB=musicdb \
	POSTGRES_USER=musicuser \
	POSTGRES_PASSWORD=musicuser123 \
	uv run pytest -v --ds=config.settings.ci --cov-report=term-missing --create-db

.PHONY: test-backend-perf
test-backend-perf: ## Run backend performance tests only
	cd backend && \
	POSTGRES_HOST=localhost \
	POSTGRES_PORT=5433 \
	POSTGRES_DB=musicdb \
	POSTGRES_USER=musicuser \
	POSTGRES_PASSWORD=musicuser123 \
	uv run pytest music/tests/test_performance.py -v --ds=config.settings.ci --create-db --no-cov

.PHONY: prod-restart
prod-restart:		## Restart prod stack safely without deleting volumes
	$(PROD) down
	$(PROD) up --build -d --remove-orphans

.PHONY: smoke-prod
smoke-prod:		## Run end-to-end smoke test against running prod stack
	@./scripts/smoke-prod.sh
