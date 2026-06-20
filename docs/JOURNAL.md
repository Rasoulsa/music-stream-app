# 📔 Development Journal

This journal records the step-by-step progress of the Music Stream App.

The purpose is to document technical decisions, learning progress, problems, and solutions.

---

## Day 1 — June 05, 2026

### What I did

- Defined the project idea: online music streaming/player app
- Decided to use Django for backend development
- Decided to use React with TypeScript for frontend development
- Decided to use Docker and Docker Compose throughout the project
- Decided to include tests from early stages
- Decided to deploy first on a VPS, then move toward cloud/AWS later
- Created the initial project structure
- Added `.gitignore`
- Added `.env.example`
- Added initial `README.md`
- Started the development journal

### Technical decisions

- VPS first is chosen to build strong Linux, Docker, deployment, and server fundamentals
- AWS/cloud will be added later after the app is stable
- TypeScript will be used in the frontend from the beginning
- Tests will be part of the project, not an afterthought
- GitHub will be used as the public contribution and progress platform

### What I learned

- Why `.env` should never be committed
- Why `.env.example` is useful for documenting required environment variables
- Why a clean GitHub history matters for a portfolio project
- Why building and documenting step by step is valuable for job search

### Next step

- Initialize the Django backend
- Add Django REST Framework
- Configure pytest
- Create the first backend test


## Day 2 — June 06, 2026

### What I did

- Created feature branch `feat/backend-foundation`
- Initialized backend with uv (Python 3.13) and automatic .venv
- Installed Django, DRF, CORS headers, django-environ, psycopg
- Installed dev tools: pytest, pytest-django, ruff, pre-commit
- Created Django project `config` and `music` app
- Split settings into base/dev/prod
- Loaded environment variables with django-environ
- Added /api/health/ health check endpoint
- Configured pytest with pytest-django
- Added sanity, database, and real API tests
- Configured Ruff for linting/formatting
- Configured pre-commit hooks
- Added production fail-fast secret key check
- Added backend/README.md
- Ran migrations and confirmed the dev server works
- Added API documentation with drf-spectacular (OpenAPI 3)
- Enabled Swagger UI (/api/docs/) and ReDoc (/api/redoc/)
- Documented the health check endpoint with @extend_schema
- Added tests for the schema and Swagger UI endpoints

### Technical decisions

- Used uv for dependency and environment management instead of pip+venv
  for reproducibility and CI/CD friendliness
- Used split settings so dev and prod configs stay clean
- Defaulted to SQLite for now; PostgreSQL via Docker comes later
- manage.py defaults to dev; wsgi/asgi default to prod
- Kept secrets in .env, never committed
- Added a health check endpoint for future Docker/monitoring use

### What I learned

- How uv manages the virtual environment via `uv run`
- Why split settings help multi-environment deployment
- How pytest-django connects tests to Django settings
- How to test real API endpoints with DRF APIClient
- Why pre-commit and security fail-fast checks matter

### Next step

- Create the Song model
- Create serializers and API endpoints
- Add API tests for create/list songs


## Day 3 — June 06, 2026

### What I did

- Created feature branch `feat/song-model-and-api`
- Installed Pillow for image support
- Created the Song model (title, artist, album, audio_file,
  cover_image, duration_seconds, timestamps)
- Configured media file handling and serving in development
- Created SongSerializer with field validation
- Created SongViewSet (full CRUD) with multipart upload support
- Wired up a DRF router for /api/songs/ endpoints
- Registered Song in Django admin with list/search/filter
- Created and applied migrations
- Created a superuser for admin access
- Auto-documented the Song API in Swagger
- Wrote API tests: list, create, validation, retrieve, update, delete
- Added conftest.py to use temporary media in tests
- Ignored backend/media/ in git

### Technical decisions

- Used ModelViewSet + DefaultRouter for clean, standard CRUD
- Used MultiPartParser/FormParser to support file uploads via the API
- Validated title/artist server-side in the serializer
- Redirected uploaded files to a temp dir during tests via conftest
- Kept media files out of version control

### What I learned

- How DRF ViewSets and routers generate CRUD endpoints
- How serializers validate and transform data
- How to handle file uploads (audio + image) in DRF
- How to test file-upload endpoints with SimpleUploadedFile
- How to isolate test media with a settings fixture

