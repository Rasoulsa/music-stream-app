# =============================================================================
# Music Stream App — Makefile
# =============================================================================
#
# Usage:
#   make dev-up          		Build and start dev stack (foreground)
#   make dev-up-d        		Build and start dev stack (detached/background)
#   make dev-down        		Stop dev stack
#   make dev-logs        		Follow dev logs
#   make dev-shell       		Open bash shell in backend container (dev)
#   make dev-test        		Run pytest in backend container (dev)
#   make dev-test-cov    		Run pytest with coverage (dev)
#   make dev-migrate     		Run migrations (dev)
#   make dev-createsuperuser    Create Django superuser (dev)
#
#   make prod-up         		Build and start prod stack (detached/background)
#   make prod-down       		Stop prod stack
#   make prod-logs       		Follow prod logs
#   make prod-ps         		Show prod service status
#   make prod-shell      		Open bash shell in backend container (prod)
#
#   make test-db-up      		Start disposable local PostgreSQL test DB
#   make test-backend    		Run backend pytest locally
#   make test-backend-cov 		Run backend pytest locally with coverage
#   make test-db-down    		Stop disposable local PostgreSQL test DB
#
#   make test-backend-perf 		Run backend performance tests only
#
#   make secrets         		Generate strong secrets for .env.prod
#   make check-env       		Validate .env.prod before deploying
#
#   make smoke-prod      		Run end-to-end smoke tests against prod stack
#   make prod-restart    		Restart prod stack safely without deleting volumes
#   make clean           		Stop dev stack + wipe dev project volumes
#   make clean-prod      		Stop prod stack + wipe prod project volumes
#   make help            		Show this help message
#
#   make vps-up          		[VPS] Build and start HTTPS stack
#   make vps-down        		[VPS] Stop HTTPS stack
#   make vps-restart     		[VPS] Restart HTTPS stack safely
#   make vps-logs        		[VPS] Follow all logs
#   make vps-nginx-test  		[VPS] Test nginx config syntax
#   make vps-nginx-verify 		[VPS] Verify APP_DOMAIN substitution in nginx
#   make vps-ps          		[VPS] Show service status
#
#	make vps-prepare-https  	[VPS] Install certbot, create HTTPS dirs, install renewal hook
# 	make vps-issue-cert VPS 	[VPS] Issue initial Let's Encrypt cert using standalone mode
#
#   make monitoring-up          [VPS] Start app + full monitoring stack
#   make monitoring-down        [VPS] Stop monitoring containers only
#   make monitoring-ps          [VPS] Show monitoring container status
#   make monitoring-logs        [VPS] Follow monitoring logs
#   make monitoring-reload      [VPS/local] Reload Prometheus config
#
#   make monitoring-up-local    [local] Start Prometheus + Grafana only
#   make monitoring-down-local  [local] Stop Prometheus + Grafana only
#   make monitoring-ps-local    [local] Show local monitoring status
#   make monitoring-logs-local  [local] Follow local monitoring logs
#
#   make backup              		Run full backup (db + media) with retention prune
#   make backup-db           		Backup database only
#   make backup-media        		Backup media files only
#   make backup-list         		List existing backups (newest first)
#
#   make restore-db FILE=<path>		Restore database from a backup file
#   make restore-media FILE=<path>	Restore media files from a backup file
#
#   make backups-install     		Install systemd daily backup timer (VPS only)
#   make backups-status      		Show backup timer status + recent logs
#
#   make backup-rsync        		Manually push backups to secondary host via rsync over SSH
#                            		(optional offsite — configure BACKUP_RSYNC_* in .env.prod)
#
# =============================================================================

# -----------------------------------------------------------------------------
# Compose command aliases
# --project-name → isolates dev/prod Compose projects
# --env-file     → tells Compose which file to use for ${VAR} interpolation
# -f base        → shared services
# -f override    → environment-specific settings
# -----------------------------------------------------------------------------
#
# Separate project names prevent dev/prod from accidentally sharing:
#   - Docker networks
#   - Compose-managed volumes
#   - generated container names, if container_name is not hardcoded
#
# NOTE:
#   This greatly reduces DB password/volume conflicts.
#   To run dev and prod-like stacks at the same time, Compose files must also:
#     1. avoid fixed container_name values
#     2. avoid duplicate host port bindings
# -----------------------------------------------------------------------------
DEV_PROJECT  ?= music-stream-dev
PROD_PROJECT ?= music-stream-app

DEV  = docker compose --project-name $(DEV_PROJECT)  --env-file .env.dev  -f docker-compose.yml -f docker-compose.dev.yml
PROD = docker compose --project-name $(PROD_PROJECT) --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml

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

.PHONY: dev-config
dev-config:		## Render final dev Compose config
	$(DEV) config

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

.PHONY: prod-config
prod-config:		## Render final prod Compose config
	$(PROD) config

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

.PHONY: prod-restart
prod-restart:		## Restart prod stack safely without deleting volumes
	$(PROD) down
	$(PROD) up --build -d --remove-orphans

