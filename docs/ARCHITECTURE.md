# Architecture — Music Stream App

This document describes the system architecture, request/data flows, and the
key design decisions behind the Music Stream App.

> For the build history and reasoning behind each step, see
> [`JOURNAL.md`](./JOURNAL.md).

---

## 1. System Overview

A full-stack, containerized music streaming platform. Users register, upload
audio files, and stream them with seeking support. The backend exposes a
versioned REST API; the frontend is a React SPA. Nginx is the single public
edge proxy.

```mermaid
graph TB
    subgraph client["Client"]
        Browser["Browser<br/>(React SPA)"]
    end

    subgraph edge["Edge Layer"]
        Nginx["Nginx<br/>reverse proxy + static + media"]
    end

    subgraph app["Application Layer"]
        Frontend["Frontend container<br/>(Nginx serving Vite build)"]
        Backend["Backend container<br/>(Django + DRF + Gunicorn)"]
        Celery["Celery worker<br/>(async audio tasks)"]
    end

    subgraph data["Data Layer"]
        Postgres[("PostgreSQL<br/>relational data")]
        Redis[("Redis<br/>cache + broker")]
        MinIO[("MinIO / S3<br/>object storage")]
    end

    Browser -->|HTTPS| Nginx
    Nginx -->|/| Frontend
    Nginx -->|/api/| Backend
    Nginx -->|/media/ proxy| MinIO

    Backend --> Postgres
    Backend --> Redis
    Backend --> MinIO
    Backend -->|enqueue tasks| Redis
    Celery -->|consume tasks| Redis
    Celery --> Postgres
    Celery --> MinIO
Why a single Nginx edge? One public entrypoint simplifies TLS, security
headers, gzip, and routing. The browser only ever talks to Nginx; internal
services (Postgres, Redis, MinIO API, MinIO console) are never exposed to the
host in production.

2. Request Flow — Authentication
JWT-based auth using djangorestframework-simplejwt. The login endpoint is
rate-limited to mitigate brute-force attacks.

Syntax error in text
mermaid version 11.15.0
Syntax error in text
mermaid version 11.15.0
3. Request Flow — Upload & Stream
Uploads go to object storage (MinIO/S3). Celery extracts metadata
asynchronously. Streaming supports HTTP Range requests for seeking.

PostgreSQL
Celery
Redis
MinIO/S3
Django/DRF
Nginx
Browser
later — playback
POST /api/v1/songs/ (multipart, Bearer)
proxy
store audio file
create Song (status=pending)
enqueue extract-metadata task
201 { id, audio_file URL }
pull task
read audio file
parse duration (mutagen)
update Song (duration, status=ready)
GET /media/songs/audio/... (Range: bytes=0-)
proxy Range request
206 Partial Content (seeking works)
4. Feed Caching (Performance)
The public feed is read-heavy and cached in Redis. See
performance.md for measurements.

yes

no

GET /api/v1/feed/

cache hit?

return cached payload
(0 DB queries)

query DB
(select_related / prefetch)

store in Redis
(short TTL)

return response

5. Data Model
has

owns

USER

int

id

PK

string

username

string

email

string

password

PROFILE

int

id

PK

int

user_id

FK

string

bio

image

avatar

SONG

int

id

PK

int

owner_id

FK

string

title

string

artist

file

audio_file

int

duration_seconds

string

status

bool

is_public

datetime

created_at

Indexing note: a composite index (is_public, -created_at) backs the public
feed query (song_public_recent_idx, migration 0009).

6. Deployment Topology
Single Host (Docker Compose)

:80 / :443

music-nginx
:80 (public)

music-frontend

music-backend (Gunicorn)

music-celery

music-db
PostgreSQL

music-redis

music-minio
:9000 API (internal)

Internet

Only Nginx is published to the host. In production the MinIO console (:9001)
is intentionally not exposed — verified by the smoke test.

7. Key Design Decisions
Decision	Why
Versioned API (/api/v1/)	Allows breaking changes later without breaking clients. Health check stays unversioned so infra checks never break.
Health check unversioned	Docker/Nginx healthchecks must be stable across API version bumps.
Object storage (MinIO/S3) instead of disk	Scalable, decoupled from app containers, S3-compatible for cloud migration.
Celery for metadata	Keeps upload requests fast; audio parsing happens async.
Redis for cache + broker	One dependency, two jobs: response caching and task queue.
JWT auth	Stateless, scales horizontally, standard for SPA + API.
Login rate limiting	Brute-force protection (5/min/IP via AnonRateThrottle).
Nginx serves media via proxy	Centralizes Range-request handling and security headers.
Split settings modules	base / dev / ci / production — clean separation, safe defaults.
8. Settings Modules
pgsql
config/settings/
├── base.py        # shared defaults
├── dev.py         # local development (DEBUG=True)
├── ci.py          # CI/test (DEBUG=False, fast, deterministic)
└── production.py  # hardened (security headers, Redis cache, S3)
9. Related Documentation
Environment & Secrets
Security Posture
Performance
Smoke Tests
Build Journal EOF
