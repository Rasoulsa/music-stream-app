"""
Pytest configuration shared across all tests.
"""

import tempfile

import pytest
from django.core.cache import cache


@pytest.fixture(autouse=True)
def use_temp_media(settings):
    """
    Redirect MEDIA_ROOT to a temporary directory during tests so
    uploaded files don't pollute the real media folder.
    """
    settings.MEDIA_ROOT = tempfile.mkdtemp()


@pytest.fixture(autouse=True)
def celery_eager(settings):
    """
    Run all Celery tasks synchronously (in-process) during tests,
    regardless of environment. Docker/production sets
    CELERY_TASK_ALWAYS_EAGER=false, which would queue tasks to Redis
    instead of running them — making this test non-deterministic.
    Forcing eager mode here guarantees tasks run inline in every environment.
    """
    settings.CELERY_TASK_ALWAYS_EAGER = True
    settings.CELERY_TASK_EAGER_PROPAGATES = True


@pytest.fixture(autouse=True)
def clear_cache_between_tests():
    """
    Keep tests isolated from Django cache state.

    CI/test settings use LocMemCache, which persists for the whole pytest
    process. Without clearing it, cached profile/feed responses from one test
    can leak into another test and produce order-dependent failures.
    """
    cache.clear()
    yield
    cache.clear()
