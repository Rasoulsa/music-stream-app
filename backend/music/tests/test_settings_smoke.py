"""
Smoke tests for production settings.
Ensures production settings import correctly and enforce security.
"""

import importlib

import pytest


def test_production_settings_import(monkeypatch):
    """Production settings should import cleanly when env vars are present."""
    monkeypatch.setenv("DJANGO_SECRET_KEY", "test-secret-key-not-the-default")
    monkeypatch.setenv("DJANGO_ALLOWED_HOSTS", "localhost,example.com")
    monkeypatch.setenv("POSTGRES_DB", "testdb")
    monkeypatch.setenv("POSTGRES_USER", "testuser")
    monkeypatch.setenv("POSTGRES_PASSWORD", "testpass")

    # Reload base FIRST so SECRET_KEY picks up the new env var,
    # then reload production which imports from base.
    base = importlib.import_module("config.settings.base")
    importlib.reload(base)
    prod = importlib.import_module("config.settings.production")
    importlib.reload(prod)

    assert prod.DEBUG is False
    assert "localhost" in prod.ALLOWED_HOSTS
    assert "example.com" in prod.ALLOWED_HOSTS


def test_production_requires_secret_key(monkeypatch):
    """Production must fail loudly if SECRET_KEY is left as the unsafe default."""
    monkeypatch.setenv("DJANGO_SECRET_KEY", "unsafe-dev-secret-key")
    monkeypatch.setenv("POSTGRES_DB", "testdb")
    monkeypatch.setenv("POSTGRES_USER", "testuser")
    monkeypatch.setenv("POSTGRES_PASSWORD", "testpass")

    # Reload base FIRST so SECRET_KEY becomes the unsafe default,
    # then production should raise ValueError on import.
    base = importlib.import_module("config.settings.base")
    importlib.reload(base)

    with pytest.raises(ValueError, match="DJANGO_SECRET_KEY"):
        prod = importlib.import_module("config.settings.production")
        importlib.reload(prod)
