import pytest
from django.contrib.auth import get_user_model
from rest_framework import serializers

from music.serializers import ProfileSerializer, SongSerializer


def test_song_serializer_validate_artist_rejects_blank_artist():
    serializer = SongSerializer()

    with pytest.raises(serializers.ValidationError) as exc_info:
        serializer.validate_artist("   ")

    assert str(exc_info.value.detail[0]) == "Artist cannot be empty."


@pytest.mark.django_db
def test_profile_serializer_updates_user_email():
    User = get_user_model()
    user = User.objects.create_user(
        username="profile_email_user",
        email="old@example.com",
        password="strong-test-password",
    )

    profile = user.profile

    serializer = ProfileSerializer(
        instance=profile,
        data={
            "email": "new@example.com",
            "display_name": "Updated Display Name",
        },
        partial=True,
    )

    assert serializer.is_valid(), serializer.errors

    updated_profile = serializer.save()

    user.refresh_from_db()
    updated_profile.refresh_from_db()

    assert user.email == "new@example.com"
    assert updated_profile.display_name == "Updated Display Name"
