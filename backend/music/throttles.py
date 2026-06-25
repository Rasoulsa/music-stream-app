"""Custom rate-limit throttles (security pass)."""

from rest_framework.throttling import ScopedRateThrottle


class LoginRateThrottle(ScopedRateThrottle):
    """Brute-force protection for the JWT login endpoint."""

    scope = "login"


class RegisterRateThrottle(ScopedRateThrottle):
    """Abuse protection for account registration."""

    scope = "login"  # reuse the strict login bucket for signups


class UploadRateThrottle(ScopedRateThrottle):
    """Abuse/DoS protection for expensive file uploads."""

    scope = "upload"
