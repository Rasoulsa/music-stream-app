"""
Test that the database and Django ORM are working.
"""

import pytest
from django.contrib.auth.models import User


@pytest.mark.django_db
def test_can_create_user():
    user = User.objects.create_user(
        username="testuser",
        password="testpass123",
    )

    assert user.id is not None
    assert User.objects.count() == 1
    assert user.username == "testuser"
