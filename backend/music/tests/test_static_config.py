from django.conf import settings


def test_static_root_configured():
    assert settings.STATIC_ROOT is not None
    assert str(settings.STATIC_ROOT).endswith("staticfiles")


def test_static_url_configured():
    assert settings.STATIC_URL == "/static/"


def test_proxy_ssl_header_configured():
    assert settings.SECURE_PROXY_SSL_HEADER == (
        "HTTP_X_FORWARDED_PROTO",
        "https",
    )
