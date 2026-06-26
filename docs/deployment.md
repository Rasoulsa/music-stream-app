# Deployment Guide

This document describes how the Music Stream App is deployed to a VPS.

## Overview

| Item | Value |
|------|-------|
| OS | Ubuntu 24.04 LTS |
| Provider | (your VPS provider) |
| Deploy user | `deploy` (non-root) |
| App directory | `/opt/music-stream-app` |
| Container runtime | Docker Engine + Compose plugin |
| Firewall | UFW (allows 22, 80, 443) |
| Intrusion prevention | fail2ban |

## Phase 5 Roadmap

| Day | Task | Status |
|-----|------|--------|
| 38 | VPS setup (server, Docker, firewall) | ✅ |
| 39 | Deploy app to VPS manually | ⬜ |
| 40 | Domain + HTTPS (Let's Encrypt) | ⬜ |
| 41 | CI/CD auto-deploy to VPS | ⬜ |
| 42 | Monitoring + logging | ⬜ |
| 43 | Backups (DB + media) | ⬜ |
| 44 | AWS/cloud migration intro | ⬜ |
| 45 | Final demo prep | ⬜ |

## Day 38 — Server Setup

### 1. Generate SSH key (local machine)

```bash
ssh-keygen -t ed25519 -C "music-stream-deploy" -f ~/.ssh/music_stream_vps
```

2. Create VPS
Ubuntu 24.04 LTS, 2 vCPU / 4 GB RAM
Add the public key (music_stream_vps.pub) during creation

3. Run the hardening script

```bash
scp -i ~/.ssh/music_stream_vps scripts/server-setup.sh root@SERVER_IP:/root/
ssh -i ~/.ssh/music_stream_vps root@SERVER_IP
chmod +x server-setup.sh
./server-setup.sh
```

4. Log in as deploy user

```bash
ssh -i ~/.ssh/music_stream_vps deploy@SERVER_IP
```

What the script does
Updates the system
Creates non-root deploy user with sudo + docker access
Copies SSH key to deploy user
Hardens SSH (disables root login + password auth)
Installs Docker Engine + Compose plugin
Configures UFW firewall (22, 80, 443 only)
Installs and enables fail2ban
Creates /opt/music-stream-app
Security Notes
Root SSH login is disabled after setup.
Password authentication is disabled — key-based only.
Only ports 22, 80, 443 are open.
.env.prod is never committed to git; it is created directly on the server.
