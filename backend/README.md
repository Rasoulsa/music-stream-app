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
