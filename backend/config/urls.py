"""
Root URL configuration.
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
    # Health check
    path("api/health/", health_check, name="health-check"),
    # Authentication
    path(
        "api/auth/register/",
        RegisterView.as_view(),
        name="register",
    ),
    path(
        "api/auth/login/",
        TokenObtainPairView.as_view(),
        name="token-obtain-pair",
    ),
    path(
        "api/auth/refresh/",
        TokenRefreshView.as_view(),
        name="token-refresh",
    ),
    # API endpoints
    path("api/", include("music.urls")),
    # OpenAPI schema (raw JSON/YAML)
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    # Swagger UI (interactive docs)
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    # ReDoc (clean documentation view)
    path(
        "api/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
]

# Serve uploaded media files
# NOTE: In production with nginx, nginx should serve /media/ directly.
# For local Docker testing over HTTP, Django/Gunicorn handles it here.
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
