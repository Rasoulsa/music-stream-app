"""
URL configuration for the music app.
"""

from rest_framework.routers import DefaultRouter

from music.views import SongViewSet

router = DefaultRouter()
router.register(r"songs", SongViewSet, basename="song")

urlpatterns = router.urls