.PHONY: smoke-prod
smoke-prod:		## Run end-to-end smoke test against running prod stack
	@COMPOSE_PROJECT_NAME=$(PROD_PROJECT) COMPOSE_ENV_FILE=.env.prod ./scripts/smoke-prod.sh

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
# Compose diagnostics
# -----------------------------------------------------------------------------
.PHONY: compose-ls
compose-ls:		## List Docker Compose projects
	docker compose ls

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
.PHONY: clean
clean:			## Stop dev stack and wipe dev project volumes
	$(DEV) down -v --remove-orphans

.PHONY: clean-prod
clean-prod:		## DANGER: Stop prod stack and DELETE prod project database/media volumes
	@echo "⚠️  WARNING: This will DELETE prod project database/media volumes."
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
test-backend-perf:	## Run backend performance tests only
	cd backend && \
	POSTGRES_HOST=localhost \
	POSTGRES_PORT=5433 \
	POSTGRES_DB=musicdb \
	POSTGRES_USER=musicuser \
	POSTGRES_PASSWORD=musicuser123 \
	uv run pytest music/tests/test_performance.py -v --ds=config.settings.ci --create-db --no-cov

# -----------------------------------------------------------------------------
# VPS (HTTPS production override)
# Used on the VPS only. Requires APP_DOMAIN and cert mounts.
# Not intended for local use (cert paths don't exist on dev machines).
# -----------------------------------------------------------------------------
VPS_PROJECT ?= $(PROD_PROJECT)

VPS = docker compose --project-name $(VPS_PROJECT) --env-file .env.prod \
      -f docker-compose.yml -f docker-compose.prod.yml -f docker-compose.vps.yml

.PHONY: vps-up
vps-up: check-env	## [VPS] Build and start HTTPS stack (detached)
	$(VPS) up --build -d --remove-orphans

.PHONY: vps-down
vps-down:		## [VPS] Stop HTTPS stack (keeps volumes)
	$(VPS) down

.PHONY: vps-restart
vps-restart:		## [VPS] Restart HTTPS stack safely without deleting volumes
	$(VPS) down
	$(VPS) up --build -d --remove-orphans

.PHONY: vps-logs
vps-logs:		## [VPS] Follow logs for all services
	$(VPS) logs -f

.PHONY: vps-logs-nginx
vps-logs-nginx:		## [VPS] Follow nginx logs only
	$(VPS) logs -f nginx

.PHONY: vps-logs-backend
vps-logs-backend:	## [VPS] Follow backend logs only
	$(VPS) logs -f backend

.PHONY: vps-ps
vps-ps:			## [VPS] Show status of all VPS services
	$(VPS) ps

.PHONY: vps-shell-nginx
vps-shell-nginx:	## [VPS] Open shell inside nginx container
	$(VPS) exec nginx /bin/sh

.PHONY: vps-shell-backend
vps-shell-backend:	## [VPS] Open bash shell inside backend container
	$(VPS) exec backend /bin/bash

.PHONY: vps-migrate
vps-migrate:		## [VPS] Run Django migrations
	$(VPS) exec backend /app/.venv/bin/python manage.py migrate

.PHONY: vps-collectstatic
vps-collectstatic:	## [VPS] Run collectstatic
	$(VPS) exec backend /app/.venv/bin/python manage.py collectstatic --noinput

.PHONY: vps-createsuperuser
vps-createsuperuser:	## [VPS] Create Django superuser
	$(VPS) exec backend /app/.venv/bin/python manage.py createsuperuser

.PHONY: vps-nginx-test
vps-nginx-test:		## [VPS] Test nginx config syntax inside container
	$(VPS) exec nginx nginx -t

.PHONY: vps-nginx-verify
vps-nginx-verify:	## [VPS] Verify APP_DOMAIN was substituted in nginx config
	@echo "--- /etc/nginx/conf.d/ contents ---"
	$(VPS) exec nginx ls -la /etc/nginx/conf.d/
	@echo "--- ssl_certificate lines ---"
	$(VPS) exec nginx grep ssl_certificate /etc/nginx/conf.d/app-ssl.conf
	@echo "--- proxy_set_header Host (should contain \$$host) ---"
	$(VPS) exec nginx grep 'proxy_set_header.*Host' /etc/nginx/conf.d/app-ssl.conf

.PHONY: vps-config
vps-config:		## [VPS] Render final VPS Compose config (dry run)
	$(VPS) config

.PHONY: vps-prepare-https
vps-prepare-https: ## VPS only: install certbot, create HTTPS dirs, install renewal hook
	./scripts/vps-prepare-https.sh

.PHONY: vps-issue-cert
vps-issue-cert: ## VPS only: issue initial Let's Encrypt cert using standalone mode
	./scripts/vps-issue-cert-standalone.sh

