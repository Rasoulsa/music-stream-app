# End-to-End Smoke Tests

A single script verifies the entire production stack from the outside —
exactly as a browser or external client would — through nginx on
`http://localhost`.

## What it checks

| # | Section | Verifies |
|---|---------|----------|
| 1 | Container health | All 7 services running/healthy |
| 2 | Infrastructure | nginx liveness, backend health, frontend HTML |
| 3 | API contract | Schema, docs, route methods, public vs protected |
| 4 | Auth + DB | Register → login (JWT) → refresh → authenticated reads |
| 5 | Object storage | MinIO internal health + nginx → MinIO proxy |
| 6 | Security headers | nosniff, frame-options, referrer-policy, hidden version |
| 7 | Environment | `.env.prod` present & ignored, examples committed, secrets set |
| 8 | **E2E journey** | **Upload song → retrieve → list → stream → Range → cleanup** |

Section 8 is the Day 34 addition: it performs a real user journey,
uploads an audio file, confirms it is retrievable and listed, streams it
back **through nginx** (including HTTP Range requests needed for audio
seeking), then deletes it to keep the database clean.

## Running

```bash
make prod-up
make smoke-prod
```
Or directly:
```bash
./scripts/smoke-prod.sh
```

## Configuration

Override the base URL for staging/remote hosts:
```bash
BASE=https://staging.example.com ./scripts/smoke-prod.sh
```

## Exit codes
0 — all critical checks passed (safe for CI gating)
1 — one or more checks failed; failing checks are listed with hints
