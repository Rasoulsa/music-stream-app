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


## Day 20 — Frontend Foundation

**Phase 3 begins.** Set up the React + TypeScript + Vite frontend skeleton.

### Done
- Scaffolded `frontend/` (Vite `react-ts` template)
- Installed core deps: react-router-dom, axios, @tanstack/react-query
- Established scalable folder structure (api / features / pages / routes / lib / hooks)
- Built typed axios client reading `VITE_API_BASE_URL`
- Added typed env accessor (`lib/env.ts`)
- Mirrored backend serializers into `api/types.ts` (Song, Profile, Paginated)
- Wired React Query + BrowserRouter providers
- Home page verifies live backend connectivity via /health/
- Configured CORS on backend for localhost:5173
- Added Prettier + npm scripts

### Verified
- `npm run dev` serves on :5173
- Frontend successfully reaches backend → status "ok"
- Full-stack dev loop confirmed working

### Next (Day 21)
- API client auth: login / register / JWT access+refresh handling

## Day 24 — Upload Song UI (2026-06-22)

**Branch:** `feat/upload-song-ui`

### Goal
Build a real upload form so authenticated users can add songs with audio,
metadata, optional cover art, and a public/private toggle.

### What I built
- `api/songs.ts` — `upload()` using `FormData` + axios `onUploadProgress`.
- `hooks/useUploadSong.ts` — mutation hook with progress, field errors,
  and general error parsing from DRF responses.
- `utils/fileValidation.ts` — client-side type/size checks for audio & images.
- `pages/UploadPage.tsx` — full form: audio dropzone, auto-filled title,
  cover preview, public toggle, live progress bar, redirect on success.

### Backend note
Confirmed `SongViewSet` includes `MultiPartParser`/`FormParser` so multipart
uploads are accepted. File served back via MinIO/S3 URL in `audio_file`.

### Decisions
- Validate on the client first (fast feedback) but trust the server as the
  source of truth — DRF field errors are mapped back onto inputs.
- Auto-fill title from filename to reduce friction.
- Reused `apiClient` so JWT refresh works during long uploads.

## Day 25 — Profile Page + Edit (2026-06-22)

### Goal
Build a profile page that displays the current user's info and allows
inline editing of display name, email, bio, and avatar.

### What I built
- `types/user.ts` — User and UpdateProfilePayload types
- `api/users.ts` — getCurrentUser, updateProfile, uploadAvatar
- `hooks/useProfile.ts` — data fetching + save/avatar mutations with
  loading/saving/error states
- `components/profile/ProfileHeader.tsx` — read-only profile view
- `components/profile/ProfileEditForm.tsx` — edit form with avatar
  preview + bio char counter
- `pages/ProfilePage.tsx` — view/edit toggle
- Protected route `/profile` + nav link
- `styles/profile.css`

### Decisions
- Avatar upload uses a separate multipart PATCH to keep JSON profile
  updates clean and simple.
- Avatar preview uses `URL.createObjectURL` for instant feedback before
  the upload completes.
- Bio capped at 500 chars with a live counter.

### Issues fixed earlier today
- Backend was hitting SQLite (`unable to open database file`) because the
  container needed a clean `make dev-down && make dev-up-d`.
- Audio playback failed with `ERR_SSL_PROTOCOL_ERROR` — MinIO dev URLs
  were generated as `https://localhost:9000`. Fixed by adding
  `AWS_S3_URL_PROTOCOL=http:` to `.env.dev` / `.env.example`.

## Day 26 — Public Feed Page (2026-06-22)

### Goal
Public discovery feed of all public songs with search + ordering,
visible to everyone (no auth required).

### What I built
- `getFeed()` in api/songs.ts — hits the dedicated /feed/ endpoint
  (backend caches the default unfiltered view in Redis)
- FeedPage — search box (350ms debounce), ordering dropdown (6 options),
  responsive 1/2/3-col SongCard grid, loading/empty/error states
- "Clear search" shortcut when empty results
- Navbar "Discover" link, /feed public route

### Key decision
SongCard previously required isActive+onPlay. Made both optional (isActive
defaults to false, onPlay is a no-op if absent) so the card works in any
context — no duplicate component needed.