### Next step

- Add search and filtering to the Song API
- Consider Artist/Album as separate models with relations
- Begin the React + TypeScript frontend foundation


## Day 4 — June 07, 2026

### What I did

- Created feature branch `feat/song-search-filter-ordering`
- Installed django-filter
- Registered DjangoFilterBackend, SearchFilter, OrderingFilter
  as global DRF filter backends
- Created a custom SongFilter (artist, album, duration range)
- Added free-text search across title, artist, album
- Added ordering by title, artist, duration, created_at
- Auto-documented all query params in Swagger
- Wrote 8 tests for search, filtering, and ordering

### Technical decisions

- Used a custom FilterSet for case-insensitive partial matching
  instead of plain filterset_fields (more professional, flexible)
- Set filter backends globally so all future endpoints inherit them
- Kept a sensible default ordering (-created_at)

### What I learned

- Difference between search (multi-field text) and filter (exact/field)
- How django-filter integrates with DRF
- How lookup expressions work (icontains, gte, lte)
- How filter query params appear automatically in Swagger

### Next step

- Begin the React + TypeScript frontend foundation (Day 5)
- Connect the frontend to the Song API with search/filter

## Day 5 — June 09, 2026

### What I did

- Created feature branch `feat/frontend-foundation`
- Scaffolded React + TypeScript app with Vite in frontend/
- Installed axios, prettier, eslint-config-prettier
- Configured Prettier and npm scripts (dev, build, lint, format)
- Set up env variables (VITE_API_BASE_URL) with .env.example
- Created folder structure (api, components, types)
- Defined TypeScript types (HealthResponse, Song, PaginatedResponse)
- Built a typed Axios API client
- Created a HealthCheck component that calls /api/health/
- Configured CORS on the backend for the React dev server
- Verified full-stack connection (React ↔ Django) works
- Added frontend/README.md

### Technical decisions

- Used Vite for fast modern React tooling
- Centralized API calls in src/api with typed functions
- Used env variables for the API base URL (no hardcoding)
- Configured CORS only in dev settings for the dev server origin

### What I learned

- How Vite env variables work (import.meta.env, VITE_ prefix)
- Why CORS is needed and how django-cors-headers solves it
- How to structure a typed React + TypeScript project
- How to connect a React frontend to a Django REST API

### Next step

- Build the song list page (fetch /api/songs/)
- Add an audio player component (Day 6)


## Day 6 — June 10, 2026

### What I did

- Created feature branch `feat/song-list-and-player`
- Added getSongs() API function with search support
- Created a duration formatting helper (seconds → m:ss)
- Built SongCard, SearchBar, AudioPlayer, and SongList components
- Wired the active song state in App so list and player share it
- Implemented debounced search (400ms) wired to ?search=
- Added loading, error, and empty states
- Styled a clean song grid and a fixed bottom player bar
- Verified end-to-end: search → click → audio plays in browser

### Technical decisions

- Lifted the "active song" state up to App (single source of truth)
- Debounced search to avoid an API call on every keystroke
- Used the native <audio controls> element for reliable playback
- Used key={song.id} on <audio> to reload on song change

### What I learned

- React state lifting and component composition
- useEffect cleanup for debouncing with setTimeout/clearTimeout
- Passing query params through Axios
- Handling loading/error/empty UI states properly

### Next step

- Dockerize the backend (Day 7)

## Day 7 — June 13, 2026

### What I did

- Created feature branch `feat/dockerize-backend`
- Added gunicorn (production WSGI server) and whitenoise (static files)
- Wrote a multi-stage Dockerfile using the official uv image
- Added a .dockerignore to keep the image small and exclude secrets
- Created .env.docker (git-ignored) and .env.docker.example (committed)
- Made production settings Docker-friendly:
  - env-driven DJANGO_ALLOWED_HOSTS
  - SQLite stored in a writable /app/data directory (for now)
  - HTTPS hardening gated behind DJANGO_SECURE_SSL flag
  - kept the secret-key fail-fast check
