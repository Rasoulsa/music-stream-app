"""
Request ID middleware.

Assigns a unique ID to every request so logs and responses can be correlated.
Reuses an inbound X-Request-ID if present (set by the edge proxy), else
generates a UUID4. Echoes it back in the X-Request-ID response header.
"""

import uuid

from .logging import request_id_var

REQUEST_ID_HEADER = "X-Request-ID"


class RequestIDMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        incoming = request.headers.get(REQUEST_ID_HEADER)
        request_id = incoming or uuid.uuid4().hex

        token = request_id_var.set(request_id)
        request.request_id = request_id

        try:
            response = self.get_response(request)
        finally:
            request_id_var.reset(token)

        response[REQUEST_ID_HEADER] = request_id
        return response
