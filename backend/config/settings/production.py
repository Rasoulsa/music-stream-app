"""
Production settings.
"""

from .base import *  # noqa: F401,F403
from .base import BASE_DIR, env  # noqa: F401

DEBUG = False

# Refuse to start in production with the unsafe default key
if SECRET_KEY == "unsafe-dev-secret-key":  # noqa: F405
    raise ValueError("DJANGO_SECRET_KEY must be set to a secure value in production.")

# Allowed hosts must come from the environment
ALLOWED_HOSTS = env.list(  # noqa: F405
    "DJANGO_ALLOWED_HOSTS",
    default=[],
)

# ----------------------------------------------------------------------
# Database
# NOTE: Still SQLite for Day 7-8. Switches to PostgreSQL on Day 9.
# ----------------------------------------------------------------------
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": "/app/data/db.sqlite3",
    }
}

# Static files (served by WhiteNoise)
STATIC_ROOT = BASE_DIR / "staticfiles"  # noqa: F405

# ----------------------------------------------------------------------
# Production security hardening
#
# These are ENABLED for real production (HTTPS behind nginx),
# but DISABLED for local Docker testing over plain HTTP.
# Controlled by the DJANGO_SECURE_SSL env variable.
# ----------------------------------------------------------------------
SECURE_SSL = env.bool("DJANGO_SECURE_SSL", default=True)  # noqa: F405

if SECURE_SSL:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
else:
    # Local Docker testing over HTTP — relax HTTPS enforcement
    SECURE_SSL_REDIRECT = False
    SESSION_COOKIE_SECURE = False
    CSRF_COOKIE_SECURE = False
    SECURE_CONTENT_TYPE_NOSNIFF = True  # safe to keep on

# CORS origins should come from environment in production
CORS_ALLOWED_ORIGINS = env.list(  # noqa: F405
    "CORS_ALLOWED_ORIGINS",
    default=[],
)
