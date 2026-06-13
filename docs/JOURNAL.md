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
