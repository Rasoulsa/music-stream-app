"""
Pytest configuration shared across all tests.
"""

import tempfile

import pytest


@pytest.fixture(autouse=True)
def use_temp_media(settings):
    """
    Redirect MEDIA_ROOT to a temporary directory during tests so
    uploaded files don't pollute the real media folder.
    """
    settings.MEDIA_ROOT = tempfile.mkdtemp()
