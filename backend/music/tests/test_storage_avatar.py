import io

import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.test import APIClient

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        username="faraz",
        email="faraz@example.com",
        password="StrongPass123!",
    )


@pytest.fixture
def auth_client(api_client, user):
    api_client.force_authenticate(user=user)
    return api_client


def _make_image() -> SimpleUploadedFile:
    """Generate a tiny in-memory PNG for upload tests."""
    buffer = io.BytesIO()
    image = Image.new("RGB", (10, 10), color="blue")
    image.save(buffer, format="PNG")
    buffer.seek(0)
    return SimpleUploadedFile("avatar.png", buffer.read(), content_type="image/png")


def test_upload_avatar(auth_client, settings, tmp_path):
    # Force local-disk storage in tests, into a temp dir
    settings.MEDIA_ROOT = tmp_path
    res = auth_client.patch(
        reverse("my-profile"),
        {"avatar": _make_image(), "display_name": "Faraz"},
        format="multipart",
    )
    assert res.status_code == status.HTTP_200_OK
    assert res.data["display_name"] == "Faraz"
    assert res.data["avatar"] is not None
    assert "avatars/" in res.data["avatar"]


def test_profile_avatar_null_by_default(auth_client):
    res = auth_client.get(reverse("my-profile"))
    assert res.status_code == status.HTTP_200_OK
    assert res.data["avatar"] is None


def test_public_profile_includes_avatar_field(api_client, user):
    res = api_client.get(reverse("public-profile", kwargs={"username": user.username}))
    assert res.status_code == status.HTTP_200_OK
    assert "avatar" in res.data
