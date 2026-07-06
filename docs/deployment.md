# Deployment Guide

This document describes how the Music Stream App is deployed to a VPS.

---

## Overview

| Item                  | Value                              |
|-----------------------|------------------------------------|
| OS                    | Ubuntu 24.04 LTS                   |
| Deploy user           | `deploy` (non-root, sudo + docker) |
| App directory         | `~/apps/music-stream-app`          |
| Container runtime     | Docker Engine + Compose plugin     |
| Firewall              | UFW (allows 22, 80, 443)           |
| Intrusion prevention  | fail2ban                           |

---

## Phase 5 Roadmap

| Day | Task                                      | Status |
|-----|-------------------------------------------|--------|
| 38  | VPS setup (server, Docker, firewall)      | ✅      |
| 39  | Deploy app to VPS manually (HTTP)         | ✅      |
| 40  | Domain + HTTPS (HAProxy + Let's Encrypt)  | ⬜      |
| 41  | CI/CD auto-deploy to VPS                  | ⬜      |
| 42  | Monitoring + logging                      | ⬜      |
| 43  | Backups (DB + media)                      | ⬜      |
| 44  | AWS / cloud migration intro               | ⬜      |
| 45  | Final demo prep                           | ⬜      |

---

## Port Strategy

This VPS runs an existing service ("X Service") on **port 443**.
The app deployment is phased to avoid any conflict:

| Phase    | Day | App Nginx binds         | Port 443 owner         | HTTPS |
|----------|-----|-------------------------|------------------------|-------|
| Phase I  | 39  | `0.0.0.0:80`            | X Service              | ❌     |
| Phase II | 40  | `127.0.0.1:8444`        | HAProxy (SNI splitter) | ✅     |

### How HAProxy shares port 443 (Phase II)

HAProxy performs **TLS passthrough** (SNI routing). It reads only the
domain name from the TLS ClientHello — without decrypting any traffic —
then routes raw bytes to the correct backend:

Internet :443
│
▼
HAProxy  (host — SNI router, zero decryption)
│                          │
│ SNI = X Service domain   │ SNI = music app domain
▼                          ▼
X Service                   App Nginx (127.0.0.1:8444)
(keeps its own TLS/cert)    (Let’s Encrypt cert)

yaml

Each service manages its own TLS independently.
The only change to the Docker stack on Day 40:
set `NGINX_HTTP_BIND=127.0.0.1:8444` in `.env.prod` — no structural
changes to any Compose file.

---

## Day 38 — Server Setup

### 1. Generate SSH key (local machine)

```bash
ssh-keygen -t ed25519 -C "music-stream-deploy" -f ~/.ssh/music_stream_vps
```
2. Create VPS
Ubuntu 24.04 LTS, minimum 2 vCPU / 2 GB RAM
Add the public key (music_stream_vps.pub) at creation time

3. Run the hardening script
```bash
scp -i ~/.ssh/music_stream_vps scripts/server-setup.sh root@YOUR_VPS_IP:/root/
ssh -i ~/.ssh/music_stream_vps root@YOUR_VPS_IP
chmod +x server-setup.sh
./server-setup.sh
```

4. Log in as deploy user
```bash
ssh -i ~/.ssh/music_stream_vps deploy@YOUR_VPS_IP
```
What the script does
Updates the system packages
Creates non-root deploy user with sudo + docker group access
Copies SSH key to deploy user’s authorized_keys
Hardens SSH (disables root login and password authentication)
Installs Docker Engine + Compose plugin
Configures UFW firewall (ports 22, 80, 443 only)
Installs and enables fail2ban
Security notes
Root SSH login is disabled after setup
Password authentication is disabled — key-based only
Only ports 22, 80, 443 are open
.env.prod is never committed to git — created directly on the server

## Day 39 — Manual VPS Deploy (HTTP)
Compose file structure
The production stack uses three compose files layered in order:

| File                      | Role                                               |
|---------------------------|----------------------------------------------------|
| `docker-compose.yml`      | Base service definitions (images, volumes, etc.)   |
| `docker-compose.prod.yml` | Production overrides (gunicorn, restart, etc.)     |
| `docker-compose.vps.yml`  | VPS-only override (nginx port binding via env var) |

`docker-compose.vps.yml` only overrides the nginx port binding.
Everything else is already correct in the base and prod files.

### Environment file
Before deploying, .env.prod must have these values set to your
actual VPS IP (not localhost):

```bash
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,backend,nginx,YOUR_VPS_IP
CSRF_TRUSTED_ORIGINS=http://YOUR_VPS_IP
CORS_ALLOWED_ORIGINS=http://YOUR_VPS_IP
AWS_S3_CUSTOM_DOMAIN=YOUR_VPS_IP/music-media
NGINX_HTTP_BIND=0.0.0.0:80
```

If any of these still say localhost, Django will return
400 Bad Request for every request and media URLs will be broken.

### First deploy
```bash
# 1. SSH in as deploy user
ssh -i ~/.ssh/music_stream_vps deploy@YOUR_VPS_IP

# 2. Clone the repo
mkdir -p ~/apps && cd ~/apps
git clone https://github.com/YOURNAME/music-stream-app.git
cd music-stream-app

# 3. Create and fill the env file
cp .env.prod.example .env.prod
nano .env.prod
# Required: replace YOUR_VPS_IP and all CHANGE_ME values

# 4. Confirm X Service still owns :443 and :80 is free
sudo ss -tlnp | grep ':443'   # must show X Service
sudo ss -tlnp | grep ':80'    # must be empty

# 5. Run the deploy script
bash scripts/deploy.sh
```

### Subsequent deploys
```bash
ssh -i ~/.ssh/music_stream_vps deploy@YOUR_VPS_IP
cd ~/apps/music-stream-app
bash scripts/deploy.sh
```

### Verify after deploy
```bash
# From the VPS:
curl -i http://localhost/healthz          # nginx health → 200 ok
curl -i http://localhost/api/health/      # django health → 200

# From your browser:
# http://YOUR_VPS_IP/
# http://YOUR_VPS_IP/api/docs/
# http://YOUR_VPS_IP/api/health/
```

### Safety check — run after EVERY deploy
```bash
# X Service must still be running on :443.
# If this returns empty, something went wrong — check X Service immediately.
sudo ss -tlnp | grep ':443'
```

### Rollback
```bash
git log --oneline -10             # find last known-good commit
git checkout <commit-hash>
bash scripts/deploy.sh
```

## Day 40 — HTTPS + HAProxy (planned)
Complete this section only after Day 39 is confirmed working.

Steps overview
Point your music domain DNS → VPS IP (DNS-only, no proxy)
Obtain Let’s Encrypt cert for the music domain
Install HAProxy on the host
Move X Service from :443 → 127.0.0.1:8443 (internal)
Set NGINX_HTTP_BIND=127.0.0.1:8444 in .env.prod
Configure HAProxy SNI splitter on :443
Add listen 443 ssl block to nginx/nginx.conf
Uncomment HSTS header in nginx/nginx.conf
Update DJANGO_ALLOWED_HOSTS, CSRF_TRUSTED_ORIGINS, CORS_ALLOWED_ORIGINS, AWS_S3_CUSTOM_DOMAIN with the real domain
Set DJANGO_SECURE_SSL=true in .env.prod
Redeploy: bash scripts/deploy.sh
Verify both X Service and app work over HTTPS
Keep rollback ready

### Useful Commands
```bash
# Shorthand — set once per session to avoid repeating -f flags
alias dc='docker compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  -f docker-compose.vps.yml \
  --env-file .env.prod'

# View running containers
dc ps

# Follow logs (all services)
dc logs -f

# Follow logs (specific services)
dc logs -f nginx backend

# Restart a single service
dc restart backend

# Open Django shell
dc exec backend /app/.venv/bin/python manage.py shell

# Run a manual migration
dc exec backend /app/.venv/bin/python manage.py migrate

# Check port usage on VPS
sudo ss -tlnp | grep -E ':80|:443'

# Stop everything
dc down

# Stop and remove volumes (destructive — wipes DB and media)
dc down -v
```

### Files Reference
| File                      | Purpose                                               |
|---------------------------|-------------------------------------------------------|
| `docker-compose.yml`      | Base service definitions                              |
| `docker-compose.prod.yml` | Production overrides (gunicorn, restart, healthcheck) |
| `docker-compose.vps.yml`  | VPS override — nginx port binding only                |
| `nginx/nginx.conf`        | App Nginx config — single source of truth             |
| `scripts/deploy.sh`       | Deploy automation with pre-flight checks              |
| `scripts/server-setup.sh` | Day 38 server hardening script                        |
| `.env.prod.example`       | Env template — copy to `.env.prod` on the server      |
| `.env.prod`               | Real secrets — never committed, lives on VPS only     |

## CI/CD Auto-Deploy (Day 41)

Manual deploys (`bash scripts/deploy.sh` over SSH) still work exactly as
before — nothing about `scripts/deploy.sh` changed. What Day 41 adds is
automation: `.github/workflows/deploy.yml` SSHes into the VPS and runs that
same script whenever `main` is updated.

### Flow

1. Push a feature branch, open a PR.
2. `Backend CI` and `Frontend CI` run automatically (unchanged from before).
3. Branch protection on `main` requires both to pass before merge.
4. On merge to `main`, `Deploy to VPS` triggers automatically:
   - SSHes into the VPS
   - Runs `bash scripts/deploy.sh` (git pull, build, health wait, nginx
     refresh, smoke checks — all pre-existing logic)
   - If `APP_PUBLIC_URL` is configured, verifies the site from the public
     internet as an extra check beyond `deploy.sh`'s own localhost checks

### Manual re-deploy without a new commit

Go to Actions → "Deploy to VPS" → "Run workflow". Check "Skip 'git pull'"
if you just want to restart the current code (e.g. after rotating a secret
in `.env.prod` on the VPS).

### Required GitHub configuration

See the comment block at the top of `.github/workflows/deploy.yml` for the
full list of required secrets and the one-time VPS/branch-protection setup.

### Known limitation

`scripts/deploy.sh` does not automatically roll back on a failed deploy —
if migrations or the build succeed but the smoke check fails, the broken
containers stay up and the workflow just fails loudly so you know to
intervene manually via `make vps-logs`. Automated rollback is a reasonable
candidate for a future day, but is out of scope for Day 41.
