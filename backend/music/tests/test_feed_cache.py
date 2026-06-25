"""
Feed cache tests.

Covers the cache-hit branch in FeedView.list().
"""

import pytest
from django.core.cache import cache
from django.urls import reverse
from rest_framework.test import APIClient

pytestmark = pytest.mark.django_db


def test_feed_default_response_can_be_served_from_cache(django_assert_num_queries):
    """
    If the default feed response already exists in cache, FeedView should
    return it directly without querying the database.
    """
    client = APIClient()
    url = reverse("feed")

    cached_payload = {
        "count": 123,
        "next": None,
        "previous": None,
        "results": [],
    }

    cache.set("feed:default", cached_payload, timeout=60)

    with django_assert_num_queries(0):
        response = client.get(url)

    assert response.status_code == 200
    assert response.data == cached_payload
