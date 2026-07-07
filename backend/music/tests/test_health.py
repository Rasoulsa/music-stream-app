"""
Tests for the health check endpoint.
"""

from unittest import mock

import pytest
from rest_framework import status
from rest_framework.test import APIClient

pytestmark = pytest.mark.django_db


@pytest.fixture
def api_client():
    return APIClient()


def test_health_check_returns_ok(api_client):
    response = api_client.get("/api/health/")

    assert response.status_code == status.HTTP_200_OK
    assert response.data["status"] == "ok"
    assert response.data["service"] == "music-stream-app"


def test_health_check_reports_dependency_status(api_client):
    response = api_client.get("/api/health/")

    assert response.status_code == status.HTTP_200_OK
    assert response.data["checks"]["database"] == "ok"
    assert response.data["checks"]["cache"] == "ok"
    assert "request_id" in response.data


def test_health_check_degraded_when_cache_fails(api_client):
    with mock.patch("music.views_health.cache.set", side_effect=Exception("boom")):
        response = api_client.get("/api/health/")

    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    assert response.data["status"] == "degraded"
    assert response.data["checks"]["cache"] == "error"


def test_health_check_degraded_when_db_fails(api_client):
    with mock.patch(
        "music.views_health._check_database",
        return_value=(False, "error"),
    ):
        response = api_client.get("/api/health/")

    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    assert response.data["status"] == "degraded"
    assert response.data["checks"]["database"] == "error"


def test_health_check_returns_request_id_header(api_client):
    response = api_client.get("/api/health/")

    assert "X-Request-ID" in response


def test_health_check_head_not_allowed(api_client):
    response = api_client.head("/api/health/")

    assert response.status_code == status.HTTP_405_METHOD_NOT_ALLOWED
