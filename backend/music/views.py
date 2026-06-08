"""
Views for the music app.
"""

from drf_spectacular.utils import extend_schema
from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from music.filters import SongFilter
from music.models import Song
from music.serializers import SongSerializer


@extend_schema(
    summary="Health check",
    description="Returns the service status. Used by load balancers, "
    "Docker healthchecks, and monitoring.",
    responses={
        200: {
            "type": "object",
            "properties": {
                "status": {"type": "string", "example": "ok"},
                "service": {
                    "type": "string",
                    "example": "music-stream-app",
                },
            },
        }
    },
)
@api_view(["GET"])
def health_check(request):
    """
    Simple health check endpoint.
    """
    return Response({"status": "ok", "service": "music-stream-app"})


@extend_schema(tags=["Songs"])
class SongViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing songs.

    Provides list, create, retrieve, update, and delete operations.
    Supports multipart uploads for audio files and cover images.

    Query parameters:
    - search: free-text search across title, artist, and album
    - artist: filter by artist (partial, case-insensitive)
    - album: filter by album (partial, case-insensitive)
    - min_duration / max_duration: filter by duration in seconds
    - ordering: sort by title, artist, duration_seconds, or created_at
      (prefix with '-' for descending)
    """

    queryset = Song.objects.all()
    serializer_class = SongSerializer
    parser_classes = [MultiPartParser, FormParser]

    # Filtering
    filterset_class = SongFilter

    # Free-text search
    search_fields = ["title", "artist", "album"]

    # Sorting
    ordering_fields = ["title", "artist", "duration_seconds", "created_at"]
    ordering = ["-created_at"]  # default sort
