"""
Custom API throttles.

DRF throttling uses Django's cache backend. In production we use Redis,
so throttle counters are shared across Gunicorn workers/containers.
"""

from rest_framework.throttling import AnonRateThrottle, UserRateThrottle


class LoginRateThrottle(AnonRateThrottle):
    """
    Throttle anonymous login attempts by client IP.

    Scope name must match REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"]["login"].
    """

    scope = "login"


class RegisterRateThrottle(AnonRateThrottle):
    """
    Throttle anonymous registration attempts by client IP.
    """

    scope = "register"


class UploadRateThrottle(UserRateThrottle):
    """
    Throttle authenticated song uploads by user id.
    """

    scope = "upload"
