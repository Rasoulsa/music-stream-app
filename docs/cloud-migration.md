# Cloud Migration Guide (AWS)

> **Status:** Conceptual + partially validated.
> The application is **cloud-ready by design**: storage is S3-native, the
> database is standard PostgreSQL, and the cache/broker is standard Redis.
> Migrating to managed AWS services is primarily a **configuration** change,
> not a rewrite.

---

## 1. Why managed cloud services?

Self-managing infrastructure on a VPS means **you** own:

- OS patching and security updates
- Database backups, replication, failover
- Storage durability and scaling
- Cache high availability
- Capacity planning and scaling
- Monitoring the underlying host

Managed services (S3, RDS, ElastiCache) shift most of this **operational
burden** to the cloud provider, at the cost of money and some flexibility.

The trade-off:

| | VPS (self-managed) | Managed cloud |
|---|---|---|
| Control | Full | Limited |
| Ops burden | High | Low |
| Cost at small scale | Low | Higher |
| Scaling | Manual | Elastic |
| Durability guarantees | You build them | Provided (e.g. S3 11 nines) |
| Time to production | Slower | Faster |

For a portfolio/demo, a VPS is the right choice for cost. For a real product
with an on-call team, managed services usually win.

---

## 2. Service mapping — current stack → AWS

| Current (self-hosted) | AWS managed equivalent | Migration effort |
|---|---|---|
| MinIO (S3-compatible object storage) | **Amazon S3** | **Config only** — already S3-native |
| PostgreSQL (Docker container) | **Amazon RDS for PostgreSQL** | Config + data dump/restore |
| Redis (Docker container) | **Amazon ElastiCache for Redis** | Config only |
| Django + Gunicorn (Docker) | **ECS Fargate** / **App Runner** / **EC2** | Containerize (already done) |
| Celery worker (Docker) | **ECS Fargate** service | Already containerized |
| Nginx reverse proxy | **Application Load Balancer (ALB)** + CloudFront | Rework routing |
| Let's Encrypt / HAProxy | **ACM (AWS Certificate Manager)** | Managed certs |
| systemd backup timer | **AWS Backup** + RDS automated snapshots | Managed |
| Prometheus + Grafana | **CloudWatch** / **Amazon Managed Grafana** | Optional |
| Docker Compose | **ECS Task Definitions** / **Terraform / CDK** | IaC rewrite |

The key insight: **the two hardest-to-migrate layers (storage and database)
are already using standard, portable interfaces.**

---

## 3. Storage migration — MinIO → Amazon S3 (validated)

This is the flagship migration story, and it's **already provable today**.

The app uses `django-storages` with the S3 backend. MinIO speaks the S3 API,
so the **exact same code** works against real AWS S3 by changing environment
variables only.

### Local / VPS (MinIO)

```dotenv
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
AWS_STORAGE_BUCKET_NAME=music-media
AWS_S3_ENDPOINT_URL=http://minio:9000
```

### Production (real AWS S3)
```ini
AWS_ACCESS_KEY_ID=<iam-access-key>
AWS_SECRET_ACCESS_KEY=<iam-secret-key>
AWS_STORAGE_BUCKET_NAME=music-media-prod
AWS_S3_REGION_NAME=eu-central-1
# Note: AWS_S3_ENDPOINT_URL is UNSET for real S3
#       (django-storages then targets AWS endpoints automatically)
```

**No application code changes.** Only environment configuration.

### Validation

The repository includes a smoke test that proves S3 compatibility:

```bash
make s3-smoke
```

It uploads a test object, lists it, downloads it, verifies the content, and
deletes it — using the same S3 API the app uses. Point it at MinIO locally or
at real AWS S3 with credentials.

### Data migration (MinIO objects → S3)

Because both speak S3, migration is a single mirror operation:

```bash
# Using AWS CLI + MinIO client
aws s3 sync s3://music-media s3://music-media-prod \
  --source-region minio --profile prod

# Or using MinIO client (mc) between two S3 endpoints
mc mirror minio/music-media awss3/music-media-prod
```

## 4. Database migration — PostgreSQL → Amazon RDS

**Concept**

RDS provides:

- Automated backups + point-in-time recovery
- Multi-AZ failover (standby replica in another availability zone)
- Automated minor version patching
- Read replicas for scaling reads
- CloudWatch metrics out of the box

**Migration approach**

The app uses standard PostgreSQL. Migration is a dump and restore:

```bash
# 1. Provision RDS PostgreSQL instance (via console or Terraform)

# 2. Dump from current DB (we already have this from Day 43!)
make backup-db
# → backups/db/daily/db-YYYYMMDD-HHMMSS.dump.gz

# 3. Restore into RDS
gunzip -c backups/db/daily/db-*.dump.gz \
  | pg_restore --no-owner --no-privileges \
      -h music-db.xxxx.eu-central-1.rds.amazonaws.com \
      -U musicuser -d musicdb
```
Then update `.env.prod`:

