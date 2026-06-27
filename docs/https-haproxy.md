# 🔒 HTTPS with Let's Encrypt + HAProxy SNI

This document describes how the Music Stream App is served over HTTPS on a VPS
that already runs another service on port 443.

It covers the architecture, the port strategy, certificate management, the
deployment scripts, and the full step-by-step deployment and verification flow.

For general VPS setup and HTTP deployment, see:

👉 [`deployment.md`](./deployment.md)

---

## 🎯 The Problem

Port 443 on the VPS is already used by an existing service ("X Service").

We cannot bind host port 443 directly for the Music Stream App, or the deploy
will fail with a port conflict.

We still want:

- A real domain
- A valid Let's Encrypt certificate
- HTTPS for the Music Stream App
- No disruption to the existing service on 443

---

## 🧩 The Solution — HAProxy SNI Splitting

HAProxy listens on port 443 in **TCP mode** and routes connections by the TLS
SNI (Server Name Indication) hostname, **without terminating TLS itself**.

- Traffic for the app domain is forwarded to the app's nginx.
- All other traffic continues to the existing X Service.

TLS is terminated by the app's own nginx container, not by HAProxy.

---

## 📐 Architecture

```text
Internet :80
  → App Nginx (host port 80)
      → Let's Encrypt HTTP-01 challenge (/.well-known/acme-challenge/)
      → HTTP → HTTPS redirect

Internet :443
  → HAProxy (TCP mode, SNI inspection, no TLS termination)
      ├─ SNI = APP_DOMAIN → 127.0.0.1:8443 → App Nginx (TLS terminated here)
      └─ default          → existing X Service
```

Key points:

- App nginx binds **host :80** publicly for ACME and redirects.
- App nginx binds **HTTPS on 127.0.0.1:8443** only.
- App nginx never binds public host port 443.
- HAProxy owns public port 443 and forwards by SNI.
- Certificates live on the host and are mounted read-only into nginx.

---

## 🔌 Port Strategy

| Component | Bind | Public? | Purpose |
|---|---|---|---|
| App Nginx HTTP | `0.0.0.0:80` | Yes | ACME challenge + HTTP to HTTPS redirect |
| App Nginx HTTPS | `127.0.0.1:8443` | No | TLS termination behind HAProxy |
| HAProxy | `0.0.0.0:443` | Yes | SNI router for app + X Service |

The binds are controlled by environment variables in `.env.prod`:

```env
NGINX_HTTP_BIND=0.0.0.0:80
NGINX_HTTPS_BIND=127.0.0.1:8443
```

No structural change to `docker-compose.vps.yml` is needed to switch behavior.
Only env values need to be correct.

---

## 🗂️ Files Involved

| File | Purpose |
|---|---|
| `docker-compose.vps.yml` | VPS overlay: nginx binds, SSL template, cert mounts |
| `nginx/app-ssl.conf.template` | Templated HTTPS edge config |
| `nginx/disabled/default.conf` | Empty file that disables the plain HTTP prod nginx config on VPS |
| `scripts/vps-prepare-https.sh` | Installs certbot, creates directories, installs renewal hook |
| `scripts/vps-issue-cert-standalone.sh` | Issues the first Let's Encrypt certificate |
| `.env.prod` | Holds `APP_DOMAIN`, `ACME_EMAIL`, nginx binds, and production secrets |

---

## 🔧 Environment Variables

The relevant Phase II HTTPS values in `.env.prod`:

```env
APP_DOMAIN=music.example.com
ACME_EMAIL=you@example.com

NGINX_HTTP_BIND=0.0.0.0:80
NGINX_HTTPS_BIND=127.0.0.1:8443

DJANGO_ALLOWED_HOSTS=music.example.com,YOUR_VPS_IP,localhost,127.0.0.1,backend,nginx
CSRF_TRUSTED_ORIGINS=https://music.example.com
CORS_ALLOWED_ORIGINS=https://music.example.com

AWS_S3_CUSTOM_DOMAIN=music.example.com/music-media
AWS_S3_URL_PROTOCOL=http:
AWS_S3_USE_SSL=false

DJANGO_SECURE_SSL=false
```

