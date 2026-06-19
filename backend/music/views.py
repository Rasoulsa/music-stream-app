"""
Views for the music app.
"""

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.db.models import Q
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import api_view, permission_classes
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from music.filters import SongFilter
from music.models import Song
from music.permissions import IsOwnerOrReadOnly
from music.serializers import (
    ProfileSerializer,
    PublicProfileSerializer,
    RegisterSerializer,
    SongSerializer,
)
from music.tasks import process_song_audio

User = get_user_model()


# ── Health ─────────────────────────────────────────────────────────────────────


@extend_schema(
    tags=["health"],
    summary="Health check",
    description="Returns the service status and cache health. Used by load "
    "balancers, Docker healthchecks, and monitoring.",
    responses={
        200: {
            "type": "object",
            "properties": {
                "status": {"type": "string", "example": "ok"},
                "service": {"type": "string", "example": "music-stream-app"},
                "cache": {"type": "string", "example": "ok"},
            },
        }
    },
)
@api_view(["GET"])
@permission_classes([AllowAny])
def health_check(request):
    """Simple health check — reports service name and cache status."""
    cache_ok = False
    try:
        cache.set("healthcheck", "ok", timeout=5)
        cache_ok = cache.get("healthcheck") == "ok"
    except Exception:  # pragma: no cover
        cache_ok = False

    return Response(
        {
            "status": "ok",
            "service": "music-stream-app",
            "cache": "ok" if cache_ok else "unavailable",
        }
    )


# ── Authentication ─────────────────────────────────────────────────────────────


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


# ── Songs ──────────────────────────────────────────────────────────────────────


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
    filterset_class = SongFilter
    search_fields = ["title", "artist", "album"]
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

        Anonymous users  → only public songs
        Authenticated    → all public songs + their own private songs
        """
        if getattr(self, "swagger_fake_view", False):
            return Song.objects.none()

        user = self.request.user
        base = Song.objects.select_related("owner")

        if user.is_authenticated:
            return base.filter(Q(is_public=True) | Q(owner=user))
        return base.filter(is_public=True)

    def perform_create(self, serializer):
        song = serializer.save(owner=self.request.user)
        # Queue background processing (async in Docker/prod, inline in dev/tests).
        process_song_audio.delay(song.id)


# ── Profiles ───────────────────────────────────────────────────────────────────


@extend_schema(tags=["profiles"])
class MyProfileView(APIView):
    """Retrieve or update the authenticated user's own profile."""

    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    @extend_schema(
        responses=ProfileSerializer,
        summary="Get my profile",
    )
    def get(self, request):
        serializer = ProfileSerializer(request.user.profile)
        return Response(serializer.data)

    @extend_schema(
        request=ProfileSerializer,
        responses=ProfileSerializer,
        summary="Update my profile",
    )
    def patch(self, request):
        serializer = ProfileSerializer(
            request.user.profile,
            data=request.data,
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


@extend_schema(
    tags=["profiles"],
    responses=PublicProfileSerializer,
    summary="Get public profile by username",
)
class PublicProfileView(generics.RetrieveAPIView):
    """Public profile of any user by username (no email exposed)."""

    permission_classes = [AllowAny]
    serializer_class = PublicProfileSerializer

    def get_object(self):
        user = get_object_or_404(User, username=self.kwargs["username"])
        return user.profile


# ── Per-user public songs ──────────────────────────────────────────────────────


@extend_schema(
    tags=["songs"],
    summary="List a user's public songs",
    responses=SongSerializer(many=True),
)
class UserPublicSongsView(generics.ListAPIView):
    """List a given user's PUBLIC songs only."""

    permission_classes = [AllowAny]
    serializer_class = SongSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Song.objects.none()
        user = get_object_or_404(User, username=self.kwargs["username"])
        return Song.objects.filter(owner=user, is_public=True).select_related("owner")


# ── My songs ───────────────────────────────────────────────────────────────────


@extend_schema(
    tags=["songs"],
    summary="List my songs (public + private)",
    responses=SongSerializer(many=True),
)
class MySongsView(generics.ListAPIView):
    """Authenticated user's own songs — both public and private."""

    permission_classes = [IsAuthenticated]
    serializer_class = SongSerializer

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Song.objects.none()
        return Song.objects.filter(owner=self.request.user).select_related("owner")


# ── Feed ───────────────────────────────────────────────────────────────────────


@extend_schema(
    tags=["feed"],
    summary="Public feed of all public songs",
    responses=SongSerializer(many=True),
)
class FeedView(generics.ListAPIView):
    """Public feed — all public songs, paginated, filterable, cached."""

    permission_classes = [AllowAny]
    serializer_class = SongSerializer
    queryset = Song.objects.filter(is_public=True).select_related("owner")

    filterset_class = SongFilter
    search_fields = ["title", "artist", "album"]
    ordering_fields = [
        "title",
        "artist",
        "duration_seconds",
        "created_at",
        "updated_at",
    ]
    ordering = ["-created_at"]

    def list(self, request, *args, **kwargs):
        # Only cache the unfiltered, first-page default view.
        # Filtered/searched/paginated queries bypass cache (always fresh).
        if request.query_params:
            return super().list(request, *args, **kwargs)

        cache_key = "feed:default"
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        response = super().list(request, *args, **kwargs)
        cache.set(cache_key, response.data, timeout=60)  # 60s TTL
        return response