```ini
POSTGRES_HOST=music-db.xxxx.eu-central-1.rds.amazonaws.com
POSTGRES_PORT=5432
POSTGRES_DB=musicdb
POSTGRES_USER=musicuser
POSTGRES_PASSWORD=<rds-password>
```

**No application code changes**. Django’s PostgreSQL backend is unchanged.

> Day 43’s backup system doubles as a migration tool — the pg_dump artifact
> restores directly into RDS.

## 5. Cache migration — Redis → ElastiCache

Standard Redis protocol. Migration is config-only:

```apache
REDIS_URL=redis://music-cache.xxxx.cache.amazonaws.com:6379/0
CELERY_BROKER_URL=redis://music-cache.xxxx.cache.amazonaws.com:6379/1
```

For production, use TLS + auth token:

```elixir
REDIS_URL=rediss://:<auth-token>@music-cache.xxxx.cache.amazonaws.com:6379/0
```

## 6. Compute migration — Docker Compose → ECS Fargate

This is the largest change, because Docker Compose is a local/single-host tool.

### Target architecture

```text
                    ┌──────────────┐
   Internet ──────► │  CloudFront  │  (CDN, TLS via ACM)
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │     ALB      │  (Application Load Balancer)
                    └──────┬───────┘
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌─────────┐  ┌─────────┐  ┌──────────┐
        │ Frontend│  │ Backend │  │  Celery  │
        │ (Fargate)│ │(Fargate)│  │ (Fargate)│
        └─────────┘  └────┬────┘  └────┬─────┘
                          │            │
              ┌───────────┼────────────┤
              ▼           ▼            ▼
        ┌─────────-┐ ┌──────────-┐ ┌─────────┐
        │   RDS    │ │ElastiCache│ │   S3    │
        │(Postgres)│ │  (Redis)  │ │ (Media) │
        └─────────-┘ └──────────-┘ └─────────┘
```

### Migration steps (conceptual)

- Push images to ECR (Elastic Container Registry)
- Define ECS Task Definitions (mirror the Compose services)
- Create ECS Services for backend, frontend, celery
- Front with an ALB; route /api/* to backend, / to frontend
- Use ACM for TLS, CloudFront for CDN
- Store secrets in AWS Secrets Manager / SSM Parameter Store
- Manage all of it with Terraform or AWS CDK (Infrastructure as Code)

### Why our project makes this easier

- Everything is already containerized — images port directly to ECR/ECS
- Config is environment-driven — no hardcoded hosts
- Secrets are externalized — map cleanly to Secrets Manager
- Health checks exist (/api/health/) — ALB target group health checks work immediately
- Stateless app tier — media in S3, sessions in JWT, cache in Redis

## 7. Recommended migration order (lowest risk first)

```text
1. Storage:  MinIO → S3            (config only, reversible)      ← easiest
2. Cache:    Redis → ElastiCache   (config only)
3. Database: PostgreSQL → RDS      (dump/restore, planned cutover)
4. Compute:  Compose → ECS Fargate (IaC, biggest lift)           ← hardest
5. Edge:     Nginx → ALB/CloudFront + ACM
6. Ops:      Prometheus → CloudWatch (optional)
```

Migrate the **stateful, portable** layers first (S3, cache, DB). Migrate the
**compute orchestration** last, because it’s the biggest change.

## 8. Cost awareness (approximate, small scale)

```text
| Service | Rough monthly cost (small) |
|---|---:|
| S3 (few GB + requests) | $1–5 |
| RDS `db.t4g.micro` | $12–15 |
| ElastiCache `cache.t4g.micro` | $12–15 |
| ECS Fargate (2 small tasks) | $20–30 |
| ALB | $16+ |
| CloudFront | Usage-based, typically low at small scale |
| **Total** | **~$70–90/month** vs. **a single $5–10 VPS** |
```

For a portfolio, a VPS is far cheaper. This document demonstrates the
**knowledge and readiness** to migrate, which is what interviews assess.

## 9. Interview summary

> “The application is cloud-ready by design. I deliberately used S3-compatible
> object storage (MinIO) so the storage layer is portable to AWS S3 with only a
> configuration change — I have a smoke test that proves the same code works
> against both. The database is standard PostgreSQL, so RDS migration is a
> dump-and-restore using my existing backup artifacts. Redis maps to
>ElastiCache with a connection string change. The app is fully containerized
> with externalized config, health checks, and a stateless app tier, so the
> largest remaining step — moving Docker Compose to ECS Fargate — is an
> infrastructure-as-code exercise rather than an application rewrite.”

## References

- [Amazon S3](https://docs.aws.amazon.com/s3/)
- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Amazon ElastiCache](https://docs.aws.amazon.com/elasticache/)
- [Amazon ECS / Fargate](https://docs.aws.amazon.com/ecs/)
- [django-storages S3 backend](https://django-storages.readthedocs.io/en/latest/backends/amazon-S3.html)
