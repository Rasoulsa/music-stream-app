"""
URL configuration for the music app.
"""

from django.urls import path
from rest_framework.routers import DefaultRouter

from music.views import (
    FeedView,
    MyProfileView,
    MySongsView,
    PublicProfileView,
    SongViewSet,
    UserPublicSongsView,
    health_check,
)

router = DefaultRouter()
router.register(r"songs", SongViewSet, basename="song")

urlpatterns = [
    # ⚠️ Explicit paths MUST come before router.urls,
    # otherwise 'mine' would be matched as songs/<pk>/
    path("health/", health_check, name="health-check"),
    path("songs/mine/", MySongsView.as_view(), name="my-songs"),
    path("feed/", FeedView.as_view(), name="feed"),
    path("users/me/", MyProfileView.as_view(), name="my-profile"),
    path("users/<str:username>/", PublicProfileView.as_view(), name="public-profile"),
    path(
        "users/<str:username>/songs/",
        UserPublicSongsView.as_view(),
        name="user-public-songs",
    ),
] + router.urls