- Added WhiteNoise middleware for static files
- Ran the container as a non-root user with a proper home directory
- Added a container-level HEALTHCHECK
- Built the image and ran the backend in Docker
- Verified /api/health/ works from inside the container

### Problems I solved

- "unable to open database file": SQLite couldn't be written by the
  non-root user → fixed by creating a writable /app/data directory
  owned by the app user.
- Gunicorn "Permission denied: /home/app": the system user had no home
  directory → fixed with useradd --create-home.
- "port is already allocated": a leftover container held port 8000 →
  fixed by stopping running containers (docker stop $(docker ps -q)).

### Technical decisions

- Multi-stage build (builder + runtime) for a small, secure image.
- Ran as a non-root user for security best practice.
- Gunicorn with 3 workers instead of Django's dev server.
- Kept secrets out of the image; passed env vars at runtime.
- Gated HTTPS hardening behind an env flag so the production image can
  be tested locally over plain HTTP.
- Stayed on SQLite for now; PostgreSQL comes with Docker Compose.

### What I learned

- The difference between a Dockerfile, image, and container.
- How multi-stage builds and layer caching work.
- Why containers run as non-root and how that surfaces file-permission
  issues (and why a real DB server like PostgreSQL is better here).
- How to debug port conflicts with lsof and docker ps.

### Next step

- Docker Compose to orchestrate the backend with one command, add
  volumes for persistence, and prepare for PostgreSQL (Day 8).

## Day 8 — June 15, 2026

### What I did

- Created feature branch `feat/docker-compose-postgres`.
- Added Docker Compose to run the full backend stack with one command.
- Added a PostgreSQL 16 service running in its own container.
- Added a persistent Docker volume for the PostgreSQL data.
- Switched the backend database from SQLite to PostgreSQL.
- Updated production settings to read PostgreSQL config from environment variables.
- Added PostgreSQL environment variables to `.env.docker.example` and `.env.docker`.
- Configured the backend to wait for the database to be healthy before starting.
- Added a PostgreSQL health check using `pg_isready`.
- Built and started the full stack with `docker compose up --build`.
- Verified that migrations run automatically against PostgreSQL.
- Verified that Gunicorn starts and serves the API.
- Verified the API health endpoint and Swagger docs.
- Tuned the Gunicorn worker timeout settings.
- Improved the container health check to send a real HTTP request.

### Problems I solved

- Saw repeated `WORKER TIMEOUT` and `no URI read` errors in Gunicorn logs.
  - Cause: the health check probe opened the socket without sending a full HTTP request, and the default Gunicorn worker timeout was too aggressive.
  - Solution: changed the container health check to make a proper HTTP GET to `/api/health/`, and added explicit Gunicorn timeout settings.
  - Confirmed the application itself was always working by testing the API directly.

### Technical decisions

- Used Docker Compose so the whole backend stack starts with one command.
- Used PostgreSQL 16 to match a realistic production database.
- Used the `db` service name as the database host, so containers communicate over the Compose network.
- Used a named volume for the database so data persists across restarts.
- Used `depends_on` with a health condition so the backend only starts after the database is ready.
- Kept secrets in `.env.docker` and out of Git.

### What I learned

- How Docker Compose connects multiple containers on one network.
- How containers reach each other by service name instead of IP.
- How to run PostgreSQL in a container with a persistent volume.
- Why the backend should wait for the database to be healthy first.
- How to debug Gunicorn worker timeouts and health check noise.
- The difference between stopping containers and deleting volumes.

### Next step

- Start building user accounts, authentication, and profiles.
- Connect songs to their owner users.
- Add public and private visibility for songs.

## Day 9 — June 16, 2026

### What I did

- Created feature branch `feat/auth-and-song-ownership`.
- Added JWT authentication using djangorestframework-simplejwt.
- Added a user registration endpoint.
- Added login and token refresh endpoints.
- Added an `owner` foreign key to the Song model.
- Added an `is_public` field for public/private songs.
- Added a custom `IsOwnerOrReadOnly` permission.
- Restricted song queryset so users only see public songs plus their own.
- Restricted song editing and deletion to the owner.
- Updated serializers to expose the owner as read-only.
- Recreated the database to apply the new owner field cleanly.
- Wrote tests for registration, login, ownership, and visibility.
- Verified all endpoints manually with curl and Swagger.
- Updated README with authentication and ownership docs.

