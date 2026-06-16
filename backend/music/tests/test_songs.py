"""
Tests for the Song API.
"""

import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import status
from rest_framework.test import APIClient

from music.models import Song

User = get_user_model()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        username="faraz",
        email="faraz@example.com",
        password="StrongPass123!",
    )


@pytest.fixture
def other_user(db):
    return User.objects.create_user(
        username="other",
        email="other@example.com",
        password="StrongPass123!",
    )


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def auth_client(user):
    client = APIClient()
    client.force_authenticate(user=user)
    return client


@pytest.fixture
def sample_audio():
    """A small fake audio file for upload tests."""
    return SimpleUploadedFile(
        name="test_song.mp3",
        content=b"fake-audio-bytes",
        content_type="audio/mpeg",
    )


@pytest.mark.django_db
def test_list_songs_empty(api_client):
    response = api_client.get("/api/songs/")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 0
    assert response.data["results"] == []


@pytest.mark.django_db
def test_create_song(auth_client, sample_audio):
    payload = {
        "title": "Test Song",
        "artist": "Test Artist",
        "album": "Test Album",
        "audio_file": sample_audio,
        "duration_seconds": 180,
        "is_public": True,
    }
    response = auth_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_201_CREATED
    assert response.data["title"] == "Test Song"
    assert response.data["artist"] == "Test Artist"
    assert response.data["owner"] == "faraz"
    assert Song.objects.count() == 1


@pytest.mark.django_db
def test_create_song_requires_authentication(api_client, sample_audio):
    payload = {
        "title": "Test Song",
        "artist": "Test Artist",
        "audio_file": sample_audio,
    }
    response = api_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
def test_create_song_missing_title_fails(auth_client, sample_audio):
    payload = {
        "artist": "Test Artist",
        "audio_file": sample_audio,
    }
    response = auth_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "title" in response.data


@pytest.mark.django_db
def test_create_song_blank_title_fails(auth_client, sample_audio):
    payload = {
        "title": "   ",
        "artist": "Test Artist",
        "audio_file": sample_audio,
    }
    response = auth_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "title" in response.data


@pytest.mark.django_db
def test_retrieve_song(api_client, user, sample_audio):
    song = Song.objects.create(
        title="Existing Song",
        artist="Existing Artist",
        audio_file=sample_audio,
        owner=user,
        is_public=True,
    )
    response = api_client.get(f"/api/songs/{song.id}/")

    assert response.status_code == status.HTTP_200_OK
    assert response.data["title"] == "Existing Song"


@pytest.mark.django_db
def test_update_song(auth_client, user, sample_audio):
    song = Song.objects.create(
        title="Old Title",
        artist="Old Artist",
        audio_file=sample_audio,
        owner=user,
        is_public=True,
    )
    response = auth_client.patch(
        f"/api/songs/{song.id}/",
        {"title": "New Title"},
        format="multipart",
    )

    assert response.status_code == status.HTTP_200_OK
    assert response.data["title"] == "New Title"


@pytest.mark.django_db
def test_non_owner_cannot_update_song(api_client, user, other_user, sample_audio):
    song = Song.objects.create(
        title="Protected Song",
        artist="Artist",
        audio_file=sample_audio,
        owner=user,
        is_public=True,
    )
    api_client.force_authenticate(user=other_user)
    response = api_client.patch(
        f"/api/songs/{song.id}/",
        {"title": "Hacked"},
        format="multipart",
    )

    assert response.status_code in (
        status.HTTP_403_FORBIDDEN,
        status.HTTP_404_NOT_FOUND,
    )


@pytest.mark.django_db
def test_delete_song(auth_client, user, sample_audio):
    song = Song.objects.create(
        title="To Delete",
        artist="Artist",
        audio_file=sample_audio,
        owner=user,
        is_public=True,
    )
    response = auth_client.delete(f"/api/songs/{song.id}/")

    assert response.status_code == status.HTTP_204_NO_CONTENT
    assert Song.objects.count() == 0


@pytest.mark.django_db
def test_non_owner_cannot_delete_song(api_client, user, other_user, sample_audio):
    song = Song.objects.create(
        title="Protected Song",
        artist="Artist",
        audio_file=sample_audio,
        owner=user,
        is_public=True,
    )
    api_client.force_authenticate(user=other_user)
    response = api_client.delete(f"/api/songs/{song.id}/")

    assert response.status_code in (
        status.HTTP_403_FORBIDDEN,
        status.HTTP_404_NOT_FOUND,
    )
    assert Song.objects.count() == 1
