# Create your models here.
"""
Models for the music app.
"""

from django.conf import settings
from django.db import models


class Song(models.Model):
    """
    Represents a single song/track in the music library.

    Files are stored in S3-compatible object storage (MinIO locally, S3 in prod).
    Storage backend is configured via STORAGES['default'] — no model changes
    needed when switching between local disk, MinIO, and AWS S3.
    """

    class ProcessingStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        PROCESSING = "processing", "Processing"
        READY = "ready", "Ready"
        FAILED = "failed", "Failed"

    title = models.CharField(
        max_length=255,
        help_text="The title of the song.",
    )
    artist = models.CharField(
        max_length=255,
        help_text="The name of the artist or band.",
    )
    album = models.CharField(
        max_length=255,
        blank=True,
        help_text="The album this song belongs to (optional).",
    )
    audio_file = models.FileField(
        upload_to="songs/audio/",
        blank=True,
        null=True,
        help_text="The audio file for the song.",
    )
    cover_image = models.ImageField(
        upload_to="songs/covers/",
        blank=True,
        null=True,
        help_text="Cover art for the song (optional).",
    )
    duration_seconds = models.PositiveIntegerField(
        default=0
    )  # seconds (filled by task)
    status = models.CharField(
        max_length=20,
        choices=ProcessingStatus.choices,
        default=ProcessingStatus.PENDING,
    )
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="songs",
        help_text="The user who uploaded this song.",
    )
    is_public = models.BooleanField(
        default=True,
        help_text="If true, the song is visible in the public feed. "
        "If false, only the owner can see it.",
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When the song was added.",
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="When the song was last updated.",
    )

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Song"
        verbose_name_plural = "Songs"
        indexes = [
            # Public feed: WHERE is_public=True ORDER BY -created_at
            # One index satisfies both the filter AND the sort.
            models.Index(
                fields=["is_public", "-created_at"],
                name="song_public_recent_idx",
            ),
            # "My songs" / user public songs: WHERE owner=? ORDER BY -created_at
            models.Index(
                fields=["owner", "-created_at"],
                name="song_owner_recent_idx",
            ),
            # SongViewSet authenticated queryset: owner + visibility combo
            models.Index(
                fields=["owner", "is_public"],
                name="song_owner_public_idx",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.title} — {self.artist}"


class Profile(models.Model):
    """
    Extended user profile.

    Auto-created via post_save signal on User registration.
    Avatar stored in object storage (MinIO/S3).
    """

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    display_name = models.CharField(max_length=80, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    avatar = models.ImageField(
        upload_to="avatars/",
        blank=True,
        null=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Profile<{self.user.username}>"
