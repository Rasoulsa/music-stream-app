"""
Filters for the music app.
"""

import django_filters

from music.models import Song


class SongFilter(django_filters.FilterSet):
    """
    Filter set for the Song model.

    Supports case-insensitive partial matches on artist and album,
    and exact/range filtering on duration.
    """

    artist = django_filters.CharFilter(
        field_name="artist",
        lookup_expr="icontains",
        help_text="Filter by artist (case-insensitive, partial match).",
    )
    album = django_filters.CharFilter(
        field_name="album",
        lookup_expr="icontains",
        help_text="Filter by album (case-insensitive, partial match).",
    )
    min_duration = django_filters.NumberFilter(
        field_name="duration_seconds",
        lookup_expr="gte",
        help_text="Minimum duration in seconds.",
    )
    max_duration = django_filters.NumberFilter(
        field_name="duration_seconds",
        lookup_expr="lte",
        help_text="Maximum duration in seconds.",
    )

    class Meta:
        model = Song
        fields = ["artist", "album", "min_duration", "max_duration"]
