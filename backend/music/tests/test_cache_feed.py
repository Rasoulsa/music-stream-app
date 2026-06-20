import pytest
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from music.models import Song

User = get_user_model()


@pytest.fixture(autouse=True)
def clear_cache():
    """Ensure a clean cache before and after every test."""
    cache.clear()
    yield
    cache.clear()


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


def _make_song(owner, title, is_public=True):
    return Song.objects.create(
        owner=owner,
        title=title,
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=is_public,
    )


# ── Health check ───────────────────────────────────────────────────────


def test_health_check_reports_cache_ok(api_client):
    res = api_client.get(reverse("health-check"))
    assert res.status_code == status.HTTP_200_OK
    assert res.data["status"] == "ok"
    assert res.data["cache"] == "ok"


# ── Feed caching ───────────────────────────────────────────────────────


def test_feed_default_is_cached(api_client, user):
    _make_song(user, "Song A")
    # First call populates cache
    res1 = api_client.get(reverse("feed"))
    assert res1.status_code == status.HTTP_200_OK
    # Cache key should now exist
    assert cache.get("feed:default") is not None


def test_feed_cache_invalidated_on_new_song(api_client, user):
    _make_song(user, "Song A")
    api_client.get(reverse("feed"))  # populate cache
    assert cache.get("feed:default") is not None

    _make_song(user, "Song B")  # signal should clear cache
    assert cache.get("feed:default") is None


def test_feed_cache_invalidated_on_song_delete(api_client, user):
    song = _make_song(user, "Song A")
    api_client.get(reverse("feed"))
    assert cache.get("feed:default") is not None

    song.delete()  # post_delete signal clears
    assert cache.get("feed:default") is None


def test_filtered_feed_bypasses_cache(api_client, user):
    _make_song(user, "Song A")
    # A filtered request should NOT populate the default cache key
    api_client.get(reverse("feed") + "?artist=Faraz")
    assert cache.get("feed:default") is None
