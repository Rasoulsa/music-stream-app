"""
Admin configuration for the music app.
"""

from django.contrib import admin

from music.models import Song


@admin.register(Song)
class SongAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "artist",
        "album",
        "owner",
        "is_public",
        "duration_seconds",
        "created_at",
    )
    list_filter = ("is_public", "artist", "album", "created_at")
    search_fields = ("title", "artist", "album", "owner__username")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("-created_at",)
