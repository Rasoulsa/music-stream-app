"""
Production settings.

Security model:
  - DEBUG is always False
  - SECRET_KEY must be strong (≥50 chars, no known placeholder values)
  - ALLOWED_HOSTS must be explicitly set
  - HTTPS hardening controlled by DJANGO_SECURE_SSL env var
    (false for local Docker testing, true for real production with TLS)
"""

from .base import *  # noqa: F401,F403
from .base import env  # noqa: F401

# -----------------------------------------------------------------------------
# Always off in production
# -----------------------------------------------------------------------------
DEBUG = False

# -----------------------------------------------------------------------------
# Fail-loud guard
# -----------------------------------------------------------------------------
_INSECURE_KEYS = {
    "",
    "unsafe-dev-secret-key",
    "CHANGE_ME_min_50_chars",
    "dev-local-insecure-key-do-not-use-in-prod",
    "dev-docker-insecure-key-not-for-production",
    "docker-local-test-key-change-me-not-for-real-prod",
}

_secret = SECRET_KEY  # noqa: F405

if _secret in _INSECURE_KEYS:
    raise ValueError(
        "\n"
        "FATAL: DJANGO_SECRET_KEY is a known placeholder or dev key.\n"
        "Run:   ./scripts/generate-secrets.sh\n"
        "Then:  paste the generated DJANGO_SECRET_KEY into .env.prod\n"
    )

if len(_secret) < 50:
    raise ValueError(
        f"\n"
        f"FATAL: DJANGO_SECRET_KEY is too short ({len(_secret)} chars, minimum 50).\n"
        f"Run:   ./scripts/generate-secrets.sh\n"
        f"Then:  paste the generated DJANGO_SECRET_KEY into .env.prod\n"
    )

_INSECURE_SUBSTRINGS = ("insecure", "change_me", "changeme", "change-me", "placeholder")
if any(s in _secret.lower() for s in _INSECURE_SUBSTRINGS):
    raise ValueError(
        "\n"
        "FATAL: DJANGO_SECRET_KEY contains a suspicious substring.\n"
        "Run:   ./scripts/generate-secrets.sh\n"
    )

# -----------------------------------------------------------------------------
# Allowed hosts
# -----------------------------------------------------------------------------
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=[])  # noqa: F405

if not ALLOWED_HOSTS:
    raise ValueError(
        "\n"
        "FATAL: DJANGO_ALLOWED_HOSTS is empty in production.\n"
        "Set it in .env.prod, e.g.: DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1\n"
    )

if "*" in ALLOWED_HOSTS:
    raise ValueError(
        "\n"
        "FATAL: DJANGO_ALLOWED_HOSTS contains '*' — not safe in production.\n"
        "Set explicit hostnames in .env.prod.\n"
    )

# -----------------------------------------------------------------------------
# Database (PostgreSQL)
# -----------------------------------------------------------------------------
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": env("POSTGRES_DB"),  # noqa: F405
        "USER": env("POSTGRES_USER"),  # noqa: F405
        "PASSWORD": env("POSTGRES_PASSWORD"),  # noqa: F405
        "HOST": env("POSTGRES_HOST", default="db"),  # noqa: F405
        "PORT": env("POSTGRES_PORT", default="5432"),  # noqa: F405
        "CONN_MAX_AGE": 60,  # reuse DB connections for 60s (performance)
    }
}

# -----------------------------------------------------------------------------
# Static & media
# -----------------------------------------------------------------------------
#
# STATIC_ROOT, USE_S3 / MinIO, and media are defined in base.py.
# No overrides needed here.
#

# -----------------------------------------------------------------------------
# Production security hardening
# -----------------------------------------------------------------------------
#
# DJANGO_SECURE_SSL controls HTTPS-dependent settings:
#   false → local Docker testing over plain HTTP  (current: Days 31-37)
#   true  → real HTTPS behind nginx + Let's Encrypt (Day 40+)
#
SECURE_SSL = env.bool("DJANGO_SECURE_SSL", default=True)  # noqa: F405

# Always-on security headers (HTTP and HTTPS)
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True

# -----------------------------------------------------------------------------
# CSRF trusted origins
# -----------------------------------------------------------------------------
# Required so Django admin / session-based POSTs work over HTTPS behind the
# HAProxy → Nginx proxy chain. Must include the scheme, e.g.:
#   CSRF_TRUSTED_ORIGINS=https://my.domain.com
CSRF_TRUSTED_ORIGINS = env.list(  # noqa: F405
    "CSRF_TRUSTED_ORIGINS",
    default=[],
)

if SECURE_SSL:
    # HTTP→HTTPS redirect is handled by Nginx on :80 (see nginx config).
    # We keep Django's redirect OFF to avoid double-redirect/loops behind
    # the HAProxy SNI passthrough + Nginx TLS termination chain.
    SECURE_SSL_REDIRECT = False

    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31_536_000  # 1 year
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
else:
    # Plain HTTP (local prod testing) — cookies still work, just not
    # marked Secure so the browser doesn't block them over HTTP.
    SECURE_SSL_REDIRECT = False
    SESSION_COOKIE_SECURE = False
    CSRF_COOKIE_SECURE = False

# -----------------------------------------------------------------------------
# CORS
# -----------------------------------------------------------------------------
CORS_ALLOWED_ORIGINS = env.list(  # noqa: F405
    "CORS_ALLOWED_ORIGINS",
    default=["https://yourdomain.com"],
)

# -----------------------------------------------------------------------------
# Logging → stdout (Docker / systemd captures it)
# -----------------------------------------------------------------------------
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
