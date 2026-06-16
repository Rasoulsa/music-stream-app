"""
Views for the music app.
"""

from django.contrib.auth import get_user_model
from django.db.models import Q
from drf_spectacular.utils import extend_schema
from rest_framework import generics, permissions, viewsets
from rest_framework.decorators import api_view
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response

from music.filters import SongFilter
from music.models import Song
from music.permissions import IsOwnerOrReadOnly
from music.serializers import RegisterSerializer, SongSerializer

User = get_user_model()


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


@extend_schema(tags=["Authentication"])
class RegisterView(generics.CreateAPIView):
    """
    API endpoint for registering a new user.

    Creates a new user account with username, email, and password.
    After registration, the user can log in using the JWT login endpoint.
    """

    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = (permissions.AllowAny,)


@extend_schema(tags=["Songs"])
class SongViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing songs.

    Provides list, create, retrieve, update, and delete operations.
    Supports multipart uploads for audio files and cover images.

    Visibility rules:
    - Anonymous users can see only public songs.
    - Authenticated users can see public songs plus their own private songs.
    - Only authenticated users can create songs.
    - Only the owner of a song can update or delete it.

    Query parameters:
    - search: free-text search across title, artist, and album
    - artist: filter by artist (partial, case-insensitive)
    - album: filter by album (partial, case-insensitive)
    - min_duration / max_duration: filter by duration in seconds
    - is_public: filter by visibility
    - ordering: sort by title, artist, duration_seconds, or created_at
      (prefix with '-' for descending)
    """

    serializer_class = SongSerializer
    parser_classes = [MultiPartParser, FormParser]

    permission_classes = (
        permissions.IsAuthenticatedOrReadOnly,
        IsOwnerOrReadOnly,
    )

    # Filtering
    filterset_class = SongFilter

    # Free-text search
    search_fields = ["title", "artist", "album"]

    # Sorting
    ordering_fields = [
        "title",
        "artist",
        "duration_seconds",
        "created_at",
        "updated_at",
    ]
    ordering = ["-created_at"]

    def get_queryset(self):
        """
        Return songs based on the current user's authentication state.

        Anonymous users:
        - only public songs

        Authenticated users:
        - all public songs
        - their own private songs
        """
        user = self.request.user

        base_queryset = Song.objects.select_related("owner")

        if user.is_authenticated:
            return base_queryset.filter(Q(is_public=True) | Q(owner=user))

        return base_queryset.filter(is_public=True)

    def perform_create(self, serializer):
        """
        Automatically set the current authenticated user as the song owner.
        """
        serializer.save(owner=self.request.user)