Keep `DJANGO_SECURE_SSL=false` until HTTPS is confirmed working.

Enabling it before HTTPS works can cause forced redirect problems and make the
app harder to debug.

`AWS_S3_USE_SSL` stays `false` because Django talks to MinIO through the
internal Docker network:

```env
AWS_S3_ENDPOINT_URL=http://minio:9000
```

After public HTTPS works, only the public media URL protocol should change:

```env
AWS_S3_URL_PROTOCOL=https:
```

---

## 🔐 How envsubst Templating Works

The official nginx image automatically runs `envsubst` on files in:

```text
/etc/nginx/templates/*.template
```

In `docker-compose.vps.yml`, nginx receives:

```yaml
environment:
  APP_DOMAIN: ${APP_DOMAIN}
  NGINX_ENVSUBST_FILTER: "APP_DOMAIN"
```

`NGINX_ENVSUBST_FILTER: "APP_DOMAIN"` ensures only `${APP_DOMAIN}` is
substituted.

This is important because nginx config also contains runtime variables such as:

```nginx
$host
$request_uri
$remote_addr
$proxy_add_x_forwarded_for
```

Those variables must stay untouched.

The template:

```text
nginx/app-ssl.conf.template
```

is rendered inside the container to:

```text
/etc/nginx/conf.d/app-ssl.conf
```

---

## 📜 Certificate Management

Certificates are managed at the host level with certbot, not inside a container.

| Path | Purpose |
|---|---|
| `/etc/letsencrypt` | Let's Encrypt certificate store |
| `/var/www/certbot` | ACME HTTP-01 webroot |

These paths are mounted into nginx by the VPS Compose overlay.

`/etc/letsencrypt` is mounted read-only into nginx because the container only
needs to read issued certificates.

Why host-level certbot?

- HAProxy is installed on the host.
- The certificate store is a host-level resource.
- Certbot's systemd renewal timer is standard and reliable.
- The nginx container does not need permission to manage private keys.
- This is a common real-world setup for single-VPS deployments.

---

## 🛠️ Deployment Scripts

### `scripts/vps-prepare-https.sh`

This script prepares the VPS host for HTTPS.

It is idempotent and safe to run multiple times.

It performs:

- certbot installation
- creation of `/etc/letsencrypt`
- creation of `/var/www/certbot`
- installation of a certbot renewal deploy hook
- nginx restart after successful certificate renewal

Run it with:

```bash
make vps-prepare-https
```

---

### `scripts/vps-issue-cert-standalone.sh`

This script issues the first Let's Encrypt certificate.

It uses certbot standalone mode.

It performs:

- reads `APP_DOMAIN` from `.env.prod`
- reads `ACME_EMAIL` from `.env.prod`
- stops app nginx temporarily to free port 80
- checks whether port 80 is available
- requests the certificate from Let's Encrypt
- prints the certificate paths after success

Run it with:

```bash
make vps-issue-cert
```

---

## 🚀 Full Deployment Flow on VPS

### 1. Point DNS at the VPS

Check DNS from your local machine or the VPS:

```bash
dig +short music.example.com
```

Expected result:

```text
YOUR_VPS_IP
```

Do not continue until DNS points to the VPS.

---

### 2. Pull the branch on the VPS

```bash
cd /opt/music-stream-app
git fetch origin
git checkout feat/domain-https-haproxy
git pull origin feat/domain-https-haproxy
```

---

### 3. Configure `.env.prod`

Open the production env file:

```bash
nano .env.prod
```

Set these values:

```env
APP_DOMAIN=music.example.com
ACME_EMAIL=you@example.com

NGINX_HTTP_BIND=0.0.0.0:80
NGINX_HTTPS_BIND=127.0.0.1:8443

DJANGO_ALLOWED_HOSTS=music.example.com,YOUR_VPS_IP,localhost,127.0.0.1,backend,nginx
CSRF_TRUSTED_ORIGINS=https://music.example.com
CORS_ALLOWED_ORIGINS=https://music.example.com

AWS_S3_CUSTOM_DOMAIN=music.example.com/music-media

DJANGO_SECURE_SSL=false
AWS_S3_URL_PROTOCOL=http:
AWS_S3_USE_SSL=false
```

Replace:

```text
music.example.com
```

with the real app domain.

Replace:

```text
YOUR_VPS_IP
```

with the real VPS IP.

---

### 4. Prepare HTTPS prerequisites

```bash
make vps-prepare-https
```

This installs certbot, creates required directories, and installs the renewal
hook.

---

### 5. Issue the first certificate

```bash
make vps-issue-cert
```

Verify certificate files:

```bash
sudo ls -la /etc/letsencrypt/live/music.example.com/
```

Expected files include:

```text
fullchain.pem
privkey.pem
```

---

### 6. Start the HTTPS Docker stack

```bash
make vps-up
```

Check containers:

```bash
make vps-ps
```

Check nginx logs if needed:

```bash
make vps-logs-nginx
```

---

### 7. Test app nginx locally on the VPS

Because app nginx HTTPS is bound to `127.0.0.1:8443`, test it from the VPS:

```bash
curl -i --resolve music.example.com:8443:127.0.0.1 \
  https://music.example.com:8443/api/health/
```

Expected result:

```text
HTTP/1.1 200 OK
```

or:

```text
HTTP/2 200
```

---

### 8. Add the HAProxy SNI route

Back up the current HAProxy config:

```bash
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak.$(date +%F-%H%M%S)
```

Edit HAProxy:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Add the SNI inspection and app backend to the existing TCP frontend on port 443.

Example:

```haproxy
frontend https_front
    bind *:443
    mode tcp
    option tcplog

    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }

    use_backend music_stream_app if { req.ssl_sni -i music.example.com }

    default_backend x_service

backend music_stream_app
    mode tcp
    server music_nginx 127.0.0.1:8443 check
```

Important:

- Keep the existing X Service backend as it already is.
- Replace `music.example.com` with the real app domain.
- Do not terminate TLS in HAProxy for this app.
- HAProxy only forwards the TCP connection.

Validate HAProxy:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Reload HAProxy:

```bash
sudo systemctl reload haproxy
```

---

### 9. Verify public HTTP redirect

From your local machine:

```bash
curl -I http://music.example.com/
```

Expected result:

```text
HTTP/1.1 301 Moved Permanently
Location: https://music.example.com/
```

---

### 10. Verify public HTTPS

From your local machine:

```bash
curl -I https://music.example.com/
```

Then test backend health:

```bash
curl -i https://music.example.com/api/health/
```

Expected result:

```text
HTTP/1.1 200 OK
```

Open the app in the browser:

```text
https://music.example.com
```

The browser should show a valid HTTPS padlock.

---

### 11. Enable Django secure SSL

Only after HTTPS is confirmed working, edit `.env.prod`:

```bash
nano .env.prod
```

Change:

```env
DJANGO_SECURE_SSL=true
AWS_S3_URL_PROTOCOL=https:
```

Keep this unchanged unless the internal S3 endpoint itself becomes HTTPS:

```env
AWS_S3_USE_SSL=false
```

Restart the stack:

```bash
make vps-up
```

Re-test:

```bash
curl -I https://music.example.com/api/health/
```

---

## 🔁 Certificate Renewal

The initial certificate is issued with standalone mode.

Validate renewal with:

```bash
sudo certbot renew --dry-run
```

The deploy hook installed by `vps-prepare-https.sh` restarts app nginx after a
successful renewal.

Hook path:

```text
/etc/letsencrypt/renewal-hooks/deploy/reload-music-stream-nginx.sh
```

A future improvement is switching renewal to webroot mode, because app nginx
already serves:

```text
/var/www/certbot
```

