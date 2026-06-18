"""
Serializers for the music app.
"""

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from music.models import Profile, Song

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
    title = serializers.CharField(allow_blank=True)
    artist = serializers.CharField(allow_blank=True)

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


class ProfileSerializer(serializers.ModelSerializer):
    """Own profile (authenticated user) — includes email + total song count."""

    username = serializers.CharField(source="user.username", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    song_count = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            "username",
            "email",
            "display_name",
            "bio",
            "song_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["username", "email", "created_at", "updated_at"]

    def get_song_count(self, obj: Profile) -> int:
        return obj.user.songs.count()


class PublicProfileSerializer(serializers.ModelSerializer):
    """Public profile — no email, only public song count."""

    username = serializers.CharField(source="user.username", read_only=True)
    public_song_count = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = [
            "username",
            "display_name",
            "bio",
            "public_song_count",
            "created_at",
        ]

    def get_public_song_count(self, obj: Profile) -> int:
        return obj.user.songs.filter(is_public=True).count()
