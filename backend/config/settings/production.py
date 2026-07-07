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
# Silence system checks that are intentionally handled at the nginx/proxy layer
# -----------------------------------------------------------------------------
#
# These security headers are set by the Nginx edge proxy, not Django:
#   W002 — X-Frame-Options       → nginx: add_header X-Frame-Options DENY
#   W006 — X-Content-Type-Options → nginx: add_header X-Content-Type-Options nosniff
#   W022 — Referrer-Policy        → nginx: add_header Referrer-Policy ...
#
# Setting them in Django would create duplicate headers on proxied responses.
# Silencing here documents this is a deliberate architectural decision.
SILENCED_SYSTEM_CHECKS = [
    "security.W002",
    "security.W006",
    "security.W022",
]

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
#   false → local Docker testing over plain HTTP
#   true  → real HTTPS behind HAProxy + Nginx + Let's Encrypt
#
SECURE_SSL = env.bool("DJANGO_SECURE_SSL", default=True)  # noqa: F405

# Cookie hardening remains Django's responsibility.
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True

# Public HTTP security headers are owned by the production Nginx edge proxy.
#
# Reason:
#   Browser → HAProxy → Nginx → Django
#
# Nginx is the public edge and can apply consistent headers to frontend, API,
# static, media, and proxied object-storage responses. Django sits behind Nginx,
# so emitting the same headers here creates duplicate response headers.
SECURE_CONTENT_TYPE_NOSNIFF = False
SECURE_REFERRER_POLICY = None

SECURE_HSTS_SECONDS = 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = False
SECURE_HSTS_PRELOAD = False

# X-Frame-Options is also emitted by Nginx.
# Remove Django's clickjacking middleware in production to avoid duplicate
# X-Frame-Options headers on proxied API/admin responses.
MIDDLEWARE = [  # noqa: F405
    middleware
    for middleware in MIDDLEWARE  # noqa: F405
    if middleware != "django.middleware.clickjacking.XFrameOptionsMiddleware"
]

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
    # HTTP→HTTPS redirect is handled by Nginx on :80.
    # Keep Django's redirect OFF to avoid double-redirect/loops behind
    # the HAProxy SNI passthrough + Nginx TLS termination chain.
    SECURE_SSL_REDIRECT = False

    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
else:
    # Plain HTTP local production-style testing.
    # Cookies must not be marked Secure, otherwise browsers block them over HTTP.
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
# Logging → structured JSON to stdout (Docker captures it)
# -----------------------------------------------------------------------------
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "filters": {
        "request_id": {
            "()": "config.logging.RequestIDFilter",
        },
    },
    "formatters": {
        "json": {
            "()": "config.logging.JSONFormatter",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "json",
            "filters": ["request_id"],
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
        "django.request": {
            "handlers": ["console"],
            "level": "WARNING",
            "propagate": False,
        },
        "celery": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": False,
        },
    },
}
