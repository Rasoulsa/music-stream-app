import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from music.models import Profile, Song

User = get_user_model()


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        username="faraz",
        email="faraz@example.com",
        password="StrongPass123",
    )


@pytest.fixture
def other_user(db):
    return User.objects.create_user(
        username="other",
        email="other@example.com",
        password="StrongPass123",
    )


@pytest.fixture
def auth_client(api_client, user):
    api_client.force_authenticate(user=user)
    return api_client


def _results(res):
    return res.data["results"] if "results" in res.data else res.data


# ── Model __str__ methods ──────────────────────────────────────────────


def test_profile_str(user):
    assert str(user.profile) == f"Profile<{user.username}>"


def test_song_str(user):
    song = Song.objects.create(
        owner=user,
        title="My Song",
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    assert str(song) == "My Song — Faraz"


# ── Profile auto-creation (signal) ─────────────────────────────────────


@pytest.mark.django_db
def test_profile_created_automatically(user):
    assert Profile.objects.filter(user=user).exists()


def test_signal_does_not_duplicate_profile_on_update(user):
    """Saving an existing user should NOT create a second profile."""
    user.email = "changed@example.com"
    user.save()
    assert Profile.objects.filter(user=user).count() == 1


# ── GET /api/v1/users/me/ ──────────────────────────────────────────────


@pytest.mark.django_db
def test_get_my_profile(auth_client):
    res = auth_client.get(reverse("my-profile"))
    assert res.status_code == status.HTTP_200_OK
    assert res.data["username"] == "faraz"
    assert res.data["email"] == "faraz@example.com"


@pytest.mark.django_db
def test_get_my_profile_requires_auth(api_client):
    res = api_client.get(reverse("my-profile"))
    assert res.status_code == status.HTTP_401_UNAUTHORIZED


# ── PATCH /api/v1/users/me/ ────────────────────────────────────────────


@pytest.mark.django_db
def test_update_my_profile(auth_client):
    res = auth_client.patch(
        reverse("my-profile"),
        {"display_name": "Faraz Music", "bio": "I make beats."},
        format="json",
    )
    assert res.status_code == status.HTTP_200_OK
    assert res.data["display_name"] == "Faraz Music"
    assert res.data["bio"] == "I make beats."


@pytest.mark.django_db
def test_update_profile_requires_auth(api_client):
    res = api_client.patch(
        reverse("my-profile"),
        {"display_name": "Hacker"},
        format="json",
    )
    assert res.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
def test_cannot_edit_others_profile_via_me(auth_client, other_user):
    auth_client.patch(
        reverse("my-profile"),
        {"display_name": "Changed"},
        format="json",
    )
    other_user.refresh_from_db()
    assert other_user.profile.display_name == ""


# ── GET /api/v1/users/{username}/ (public profile) ─────────────────────


@pytest.mark.django_db
def test_public_profile_returns_200(api_client, user):
    res = api_client.get(reverse("public-profile", kwargs={"username": user.username}))
    assert res.status_code == status.HTTP_200_OK
    assert res.data["username"] == "faraz"


@pytest.mark.django_db
def test_public_profile_hides_email(api_client, user):
    res = api_client.get(reverse("public-profile", kwargs={"username": user.username}))
    assert "email" not in res.data


@pytest.mark.django_db
def test_public_profile_404_unknown_user(api_client):
    res = api_client.get(reverse("public-profile", kwargs={"username": "ghost"}))
    assert res.status_code == status.HTTP_404_NOT_FOUND


# ── GET /api/v1/feed/ ──────────────────────────────────────────────────


@pytest.mark.django_db
def test_feed_shows_only_public_songs(api_client, user, other_user):
    Song.objects.create(
        owner=user,
        title="Public A",
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    Song.objects.create(
        owner=user,
        title="Private B",
        artist="Faraz",
        album="Demo",
        duration_seconds=200,
        is_public=False,
    )
    Song.objects.create(
        owner=other_user,
        title="Public C",
        artist="Other",
        album="Demo",
        duration_seconds=150,
        is_public=True,
    )
    res = api_client.get(reverse("feed"))
    assert res.status_code == status.HTTP_200_OK
    titles = {s["title"] for s in _results(res)}
    assert "Public A" in titles
    assert "Public C" in titles
    assert "Private B" not in titles


@pytest.mark.django_db
def test_feed_accessible_without_auth(api_client):
    res = api_client.get(reverse("feed"))
    assert res.status_code == status.HTTP_200_OK


# ── GET /api/v1/songs/mine/ ────────────────────────────────────────────


@pytest.mark.django_db
def test_my_songs_includes_private(auth_client, user):
    Song.objects.create(
        owner=user,
        title="Mine Public",
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    Song.objects.create(
        owner=user,
        title="Mine Private",
        artist="Faraz",
        album="Demo",
        duration_seconds=200,
        is_public=False,
    )
    res = auth_client.get(reverse("my-songs"))
    assert res.status_code == status.HTTP_200_OK
    titles = {s["title"] for s in _results(res)}
    assert "Mine Public" in titles
    assert "Mine Private" in titles


@pytest.mark.django_db
def test_my_songs_excludes_others(auth_client, other_user):
    Song.objects.create(
        owner=other_user,
        title="Not Mine",
        artist="Other",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    res = auth_client.get(reverse("my-songs"))
    titles = {s["title"] for s in _results(res)}
    assert "Not Mine" not in titles


@pytest.mark.django_db
def test_my_songs_requires_auth(api_client):
    res = api_client.get(reverse("my-songs"))
    assert res.status_code == status.HTTP_401_UNAUTHORIZED


# ── GET /api/v1/users/{username}/songs/ ────────────────────────────────


@pytest.mark.django_db
def test_user_public_songs_excludes_private(api_client, user):
    Song.objects.create(
        owner=user,
        title="Pub",
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    Song.objects.create(
        owner=user,
        title="Priv",
        artist="Faraz",
        album="Demo",
        duration_seconds=200,
        is_public=False,
    )
    res = api_client.get(
        reverse("user-public-songs", kwargs={"username": user.username})
    )
    assert res.status_code == status.HTTP_200_OK
    titles = {s["title"] for s in _results(res)}
    assert "Pub" in titles
    assert "Priv" not in titles


@pytest.mark.django_db
def test_user_public_songs_no_auth_required(api_client, user):
    res = api_client.get(
        reverse("user-public-songs", kwargs={"username": user.username})
    )
    assert res.status_code == status.HTTP_200_OK


def test_public_profile_song_count(api_client, user):
    """Covers the public_song_count SerializerMethodField."""
    from music.models import Song

    Song.objects.create(
        owner=user,
        title="Pub",
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    Song.objects.create(
        owner=user,
        title="Priv",
        artist="Faraz",
        album="Demo",
        duration_seconds=200,
        is_public=False,
    )
    res = api_client.get(reverse("public-profile", kwargs={"username": user.username}))
    assert res.status_code == 200
    assert res.data["public_song_count"] == 1


def test_my_profile_song_count(auth_client, user):
    """Covers the song_count SerializerMethodField."""
    from music.models import Song

    Song.objects.create(
        owner=user,
        title="A",
        artist="Faraz",
        album="Demo",
        duration_seconds=180,
        is_public=True,
    )
    res = auth_client.get(reverse("my-profile"))
    assert res.status_code == 200
    assert res.data["song_count"] == 1
