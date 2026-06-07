# Create your models here.
"""
Models for the music app.
"""

from django.db import models


class Song(models.Model):
    """
    Represents a single song/track in the music library.
    """

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
        help_text="The audio file for the song.",
    )
    cover_image = models.ImageField(
        upload_to="songs/covers/",
        blank=True,
        null=True,
        help_text="Cover art for the song (optional).",
    )
    duration_seconds = models.PositiveIntegerField(
        default=0,
        help_text="Duration of the song in seconds.",
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

    def __str__(self) -> str:
        return f"{self.title} — {self.artist}"