### Technical decisions

- Chose JWT over session auth because the frontend will be a separate React app.
- Used a read-only owner field, set automatically from the request user.
- Used object-level permissions to enforce ownership.
- Filtered the queryset so private songs never leak to other users.

### What I learned

- How JWT access and refresh tokens work in DRF.
- How to attach the request user as the owner on create.
- How object-level permissions differ from view-level permissions.
- How to filter querysets based on the authenticated user.

### Next step

- Add user profile endpoints.
- Build the public feed page logic.
- Add song file upload handling.

## Day 10 — CI/CD Foundation with GitHub Actions

### Completed
- Added GitHub Actions CI workflow.
- CI runs automatically on pull requests and pushes to `main`.
- Added backend quality checks:
  - Ruff format check
  - Ruff lint check
  - Pytest test suite
- Added Docker image build verification.
- Merged CI pipeline through a pull request.
- Deleted the feature branch after merge.

### Local verification
- Ruff format check passed.
- Ruff lint passed.
- Pytest passed with 31 tests.

### Notes
- Current CI uses SQLite test database through `config.settings.dev`.
- Future improvement: run tests against PostgreSQL in CI to match production more closely.
- Future CD step can deploy the application after CI passes.

## Day 11 — User Profiles & Public Feed

### Goal
Complete the user-centric backend: profiles, public feed,
per-user public songs, and a "my songs" endpoint.

### Added
- `Profile` model (one-to-one with User): display_name, bio, created_at/updated_at.
- `post_save` signal auto-creates a Profile on user registration.
- Data migration backfilling profiles for existing users.
- `related_name="songs"` on `Song.owner` for clean reverse queries.

### Endpoints
| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET    | `/api/users/me/`              | ✅ | Own profile (email + song count) |
| PATCH  | `/api/users/me/`              | ✅ | Update display_name / bio |
| GET    | `/api/users/{username}/`      | ❌ | Public profile (no email) |
| GET    | `/api/users/{username}/songs/`| ❌ | User's public songs |
| GET    | `/api/songs/mine/`            | ✅ | My songs (public + private) |
| GET    | `/api/feed/`                  | ❌ | All public songs (paginated, filterable) |

### Quality
- Tested locally (SQLite) and in Docker (PostgreSQL).
- `select_related("owner")` avoids N+1 queries on listing endpoints.
- drf-spectacular tags + summaries keep Swagger clean and grouped.
- Ruff format + lint clean; pre-commit hooks passed; CI green.

### Notes
- Used `settings.AUTH_USER_MODEL` throughout (future custom-user-safe).
- Avatar/image deferred to the MinIO storage milestone.


## Day 12 — Harden CI: Tests Against PostgreSQL

### Goal
Make CI run pytest against a real PostgreSQL 16 service — matching the
production database — instead of SQLite. Eliminates the "passes on
SQLite but breaks on PostgreSQL" class of bugs.

### Added
- `config/settings/ci.py` — dedicated CI settings (PostgreSQL via env vars,
  fast MD5 password hasher for test speed).
- Split CI into two jobs:
  - `lint` — Ruff lint + format check.
  - `test` — runs only if lint passes; spins up postgres:16 service,
    runs migrations, then pytest.
- PostgreSQL service with health checks so tests wait for DB readiness.
- `uv sync --frozen` for reproducible installs from the lockfile.

### Why it matters
- Local dev → SQLite (fast)
- Docker / CI / Production → PostgreSQL (parity)
- Migrations are now validated against PostgreSQL on every PR.

### Quality
- Verified locally via `docker compose exec backend pytest -v`.
- All CI checks green on the PR.

## Day 13 — Test Coverage Reporting

### Goal
Measure test coverage, enforce a minimum threshold in CI, and display
a live coverage badge — signaling engineering discipline.

### Added
- `pytest-cov` dev dependency.
- Coverage config in `pyproject.toml`:
  - branch coverage enabled (if/else paths, not just lines)
  - omits migrations, tests, settings, boilerplate
  - `--cov-fail-under=85` enforced on every test run
