import pytest
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APIClient

User = get_user_model()


@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(username="alice", password="StrongPass123!")


def auth_header(client, username, password):
    res = client.post(
        "/api/auth/login/",
        {"username": username, "password": password},
        format="json",
    )
    token = res.data["access"]
    return {"HTTP_AUTHORIZATION": f"Bearer {token}"}


@pytest.mark.django_db
def test_register(client):
    res = client.post(
        "/api/auth/register/",
        {"username": "bob", "email": "bob@example.com", "password": "StrongPass123!"},
        format="json",
    )
    assert res.status_code == 201
    assert User.objects.filter(username="bob").exists()


@pytest.mark.django_db
def test_login_returns_tokens(client, user):
    res = client.post(
        "/api/auth/login/",
        {"username": "alice", "password": "StrongPass123!"},
        format="json",
    )
    assert res.status_code == 200
    assert "access" in res.data
    assert "refresh" in res.data


@pytest.mark.django_db
def test_authenticated_user_can_create_song(client, user):
    headers = auth_header(client, "alice", "StrongPass123!")
    res = client.post(
        "/api/songs/",
        {"title": "Song A", "artist": "Alice", "is_public": True},
        format="multipart",
        **headers,
    )
    assert res.status_code == 201
    assert res.data["owner"] == "alice"


@pytest.mark.django_db
def test_anonymous_cannot_create_song(client):
    res = client.post(
        "/api/songs/",
        {"title": "Nope", "artist": "X", "is_public": True},
        format="multipart",
    )
    assert res.status_code in (401, 403)


@pytest.mark.django_db
def test_private_song_hidden_from_others(client, user):
    # Alice creates a private song
    headers = auth_header(client, "alice", "StrongPass123!")
    client.post(
        "/api/songs/",
        {"title": "Secret", "artist": "Alice", "is_public": False},
        format="multipart",
        **headers,
    )
    # Anonymous list should not include it
    res = client.get("/api/songs/")
    titles = (
        [s["title"] for s in res.data["results"]]
        if "results" in res.data
        else [s["title"] for s in res.data]
    )
    assert "Secret" not in titles


@pytest.mark.django_db
def test_user_cannot_edit_others_song(client):
    User.objects.create_user(username="alice2", password="StrongPass123!")
    User.objects.create_user(username="bob2", password="StrongPass123!")

    a_headers = auth_header(client, "alice2", "StrongPass123!")
    create = client.post(
        "/api/songs/",
        {"title": "Alice Song", "artist": "Alice", "is_public": True},
        format="multipart",
        **a_headers,
    )
    song_id = create.data["id"]

    b_headers = auth_header(client, "bob2", "StrongPass123!")
    res = client.patch(
        f"/api/songs/{song_id}/",
        {"title": "Hacked"},
        format="multipart",
        **b_headers,
    )
    assert res.status_code == 403


@pytest.mark.django_db
def test_user_can_upload_song_with_audio_file(client, user):
    headers = auth_header(client, "alice", "StrongPass123!")
    audio = SimpleUploadedFile("track.mp3", b"fake-audio", content_type="audio/mpeg")
    res = client.post(
        "/api/songs/",
        {
            "title": "Uploaded Song",
            "artist": "Alice",
            "is_public": True,
            "audio_file": audio,
        },
        format="multipart",
        **headers,
    )
    assert res.status_code == 201
    assert res.data["title"] == "Uploaded Song"
    assert res.data["owner"] == "alice"
