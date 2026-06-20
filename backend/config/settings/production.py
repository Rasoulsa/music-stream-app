"""
Production settings.
"""

from .base import *  # noqa: F401,F403
from .base import env  # noqa: F401

DEBUG = False

# Refuse to start in production with the unsafe default key
if SECRET_KEY == "unsafe-dev-secret-key":  # noqa: F405
    raise ValueError("DJANGO_SECRET_KEY must be set to a secure value in production.")

# Allowed hosts must come from the environment
ALLOWED_HOSTS = env.list(  # noqa: F405
    "DJANGO_ALLOWED_HOSTS",
    default=[],
)

# Trusted origins for CSRF when posting through the reverse proxy (Nginx)
CSRF_TRUSTED_ORIGINS = env.list(  # noqa: F405
    "CSRF_TRUSTED_ORIGINS",
    default=[],
)

# ----------------------------------------------------------------------
# Database (PostgreSQL)
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# Static & media
# STATIC_ROOT, SECURE_PROXY_SSL_HEADER, USE_X_FORWARDED_HOST, and media
# (USE_S3 / MinIO) are all already defined in base.py — no overrides here.
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Production security hardening
#
# ENABLED for real production (HTTPS behind Nginx),
# DISABLED for local Docker testing over plain HTTP.
# Controlled by the DJANGO_SECURE_SSL env variable.
# ----------------------------------------------------------------------
SECURE_SSL = env.bool("DJANGO_SECURE_SSL", default=True)  # noqa: F405

# Always-safe headers (regardless of HTTPS)
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True

if SECURE_SSL:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
else:
    SECURE_SSL_REDIRECT = False
    SESSION_COOKIE_SECURE = False
    CSRF_COOKIE_SECURE = False

# ----------------------------------------------------------------------
# CORS — origins from environment in production
# ----------------------------------------------------------------------
CORS_ALLOWED_ORIGINS = env.list(  # noqa: F405
    "CORS_ALLOWED_ORIGINS",
    default=[],
)

# ----------------------------------------------------------------------
# Logging to stdout (Docker captures it)
# ----------------------------------------------------------------------
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {name} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}
