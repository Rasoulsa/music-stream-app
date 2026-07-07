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
        Browser["Browser<br/>React SPA"]
    end

    subgraph edge["Edge Layer"]
        Nginx["Nginx<br/>Reverse Proxy"]
    end

    subgraph app["Application Layer"]
        Frontend["Frontend Container<br/>Vite build served by Nginx"]
        Backend["Backend Container<br/>Django + DRF + Gunicorn"]
        Celery["Celery Worker<br/>async audio tasks"]
    end

    subgraph data["Data Layer"]
        Postgres[("PostgreSQL")]
        Redis[("Redis<br/>Cache + Broker")]
        RedisQueue["Redis Queue<br/>Celery task queue"]
        MinIO[("MinIO / S3<br/>Media Storage")]
    end

    subgraph observability["Observability Layer"]
        Prometheus["Prometheus<br/>127.0.0.1 only"]
        NodeExporter["node_exporter<br/>host metrics"]
        CAdvisor["cAdvisor<br/>container metrics"]
        Grafana["Grafana<br/>127.0.0.1 only"]
    end

    Browser -->|HTTPS| Nginx
    Nginx -->|/| Frontend
    Nginx -->|/api/| Backend
    Nginx -->|/media/ proxy| MinIO

    Backend --> Postgres
    Backend --> Redis
    Backend --> MinIO
    Backend -->|enqueue tasks| RedisQueue

    RedisQueue --> Redis
    Celery -->|consume tasks| RedisQueue
    Celery --> Postgres
    Celery --> MinIO

    Prometheus -->|scrapes /metrics| Backend
    Prometheus -->|scrapes| NodeExporter
    Prometheus -->|scrapes| CAdvisor
    Grafana -->|queries| Prometheus
```

**Why a single Nginx edge?**

One public entrypoint simplifies TLS, security headers, gzip, and routing.
The browser only talks to Nginx. Internal services such as PostgreSQL, Redis,
Celery, and MinIO are kept inside the Docker network.

Prometheus scrapes application, host, and container metrics. Prometheus and
Grafana are bound to `127.0.0.1` on the VPS and are accessed through an SSH
tunnel instead of being exposed publicly.

---

## 2. Request Flow — Authentication

JWT-based authentication is handled by Django REST Framework and SimpleJWT.
The login endpoint is rate-limited to reduce brute-force risk.

```mermaid
sequenceDiagram
    participant B as Browser
    participant N as Nginx
    participant D as Django API
    participant R as Redis
    participant DB as PostgreSQL

    B->>N: POST /api/v1/auth/login/
    N->>D: Proxy request
    D->>R: Check login throttle

    alt Too many attempts
        D-->>B: 429 Too Many Requests
    else Allowed
        D->>DB: Verify username and password
        DB-->>D: User record
        D-->>B: JWT access and refresh tokens
    end

    B->>N: GET /api/v1/users/me/ with Bearer token
    N->>D: Proxy request
    D->>D: Validate JWT
    D->>DB: Load user profile
    D-->>B: 200 OK profile data
```

---

## 3. Request Flow — Upload and Stream

Uploads go to object storage through MinIO/S3. Celery extracts audio metadata
asynchronously. Streaming supports HTTP Range requests so users can seek inside
the audio player.

```mermaid
sequenceDiagram
    participant B as Browser
    participant N as Nginx
    participant D as Django API
    participant S as MinIO or S3
    participant R as Redis
    participant C as Celery
    participant DB as PostgreSQL

    B->>N: POST /api/v1/songs/ multipart upload
    N->>D: Proxy request
    D->>S: Store audio file
    D->>DB: Create Song row with pending status
    D->>R: Enqueue metadata task
    D-->>B: 201 Created with song data

    C->>R: Consume task
    C->>S: Read audio file
    C->>C: Extract duration with mutagen
    C->>DB: Update song duration and status

    B->>N: GET media file with Range header
    N->>S: Proxy media request
    S-->>B: 206 Partial Content
```

---

## 4. Feed Caching — Performance

The public feed is read-heavy and is cached in Redis. This reduces database
load and improves response time.

```mermaid
graph LR
    Request["GET /api/v1/feed/"] --> CacheCheck{"Redis cache hit?"}

    CacheCheck -->|Yes| Cached["Return cached response"]
    CacheCheck -->|No| Query["Query PostgreSQL"]

    Query --> Optimize["Use optimized query and indexes"]
    Optimize --> Store["Store response in Redis"]
    Store --> Response["Return API response"]
    Cached --> Response
