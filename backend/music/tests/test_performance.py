"""
Performance regression tests.

Lock in query counts so a future change that reintroduces an N+1
query FAILS CI. Performance becomes a tested contract, not a hope.

Also verifies the cache layer serves cached reads.
"""

import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from music.models import Song

pytestmark = pytest.mark.django_db


@pytest.fixture
def user(django_user_model):
    return django_user_model.objects.create_user(
        username="perfuser",
        password="pass12345",
    )


@pytest.fixture
def many_songs(user):
    """10 public songs by one owner — enough to expose an N+1."""
    return Song.objects.bulk_create(
        [
            Song(
                title=f"Song {i}",
                artist="Artist",
                owner=user,
                is_public=True,
            )
            for i in range(10)
        ]
    )


def test_song_list_query_count_is_constant(
    django_assert_max_num_queries,
    many_songs,
):
    """
    SongViewSet list must NOT scale queries with row count.

    select_related('owner') fetches owner.username in the same JOIN,
    so query count stays constant regardless of how many songs exist.
    """
    client = APIClient()
    url = reverse("song-list")

    with django_assert_max_num_queries(4):
        response = client.get(url)

    assert response.status_code == 200
    assert len(response.data["results"]) == 10


def test_my_songs_query_count_is_constant(
    django_assert_max_num_queries,
    user,
    many_songs,
):
    """Authenticated 'my songs' list stays query-bounded."""
    client = APIClient()
    client.force_authenticate(user=user)
    url = reverse("my-songs")

    with django_assert_max_num_queries(5):
        response = client.get(url)

    assert response.status_code == 200


def test_user_public_songs_query_count_is_constant(
    django_assert_max_num_queries,
    user,
    many_songs,
):
    """A user's public songs list stays query-bounded."""
    client = APIClient()
    url = reverse("user-public-songs", kwargs={"username": user.username})

    with django_assert_max_num_queries(5):
        response = client.get(url)

    assert response.status_code == 200


def test_public_profile_is_served_from_cache(
    django_assert_max_num_queries,
    user,
    many_songs,
):
    """
    Warming the public-profile cache means the second request
    avoids re-querying the user/profile object.

    The serializer may still run one COUNT query for public_song_count.
    """
    client = APIClient()
    url = reverse("public-profile", kwargs={"username": user.username})

    # First call — cold cache, hits DB, sets cache.
    r1 = client.get(url)
    assert r1.status_code == 200

    # Second call — warm cache.
    with django_assert_max_num_queries(1):
        r2 = client.get(url)

    assert r2.status_code == 200
    assert r1.data["username"] == r2.data["username"]
