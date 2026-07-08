# Backups & Restore Runbook

> A backup you have never restored is not a backup.

## What is backed up

| Component  | Method                          | Output                              |
|------------|---------------------------------|-------------------------------------|
| PostgreSQL | `pg_dump -Fc` + gzip            | `backups/db/daily/db-<ts>.dump.gz`  |
| Media      | `mc mirror` bucket → tar.gz     | `backups/media/daily/media-<ts>.tar.gz` |

Each artifact has a `.sha256` checksum. A `latest.*` symlink points to the
newest backup in each daily folder. Weekly copies are taken on Sundays.

## Layout

```text
backups/
  db/    daily/  weekly/
  media/ daily/  weekly/
  logs/
```

## Configuration (.env.prod)

```makefile
BACKUP_ROOT=            # default: <project>/backups
KEEP_DAILY=7
KEEP_WEEKLY=4
BACKUP_REMOTE_UPLOAD=false
BACKUP_S3_BUCKET=
BACKUP_S3_ENDPOINT=
```
Media backup reuses existing `AWS_*` credentials and `AWS_STORAGE_BUCKET_NAME`.

## Run backups

```bash
make backup          # db + media + prune
make backup-db       # db only
make backup-media    # media only
make backup-list     # list artifacts
```

Override retention:

```bash
KEEP_DAILY=30 make backup
```

## Restore

> Restores are destructive and require a confirmation phrase.

```bash
make restore-db    FILE=backups/db/daily/db-<ts>.dump.gz
make restore-media FILE=backups/media/daily/media-<ts>.tar.gz
```

Restore-db also runs `manage.py migrate` afterward to reconcile schema state.

## Verify a backup without restoring
```bash
# DB dump contents:
gunzip -c backups/db/daily/db-<ts>.dump.gz | pg_restore --list | head
# Media contents:
tar -tzf backups/media/daily/media-<ts>.tar.gz | head
# Checksum:
( cd backups/db/daily && sha256sum -c db-<ts>.dump.gz.sha256 )
```

## Scheduled backups (VPS, systemd)

```bash
make backups-install     # installs daily timer at 03:30 UTC
make backups-status
sudo systemctl start music-backup.service   # run once now
journalctl -u music-backup.service -n 50 --no-pager
```

## Off-site (3-2-1)

We aim for the 3-2-1 rule: 3 copies, 2 media, 1 offsite.
Enable offsite upload:

```routeros
BACKUP_REMOTE_UPLOAD=true
BACKUP_S3_BUCKET=my-offsite-bucket
BACKUP_S3_ENDPOINT=    # empty for AWS S3; set for S3-compatible
```

## Restore drill (do this regularly)

```text
1. make backup
2. make restore-db    FILE=backups/db/daily/latest.dump.gz
3. make restore-media FILE=backups/media/daily/latest.tar.gz
4. make smoke-prod
```

### RPO / RTO

```text
| Metric | Meaning | Target |
|---|---|---|
| RPO | Max acceptable data loss | 24h |
| RTO | Max acceptable recovery time | 1h |
```

Daily backups → worst-case data loss ~24h. Shorten the timer for a smaller RPO.
For sub-hour RPO in cloud, consider WAL/PITR (e.g. RDS)


### Option B — rsync over SSH to a secondary host (manual)

Not called automatically. Run manually when needed:

```bash
make backup-rsync
```

Configure in .env.prod:

```ini
BACKUP_RSYNC_HOST=deploy@backup.example.com
BACKUP_RSYNC_PATH=/opt/backups/music-stream-app
BACKUP_RSYNC_KEY=/home/deploy/.ssh/backup_key
```

No cloud account needed. A cheap second VPS is sufficient.
