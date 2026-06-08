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
