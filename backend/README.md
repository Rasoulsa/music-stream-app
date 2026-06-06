# Backend — Music Stream App

Django + Django REST Framework backend.

## Requirements

- Python 3.13
- uv

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
- `config/settings/prod.py` — production

Local commands default to `dev`. WSGI/ASGI default to `prod`.


## API Documentation

Interactive API docs are available when the server is running:

- Swagger UI: http://127.0.0.1:8000/api/docs/
- ReDoc: http://127.0.0.1:8000/api/redoc/
- OpenAPI schema: http://127.0.0.1:8000/api/schema/

Generated automatically with drf-spectacular (OpenAPI 3).
