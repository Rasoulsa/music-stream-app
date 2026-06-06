"""
Tests for the API documentation / OpenAPI schema.
"""

import pytest
from rest_framework import status
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


def test_openapi_schema_is_available(api_client):
    response = api_client.get("/api/schema/")
    assert response.status_code == status.HTTP_200_OK


def test_swagger_ui_is_available(api_client):
    response = api_client.get("/api/docs/")
    assert response.status_code == status.HTTP_200_OK