Webroot renewal avoids needing port 80 to be free during renewal.

---

## 🧯 Troubleshooting

### `make vps-issue-cert` fails because port 80 is in use

Find the process using port 80:

```bash
sudo ss -ltnp | grep ':80'
```

The cert issuance script tries to stop app nginx automatically, but another
service may still be using port 80.

Stop that service temporarily, then retry:

```bash
make vps-issue-cert
```

---

### `APP_DOMAIN` renders empty in Compose config

Check `.env.prod`:

```bash
grep -E "^APP_DOMAIN=" .env.prod
```

Expected:

```env
APP_DOMAIN=music.example.com
```

Check rendered config:

```bash
make vps-config 2>&1 | grep -A 50 "nginx:"
```

Expected:

```yaml
environment:
  APP_DOMAIN: music.example.com
  NGINX_ENVSUBST_FILTER: APP_DOMAIN
```

If `APP_DOMAIN` is empty, ensure the Makefile target uses:

```bash
--env-file .env.prod
```

---

### Browser shows the wrong service on HTTPS

The HAProxy SNI ACL likely did not match.

Check HAProxy config:

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Confirm the domain in this line exactly matches `APP_DOMAIN`:

```haproxy
use_backend music_stream_app if { req.ssl_sni -i music.example.com }
```

Reload HAProxy:

```bash
sudo systemctl reload haproxy
```

---

### HTTPS works on 8443 but not on public 443

This usually means the app nginx is working, but HAProxy forwarding is not.

Check:

```bash
sudo systemctl status haproxy
sudo journalctl -u haproxy -n 100 --no-pager
sudo ss -ltnp | grep ':443'
sudo ss -ltnp | grep ':8443'
```

Expected:

- HAProxy listens on `0.0.0.0:443`
- Docker/app nginx listens on `127.0.0.1:8443`

---

### Redirect loop after enabling `DJANGO_SECURE_SSL`

Temporarily revert:

```env
DJANGO_SECURE_SSL=false
```

Restart:

```bash
make vps-up
```

Confirm:

- HAProxy forwards to `127.0.0.1:8443`
- nginx terminates TLS
- forwarded headers are set correctly
- `https://APP_DOMAIN/api/health/` works

Only then enable:

```env
DJANGO_SECURE_SSL=true
```

---

### Certbot says certificate already exists

This is normal if a certificate was issued before.

Check:

```bash
sudo certbot certificates
```

If the certificate is valid, continue with:

```bash
make vps-up
```

---

## ✅ Verification Checklist

- [ ] DNS A record points to the VPS IP
- [ ] `.env.prod` contains `APP_DOMAIN`
- [ ] `.env.prod` contains `ACME_EMAIL`
- [ ] `.env.prod` contains `NGINX_HTTP_BIND=0.0.0.0:80`
- [ ] `.env.prod` contains `NGINX_HTTPS_BIND=127.0.0.1:8443`
- [ ] `make vps-prepare-https` completed
- [ ] `make vps-issue-cert` completed
- [ ] Certificate exists under `/etc/letsencrypt/live/APP_DOMAIN/`
- [ ] `make vps-up` starts containers successfully
- [ ] App nginx is healthy
- [ ] Local HTTPS test to `127.0.0.1:8443` returns 200
- [ ] HAProxy SNI route is configured
- [ ] HAProxy config validates successfully
- [ ] HAProxy reloads successfully
- [ ] `http://APP_DOMAIN` redirects to HTTPS
- [ ] `https://APP_DOMAIN` returns 200
- [ ] Browser shows valid HTTPS padlock
- [ ] `DJANGO_SECURE_SSL=true` enabled after HTTPS confirmation
- [ ] `certbot renew --dry-run` passes

---

## 📚 Related Documentation

- [`deployment.md`](./deployment.md)
- [`env-management.md`](./env-management.md)
- [`security.md`](./security.md)
- [`ARCHITECTURE.md`](./ARCHITECTURE.md)
- [`../README.md`](../README.md)
