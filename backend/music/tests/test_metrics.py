"""
Tests for the Prometheus metrics endpoint (django-prometheus).
"""

import pytest
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


@pytest.mark.django_db
def test_metrics_endpoint_is_exposed(api_client):
    """django-prometheus exposes a plaintext /metrics endpoint."""
    response = api_client.get("/metrics")

    assert response.status_code == 200

    # django-prometheus output is plaintext exposition format.
    content = response.content
    assert b"# HELP" in content or b"# TYPE" in content
