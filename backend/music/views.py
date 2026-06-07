"""
Views for the music app.
"""

from drf_spectacular.utils import extend_schema
from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

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
    """

    queryset = Song.objects.all()
    serializer_class = SongSerializer
    parser_classes = [MultiPartParser, FormParser]
