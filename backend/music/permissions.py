from rest_framework import permissions


class IsOwnerOrReadOnly(permissions.BasePermission):
    """Read for anyone allowed; write only for the song's owner."""

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.owner == request.user
