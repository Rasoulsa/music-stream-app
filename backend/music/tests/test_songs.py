"""
Tests for the Song API.
"""

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import status
from rest_framework.test import APIClient

from music.models import Song


@pytest.fixture
def api_client():
    return APIClient()


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
def test_create_song(api_client, sample_audio):
    payload = {
        "title": "Test Song",
        "artist": "Test Artist",
        "album": "Test Album",
        "audio_file": sample_audio,
        "duration_seconds": 180,
    }
    response = api_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_201_CREATED
    assert response.data["title"] == "Test Song"
    assert response.data["artist"] == "Test Artist"
    assert Song.objects.count() == 1


@pytest.mark.django_db
def test_create_song_missing_title_fails(api_client, sample_audio):
    payload = {
        "artist": "Test Artist",
        "audio_file": sample_audio,
    }
    response = api_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "title" in response.data


@pytest.mark.django_db
def test_create_song_blank_title_fails(api_client, sample_audio):
    payload = {
        "title": "   ",
        "artist": "Test Artist",
        "audio_file": sample_audio,
    }
    response = api_client.post("/api/songs/", payload, format="multipart")

    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "title" in response.data


@pytest.mark.django_db
def test_retrieve_song(api_client, sample_audio):
    song = Song.objects.create(
        title="Existing Song",
        artist="Existing Artist",
        audio_file=sample_audio,
    )
    response = api_client.get(f"/api/songs/{song.id}/")

    assert response.status_code == status.HTTP_200_OK
    assert response.data["title"] == "Existing Song"


@pytest.mark.django_db
def test_update_song(api_client, sample_audio):
    song = Song.objects.create(
        title="Old Title",
        artist="Old Artist",
        audio_file=sample_audio,
    )
    response = api_client.patch(
        f"/api/songs/{song.id}/",
        {"title": "New Title"},
        format="multipart",
    )

    assert response.status_code == status.HTTP_200_OK
    assert response.data["title"] == "New Title"


@pytest.mark.django_db
def test_delete_song(api_client, sample_audio):
    song = Song.objects.create(
        title="To Delete",
        artist="Artist",
        audio_file=sample_audio,
    )
    response = api_client.delete(f"/api/songs/{song.id}/")

    assert response.status_code == status.HTTP_204_NO_CONTENT
    assert Song.objects.count() == 0
