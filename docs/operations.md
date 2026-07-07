## Fallback HTTPS Time Synchronization

In restricted networks, standard NTP may fail because NTP uses UDP/123.
For example, some region-level firewalls may allow HTTPS/TCP traffic but block
NTP UDP responses.

This project includes an optional fallback timer that corrects system time using
HTTPS `Date` headers over TCP/443.

> Important: this is an operational fallback, not a full replacement for proper
> NTP/Chrony. Use real NTP whenever UDP/123 is available.

### Install or update

```bash
sudo bash scripts/ops/https-time-sync.sh install
```

The default action is also `install`, so this works too:

```bash
sudo bash scripts/ops/https-time-sync.sh
```

This installs/updates:

```text
/usr/local/sbin/sync-time-https.sh
/etc/systemd/system/sync-time-https.service
/etc/systemd/system/sync-time-https.timer
```

It also enables the timer and runs one immediate sync attempt.

### Run once manually

```bash
sudo bash scripts/ops/https-time-sync.sh run
```

### Check status

```bash
bash scripts/ops/https-time-sync.sh status
```

Or directly with systemd:

```bash
systemctl status sync-time-https.timer --no-pager
systemctl list-timers --all | grep sync-time
journalctl -u sync-time-https.service -n 50 --no-pager
```

### View logs

```bash
bash scripts/ops/https-time-sync.sh logs
```

### Uninstall

```bash
sudo bash scripts/ops/https-time-sync.sh uninstall
```

### Expected logs

If the clock is already close enough:

```text
Source: https://www.google.com -> ...
Source: https://www.cloudflare.com -> ...
Local epoch: ...
Remote epoch: ...
Offset: 0s
Clock offset <= 2s; no change needed.
```

If the clock has drifted:

```text
Updating system time from HTTPS Date header...
Syncing hardware clock...
Done.
```
