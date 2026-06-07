"""
Serializers for the music app.
"""

from rest_framework import serializers

from music.models import Song


class SongSerializer(serializers.ModelSerializer):
    """
    Serializer for the Song model.
    """

    class Meta:
        model = Song
        fields = [
            "id",
            "title",
            "artist",
            "album",
            "audio_file",
            "cover_image",
            "duration_seconds",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

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
