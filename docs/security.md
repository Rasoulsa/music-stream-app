# Security — Music Stream App

This document describes the security posture of the application
(Integration & Production).

## Threat model

| Threat | Mitigation |
|---|---|
| Cross-origin browser attacks | CORS allowlist (`CORS_ALLOWED_ORIGINS`), no wildcard |
| Clickjacking | `X-Frame-Options: DENY` (Django + nginx) |
| MIME sniffing | `X-Content-Type-Options: nosniff` |
| Protocol downgrade | HSTS (`SECURE_HSTS_SECONDS`), SSL redirect |
| Session hijacking | `Secure` + `HttpOnly` cookies, `SameSite=Lax` |
| Brute-force login | DRF `ScopedRateThrottle` — 5 login attempts/min/IP |
| API abuse | Anon 30/min, authenticated 120/min |
| Upload abuse / DoS | Upload throttle 10/min + nginx `client_max_body_size 50M` |
| Info disclosure | `server_tokens off` (hide nginx version), `DEBUG=False` |
| CSRF | Django CSRF middleware + `CSRF_TRUSTED_ORIGINS` |

## Rate limits

| Scope | Limit | Applies to |
|---|---|---|
| `anon` | 30/min | Unauthenticated requests |
| `user` | 120/min | Authenticated requests |
| `login` | 5/min | `POST /api/v1/auth/token/` |
| `upload` | 10/min | `POST /api/v1/songs/` (file upload) |

> Throttle counts are stored in the cache backend (Redis in production).

## Security headers (verify)

```bash
curl -sI https://yourdomain.com/api/health/
```
Expected:

- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Referrer-Policy: same-origin
- Strict-Transport-Security: max-age=31536000; includeSubDomains (once HTTPS live)
- o Server: nginx/<version> (version hidden)
