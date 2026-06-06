"""
Tests for the health check endpoint.
"""

import pytest
from rest_framework import status
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


def test_health_check_returns_ok(api_client):
    response = api_client.get("/api/health/")

    assert response.status_code == status.HTTP_200_OK
    assert response.data["status"] == "ok"
    assert response.data["service"] == "music-stream-app"
