"""
Base settings shared across all environments.
"""

from datetime import timedelta
from pathlib import Path

import environ

# BASE_DIR points to the backend/ folder
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Initialize environment reader
env = environ.Env(
    DEBUG=(bool, False),
)

# Read the .env file located at the project root (one level above backend/)
environ.Env.read_env(BASE_DIR.parent / ".env")

# -----------------------------------------------------------------------------
# Core security settings
# -----------------------------------------------------------------------------
SECRET_KEY = env("DJANGO_SECRET_KEY", default="unsafe-dev-secret-key")

DEBUG = env.bool("DEBUG", default=False)

ALLOWED_HOSTS = env.list(
    "DJANGO_ALLOWED_HOSTS",
    default=["localhost", "127.0.0.1"],
)

# -----------------------------------------------------------------------------
# Applications
# -----------------------------------------------------------------------------
DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "drf_spectacular",
    "django_filters",
]

LOCAL_APPS = [
    "music",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# -----------------------------------------------------------------------------
# Middleware
# -----------------------------------------------------------------------------
MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# -----------------------------------------------------------------------------
# Nginx
# -----------------------------------------------------------------------------
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------
# Default to SQLite for easy local dev.
# PostgreSQL via Docker will be configured on a later day.
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

# -----------------------------------------------------------------------------
# Password validation
# -----------------------------------------------------------------------------
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation."
        "UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

# -----------------------------------------------------------------------------
# Internationalization
# -----------------------------------------------------------------------------
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# -----------------------------------------------------------------------------
# Static files
# -----------------------------------------------------------------------------
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# -----------------------------------------------------------------------------
# Media files / Object Storage (django-storages + S3/MinIO)
# -----------------------------------------------------------------------------
# USE_S3=false → local filesystem (fast local dev, no MinIO needed)
# USE_S3=true  → S3-compatible storage (MinIO in Docker, AWS S3 in production)
# Switching environments requires ONLY env vars — no code changes.
# -----------------------------------------------------------------------------
USE_S3 = env.bool("USE_S3", default=False)

if USE_S3:
    AWS_ACCESS_KEY_ID = env("AWS_ACCESS_KEY_ID")
    AWS_SECRET_ACCESS_KEY = env("AWS_SECRET_ACCESS_KEY")
    AWS_STORAGE_BUCKET_NAME = env("AWS_STORAGE_BUCKET_NAME")
    AWS_S3_ENDPOINT_URL = env("AWS_S3_ENDPOINT_URL")
    AWS_S3_CUSTOM_DOMAIN = env("AWS_S3_CUSTOM_DOMAIN")
    AWS_S3_REGION_NAME = env("AWS_S3_REGION_NAME", default="us-east-1")
    AWS_S3_USE_SSL = env.bool("AWS_S3_USE_SSL", default=False)
    AWS_S3_URL_PROTOCOL = env("AWS_S3_URL_PROTOCOL", default="http:")

    AWS_S3_OBJECT_PARAMETERS = {"CacheControl": "max-age=86400"}
    AWS_DEFAULT_ACL = None
    AWS_QUERYSTRING_AUTH = False  # public-read URLs (no signed query string)

    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.s3.S3Storage",
        },
        "staticfiles": {
            "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
        },
    }

    MEDIA_URL = f"http://{AWS_S3_CUSTOM_DOMAIN}/"
else:
    STORAGES = {
        "default": {
            "BACKEND": "django.core.files.storage.FileSystemStorage",
        },
        "staticfiles": {
            "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
        },
    }
    MEDIA_URL = "media/"
    MEDIA_ROOT = BASE_DIR / "media"


# ------------------------------------------------------------------
# Cache (Redis if REDIS_URL is set, else local-memory fallback)
# ------------------------------------------------------------------
REDIS_URL = env("REDIS_URL", default="")

if REDIS_URL:
    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": REDIS_URL,
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
            },
            "KEY_PREFIX": "music",
            "TIMEOUT": 300,  # default 5 minutes
        }
    }
else:
    # Local dev fallback — no Redis needed
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "music-locmem",
        }
    }


# -----------------------------------------------------------------------------
# Celery (background tasks)
# -----------------------------------------------------------------------------
# Broker  → Redis /0
# Backend → Redis /2
#
# CELERY_TASK_ALWAYS_EAGER switch:
#   true  → tasks run inline, in-process (local dev & tests, no worker needed)
#   false → tasks go to Redis, processed by a real async worker (Docker / prod)
# -----------------------------------------------------------------------------
CELERY_BROKER_URL = env("CELERY_BROKER_URL", default="redis://localhost:6379/0")
CELERY_RESULT_BACKEND = env("CELERY_RESULT_BACKEND", default="redis://localhost:6379/2")
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_TIMEZONE = "UTC"
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 300  # hard kill after 5 min
CELERY_TASK_SOFT_TIME_LIMIT = 270  # graceful warning at 4.5 min

CELERY_TASK_ALWAYS_EAGER = env.bool("CELERY_TASK_ALWAYS_EAGER", default=True)
CELERY_TASK_EAGER_PROPAGATES = True

# -----------------------------------------------------------------------------
# Django REST Framework
# -----------------------------------------------------------------------------
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ),
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],
    "DEFAULT_PAGINATION_CLASS": ("rest_framework.pagination.PageNumberPagination"),
    "PAGE_SIZE": 20,
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_FILTER_BACKENDS": [
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ],
    # ── Throttling ──────────────────────────────────
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "30/min",
        "user": "120/min",
        "login": "5/min",
        "register": "5/min",
        "upload": "10/min",
    },
}

# -----------------------------------------------------------------------------
# CORS
# -----------------------------------------------------------------------------
# Never use CORS_ALLOW_ALL_ORIGINS=True in production.
CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=["http://localhost", "http://127.0.0.1"],
)
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ["DELETE", "GET", "OPTIONS", "PATCH", "POST", "PUT"]
CORS_ALLOW_HEADERS = [
    "accept",
    "authorization",
    "content-type",
    "origin",
    "x-csrftoken",
    "x-requested-with",
]

# -----------------------------------------------------------------------------
# API Documentation (drf-spectacular / OpenAPI 3)
# -----------------------------------------------------------------------------
SPECTACULAR_SETTINGS = {
    "TITLE": "Music Stream App API",
    "DESCRIPTION": (
        "API for a full-stack dockerized music streaming application. "
        "Built with Django, Django REST Framework, and OpenAPI 3. "
        "Supports user auth, song upload, async audio processing, "
        "filtering, and S3-backed media storage."
    ),
    # Frozen at v1.0.0 — bump only when the API contract intentionally changes.
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    # Tells Spectacular our resource endpoints live under /api/v1/.
    # Keeps version prefix out of operation IDs and groups paths cleanly.
    "SCHEMA_PATH_PREFIX": r"/api/v[0-9]+",
    "COMPONENT_SPLIT_REQUEST": True,
    "SORT_OPERATIONS": False,
    "SWAGGER_UI_SETTINGS": {
        "deepLinking": True,
        "persistAuthorization": True,
        "displayOperationId": False,
    },
    "TAGS": [
        {"name": "auth", "description": "Registration & JWT authentication"},
        {"name": "songs", "description": "Song CRUD, upload & filtering"},
        {"name": "profiles", "description": "User profiles & avatars"},
        {"name": "feed", "description": "Public song feed"},
        {"name": "health", "description": "Service health checks"},
    ],
    "CONTACT": {"name": "Faraz"},
    "LICENSE": {"name": "MIT"},
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
}
