import os

from .base import *  # noqa: F403

DEBUG = False

SECRET_KEY = os.environ.get("SECRET_KEY", "ci-insecure-test-key")

ALLOWED_HOSTS = ["*"]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("POSTGRES_DB", "test_db"),
        "USER": os.environ.get("POSTGRES_USER", "test_user"),
        "PASSWORD": os.environ.get("POSTGRES_PASSWORD", "test_pass"),
        "HOST": os.environ.get("POSTGRES_HOST", "localhost"),
        "PORT": os.environ.get("POSTGRES_PORT", "5432"),
    }
}

# Speed up password hashing in tests
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.MD5PasswordHasher",
]


# Force local-disk storage in CI/tests (never touch real object storage)
STORAGES = {
    "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
    "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
}
