"""
API contract tests — the API freeze guarantee.

These tests fail loudly if the live API schema drifts from the
committed frozen schema (api/schema.yml). When you intentionally
change the API, regenerate the frozen schema and bump VERSION.
"""

from pathlib import Path

import pytest
import yaml
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

SCHEMA_FILE = Path(__file__).resolve().parent.parent.parent / "api" / "schema.yml"


@pytest.fixture
def client():
    return APIClient()


def test_frozen_schema_file_exists():
    """The frozen schema artifact must be committed to the repo."""
    assert SCHEMA_FILE.exists(), (
        f"Frozen schema not found at {SCHEMA_FILE}. "
        "Run: manage.py spectacular --file api/schema.yml"
    )


def test_schema_endpoint_returns_200(client):
    """Live schema endpoint must be reachable."""
    url = reverse("schema")
    resp = client.get(url)
    assert resp.status_code == status.HTTP_200_OK


def test_live_schema_matches_frozen(client):
    """
    The live generated schema must match the committed frozen schema.

    If this fails, EITHER you broke the API by accident (fix the code),
    OR you changed it intentionally (regenerate api/schema.yml + bump VERSION).
    """
    url = reverse("schema")
    resp = client.get(url, HTTP_ACCEPT="application/yaml")
    assert resp.status_code == status.HTTP_200_OK

    live = yaml.safe_load(resp.content)
    with SCHEMA_FILE.open() as f:
        frozen = yaml.safe_load(f)

    # Compare the contract-critical sections
    assert live["paths"].keys() == frozen["paths"].keys(), (
        "API paths changed! Live paths differ from frozen schema.\n"
        f"Live:   {sorted(live['paths'].keys())}\n"
        f"Frozen: {sorted(frozen['paths'].keys())}"
    )

    assert (
        live["info"]["version"] == frozen["info"]["version"]
    ), "API version mismatch — did you forget to bump/freeze?"


def test_api_is_versioned():
    """All resource endpoints must live under /api/v1/."""
    with SCHEMA_FILE.open() as f:
        frozen = yaml.safe_load(f)

    versioned = [p for p in frozen["paths"] if p.startswith("/api/v1/")]
    assert versioned, "No /api/v1/ endpoints found — API is not versioned!"
