#!/usr/bin/env bash
#
# server-setup.sh — VPS setup for Music Stream App
#
# Run this ON THE SERVER as root, ONCE, on a fresh Ubuntu 24.04 host.
#
# ACCESS MODEL (as requested):
#   - Your laptop  -> passwordless login (SSH key) for both root and deploy
#   - Any other machine -> login with password for both root and deploy
#
# It will:
#   1. Update the system
#   2. Create user 'deploy' with sudo access
#   3. Copy root's SSH key to deploy (so laptop key works for deploy too)
#   4. Configure SSH (key + password BOTH enabled, root login allowed)
#   5. Install Docker Engine + Compose plugin
#   6. Configure UFW firewall (allow SSH, HTTP, HTTPS only)
#   7. Install and enable fail2ban (protects password logins)
#   8. Create the app directory
#
# Usage:
#   scp -i ~/.ssh/music_stream_vps scripts/server-setup.sh root@SERVER_IP:/root/
#   ssh -i ~/.ssh/music_stream_vps root@SERVER_IP
#   chmod +x server-setup.sh
#   ./server-setup.sh
#
# AFTER running: set deploy's password manually:
#   passwd deploy
#
set -euo pipefail

# ---- Configuration -------------------------------------------------------
DEPLOY_USER="deploy"
APP_DIR="/home/${DEPLOY_USER}/apps/music-stream-app"
SSH_PORT="22"   # change if you want a custom SSH port (also update UFW)

echo "==> Music Stream App — Server Setup"

# ---- 0. Must be root -----------------------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: run this script as root."
  exit 1
fi

# ---- 1. System update ----------------------------------------------------
echo "==> Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  make \
  git \
  ufw \
  fail2ban \
  unattended-upgrades

# ---- 2. Create deploy user ----------------------------------------------
# Created WITHOUT a password here. Set it manually after the script:
#   passwd deploy
if id "$DEPLOY_USER" &>/dev/null; then
  echo "==> User '$DEPLOY_USER' already exists, skipping creation."
else
  echo "==> Creating user '$DEPLOY_USER'..."
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
  usermod -aG sudo "$DEPLOY_USER"
fi

# Allow passwordless sudo for deploy (optional; comment out for stricter security)
echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$DEPLOY_USER"
chmod 440 "/etc/sudoers.d/90-$DEPLOY_USER"

# ---- 3. Copy SSH key to deploy ------------------------------------------
# This copies the laptop key already present in root's authorized_keys,
# so passwordless login works for deploy too.
echo "==> Setting up SSH key access for '$DEPLOY_USER'..."
mkdir -p "/home/$DEPLOY_USER/.ssh"
if [[ -f /root/.ssh/authorized_keys ]]; then
  cp /root/.ssh/authorized_keys "/home/$DEPLOY_USER/.ssh/authorized_keys"
else
  echo "WARNING: /root/.ssh/authorized_keys not found."
  echo "         Add your laptop key to root first, or use ssh-copy-id later."
  touch "/home/$DEPLOY_USER/.ssh/authorized_keys"
fi
chmod 700 "/home/$DEPLOY_USER/.ssh"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"

# ---- 4. Configure SSH (key + password BOTH enabled) ---------------------
# ACCESS MODEL:
#   - Laptop with key       -> passwordless (key tried first)
#   - Other machine no key  -> falls back to password
#   - root allowed via both key and password
echo "==> Configuring SSH (key + password, root allowed)..."
SSHD_CONFIG="/etc/ssh/sshd_config.d/99-access.conf"
cat > "$SSHD_CONFIG" <<EOF
Port ${SSH_PORT}

# Both authentication methods enabled
PubkeyAuthentication yes
PasswordAuthentication yes

# Root can log in with BOTH key and password
PermitRootLogin yes

# Hardening that does NOT block password login
X11Forwarding no
MaxAuthTries 4
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Some Ubuntu images ship a cloud-init file that forces
# 'PasswordAuthentication no'. Neutralize it so our config wins.
CLOUD_INIT="/etc/ssh/sshd_config.d/50-cloud-init.conf"
if [[ -f "$CLOUD_INIT" ]]; then
  echo "==> Found cloud-init SSH config, disabling its password override..."
  sed -i 's/^PasswordAuthentication.*/# &  (overridden by 99-access.conf)/' "$CLOUD_INIT"
fi

systemctl restart ssh

# ---- 5. Install Docker ---------------------------------------------------
if command -v docker &>/dev/null; then
  echo "==> Docker already installed, skipping."
else
  echo "==> Installing Docker Engine + Compose plugin..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

# Add deploy to docker group
usermod -aG docker "$DEPLOY_USER"
systemctl enable docker
systemctl start docker

# ---- 6. Firewall (UFW) ---------------------------------------------------
echo "==> Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp" comment 'SSH'
ufw allow 80/tcp  comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

# ---- 7. fail2ban ---------------------------------------------------------
# Important: password login is enabled, so fail2ban protects against
# brute-force attempts on both root and deploy.
echo "==> Enabling fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

# ---- 8. App directory ----------------------------------------------------
echo "==> Creating app directory at $APP_DIR..."
mkdir -p "$APP_DIR"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"

# ---- 9. Verification ----------------------------------------------------
echo "==> Verifying installed tools..."
docker --version
docker compose version
make --version | head -n 1
git --version

# ---- Done ----------------------------------------------------------------
echo ""
echo "============================================================"
echo " Server setup complete!"
echo ""
echo " User        : $DEPLOY_USER (sudo + docker)"
echo " App dir      : $APP_DIR"
echo " SSH port     : $SSH_PORT"
echo ""
echo " ACCESS MODEL:"
echo "   - Laptop (key)        -> passwordless (root + $DEPLOY_USER)"
echo "   - Other machine       -> password     (root + $DEPLOY_USER)"
echo ""
echo " >>> IMPORTANT: set deploy's password now: <<<"
echo "       passwd $DEPLOY_USER"
echo ""
echo " (root password: set/confirm with 'passwd root' if needed)"
echo "============================================================"
