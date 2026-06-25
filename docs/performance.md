# Performance — Music Stream App

Day 36 performance pass. Documents the optimizations, how to measure
them, and the guarantees enforced by automated tests.

## Optimizations

| Area | Technique | Status |
|------|-----------|--------|
| N+1 queries | `select_related("owner")` on all song querysets | ✅ Verified by tests |
| DB indexes | 3 composite indexes on hot query paths | ✅ Migrated |
| Feed caching | Redis, 60s TTL + signal-based invalidation | ✅ |
| Public profile caching | Redis, 5min TTL + invalidation on edit | ✅ |
| Pagination | DRF `PAGE_SIZE = 20` | ✅ |
| Compression | nginx gzip | ✅ |

## Database indexes

| Index | Fields | Serves |
|-------|--------|--------|
| `song_public_recent_idx` | `(is_public, -created_at)` | Public feed — filter + sort from one index |
| `song_owner_recent_idx` | `(owner, -created_at)` | "My songs", user public-song lists |
| `song_owner_public_idx` | `(owner, is_public)` | Authenticated visibility queries |

Each index matches a real query pattern. Postgres can satisfy both the
`WHERE` filter and the `ORDER BY` from a single index scan on the feed.

## Caching strategy

Two-layer freshness model:

- **TTL** is the safety net (data is never stale longer than the TTL).
- **Event-based invalidation** is the freshness guarantee (writes purge
  the relevant key immediately).

| Key | TTL | Invalidated when |
|-----|-----|------------------|
| `feed:default` | 60s | Any `Song` save/delete (via `signals.py`) |
| `profile:public:<username>` | 5min | Owner edits their profile (`MyProfileView.patch`) |

## How to measure

### Query counts — debug toolbar (local)
```bash
ls config/settings/            # find your dev settings
DEBUG=True uv run python manage.py runserver
```
# Open http://localhost:8000/api/v1/songs/ → SQL panel
