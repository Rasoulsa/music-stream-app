"""
Views for the music app.
"""

from drf_spectacular.utils import extend_schema
from rest_framework.decorators import api_view
from rest_framework.response import Response


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
