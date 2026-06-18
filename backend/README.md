# Backend — Music Stream App

Django + Django REST Framework backend.

## Requirements

- Python 3.13
- uv
- Docker optional, for containerized runs

## Setup

Install dependencies:

```bash
uv sync
```

## Running

Start the development server:

```bash
uv run python manage.py runserver
```

API health check:

```text
http://127.0.0.1:8000/api/health/
```


## Testing

Run the test suite:

```bash
uv run pytest
```


## Linting & Formatting

```bash
uv run ruff check .
uv run ruff format .
```

## Settings

Settings are split by environment:

- `config/settings/base.py` — shared
- `config/settings/dev.py` — development
- `config/settings/production.py` — production

Local commands default to `dev`. WSGI/ASGI default to `production`.

## API Documentation

Interactive API docs are available when the server is running:

- Swagger UI: http://127.0.0.1:8000/api/docs/
- ReDoc: http://127.0.0.1:8000/api/redoc/
- OpenAPI schema: http://127.0.0.1:8000/api/schema/

Generated automatically with drf-spectacular.

## Running with Docker

The backend can run inside a Docker container using a multi-stage image built with `uv`.

### Build the image

```bash
docker build -t music-stream-backend .
```

### Set up the environment file

```bash
cp .env.docker.example .env.docker
# then edit .env.docker with your values
```

### Run the container

```bash
docker run --rm --name music-stream-backend -p 8000:8000 --env-file .env.docker music-stream-backend
```

The API is available at:

- Health: http://localhost:8000/api/health/
- Docs: http://localhost:8000/api/docs/
- Songs: http://localhost:8000/api/songs/

### Stop the container

If the container is running in the current terminal, stop it with:

```bash
Ctrl + C
```

If it is running in another terminal or in detached mode:

```bash
docker stop music-stream-backend
```

### Run migrations inside the container, if needed

Migrations run automatically when the container starts. For manual debugging:

```bash
docker exec music-stream-backend python manage.py migrate
```

### Troubleshooting

If port 8000 is already in use:

```bash
lsof -i :8000
docker ps
docker stop $(docker ps -q)
```

Or run the container on another host port:

```bash
docker run --rm --name music-stream-backend -p 8001:8000 --env-file .env.docker music-stream-backend
```

Then use:

```text
http://localhost:8001/api/health/
```

### Docker notes

- The image uses a multi-stage Docker build.
- Dependencies are installed with `uv`.
- The application runs with Gunicorn, not Django's development server.
- The container runs as a non-root `app` user.
- SQLite is stored in `/app/data` for local Docker testing.
- PostgreSQL will be added later with Docker Compose.


## Running with Docker Compose

The full backend stack (Django + PostgreSQL) can be started with a single command using Docker Compose.

### Set up the environment file

```bash
cp backend/.env.docker.example backend/.env.docker
# then edit backend/.env.docker with your values
```

### Start the stack

From the project root:

```bash
docker compose up --build
```

This starts two services:

- `db` — PostgreSQL 16 with a persistent volume
- `backend` — Django backend served with Gunicorn

The backend waits until the database is healthy before starting.

The API is available at:

- Health: http://localhost:8000/api/health/
- Docs: http://localhost:8000/api/docs/
- Songs: http://localhost:8000/api/songs/

### Run in the background

```bash
docker compose up --build -d
```

### Stop the stack

Stop and remove the containers, but keep the database volume:

```bash
docker compose down
```

Stop and also delete the database volume (this wipes all data):

```bash
docker compose down -v
```

### Useful commands

```bash
docker compose ps                       # list services
docker compose logs -f                  # follow all logs
docker compose logs -f backend          # follow backend logs
docker compose exec backend bash        # shell inside the backend
docker compose exec db psql -U music    # open the PostgreSQL shell
docker compose restart backend          # restart the backend
```

### Create a superuser

```bash
docker compose exec backend python manage.py createsuperuser
```

### Data persistence

PostgreSQL data is stored in a named Docker volume (`postgres_data`).
Data survives `docker compose down` and is only removed when you run
`docker compose down -v`.

### Notes

- Migrations run automatically when the backend container starts.
- The backend runs with Gunicorn, not Django's development server.
- The backend connects to PostgreSQL using the `db` service name.
- Database credentials are provided through `backend/.env.docker`.
- The real `.env.docker` file is kept out of Git.


## Authentication

The API uses JWT authentication.

### Register

```bash
POST /api/auth/register/
{ "username": "...", "email": "...", "password": "..." }
```

### Login

```bash
POST /api/auth/login/
{ "username": "...", "password": "..." }
```

Returns `access` and `refresh` tokens.

### Use the token

Add this header to authenticated requests:

```text
Authorization: Bearer <access_token>
```

### Refresh the token

```bash
POST /api/auth/refresh/
{ "refresh": "<refresh_token>" }
```

## Song ownership and visibility

- Each song belongs to the user who created it.
- Songs can be public or private (`is_public`).
- Anonymous users see only public songs.
- Authenticated users see public songs plus their own private songs.
- Only the owner can edit or delete their songs.


### Profiles & Feed
- `GET/PATCH /api/users/me/` — manage your own profile (auth required)
- `GET /api/users/{username}/` — public profile
- `GET /api/users/{username}/songs/` — a user's public songs
- `GET /api/songs/mine/` — your songs, public + private (auth required)
- `GET /api/feed/` — public feed of all public songs (paginated, filterable)


## Continuous Integration

CI runs on every push and pull request:

1. **Lint** — Ruff lint + format checks.
2. **Test** — runs against PostgreSQL 16 (matching production):
   - applies migrations
   - runs the full pytest suite

Tests use a dedicated `config/settings/ci.py` configuration.

See the [root README](../README.md) for build status and coverage badges.
