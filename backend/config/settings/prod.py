"""
Production settings.
"""

from .base import *  # noqa: F401,F403

DEBUG = False

# Refuse to start in production with the unsafe default key
if SECRET_KEY == "unsafe-dev-secret-key":  # noqa: F405
    raise ValueError("DJANGO_SECRET_KEY must be set to a secure value in production.")

# Production security hardening
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True

# CORS origins should come from environment in production
CORS_ALLOWED_ORIGINS = env.list(  # noqa: F405
    "CORS_ALLOWED_ORIGINS",
    default=[],
)
