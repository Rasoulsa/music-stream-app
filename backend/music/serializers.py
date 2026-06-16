"""
Serializers for the music app.
"""

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from music.models import Song

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
    )

    class Meta:
        model = User
        fields = ("id", "username", "email", "password")

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data["username"],
            email=validated_data.get("email", ""),
            password=validated_data["password"],
        )
        return user


class SongSerializer(serializers.ModelSerializer):
    """
    Serializer for the Song model.
    """

    owner = serializers.ReadOnlyField(source="owner.username")

    class Meta:
        model = Song
        fields = [
            "id",
            "title",
            "artist",
            "is_public",
            "owner",
            "album",
            "audio_file",
            "cover_image",
            "duration_seconds",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["owner", "created_at", "updated_at"]

    def validate_title(self, value: str) -> str:
        """Ensure the title is not blank or whitespace only."""
        if not value.strip():
            raise serializers.ValidationError("Title cannot be empty.")
        return value

    def validate_artist(self, value: str) -> str:
        """Ensure the artist is not blank or whitespace only."""
        if not value.strip():
            raise serializers.ValidationError("Artist cannot be empty.")
        return value
