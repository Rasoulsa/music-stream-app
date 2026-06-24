# 🎵 Music Stream App

![CI](https://github.com/Rasoulsa/music-stream-app/actions/workflows/ci.yml/badge.svg)
![Coverage](https://codecov.io/gh/Rasoulsa/music-stream-app/branch/main/graph/badge.svg)

A full-stack, dockerized music streaming application built as a professional portfolio project.

The goal of this project is to demonstrate practical backend development, frontend development, Docker, testing, CI/CD, and real deployment practices.

## 🚧 Project Status

🟡 In active development.

This project is being built step by step with a professional Git/GitHub workflow.

## 🎯 Project Goals

- Build a real online music player application
- Use Django and Django REST Framework for the backend
- Use React, TypeScript, and Vite for the frontend
- Use Docker and Docker Compose for development and deployment
- Add automated tests for backend and frontend
- Add CI/CD with GitHub Actions
- Deploy first to a VPS
- Later migrate or extend deployment to AWS/cloud

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django, Django REST Framework |
| Frontend | React, TypeScript, Vite |
| Database | PostgreSQL |
| Cache / Broker | Redis |
| Background Jobs | Celery |
| Storage | MinIO locally, S3 in production |
| Containerization | Docker, Docker Compose |
| Reverse Proxy | Nginx |
| Testing | pytest, Vitest, React Testing Library |
| CI/CD | GitHub Actions |
| Deployment | VPS first, cloud later |

## ✨ Features

- [x] User registration and login
- [x] JWT authentication
- [x] Upload songs
- [x] Stream/play songs
- [x] Song list and search
- [x] Background audio processing (Celery)
- [x] Dockerized development and production environments
- [x] Automated backend tests with 100% coverage
- [x] CI/CD pipeline
- [x] Versioned REST API (`/api/v1/`) with frozen contract
- [ ] Playlists
- [ ] Favorite/liked songs
- [ ] Frontend (React + TypeScript)
- [ ] Live VPS deployment

## 📐 Architecture

```text
Browser
   |
   v
Nginx :80
   |
   |--- /static/   → served directly by Nginx
   |--- /media/    → served by MinIO (or Nginx in local-disk mode)
   |--- /api/      → Gunicorn :8000 (internal) → Django
                            |
                            |--- PostgreSQL
                            |--- Redis
                            |--- Celery Worker
                            |--- MinIO / S3
```

## 🌐 API

The backend exposes a versioned REST API. All resource endpoints live under `/api/v1/`.
Operational endpoints are intentionally unversioned so they stay stable across API versions.

| Type | Example endpoints |
|------|------------------|
| Versioned | `/api/v1/songs/`, `/api/v1/feed/`, `/api/v1/users/me/` |
| Unversioned | `/api/health/`, `/api/schema/`, `/api/docs/` |

- Breaking changes will introduce `/api/v2/` — `/api/v1/` is never mutated.
- The OpenAPI schema is **frozen**: a contract test fails if the public API shape drifts unintentionally.

## 🗄️ Object Storage

Media files (audio, avatars) are stored in S3-compatible object storage.

| Environment | Storage |
|-------------|---------|
| Local dev | Local disk (`USE_S3=false`) |
| Docker | MinIO (`USE_S3=true`) |
| Production | AWS S3 (`USE_S3=true`) |

MinIO console (Docker): http://localhost:9001 (minioadmin / minioadmin123)

Switching between MinIO and S3 requires **no code changes** — only environment variables change.

## ⚡ Caching (Redis)

The public feed is cached in Redis for fast, low-load reads.

| Environment | Cache backend |
|-------------|---------------|
| Local dev | In-memory (`REDIS_URL` empty) |
| Docker | Redis 7 (`redis://redis:6379/1`) |
| Production | Redis (managed or self-hosted) |

- Default feed is cached for 60 seconds and invalidated automatically when songs change.
- Filtered/searched feed queries always hit the database (fresh results).
- Health check: `GET /api/health/` reports API and cache status.

Redis also serves as the Celery broker for background tasks.

## 🔄 Background Tasks (Celery)

Audio processing runs asynchronously via Celery workers.

| Environment | Broker |
|-------------|--------|
| Docker / Production | Redis (`redis://redis:6379/0`) |

- Song uploads trigger a processing task automatically via Django signals.
- Task retries are configured for resilience against transient failures.

## 🌍 Production Serving (Nginx + Gunicorn)

Nginx is the single public entry point (port 80) and reverse-proxies to Gunicorn (internal only).

```text
internet → Nginx :80 → Gunicorn :8000 (internal) → Django
                     → /static/  served directly by Nginx
                     → /media/   served by MinIO (or Nginx in local-disk mode)
```

## 🚀 Running Locally

### Development

```bash
make dev-up        # starts all services with hot-reload
                   # → http://localhost:8000
```

### Production-like

```bash
make prod-up       # Nginx + Gunicorn, DEBUG off, hardened
                   # → http://localhost
```

## 🧪 Testing

| Tool | Purpose |
|------|---------|
| pytest + pytest-django | Backend unit and integration tests |
| pytest-cov | Coverage reporting (minimum 85%, currently 100%) |
| Vitest + React Testing Library | Frontend tests (planned) |

```bash
# Run backend tests with coverage
make dev-test

# Generate HTML coverage report
uv run pytest --cov --cov-report=html
open htmlcov/index.html
```

## Continuous Integration

| Workflow | Triggers on | Jobs |
|----------|-------------|------|
| **Backend CI** (`ci.yml`) | push/PR to `main` | Lint & Format (ruff) → Tests (PostgreSQL + coverage) |
| **Frontend CI** (`frontend-ci.yml`) | `frontend/**` changes | Lint & Format (eslint + prettier) → Tests & Build (vitest + vite) → Docker Build |

Run frontend checks locally before pushing:

```bash
cd frontend
npm ci && npm run lint && npm run format:check && npm run test && npm run build
```


## 📦 Deployment Plan

1. VPS deployment using Docker Compose
2. Cloud deployment/migration (likely AWS)

### Nginx Routing (Production-Grade)

The edge nginx (`music-nginx`) is the single public entry point on
port 80. It reverse-proxies all traffic and is the only exposed port
in the stack — Postgres, Redis, and MinIO stay internal.

**Routing:**
| Path | Destination |
|------|-------------|
| `/api/`, `/admin/` | Django (gunicorn) `backend:8000` |
| `/static/`, `/media/` | Shared Docker volumes (direct) |
| `/music-media/` | MinIO `minio:9000` (proxied, never public) |
| `/healthz` | nginx liveness (200, no upstream) |
| everything else | React SPA `frontend:80` → `try_files` fallback |

**Production hardening:** gzip compression, browser cache headers,
baseline security headers (`X-Content-Type-Options`, `X-Frame-Options`,
`Referrer-Policy`), upstream keepalive, hidden nginx version, and tuned
timeouts for 50 MB audio uploads.

```bash
make prod-up
curl http://localhost/healthz     # → ok
```

## 📔 Development Journal

For day-by-day implementation details, see [`docs/JOURNAL.md`](docs/JOURNAL.md).

## 📄 License

MIT
