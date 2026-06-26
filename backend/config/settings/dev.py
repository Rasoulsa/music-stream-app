"""
Development settings.
"""

import sys

from .base import *  # noqa: F401,F403
from .base import BASE_DIR, env  # noqa: F401

DEBUG = True

RUNNING_TESTS = "pytest" in sys.modules or any("pytest" in arg for arg in sys.argv)

ALLOWED_HOSTS = ["localhost", "127.0.0.1", "0.0.0.0", "backend"]

# Allow the React dev server during development
CORS_ALLOWED_ORIGINS = []
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127\.0\.0\.1:\d+$",
]

# Show the browsable API in development for easier testing
REST_FRAMEWORK["DEFAULT_RENDERER_CLASSES"] = [  # noqa: F405
    "rest_framework.renderers.JSONRenderer",
    "rest_framework.renderers.BrowsableAPIRenderer",
]

# ------------------------------------------------------------------
# Database
# Local dev  → SQLite  (fast, no Docker needed)   USE_DOCKER=false
# Docker dev → PostgreSQL (matches production)     USE_DOCKER=true
# ------------------------------------------------------------------
if env.bool("USE_DOCKER", default=False):  # noqa: F405
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

# -----------------------------------------------------------------------------
# Django Debug Toolbar — local profiling only
# -----------------------------------------------------------------------------
if DEBUG and not RUNNING_TESTS:
    try:
        import debug_toolbar  # noqa: F401

        INSTALLED_APPS += ["debug_toolbar"]
        MIDDLEWARE.insert(0, "debug_toolbar.middleware.DebugToolbarMiddleware")
        INTERNAL_IPS = ["127.0.0.1", "localhost"]

        # Docker: resolve container IP so the toolbar renders inside the network.
        # On some local macOS setups, socket.gethostname() cannot be resolved;
        # debug toolbar should never break Django startup, so this is best-effort.
        import socket

        try:
            _hostname, _, _ips = socket.gethostbyname_ex(socket.gethostname())
            INTERNAL_IPS += [ip.rsplit(".", 1)[0] + ".1" for ip in _ips if "." in ip]
        except socket.gaierror:
            pass

        DEBUG_TOOLBAR_CONFIG = {"SHOW_TOOLBAR_CALLBACK": lambda request: True}
    except ImportError:
        pass
