"""
Tests for search, filtering, and ordering on the Song API.
"""

import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from music.models import Song

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
def songs(db, user):
    """Create a set of songs for filtering tests."""
    audio = SimpleUploadedFile("a.mp3", b"x", content_type="audio/mpeg")
    Song.objects.create(
        title="Yesterday",
        artist="The Beatles",
        album="Help",
        audio_file=audio,
        duration_seconds=125,
        owner=user,
        is_public=True,
    )
    Song.objects.create(
        title="Let It Be",
        artist="The Beatles",
        album="Let It Be",
        audio_file=audio,
        duration_seconds=243,
        owner=user,
        is_public=True,
    )
    Song.objects.create(
        title="Bohemian Rhapsody",
        artist="Queen",
        album="A Night at the Opera",
        audio_file=audio,
        duration_seconds=354,
        owner=user,
        is_public=True,
    )
    Song.objects.create(
        title="Love Story",
        artist="Taylor Swift",
        album="Fearless",
        audio_file=audio,
        duration_seconds=235,
        owner=user,
        is_public=True,
    )


@pytest.mark.django_db
def test_search_by_artist(api_client, songs):
    response = api_client.get(reverse("song-list") + "?search=beatles")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 2


@pytest.mark.django_db
def test_search_by_title(api_client, songs):
    response = api_client.get(reverse("song-list") + "?search=love")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 1
    assert response.data["results"][0]["title"] == "Love Story"


@pytest.mark.django_db
def test_filter_by_artist(api_client, songs):
    response = api_client.get(reverse("song-list") + "?artist=queen")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 1
    assert response.data["results"][0]["artist"] == "Queen"


@pytest.mark.django_db
def test_filter_by_min_duration(api_client, songs):
    response = api_client.get(reverse("song-list") + "?min_duration=300")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 1
    assert response.data["results"][0]["title"] == "Bohemian Rhapsody"


@pytest.mark.django_db
def test_filter_by_duration_range(api_client, songs):
    response = api_client.get(
        reverse("song-list") + "?min_duration=200&max_duration=300"
    )
    assert response.status_code == status.HTTP_200_OK
    # Let It Be (243) and Love Story (235)
    assert response.data["count"] == 2


@pytest.mark.django_db
def test_ordering_by_title_ascending(api_client, songs):
    response = api_client.get(reverse("song-list") + "?ordering=title")
    assert response.status_code == status.HTTP_200_OK
    titles = [s["title"] for s in response.data["results"]]
    assert titles == sorted(titles)


@pytest.mark.django_db
def test_ordering_by_duration_descending(api_client, songs):
    response = api_client.get(reverse("song-list") + "?ordering=-duration_seconds")
    assert response.status_code == status.HTTP_200_OK
    durations = [s["duration_seconds"] for s in response.data["results"]]
    assert durations == sorted(durations, reverse=True)


@pytest.mark.django_db
def test_search_and_ordering_combined(api_client, songs):
    response = api_client.get(reverse("song-list") + "?search=beatles&ordering=title")
    assert response.status_code == status.HTTP_200_OK
    assert response.data["count"] == 2
    titles = [s["title"] for s in response.data["results"]]
    assert titles == ["Let It Be", "Yesterday"]
