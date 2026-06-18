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

## 🛠️ Planned Tech Stack

| Layer | Technology |
|---|---|
| Backend | Django, Django REST Framework |
| Frontend | React, TypeScript, Vite |
| Database | PostgreSQL |
| Cache / Broker | Redis |
| Background Jobs | Celery |
| Storage | MinIO locally, S3 later |
| Containerization | Docker, Docker Compose |
| Reverse Proxy | Nginx or Traefik |
| Testing | pytest, Vitest, React Testing Library |
| CI/CD | GitHub Actions |
| Deployment | VPS first, cloud later |

## ✨ Planned Features

- [ ] User registration and login
- [ ] JWT authentication
- [ ] Upload songs
- [ ] Stream/play songs
- [ ] Song list and search
- [ ] Playlists
- [ ] Favorite/liked songs
- [ ] Background audio processing
- [ ] Dockerized development environment
- [ ] Automated tests
- [ ] CI/CD pipeline
- [ ] Live VPS deployment

## 📐 Architecture

Initial planned architecture:

```text
Browser
   |
   v
Reverse Proxy
   |
   |--- Frontend: React + TypeScript
   |
   |--- Backend: Django REST API
            |
            |--- PostgreSQL
            |--- Redis
            |--- Celery
            |--- MinIO/S3
```

## 🚀 Running Locally

Instructions will be added as the project develops.

## 🧪 Testing

Testing setup will include:

- Backend: pytest + pytest-django
- Frontend: Vitest + React Testing Library

### Test Coverage

Coverage is measured with `pytest-cov` and enforced in CI (minimum 85%).

# Run tests with coverage report

```bash
uv run pytest --cov --cov-report=term-missing
```

# Generate an HTML report

```bash
uv run pytest --cov --cov-report=html
open htmlcov/index.html
```

## 🗄️ Object Storage

Media files (audio, avatars) are stored in S3-compatible object storage.

| Environment | Storage |
|-------------|---------|
| Local dev   | Local disk (`USE_S3=false`) |
| Docker      | MinIO (`USE_S3=true`) |
| Production  | AWS S3 (`USE_S3=true`) |

MinIO console (Docker): http://localhost:9001 (minioadmin / minioadmin123)

Switching between MinIO and S3 requires **no code changes** — only env vars.

## ⚡ Caching (Redis)

The public feed is cached in Redis for fast, low-load reads.

| Environment | Cache backend |
|-------------|---------|
| Local dev   | In-memory (REDIS_URL empty) |
| Docker      | Redis 7 (redis://redis:6379/1) |
| Production  | Redis (managed/self-hosted) |

- Default feed is cached for 60 seconds and invalidated automatically when songs change.
- Filtered/searched feed queries always hit the database (fresh results).
- Health check endpoint: GET /api/health/ (reports API/cache status).

Redis also serves as the Celery broker foundation for background tasks.


## 🚀 Running Locally
Detailed setup instructions are evolving as the project progresses.


## 📦 Deployment Plan

The project will be deployed in two stages:

1. VPS deployment using Docker Compose
2. Cloud deployment/migration, likely AWS


## 📔 Development Journal

For day-by-day implementation details, see the development see [`docs/JOURNAL.md`](docs/JOURNAL.md).


## 📄 License

MIT
