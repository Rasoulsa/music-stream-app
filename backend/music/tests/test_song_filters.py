"""
Tests for search, filtering, and ordering on the Song API.
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
def songs(db):
    """Create a set of songs for filtering tests."""
    audio = SimpleUploadedFile("a.mp3", b"x", content_type="audio/mpeg")
    Song.objects.create(
        title="Yesterday",
        artist="The Beatles",
        album="Help",
        audio_file=audio,
        duration_seconds=125,
    )
    Song.objects.create(
        title="Let It Be",
        artist="The Beatles",
        album="Let It Be",
        audio_file=audio,
        duration_seconds=243,
    )
    Song.objects.create(
        title="Bohemian Rhapsody",
        artist="Queen",
        album="A Night at the Opera",
        audio_file=audio,
        duration_seconds=354,
    )
    Song.objects.create(
        title="Love Story",
        artist="Taylor Swift",
        album="Fearless",
        audio_file=audio,
        duration_seconds=235,
    )


@pytest.mark.django_db
def test_search_by_artist(api_client, songs):
    response = api_client.get("/api/songs/?search=beatles")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 2


@pytest.mark.django_db
def test_search_by_title(api_client, songs):
    response = api_client.get("/api/songs/?search=love")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 1
    assert response.data["results"][0]["title"] == "Love Story"


@pytest.mark.django_db
def test_filter_by_artist(api_client, songs):
    response = api_client.get("/api/songs/?artist=queen")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 1
    assert response.data["results"][0]["artist"] == "Queen"


@pytest.mark.django_db
def test_filter_by_min_duration(api_client, songs):
    response = api_client.get("/api/songs/?min_duration=300")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 1
    assert response.data["results"][0]["title"] == "Bohemian Rhapsody"


@pytest.mark.django_db
def test_filter_by_duration_range(api_client, songs):
    response = api_client.get("/api/songs/?min_duration=200&max_duration=300")
    assert response.status_code == status.HTTP_200_OK
    # Let It Be (243) and Love Story (235)
    assert response.data["count"] == 2


@pytest.mark.django_db
def test_ordering_by_title_ascending(api_client, songs):
    response = api_client.get("/api/songs/?ordering=title")
    assert response.status_code == status.HTTP_200_OK
    titles = [s["title"] for s in response.data["results"]]
    assert titles == sorted(titles)


@pytest.mark.django_db
def test_ordering_by_duration_descending(api_client, songs):
    response = api_client.get("/api/songs/?ordering=-duration_seconds")
    assert response.status_code == status.HTTP_200_OK
    durations = [s["duration_seconds"] for s in response.data["results"]]
    assert durations == sorted(durations, reverse=True)


@pytest.mark.django_db
def test_search_and_ordering_combined(api_client, songs):
    response = api_client.get("/api/songs/?search=beatles&ordering=title")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 2
    titles = [s["title"] for s in response.data["results"]]
    assert titles == ["Let It Be", "Yesterday"]
