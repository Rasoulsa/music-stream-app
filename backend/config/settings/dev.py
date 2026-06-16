"""
Development settings.
"""

import os

from .base import *  # noqa: F401,F403

DEBUG = True

ALLOWED_HOSTS = ["localhost", "127.0.0.1", "0.0.0.0"]

# Allow the React dev server during development
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
]

# Show the browsable API in development for easier testing
REST_FRAMEWORK["DEFAULT_RENDERER_CLASSES"] = [  # noqa: F405
    "rest_framework.renderers.JSONRenderer",
    "rest_framework.renderers.BrowsableAPIRenderer",
]

# ------------------------------------------------------------------
# Database
# Local dev  → SQLite  (fast, no Docker needed)
# Docker dev → PostgreSQL (matches production)
# Controlled by USE_DOCKER env var:
#   .env             → USE_DOCKER=false  (local)
#   docker-compose   → USE_DOCKER=true   (Docker)
# ------------------------------------------------------------------
if os.environ.get("USE_DOCKER", "false").lower() == "true":
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": env("POSTGRES_DB"),  # noqa: F405
            "USER": env("POSTGRES_USER"),  # noqa: F405
            "PASSWORD": env("POSTGRES_PASSWORD"),  # noqa: F405
            "HOST": env("POSTGRES_HOST", default="db"),  # noqa: F405
            "PORT": env("POSTGRES_PORT", default="5432"),  # noqa: F405
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",  # noqa: F405
        }
    }