# -----------------------------------------------------------------------------
# Monitoring / Observability
# -----------------------------------------------------------------------------
#
# VPS monitoring:
#   Full production/VPS compose stack with Prometheus, Grafana, node_exporter,
#   and cAdvisor.
#
# Local monitoring:
#   macOS/dev-safe monitoring with Prometheus + Grafana only.
#   This avoids Linux-host-specific node_exporter/cAdvisor behavior locally.
#
# Ports:
#   Prometheus: 127.0.0.1:9090
#   Grafana:    127.0.0.1:3001
# -----------------------------------------------------------------------------

MONITORING_PROJECT ?= $(PROD_PROJECT)

MONITORING_VPS = docker compose \
	--project-name $(MONITORING_PROJECT) \
	--env-file .env.prod \
	-f docker-compose.yml \
	-f docker-compose.prod.yml \
	-f docker-compose.vps.yml \
	-f docker-compose.monitoring.yml

MONITORING_LOCAL = docker compose \
	--project-name $(MONITORING_PROJECT) \
	--env-file .env.prod \
	-f docker-compose.yml \
	-f docker-compose.prod.yml \
	-f docker-compose.monitoring.yml

.PHONY: monitoring-up
monitoring-up: ## [VPS] Start app + monitoring stack
	@./scripts/check-env.sh .env.prod --with-monitoring
	$(MONITORING_VPS) up -d --build

.PHONY: monitoring-down
monitoring-down: ## [VPS] Stop monitoring containers only; keep app running
	$(MONITORING_VPS) stop prometheus grafana node_exporter cadvisor
	$(MONITORING_VPS) rm -f prometheus grafana node_exporter cadvisor

.PHONY: monitoring-ps
monitoring-ps: ## [VPS] Show monitoring container status
	$(MONITORING_VPS) ps prometheus grafana node_exporter cadvisor

.PHONY: monitoring-logs
monitoring-logs: ## [VPS] Follow monitoring logs
	$(MONITORING_VPS) logs -f prometheus grafana node_exporter cadvisor

.PHONY: monitoring-config
monitoring-config: ## [VPS] Render final monitoring Compose config
	$(MONITORING_VPS) config

.PHONY: monitoring-reload
monitoring-reload: ## [VPS/local] Hot-reload Prometheus config
	curl -fsS -X POST http://localhost:9090/-/reload && echo "Prometheus reloaded"

.PHONY: monitoring-up-local
monitoring-up-local: ## [local] Start Prometheus + Grafana only
	@./scripts/check-env.sh .env.prod --with-monitoring
	$(MONITORING_LOCAL) up -d prometheus grafana

.PHONY: monitoring-down-local
monitoring-down-local: ## [local] Stop Prometheus + Grafana only
	$(MONITORING_LOCAL) stop prometheus grafana
	$(MONITORING_LOCAL) rm -f prometheus grafana

.PHONY: monitoring-ps-local
monitoring-ps-local: ## [local] Show local monitoring status
	$(MONITORING_LOCAL) ps prometheus grafana

.PHONY: monitoring-logs-local
monitoring-logs-local: ## [local] Follow local monitoring logs
	$(MONITORING_LOCAL) logs -f prometheus grafana

.PHONY: monitoring-config-local
monitoring-config-local: ## [local] Render local monitoring Compose config
	$(MONITORING_LOCAL) config

# ─────────────────────────────────────────────
#  Backups
# ─────────────────────────────────────────────
.PHONY: backup backup-db backup-media backup-list \
        restore-db restore-media backups-install backups-status

backup:            ## Full backup (db + media) with retention prune
	bash scripts/backup/backup.sh

backup-db:         ## Backup database only
	bash scripts/backup/backup.sh --db-only

backup-media:      ## Backup media only
	bash scripts/backup/backup.sh --media-only

backup-list:       ## List existing backups (newest first)
	@echo "== DB daily =="   ; ls -1t backups/db/daily/db-*.dump.gz     2>/dev/null || echo "  (none)"
	@echo "== DB weekly =="  ; ls -1t backups/db/weekly/db-*.dump.gz    2>/dev/null || echo "  (none)"
	@echo "== Media daily ==" ; ls -1t backups/media/daily/media-*.tar.gz  2>/dev/null || echo "  (none)"
	@echo "== Media weekly ==" ; ls -1t backups/media/weekly/media-*.tar.gz 2>/dev/null || echo "  (none)"

restore-db:        ## make restore-db FILE=backups/db/daily/db-xxx.dump.gz
	@test -n "$(FILE)" || { echo "Usage: make restore-db FILE=<path>.dump.gz"; exit 1; }
	bash scripts/backup/restore-db.sh "$(FILE)"

restore-media:     ## make restore-media FILE=backups/media/daily/media-xxx.tar.gz
	@test -n "$(FILE)" || { echo "Usage: make restore-media FILE=<path>.tar.gz"; exit 1; }
	bash scripts/backup/restore-media.sh "$(FILE)"

backups-install:   ## Install systemd daily backup timer (VPS)
	sudo bash scripts/ops/install-backups.sh install

backups-status:    ## Show backup timer + recent logs
	bash scripts/ops/install-backups.sh status

backup-rsync:      ## Manually push backups to secondary host via rsync over SSH
	bash scripts/backup/upload-rsync.sh