```

See [`performance.md`](./performance.md) for performance notes.

---

## 5. Data Model

```mermaid
erDiagram
    USER ||--|| PROFILE : has
    USER ||--o{ SONG : owns

    USER {
        int id PK
        string username
        string email
        string password
    }

    PROFILE {
        int id PK
        int user_id FK
        string bio
        string avatar
    }

    SONG {
        int id PK
        int owner_id FK
        string title
        string artist
        string audio_file
        int duration_seconds
        string status
        bool is_public
        datetime created_at
    }
```

Indexing note: a composite index on public/recent songs supports the public
feed query.

Relevant migration:

```text
backend/music/migrations/0009_song_song_public_recent_idx_and_more.py
```

---

## 6. Production Deployment Topology

```mermaid
graph TB
    Internet["Internet"] -->|HTTP / HTTPS| Nginx["music-nginx<br/>public reverse proxy"]

    subgraph host["Single VPS / Docker Host"]
        Nginx --> Frontend["music-frontend<br/>React static app"]
        Nginx --> Backend["music-backend<br/>Django + Gunicorn"]
        Nginx --> MinIO["music-minio<br/>object storage API"]

        Backend --> DB["music-db<br/>PostgreSQL"]
        Backend --> Redis["music-redis<br/>cache + broker"]
        Backend --> MinIO

        Celery["music-celery<br/>background worker"] --> Redis
        Celery --> DB
        Celery --> MinIO
    end
```

Only Nginx is intended to be publicly exposed. Internal services such as
PostgreSQL, Redis, the backend container, Celery, and the MinIO console should
not be exposed directly in production.

The production smoke test verifies important deployment assumptions.

---

## 7. Backend Settings Modules

The backend uses separate settings modules for each environment.

```mermaid
graph TB
    Base["config.settings.base<br/>shared settings"]

    Base --> Dev["config.settings.dev<br/>local development"]
    Base --> CI["config.settings.ci<br/>tests and GitHub Actions"]
    Base --> Prod["config.settings.production<br/>hardened production"]
```

Settings files:

```text
backend/config/settings/
├── base.py
├── dev.py
├── ci.py
└── production.py
```

| Settings module | Purpose |
|---|---|
| `config.settings.base` | Shared Django/DRF configuration |
| `config.settings.dev` | Local development |
| `config.settings.ci` | Automated tests and GitHub Actions |
| `config.settings.production` | Production security, Redis cache, object storage |

---

## 8. API Route Map

```mermaid
graph TB
    API["Music Stream API"]

    API --> Health["/api/health/"]
    API --> Docs["/api/schema/<br/>/api/docs/<br/>/api/redoc/"]
    API --> V1["/api/v1/"]

    V1 --> Auth["auth<br/>register, login, refresh"]
    V1 --> Songs["songs<br/>list, upload, detail, mine"]
    V1 --> Users["users<br/>me, public profile, public songs"]
    V1 --> Feed["feed<br/>cached public feed"]
```

Main API routes:

| Endpoint | Purpose |
|---|---|
| `/api/health/` | Health check |
| `/api/schema/` | OpenAPI schema |
| `/api/docs/` | Swagger UI |
| `/api/redoc/` | Redoc UI |
| `/api/v1/auth/register/` | User registration |
| `/api/v1/auth/login/` | JWT login |
| `/api/v1/auth/refresh/` | JWT refresh |
| `/api/v1/songs/` | Song list and upload |
| `/api/v1/songs/mine/` | Current user's songs |
| `/api/v1/feed/` | Public cached feed |
| `/api/v1/users/me/` | Current user's profile |
| `/api/v1/users/<username>/` | Public user profile |
| `/api/v1/users/<username>/songs/` | Public songs by user |

---

## 9. Security Architecture

```mermaid
graph TB
    Browser["Browser"] --> Nginx["Nginx"]

    Nginx --> Headers["Security headers<br/>CORS<br/>gzip<br/>hidden server tokens"]
    Nginx --> Backend["Django API"]

    Backend --> Auth["JWT authentication"]
    Backend --> Throttle["DRF throttling<br/>login/register/upload"]
    Backend --> Env["Environment-based secrets"]
    Backend --> Storage["Private/internal object storage"]
```

Security highlights:

- `DEBUG=False` in production
- environment-based secrets
- CORS configuration
- security headers
- hidden Nginx version
- JWT authentication
- login/register/upload throttling
- MinIO console not publicly exposed in production
- smoke test checks security assumptions

See [`security.md`](./security.md).

---

## 10. Key Design Decisions

| Decision | Why |
|---|---|
| Versioned API under `/api/v1/` | Allows future breaking changes without breaking existing clients |
| Unversioned `/api/health/` | Stable health check for Docker, Nginx, and deployment checks |
| JWT authentication | Works well with a React SPA and stateless API design |
| MinIO/S3 object storage | Better fit for uploaded media than container-local disk |
| Celery background worker | Keeps upload requests fast by processing audio metadata asynchronously |
| Redis as broker | Celery uses Redis for task queueing |
| Redis as cache | Improves public feed performance and supports throttling |
| Nginx reverse proxy | Central routing, security headers, gzip, and media proxying |
| Docker Compose | Reproducible dev and production-like environments |
| Split settings modules | Clean separation between dev, CI, and production |
| OpenAPI schema | API contract can be documented and frozen |
| Smoke tests | Confidence that the full production-like stack works end to end |

---

## 11. Related Documentation

- [`env-management.md`](./env-management.md)
- [`security.md`](./security.md)
- [`performance.md`](./performance.md)
- [Monitoring and logging](monitoring.md)
- [`smoke-tests.md`](./smoke-tests.md)
- [`JOURNAL.md`](./JOURNAL.md)
