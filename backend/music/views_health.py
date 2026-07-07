"""
Health / readiness endpoint.

GET /api/health/ verifies critical dependencies (db, cache).
Returns 200 when healthy, 503 when degraded.
Unauthenticated and unthrottled so monitors can call it frequently.
"""

import logging

from django.core.cache import cache
from django.db import connection
from drf_spectacular.utils import extend_schema
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
    throttle_classes,
)
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

logger = logging.getLogger(__name__)


def _check_database() -> tuple[bool, str]:
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return True, "ok"
    except Exception as exc:  # noqa: BLE001
        logger.error("Health DB failure: %s", exc)
        return False, "error"


def _check_cache() -> tuple[bool, str]:
    try:
        cache.set("healthcheck", "ok", timeout=5)
        if cache.get("healthcheck") == "ok":
            return True, "ok"
        return False, "unexpected_value"
    except Exception as exc:  # noqa: BLE001
        logger.error("Health cache failure: %s", exc)
        return False, "error"


@extend_schema(exclude=True)
@api_view(["GET"])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([])
def health(request):
    db_ok, db_status = _check_database()
    cache_ok, cache_status = _check_cache()
    all_ok = db_ok and cache_ok

    body = {
        "status": "ok" if all_ok else "degraded",
        "service": "music-stream-app",  # preserved for backward compatibility
        "checks": {"database": db_status, "cache": cache_status},
        "request_id": getattr(request, "request_id", "-"),
    }
    return Response(body, status=200 if all_ok else 503)
