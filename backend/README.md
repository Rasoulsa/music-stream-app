# Backend — Music Stream App

Django + Django REST Framework backend for the Music Stream App.

The backend provides authentication, song upload, song streaming metadata,
profiles, public feeds, caching, throttling, and background audio processing.

For the full system design, see:

👉 [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)

---

## Requirements

- Python 3.13
- uv
- Docker and Docker Compose, recommended
- PostgreSQL
- Redis
- MinIO/S3-compatible object storage

---

## Tech Stack

| Area | Technology |
|---|---|
| Web framework | Django |
| API framework | Django REST Framework |
| Auth | SimpleJWT |
| Database | PostgreSQL |
| Cache | Redis / django-redis |
| Task queue | Celery |
| Broker | Redis |
| Storage | MinIO locally, S3-compatible storage in production |
| API docs | drf-spectacular |
| Testing | pytest, pytest-django, pytest-cov |
| Formatting / linting | Ruff |
| Dependency manager | uv |

---

## Backend Structure

```text
backend/
├── config/
│   ├── settings/
│   │   ├── base.py
│   │   ├── dev.py
│   │   ├── ci.py
│   │   └── production.py
│   ├── celery.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── music/
│   ├── models.py
│   ├── serializers.py
│   ├── views.py
│   ├── urls.py
│   ├── filters.py
│   ├── permissions.py
│   ├── throttles.py
│   ├── tasks.py
│   ├── signals.py
│   └── tests/
├── api/
│   └── schema.yml
├── Dockerfile
├── manage.py
├── pyproject.toml
└── uv.lock
```

---

## Settings Modules

The project uses separate settings modules for different environments.

| Module | Purpose |
|---|---|
| `config.settings.base` | Shared settings |
| `config.settings.dev` | Local development |
| `config.settings.ci` | CI/test settings |
| `config.settings.production` | Production settings |

The health check route intentionally stays unversioned:

```text
/api/health/
```

The versioned API lives under:

```text
/api/v1/
```

---

## Running with Docker

From the project root:

```bash
make dev-up-d
```

Run migrations:

```bash
make dev-migrate
```

Open a shell inside the backend container:

```bash
make dev-shell
```

View backend logs:

```bash
make dev-logs-backend
```

Create a superuser:

```bash
make dev-createsuperuser
```

Stop the development stack:

```bash
make dev-down
```

---

## Running Locally Without Docker

From the backend directory:

```bash
cd backend
uv sync
uv run python manage.py migrate
uv run python manage.py runserver
```

Run with an explicit settings module if needed:

```bash
DJANGO_SETTINGS_MODULE=config.settings.dev uv run python manage.py runserver
```

---

## API Routes

### Health and docs

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/health/` | Health check |
| `GET` | `/api/schema/` | OpenAPI schema |
| `GET` | `/api/docs/` | Swagger UI |
| `GET` | `/api/redoc/` | Redoc UI |

### Auth

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/v1/auth/register/` | Register user |
| `POST` | `/api/v1/auth/login/` | Login and receive JWT tokens |
| `POST` | `/api/v1/auth/refresh/` | Refresh JWT access token |

### Songs

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/v1/songs/` | List public songs |
| `POST` | `/api/v1/songs/` | Upload a song |
| `GET` | `/api/v1/songs/<id>/` | Retrieve song |
| `PATCH` | `/api/v1/songs/<id>/` | Update song |
| `DELETE` | `/api/v1/songs/<id>/` | Delete song |
| `GET` | `/api/v1/songs/mine/` | List current user's songs |
| `GET` | `/api/v1/feed/` | Cached public feed |

### Users

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` / `PATCH` | `/api/v1/users/me/` | Current user's profile |
| `GET` | `/api/v1/users/<username>/` | Public user profile |
| `GET` | `/api/v1/users/<username>/songs/` | Public songs by user |

---

## Authentication

Authentication uses JWT through SimpleJWT.

Login:

```http
POST /api/v1/auth/login/
Content-Type: application/json

{
  "username": "demo",
  "password": "password"
}
```