- Codecov integration in CI (`coverage.xml` upload).
- HTML report (`htmlcov/`) for local visual inspection (gitignored).

### Results
- Coverage: ~93% (branch + line).
- CI now fails if coverage drops below 85%.

### Why it matters
- Coverage is enforced, not optional — quality can't silently regress.
- Branch coverage catches untested code paths, not just unexecuted lines.
- Honest, focused coverage (excludes auto-generated/config code).


## Day 14 — Object Storage (MinIO / S3) + Avatars

### Goal
Move media (audio files, avatars) off local disk onto S3-compatible
object storage. MinIO locally, AWS S3 in production — same code path.

### Added
- `django-storages` + `boto3`.
- MinIO service in docker-compose + one-shot bucket-creation service.
- `USE_S3` env switch:
  - false → local disk (fast local dev, no MinIO)
  - true  → S3-compatible storage (MinIO / AWS S3)
- Modern Django 5 `STORAGES` setting (not deprecated DEFAULT_FILE_STORAGE).
- `avatar` ImageField on Profile; `audio_file` uses object storage.
- MyProfileView now accepts multipart uploads (avatar) + JSON.

### Why it matters
- Audio files now live in durable, scalable object storage.
- Identical code for local (MinIO) and production (S3) — swapped by env var.
- Container restarts no longer lose uploaded media.

### Testing approach
- Tests force local-disk storage (USE_S3=false) — fast, isolated, never
  touch real MinIO/S3.
- In-memory PNG generated with Pillow for avatar upload tests.

### Verified
- Avatar uploaded via PATCH /api/users/me/ appears in MinIO bucket.
- File served directly from MinIO at its public URL.
- CI green; coverage still ≥ 85%.


## Day 15 — Redis (Caching + Celery Foundation)

### Goal
Add Redis to the stack and use it as a Django cache backend. Cache the
public feed (the hottest read) and invalidate it automatically on song
changes. Also lays the foundation for Celery (Day 16).

### Added
- `redis` + `django-redis`.
- Redis 7 service in docker-compose (persistence + health check).
- `REDIS_URL` env switch:
  - set   → Redis cache (Docker / prod)
  - empty → local-memory cache (dev without Redis)
- Feed caching: default first-page cached 60s; filtered/searched queries
  bypass cache (always fresh).
- Automatic cache invalidation via post_save / post_delete signals on Song.
- `/api/health/` endpoint reporting DB + cache status.

### Redis DB layout
- /1 → Django cache (this day)
- /0 → reserved for Celery broker (Day 16)

### Why it matters
- Hot reads served from memory, not the DB → faster, less load.
- Correct cache invalidation → users never see stale data.
- Health endpoint → production monitoring + demo-friendly.

### Testing approach
- Local: local-memory cache (no Redis needed).
- Docker/CI: behavior verified; autouse fixture clears cache per test.

### Verified
- redis-cli PING → PONG.
- Cache key appears after first feed request; cleared on song create/delete.
- Filtered feed bypasses cache as designed.
- CI green; coverage ≥ 85%.


## Day 16 — Celery (Async Audio Processing)

### Goal
Offload slow audio metadata extraction to a background worker so uploads
return instantly. Celery with Redis broker (the /0 DB reserved on Day 15).

### Added
- `celery` + `mutagen`.
- `config/celery.py` Celery app + autodiscover; loaded via `config/__init__.py`.
- Celery settings (broker /0, results /2, time limits, retries).
- `CELERY_TASK_ALWAYS_EAGER` env switch:
  - true  → inline in-process (local dev & tests, no worker)
  - false → real async worker (Docker / prod)
- `Song.status` (pending/processing/ready/failed) + duration filled by task.
- `process_song_audio` task: extracts duration via mutagen, retries on failure.
- `perform_create` queues the task on upload (.delay()).
- `celery_worker` service in docker-compose (same image as backend).

### Redis DB layout (final)
- /0 → Celery broker
- /1 → Django cache (Day 15)
- /2 → Celery results

### Why it matters
- Uploads respond immediately; heavy work happens off the request cycle.
- Status field lets the frontend show processing → ready.
- Retries handle transient failures (production-grade).