---

## Day 27 — Public User Profiles (2026-06-22)

### Goal
Visit any user at /users/:username to see their public profile + songs.

### What I built
- PublicProfile type (matches PublicProfileSerializer — public_song_count,
  no email)
- api/users.ts — getPublicProfile + getUserPublicSongs (real endpoints
  confirmed from urls.py)
- UserProfilePage — avatar/bio/join-date/song-count header + public song
  grid, Promise.all parallel fetch, cleanup flag (no setState after
  unmount), loading + 404 states
- SongCard owner name is now a Link to /users/:username (stopPropagation
  so it doesn't trigger play)
- /users/:username public route

### No backend changes
Backend already had PublicProfileView + UserPublicSongsView — endpoints
matched exactly.

## Day 28 — Frontend Tests (2026-06-23)

### Goal
Set up the frontend testing stack (Vitest + React Testing Library) and
write the first tests, following the same philosophy as the backend
pytest suite.

### Backend ↔ Frontend test mapping
| Backend (pytest + DRF) | Frontend (Vitest + RTL) |
|------------------------|--------------------------|
| pytest runner | Vitest runner |
| APIClient | render() + screen queries |
| mock S3/Redis | mock axios client |
| assert status_code | expect(...).toBeInTheDocument() |
| AAA pattern | AAA pattern (identical) |

### What I built
- Installed: vitest, @testing-library/react, user-event, jest-dom, jsdom
- vitest.config.ts (jsdom env, globals, setup file)
- src/test/setup.ts — afterEach cleanup + clearAllMocks (test isolation,
  like conftest.py)
- Test scripts in package.json

### Tests (15 total)
- utils/format.test.ts — formatDuration: m:ss, padding, zero, exact minute
- api/songs.test.ts — getFeed hits /feed/ with correct params, parses
  paginated payload (axios mocked)
- components/SongCard.test.tsx — title/artist/duration render, owner links
  to /users/:username, onPlay fires on click, no-crash in read-only mode
- pages/FeedPage.test.tsx — loading→songs, empty state, error state (api
  mocked, waitFor for the 350ms debounce)

### Refactor
- Extracted formatDuration from SongCard.tsx → utils/format.ts so the
  component and the test share one source of truth

### Key learning
Frontend tests simulate a USER (click/type/see text) rather than hitting
an HTTP endpoint, but the discipline is the same: mock the boundary
(axios), test observable behavior, keep tests isolated.

## Day 29 — Dockerize Frontend (2026-06-23)

### Goal
Produce a small, production-ready container image for the React frontend
and add it to docker-compose.

### Approach: multi-stage build
- Stage 1 (node:22-alpine): npm ci → npm run build → /dist
- Stage 2 (nginx:alpine): copy /dist, serve static files
- Result: ~50MB image instead of ~1GB (no node runtime or deps in prod)

### Two key gotchas learned
1. **Vite env vars are build-time, not runtime.** import.meta.env.VITE_*
   is replaced with literal strings during `npm run build`. You can't
   change the API URL by passing env to the running container — must use
   --build-arg. (For cloud, will switch to runtime config.js injection.)

2. **SPA routing + nginx.** A hard refresh on /users/faraz makes nginx
   look for that file → 404. Fixed with try_files ... /index.html so
   nginx always serves index.html and React Router handles the route.

### Files
- frontend/Dockerfile (multi-stage)
- frontend/nginx.conf (SPA fallback + immutable asset caching)
- frontend/.dockerignore (slim context, exclude node_modules/.env)
- docker-compose.yml: frontend service, build arg, port 3000:80

### Verified
- Image ~50MB
- App loads, hard refresh on deep routes works
- API calls hit configured base URL
- Hashed /assets cached immutable, index.html no-cache

### Goal
Automate frontend quality gates on every push/PR — completing Phase 3.

### Pipeline (.github/workflows/frontend-ci.yml)
Mirrors the backend ci.yml. Three gated jobs:
1. lint   — eslint + prettier --check
2. test   — vitest run + vite build (needs: lint)
3. docker — builds the Day 29 multi-stage image (needs: test)

### Design decisions
- **Mirrored backend style**: same lint→test gating so both pipelines read
  the same way (good for the portfolio).
- **Path filters (frontend/**)**: independent from backend CI — frontend
  changes don't trigger backend runs and vice versa.
- **Caching**: npm (setup-node) + Docker layers (type=gha).
- **concurrency + cancel-in-progress**: stale runs cancelled on new push.

### Gotcha
prettier --check is strict — had to run `npm run format` first since some
files weren't formatted. CI mirrors local exactly: if the 5-command local
run is green, CI is green.

### Phase 3 complete ✅ (Days 20–30)
foundation → auth → routing → player → upload → profile → feed →
user pages → tests → docker → CI.
Full React/TS frontend: tested, containerized, continuously integrated.


### Phase 4 begins: Integration & Production

### Goal
Complete the single-entry-point production stack. The base/dev/prod
compose architecture, all Dockerfiles, and nginx configs already existed.
Day 31 closed three specific gaps preventing the full stack from running.

### Architecture (why two nginx, no backend nginx)

root/nginx/nginx.conf    → edge proxy  (public :80, routing decisions)
frontend/nginx.conf      → SPA server  (internal :80, static file serving)
backend/                 → NO nginx    (gunicorn is the Python WSGI server;
                                        edge nginx is the HTTP layer)

The edge nginx is the only public-facing process. It routes:
  /api, /admin           → backend:8000 (gunicorn)
  /static, /media        → shared Docker volumes (direct disk, fast)
  /                      → frontend:80 (nginx serving React build)

### Gaps closed
1. nginx/nginx.conf only had `upstream django` routing everything to
   gunicorn. Added `upstream frontend`; split location blocks so /api +
   /admin go to backend and / goes to the React container.

2. docker-compose.prod.yml had no `frontend` service. The nginx upstream
   `frontend:80` had no container to resolve to — would have crashed.
   Added frontend service with VITE_API_BASE_URL=/api/v1.

3. Compose MERGES `ports` lists (does not replace). Base had ports:3000:80
   and 8000:8000 which leaked into prod. Moved host ports to dev override
   only. Prod stack is now fully internal behind the edge nginx.

### Key insight
VITE_API_BASE_URL=/api/v1 (no host/port) is what eliminates CORS in prod.
Both frontend and backend are served from http://localhost — one origin.
The edge nginx is what makes this possible.

### Run commands
  Prod: docker compose -f docker-compose.yml -f docker-compose.prod.yml up --build
  Dev:  docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
  Shortcut: make prod / make dev

### Magic moment
Register + login in the browser at http://localhost — zero CORS errors.
Frontend + backend share one origin behind the edge nginx. 🎯

## Day 32 — Dockerize Frontend (2026-06-24)

## Goal
Harden the edge reverse proxy and frontend nginx from "working"
(Day 31) to "production-grade": compression, caching, security
headers, connection reuse, and a proper health endpoint.

## Architecture
                     ┌─────────────────────────────┐
browser :80 ────────► │   Edge nginx (music-nginx)  │
│   the ONLY public port      │
└──────────────┬──────────────┘
┌─────────────────────────┼───────────────────────┐
▼                         ▼                        ▼
/api, /admin             /music-media/            / (everything)
backend:8000             minio:9000               frontend:80
(gunicorn)               (S3 objects)             (React SPA nginx)
│                                                  │
/static, /media  ──► served directly from shared volumes │
▼
try_files → index.html
(React Router fallback)

## Key decisions

| Decision | Rationale |
|----------|-----------|
| Two-nginx (edge + frontend) | Each service independently deployable; matches container ownership model |
| Single public port (80) | Minimal attack surface; MinIO/Redis/DB never exposed |
| MinIO proxied via `/music-media/` | Browser never talks to MinIO directly; keeps it internal |
| Keepalive upstreams | Reuse TCP to backends → lower latency |
| gzip at edge | Compress API JSON + static; ~70% payload reduction |
| `/healthz` for nginx liveness | Pure liveness, no Django load; backend has own healthcheck |

## Bug fixed
- MinIO `Host` header was `$host` (`localhost`) which breaks S3
  signature/routing. Changed to `minio:9000`.

## Verification
```bash
docker run --rm -v "$(pwd)/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:1.27-alpine nginx -t        # syntax check
make prod-up
curl -s http://localhost/healthz    # → ok
```

## Day 37 — Documentation Polish

**Goal:** Make the project interview-ready with accurate, polished docs.

- Created `docs/ARCHITECTURE.md` with Mermaid diagrams:
  system overview, auth flow, upload/stream flow, feed caching, ER model,
  and deployment topology — plus a design-decisions table.
- Finalized root `README.md`: fixed stale feature checklist (frontend done),
  added quickstart (dev + prod), API table, project structure, docs map,
  and an embedded architecture diagram.
- Enhanced `backend/README.md`: settings modules, Docker/Make workflow,
  testing + coverage, schema freeze/check, key files.
- Polished `frontend/README.md`: clean single-source doc with scripts,
  structure, and feature list.
- Verified all docs reflect the **actual** routes (`config/urls.py`,
  `music/urls.py`) and Makefile targets — no fictional commands.

  ## Day 38 — VPS Setup and Server Hardening

### Goal
Prepare a clean VPS as the first real deployment target for the Music Stream
App.

### What I did

- Prepared the VPS for production-style deployment.
- Created a non-root deploy user for application management.
- Configured SSH access for safer remote administration.
- Installed required server packages.
- Installed Docker and Docker Compose plugin.
- Verified Docker works under the deploy user.
- Prepared firewall rules for the deployment.
- Kept infrastructure services such as PostgreSQL, Redis, and MinIO internal
  to Docker.
- Documented the VPS-first deployment approach.

### Technical decisions

- Chose VPS deployment first to practice real Linux, Docker, firewall, SSH,
  and operational workflows before moving to managed cloud services.
- Used Docker Compose on the VPS to keep the deployment reproducible.
- Kept application secrets in `.env.prod`, never committed to Git.
- Kept production infra private by exposing only the reverse proxy layer.

### What I learned

- How host-level setup differs from application-level deployment.
- Why a dedicated deploy user is safer than deploying directly as root.
- Why Docker permissions and server firewall rules must be verified early.
- Why production deployment needs repeatable commands and documentation.

### Related docs

- [`deployment.md`](./deployment.md) — VPS setup and deployment flow.
- [`security.md`](./security.md) — production security highlights.
- [`env-management.md`](./env-management.md) — secrets and environment files.

### Next step

- Clone the repository on the VPS.
- Create `.env.prod`.
- Start the production stack manually over HTTP.
- Verify the deployed application through the VPS IP.

---

## Day 39 — Manual VPS Deployment over HTTP

### Goal
Deploy the full Dockerized Music Stream App manually on the VPS and verify that
the stack works over plain HTTP before adding a domain and HTTPS.

### What I did

- Cloned the project repository on the VPS.
- Created and configured `.env.prod` from `.env.prod.example`.
- Generated strong production secrets with `scripts/generate-secrets.sh`.
- Started the production stack with Docker Compose.
- Verified PostgreSQL, Redis, MinIO, backend, Celery, frontend, and nginx
  containers.
- Ran migrations and collected static files through the backend container
  startup flow.
- Verified nginx as the public entrypoint on port 80.
- Tested backend health through nginx.
- Confirmed the frontend was reachable through the VPS.
- Debugged production deployment issues from container logs.
- Improved deployment commands and documentation.

### Problems I solved

- Fixed PostgreSQL authentication issues caused by mismatched production
  database credentials.
- Resolved container name conflicts from previous failed deployment attempts.
- Cleaned stale containers and images when restarting the deployment from a
  known-good state.
- Fixed environment-variable issues where required production values were
  missing or not loaded by Docker Compose.
- Confirmed that `.env.prod` must be present and correct on the VPS before
  starting the stack.

### Technical decisions

- Kept the first real deployment HTTP-only to reduce variables during initial
  production validation.
- Kept `DJANGO_SECURE_SSL=false` until HTTPS is fully confirmed.
- Used Makefile targets and Docker Compose overlays instead of long manual
  commands where possible.
- Treated the HTTP deployment as the baseline before introducing DNS, TLS,
  and HAProxy routing.

### What I learned

- How to debug deployment failures using `docker compose ps`, logs, and health
  checks.
- Why production environment variables must be validated before containers
  start.
- Why deployment should be done in phases: HTTP first, then HTTPS.
- Why stale Docker resources can cause confusing production errors.

### Related docs

- [`deployment.md`](./deployment.md) — manual VPS deployment steps.
- [`env-management.md`](./env-management.md) — `.env.prod` and secrets.
- [`smoke-tests.md`](./smoke-tests.md) — production validation checks.
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — production service topology.

### Next step

- Add a real domain.
- Prepare Let's Encrypt certificate management.
- Add HTTPS support without breaking the existing service already using port
  443 on the VPS.

---

## Day 40 — Domain + HTTPS with Let's Encrypt and HAProxy SNI

### Goal
Add HTTPS for the Music Stream App using a real domain and Let's Encrypt, while
coexisting with another service already using public port 443 on the same VPS.

### What I did

- Designed an HTTPS deployment strategy using HAProxy SNI splitting.
- Kept HAProxy as the public listener on port 443.
- Configured the Music Stream App nginx container to terminate TLS on
  `127.0.0.1:8443`.
- Kept app nginx bound to public port 80 for Let's Encrypt HTTP-01 challenges
  and HTTP-to-HTTPS redirects.
- Added a VPS-specific Docker Compose overlay for HTTPS deployment.
- Added an nginx HTTPS template using the official nginx image's envsubst
  mechanism.
- Used `NGINX_ENVSUBST_FILTER=APP_DOMAIN` so only `APP_DOMAIN` is substituted
  and nginx runtime variables remain untouched.
- Added an empty nginx default config override to disable the plain HTTP prod
  config on the VPS.
- Added host-level certbot preparation script:
  `scripts/vps-prepare-https.sh`.
- Added first-certificate issuance script:
  `scripts/vps-issue-cert-standalone.sh`.
- Added Makefile targets for HTTPS preparation and certificate issuance.
- Improved `scripts/generate-secrets.sh` so only valid `KEY=VALUE` lines go to
  stdout and human-readable messages go to stderr.
- Updated `.env.prod.example` with clear Phase I HTTP and Phase II HTTPS
  instructions.
- Documented the full HTTPS + HAProxy SNI architecture in
  `docs/https-haproxy.md`.
- Updated README and deployment docs to reference the new HTTPS workflow.

### Architecture

Internet :80
  → App Nginx
      → Let's Encrypt HTTP-01 challenge
      → HTTP to HTTPS redirect

Internet :443
  → HAProxy in TCP mode with SNI inspection
      ├─ APP_DOMAIN → 127.0.0.1:8443 → App Nginx terminates TLS
      └─ default    → existing service

### Technical decisions

- Did not bind the app directly to public port 443 because another service is
  already using it.
- Used HAProxy in TCP mode so it routes by SNI without terminating TLS.
- Kept TLS termination inside the app nginx container.
- Managed Let's Encrypt certificates at the host level with certbot.
- Mounted `/etc/letsencrypt` read-only into nginx for certificate access.
- Created `/var/www/certbot` as the ACME webroot path.
- Used scripts for VPS HTTPS preparation instead of manual one-off commands.
- Kept the scripts idempotent so they can be safely re-run.
- Kept `DJANGO_SECURE_SSL=false` until public HTTPS is confirmed working.
- Kept the detailed command-level HTTPS guide in `docs/https-haproxy.md` so
  the journal stays focused on progress and decisions.

### Why this matters

- The app can now be served securely with a real domain.
- The VPS can host multiple HTTPS services on the same public port 443.
- The deployment matches a real-world single-VPS pattern:
  host HAProxy + host certbot + Dockerized application stack.
- Certificate management is separated from application deployment.
- The deployment process is documented, repeatable, and easier to debug.
- The project now demonstrates production deployment constraints beyond a
  simple one-app-one-server setup.

### What I learned

- How SNI allows multiple HTTPS services to share one public IP and port.
- How HAProxy can route TLS traffic in TCP mode without decrypting it.
- Why certbot and certificate directories are often managed at the host level.
- How the official nginx Docker image renders templates from
  `/etc/nginx/templates/*.template`.
- Why envsubst must be filtered to avoid accidentally replacing nginx runtime
  variables like `$host`, `$request_uri`, and `$remote_addr`.
- Why HTTPS should be enabled in phases to avoid redirect lockouts.
- Why deployment scripts should be idempotent and safe to run multiple times.

### Verification

- Confirmed Compose configuration renders expected nginx binds.
- Confirmed `APP_DOMAIN` is passed into the nginx container.
- Confirmed nginx template strategy preserves nginx runtime variables.
- Confirmed generated secrets are append-safe for `.env.prod`.
- Prepared the deployment flow for real certificate issuance and HAProxy reload
  on the VPS.
- Confirmed the HTTPS deployment guide documents DNS, certbot, nginx, HAProxy,
  verification, renewal, and troubleshooting.

### Related docs

- [`https-haproxy.md`](./https-haproxy.md) — full HTTPS + HAProxy SNI guide.
- [`deployment.md`](./deployment.md) — general VPS deployment flow.
- [`env-management.md`](./env-management.md) — production environment variables.
- [`security.md`](./security.md) — security decisions and production hardening.
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — system topology and request flows.

### Next step

- Pull the branch on the VPS.
- Set real `APP_DOMAIN` and `ACME_EMAIL` in `.env.prod`.
- Run `make vps-prepare-https`.
- Run `make vps-issue-cert`.
- Start the HTTPS stack with `make vps-up`.
- Add the HAProxy SNI route and reload HAProxy.
- Verify public HTTPS in the browser.
- Enable `DJANGO_SECURE_SSL=true` only after HTTPS works.

## Day 41 — CI/CD Auto-Deploy to VPS

### Goal
Automate deployment so every merge to `main` ships to the VPS without a
manual SSH session, while reusing the existing deploy script rather than
duplicating its logic in CI.

### What I did

- Added `.github/workflows/deploy.yml`: SSHes into the VPS on every push to
  `main` and runs the existing `scripts/deploy.sh` unchanged.
- Added `workflow_dispatch` with a `skip_pull` input for manual re-deploys
  (e.g. after rotating a secret in `.env.prod` without a new commit).
- Added an optional external health check step that verifies the public
  domain after deploy, catching HAProxy/DNS/TLS issues that `deploy.sh`'s
  own localhost-only smoke checks structurally cannot see.
- Set `concurrency: cancel-in-progress: false` so an in-flight deploy can
  never be cancelled mid-`docker compose up --build`, which could leave the
  VPS half-upgraded.
- Documented required secrets, the branch-protection prerequisite, and the
  known rollback limitation in `docs/deployment.md`.

### Technical decisions

- Did NOT rewrite `scripts/deploy.sh` or move to a registry-based
  (build-and-push-image) deploy strategy. The existing build-in-place
  approach with pre-flight port checks, health polling, and nginx refresh
  already works and is well-tested manually across Days 38-40 — CI just
  needed to call it.
- Chose "push to main triggers deploy" over "workflow_run gating on two
  separate CI workflows" — simpler to read and reason about, at the cost of
  depending on branch protection actually being configured to require
  Backend CI + Frontend CI before merge. Documented this dependency clearly
  since it's easy to silently disable by accident.
- Used a GitHub Actions "Variable" (not secret) for the public health-check
  URL since it's not sensitive data.

### What I learned

- The difference between GitHub Secrets and Variables, and when a value
  (like a public URL) belongs in the latter.
- Why `cancel-in-progress: false` matters specifically for deploy workflows,
  as opposed to CI/test workflows where cancelling a superseded run is safe.
- Why a localhost-only health check (inside the VPS) and a public health
  check (over the internet) catch different failure classes — the first
  proves the app is running; the second proves the whole edge path
  (DNS → HAProxy → TLS → nginx → app) works.

### Related docs

- [`deployment.md`](./deployment.md) — full CI/CD auto-deploy flow.
- [`https-haproxy.md`](./https-haproxy.md) — the edge path the public
  health check exercises.

## Day 42 — Structured Logging + Observability (Prometheus, Grafana, node_exporter, cAdvisor)

### Goal
Add production-grade observability so the app's health, performance, and resource usage are visible without exposing any monitoring surface to the public internet.

### What I did
- Instrumented the Django app with `django-prometheus` for request rate, latency, and status-code metrics.
- Added `node_exporter` for host-level metrics (CPU, RAM, disk) and `cAdvisor` for per-container metrics.
- Added a `docker-compose.monitoring.yml` overlay so the monitoring stack can run alongside the app without being part of the default `docker-compose.yml`.
- Set up Prometheus to scrape all targets every 15s.
- Provisioned Grafana as code: a `prometheus` datasource and an `app-overview` dashboard under `monitoring/grafana/provisioning/`, so dashboards exist from first boot without manual clicking.
- Added Prometheus alert rules (`monitoring/prometheus/rules/alerts.yml`) covering: target down, high HTTP 5xx rate, high disk usage, high memory usage.
- Converted production logging to structured, single-line JSON, with a per-request `X-Request-ID` propagated across logs and response headers for tracing.
- Configured Docker's `json-file` log driver with rotation (10MB × 3 files per container) to prevent unbounded log growth.
- Turned `/api/health/` into a real readiness check — verifies DB and cache, returns `503` when degraded instead of always `200` — so uptime monitors and load balancers get a meaningful signal.
- Locked down monitoring access: Prometheus (`:9090`) and Grafana (`:3000`) bind to `127.0.0.1` only, reached via SSH tunnel; `/metrics` returns `404` at the public Nginx edge.
- Added `scripts/ops/https-time-sync.sh` as a fallback time-sync mechanism for restricted networks where NTP's UDP/123 is blocked, using HTTPS `Date` headers over TCP/443 instead.
- Documented all of this in `docs/monitoring.md` and `docs/operations.md`.

### Technical decisions
- Kept monitoring on a separate Compose overlay (`docker-compose.monitoring.yml`) rather than folding it into the main stack, so it can be started/stopped independently (`make monitoring-up` / `make monitoring-down`) without touching the running app.
- Chose SSH tunnel access over exposing Grafana/Prometheus publicly, even behind auth — smaller attack surface for a single-operator portfolio deployment.
- Made `/api/health/` a real dependency check (DB + cache) rather than a static "I'm alive" response, since the whole point of a readiness probe is catching *degraded*, not just *dead*.
- Provisioned Grafana dashboards as code instead of manually building them in the UI, so the dashboard is reproducible and versioned like everything else.
- Treated the HTTPS-based time-sync fallback as a documented exception, not the default — proper NTP/Chrony remains the primary mechanism; the fallback only exists for restricted-network edge cases.

### Why this matters
- The app can now answer "is it actually healthy" with real dependency checks, not just "is the process running."
- Metrics + logs + request tracing together mean a production issue can be diagnosed without SSHing in blind and grepping raw logs.
- Keeping the observability surface private-by-default demonstrates a security-conscious default, not just "monitoring exists."

### What I learned
- The difference between a liveness check (process is up) and a readiness check (dependencies are actually healthy) — and why load balancers care about the second one.
- How Prometheus scrape targets, exporters, and Grafana provisioning-as-code fit together as one coherent stack.
- Why structured JSON logs with a request ID matter once you have more than one moving part to correlate across.
- Why log rotation has to be configured explicitly — Docker's default `json-file` driver doesn't rotate on its own.

### Related docs
- [`monitoring.md`](./monitoring.md) — full metrics, logging, and alerting setup.
- [`operations.md`](./operations.md) — fallback HTTPS time synchronization.
- [`security.md`](./security.md) — why monitoring endpoints stay private.

---

## Day 43 — Database and Media Backups

### Goal
Add a real backup and disaster-recovery system for both PostgreSQL data and MinIO/S3 media objects, with retention, verification, and optional offsite copies.

### What I did
- Built `scripts/backup/backup.sh` (full backup) plus standalone `backup-db.sh` and `backup-media.sh` for targeted backups.
- Database backups use `pg_dump` in custom format, gzip-compressed.
- Media backups mirror the MinIO/S3 `music-media` bucket via `mc` (MinIO Client) through the object-storage API rather than touching MinIO's internal data directory directly, then archive with `tar.gz`.
- Generated a SHA256 checksum for every backup artifact, plus gzip integrity verification.
- Implemented a retention policy: keep 7 daily backups + 4 weekly backups, with `scripts/backup/prune.sh` removing anything older.
- Added "latest backup" symlinks for convenience when scripting restores.
- Built `restore-db.sh` and `restore-media.sh`, both requiring explicit confirmation before overwriting existing data.
- Added `scripts/ops/install-backups.sh` to install a systemd timer for daily scheduled backups on the VPS (with persistent execution, so a missed run — e.g. VPS was off — still catches up).
- Added two optional offsite strategies: `upload-remote.sh` (S3-compatible storage, disabled by default, opt-in via `BACKUP_REMOTE_UPLOAD=true`) and `upload-rsync.sh` (manual-only push to a secondary VPS over SSH — deliberately never runs automatically).
- Made the backup root configurable via `BACKUP_ROOT`, so backups can target a different disk or mounted volume instead of the default `./backups/`.
- Verified locally: successful DB backup, successful media backup from the `music-media` bucket, backup listing, tar archive inspection, and SHA256 verification for both artifact types.
- Documented everything in `docs/backups.md`.

### Technical decisions
- Backed up media through the object-storage API (`mc mirror`) instead of reaching into MinIO's internal storage directly — keeps the backup mechanism portable to real S3 later, since Day 44 is an AWS/cloud migration.
- Kept the rsync-to-secondary-VPS path strictly manual (`make backup-rsync`), never automatic — an accidental automated sync of a corrupted backup to your only offsite copy defeats the purpose of having one.
- Used a systemd timer instead of cron for scheduling, specifically for persistent/catch-up execution semantics after a missed run.
- Required explicit confirmation in both restore scripts — a backup system that makes destructive restores easy to trigger by accident is worse than not automating restores at all.
- Made offsite S3 upload opt-in/disabled by default, so the backup system works out of the box locally without requiring external credentials just to test it.

### Why this matters
- The project now has an actual disaster-recovery story, not just "backups exist somewhere" — retention, checksums, and restore confirmation all point at RPO/RTO thinking, not just running `pg_dump` once.
- Two independent offsite options (S3-compatible + manual rsync) demonstrate the 3-2-1 backup principle rather than a single point of failure on the same VPS being backed up.

### What I learned
- Why backing up object storage through its API is more portable than copying MinIO's internal files directly.
- Why checksums matter as much as the backup itself — a corrupted backup that "exists" is worse than knowing you have none.
- Why systemd timers, not cron, are the better fit when a missed scheduled run still needs to happen later.
- Why irreversible operations (restore) should require a deliberate, explicit confirmation step rather than a single flag.

### Related docs
- [`backups.md`](./backups.md) — full backup, restore, retention, and offsite documentation.

## Day 44 — AWS / Cloud Migration Intro

**Goal:** Demonstrate cloud-migration readiness without a full AWS deployment.

**Delivered:**
- `docs/cloud-migration.md` — service mapping (S3, RDS, ElastiCache, ECS),
  migration order, cost awareness, and interview summary.
- `scripts/cloud/s3-smoke.sh` + `make s3-smoke` — proves the storage layer works
  against both MinIO and real AWS S3 via the same S3 API (config-only swap).
- `.env.prod.example` — documented MinIO vs. real AWS S3 configuration.
- README — Cloud Migration Readiness section.

**Key insight:** The two hardest layers to migrate (storage, database) already
use portable interfaces. Storage → S3 is config-only (validated). Database → RDS
reuses the Day 43 `pg_dump` artifacts. The biggest remaining step (Compose → ECS)
is an infrastructure-as-code exercise, not an app rewrite.

**Validated:** `make s3-smoke` passed against local MinIO.