Response:

```json
{
  "access": "jwt-access-token",
  "refresh": "jwt-refresh-token"
}
```

Authenticated requests use:

```http
Authorization: Bearer <access-token>
```

Token refresh:

```http
POST /api/v1/auth/refresh/
Content-Type: application/json

{
  "refresh": "jwt-refresh-token"
}
```

---

## Object Storage

The app uses object storage for uploaded audio files and avatars.

- Local/development: MinIO
- Production/cloud-ready: S3-compatible storage

This keeps media files outside the application container and prepares the app
for later AWS S3 migration.

---

## Background Jobs

Celery is used for asynchronous audio processing.

Current background task responsibilities include:

- Reading uploaded audio files
- Extracting duration/metadata using `mutagen`
- Updating the song status and duration in PostgreSQL

Redis is used as the Celery broker.

Useful commands:

```bash
make dev-logs-celery
make prod-logs-celery
```

---

## Caching

Redis is used for caching read-heavy endpoints such as the public feed.

The performance pass optimized:

- feed queries
- selected related user/profile data
- database indexing
- response caching

More details:

👉 [`../docs/performance.md`](../docs/performance.md)

---

## Throttling

DRF throttling is used to protect sensitive endpoints.

Examples:

| Scope | Purpose |
|---|---|
| `login` | Limit login attempts |
| `register` | Limit registration attempts |
| `upload` | Limit song uploads |

Throttle classes live in:

```text
music/throttles.py
```

Security details:

👉 [`../docs/security.md`](../docs/security.md)

---

## Testing

Run backend tests from the project root:

```bash
make test-backend
```

Run with coverage:

```bash
make test-backend-cov
```

Run performance tests only:

```bash
make test-backend-perf
```

Run tests inside the development container:

```bash
make dev-test
make dev-test-cov
```

The backend uses:

- pytest
- pytest-django
- pytest-cov
- Django test database
- disposable PostgreSQL test database for local test commands

---

## Schema Management

The API contract is generated with drf-spectacular.

Generate/freeze the schema:

```bash
make schema-freeze
```

Check that the live schema matches the frozen schema:

```bash
make schema-check
```

Frozen schema file:

```text
backend/api/schema.yml
```

---

## Production Checks

Run Django production checks:

```bash
make prod-check
```

Run the full production smoke test:

```bash
make smoke-prod
```

Expected smoke test result:

```text
Results: 52 passed, 0 failed
```

Smoke test documentation:

👉 [`../docs/smoke-tests.md`](../docs/smoke-tests.md)

---

## Important Files

| File | Purpose |
|---|---|
| `config/urls.py` | Root URL config |
| `music/urls.py` | Versioned music app routes |
| `music/models.py` | Song and Profile models |
| `music/serializers.py` | API serializers |
| `music/views.py` | API views and viewsets |
| `music/tasks.py` | Celery tasks |
| `music/throttles.py` | Custom throttle classes |
| `music/filters.py` | Filtering and search logic |
| `config/celery.py` | Celery application |
| `config/settings/production.py` | Production settings |
| `api/schema.yml` | Frozen OpenAPI schema |

---

## Common Troubleshooting

### Database connection refused

Start the database/container stack:

```bash
make dev-up-d
```

or for local tests:

```bash
make test-db-up
```

---

### Login returns `429 Too Many Requests`

Login throttling is working. Wait for the throttle window to expire, or clear
the Redis throttle cache in local testing.

Example local reset:

```bash
docker exec music-redis redis-cli -n 1 FLUSHDB
```

---

### Media file does not stream

Check:

```bash
make prod-logs-nginx
make prod-logs-backend
docker exec music-nginx wget -qO- http://minio:9000/minio/health/live
```

---

## Related Documentation

- [`../README.md`](../README.md)
- [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)
- [`../docs/env-management.md`](../docs/env-management.md)
- [`../docs/security.md`](../docs/security.md)
- [`../docs/performance.md`](../docs/performance.md)
- [`../docs/smoke-tests.md`](../docs/smoke-tests.md)
