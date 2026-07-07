# Monitoring & Observability

The Music Stream App uses Prometheus + Grafana for metrics, plus structured
JSON logging for troubleshooting.

## Architecture

```text
Grafana (127.0.0.1:3001)
   │ queries
Prometheus (127.0.0.1:9090)
   │ scrapes every 15s
   ├─ backend:8000/metrics   (django-prometheus: app metrics)
   ├─ node_exporter:9100     (host CPU/RAM/disk)
   └─ cadvisor:8080          (per-container metrics)
```

Prometheus and Grafana are bound to 127.0.0.1 and are never exposed publicly.

Grafana is exposed on host port 3001, not 3000, to avoid conflict with
the frontend development server, which commonly runs on localhost:3000.
Grafana still listens on port 3000 inside the container.

## Access Grafana (SSH tunnel)

From your laptop:

```bash
ssh -L 3001:127.0.0.1:3001 <vps-user>@<vps-host>
```

Then open:
```text
Grafana:    http://localhost:3001
```

Login with `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` from `.env.prod`.

The “Music Stream — Overview” dashboard is auto-provisioned.

## Access Prometheus (SSH tunnel)

```bash
ssh -L 9090:localhost:9090 <vps-user>@<vps-host>
```
Then open `http://localhost:9090`. Useful pages:

- Status → Targets (all should be UP)
- Alerts (fired alerts)
- Graph (run PromQL)

### Useful PromQL

```axapta
# Request rate
sum(rate(django_http_requests_total_by_view_transport_method_total[5m]))

# 5xx error rate
sum(rate(django_http_responses_total_by_status_total{status=~"5.."}[5m]))

# p95 latency
histogram_quantile(0.95, sum(rate(django_http_requests_latency_seconds_by_view_method_bucket[5m])) by (le))

# Host memory used %
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

### Logging

Production logs are JSON on stdout, captured by Docker.

Each line has a `request_id`. The same ID is returned in the `X-Request-ID`
response header, enabling end-to-end request tracing.

```bash
make vps-logs-backend
make vps-logs-backend | grep <request_id>
```
Log rotation: json-file driver, max 10MB x 3 files per container.

### Health / readiness

`GET /api/health/` checks database and cache.

- `200` `"status": "ok"`
- `503` `"status": "degraded"`
Use `GET`, not `HEAD` (`curl -I`returns 405 by design).

### Alert rules

Defined in `monitoring/prometheus/rules/alerts.yml`:

- `TargetDown` — a scrape target is unreachable
- `HighHTTP5xxRate` — 5xx ratio > 5%
- `HighDiskUsage` — root fs > 85%
- `HighMemoryUsage` — host memory > 90%

Alerts currently fire inside Prometheus. Routing to Telegram/Slack requires
Alertmanager (future improvement).

### Operations

VPS:
```bash
make monitoring-up       # start app + full monitoring stack
make monitoring-ps       # monitoring status
make monitoring-logs     # monitoring logs
make monitoring-reload   # reload Prometheus config
make monitoring-down     # stop monitoring only; keep app running
```

Local/macOS:
```bash
make monitoring-up-local    # start Prometheus + Grafana only
make monitoring-ps-local    # local monitoring status
make monitoring-logs-local  # local monitoring logs
make monitoring-down-local  # stop Prometheus + Grafana only
```

### Security notes

- Monitoring bound to localhost, accessed via SSH tunnel
- `/metrics` returns 404 on the public edge (Nginx)
- Grafana sign-up disabled; admin password required via env

### Future improvements

- Alertmanager for Telegram/Slack routing
- Loki for centralized log aggregation
- Sentry for error tracking
- Grafana behind Nginx + basic auth (instead of SSH tunnel)
