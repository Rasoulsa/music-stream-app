"""
Root URL configuration.

API is versioned under /api/v1/.
Health check stays UNVERSIONED at /api/health/ so Docker/Nginx
healthchecks never break across API version bumps.
"""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from music.views import RegisterView, health_check

urlpatterns = [
    path("admin/", admin.site.urls),
    # ── Health check (UNVERSIONED — infra/healthchecks) ─────────────
    path("api/health/", health_check, name="health-check"),
    # ── Authentication (versioned) ──────────────────────────────────
    path(
        "api/v1/auth/register/",
        RegisterView.as_view(),
        name="register",
    ),
    path(
        "api/v1/auth/login/",
        TokenObtainPairView.as_view(),
        name="token-obtain-pair",
    ),
    path(
        "api/v1/auth/refresh/",
        TokenRefreshView.as_view(),
        name="token-refresh",
    ),
    # ── Versioned API endpoints ─────────────────────────────────────
    path("api/v1/", include("music.urls")),
    # ── OpenAPI schema (unversioned — always current contract) ──────
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "api/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
]

# Serve uploaded media files
# NOTE: In production with nginx, nginx serves /media/ directly.
# For local Docker testing over HTTP, Django/Gunicorn handles it here.
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
