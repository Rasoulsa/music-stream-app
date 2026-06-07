"""
Admin configuration for the music app.
"""

from django.contrib import admin

from music.models import Song


@admin.register(Song)
class SongAdmin(admin.ModelAdmin):
    list_display = ("title", "artist", "album", "duration_seconds", "created_at")
    list_filter = ("artist", "album", "created_at")
    search_fields = ("title", "artist", "album")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("-created_at",)
