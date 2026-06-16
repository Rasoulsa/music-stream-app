# ---------- Stage 1: Builder ----------
# Use the official uv image which includes uv + Python 3.13
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

# uv environment settings for reproducible, fast builds
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Install dependencies first (cached layer) using only lock + project files
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Now copy the rest of the application code
COPY . .

# Install the project itself
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev


# ---------- Stage 2: Runtime ----------
FROM python:3.13-slim-bookworm AS runtime

# Create a non-root user for security
RUN groupadd --system app \
    && useradd --system --gid app --create-home --home-dir /home/app app

# Runtime environment
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Copy the built virtual environment and app from the builder stage
COPY --from=builder --chown=app:app /app /app

# Create a writable directory for the SQLite database and media,
# owned by the non-root user
RUN mkdir -p /app/data /app/media && chown -R app:app /app/data /app/media

# Switch to the non-root user
USER app

# Expose the port Gunicorn will listen on
EXPOSE 8000

# Container-level health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health/')" || exit 1

# Migrate, then start Gunicorn with a writable temp dir
CMD ["sh", "-c", "python manage.py migrate --noinput && gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 3 --worker-tmp-dir /dev/shm"]