### Testing approach
- Tests run tasks eagerly (synchronous) — no worker/Redis required.
- Covers task success, missing song, missing file, and upload-triggers-task.

### Verified
- Worker boots and registers process_song_audio.
- Upload returns instantly; worker fills duration + sets status=ready.
- CI green; coverage ≥ 85%.

### Fix
- Discovered tests assumed CELERY_TASK_ALWAYS_EAGER=true, which holds in
  dev but not in Docker (production settings, EAGER=false → task queued,
  not run inline). Added an autouse conftest fixture forcing eager mode in
  all tests, making the suite deterministic across environments.

## Day 17 — Nginx Reverse Proxy

### Goal
Put Nginx in front of Gunicorn as the production gateway: single entry
point, direct static file serving, request buffering, large upload support.

### Added
- `nginx/nginx.conf`: proxies /api, /admin, /docs to Gunicorn; serves
  /static and /media directly; client_max_body_size 50M for audio uploads.
- `nginx` service (nginx:1.27-alpine) on port 80 — the only public web port.
- Backend switched from `ports` to `expose` — Gunicorn is internal only.
- Backend command now runs migrate + collectstatic + gunicorn.
- Shared `static_files` volume (backend writes, Nginx reads).
- Django proxy-aware settings: SECURE_PROXY_SSL_HEADER, USE_X_FORWARDED_HOST.
- ALLOWED_HOSTS includes internal service names (backend, nginx).

### Architecture
internet → Nginx (80) → Gunicorn (8000, internal) → Django
                      → /static, /media served directly

### Why it matters
- Gunicorn never faces the internet directly.
- Static files served efficiently by Nginx (no Python overhead).
- Single, clean entry point — ready for HTTPS + frontend routing later.

### Verified
- http://localhost/api/docs/ and /admin/ load (static via Nginx).
- http://localhost:8000 → connection refused (backend internal only).
- collectstatic populates shared volume; Nginx serves it.
- CI green; coverage ≥ 85%.

### Deferred
- HTTPS (Let's Encrypt) → Phase 5 (VPS deployment).
- Frontend routing through Nginx → Phase 4 (integration).

## Day 18 — Production Docker Compose (Dev/Prod Split)

### Goal
Cleanly separate dev and prod environments using the Compose override
pattern — one codebase, two stacks, no manual changes.

### Added
- `config/settings/production.py`: DEBUG off, strict ALLOWED_HOSTS,
  security headers, stdout logging, fail-loud SECRET_KEY, env-gated HTTPS flags.
- `docker-compose.yml` refactored to a clean BASE (shared services, env vars).
- `docker-compose.dev.yml`: runserver, exposed ports, code volume (hot-reload),
  DEBUG=true via .env.dev.
- `docker-compose.prod.yml`: gunicorn + collectstatic, nginx gateway,
  internal-only backend/infra, restart policies, .env.prod.
- `.env.dev` / `.env.prod` (gitignored; .env.example documents them).
- Makefile with dev-up/down/test and prod-up/down/logs targets.

### Verified
- Dev: http://localhost:8000 direct access + auto-reload.
- Prod: http://localhost (Nginx only); :8000 refused; DB not exposed; DEBUG=False.
- Production settings import test + fail-loud-on-missing-secret test.

### Why it matters
- Identical code, environment chosen by override file.
- Prod is hardened (no debug, no exposed infra, restart policies).
- Dev stays fast (hot-reload, direct ports).

### Deferred
- HTTPS flags flip to true in Phase 5 (TLS termination).

## Day 19 — API Versioning & Contract Freeze

Added `/api/v1/` prefix to all resource endpoints. Kept `/api/health/`,
`/api/schema/`, and `/api/docs/` unversioned so operational endpoints stay
stable across versions.

Migrated all tests from hardcoded URLs (`/api/songs/`) to `reverse()` so
they're resilient to prefix changes.

Froze the OpenAPI schema and added a contract test
(`test_api_contract.py::test_api_is_versioned`) that fails if the public API
shape drifts.

**Key realization:** `/api/v1/` is not dev-only — it lives in `urls.py`, so
it applies to dev *and* production. The freeze enforces the contract everywhere.

All 79 tests pass, 100% coverage.
