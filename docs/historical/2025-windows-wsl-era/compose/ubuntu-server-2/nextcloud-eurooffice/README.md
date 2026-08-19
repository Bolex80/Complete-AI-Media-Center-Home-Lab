# Nextcloud + EuroOffice on Ubuntu Server 2 (.210)

Self-hosted Nextcloud (https://nube.bentomo.es) with EuroOffice document editor (https://eurooffice.nube.bentomo.es).

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | MariaDB, Redis, Nextcloud Apache, EuroOffice Document Server |
| `deploy.sh` | One-command deploy / refresh |
| `teardown.sh` | Stop and remove the stack and leftover volumes |
| `setup-secrets.sh` | Generate admin, DB and EuroOffice JWT secrets |
| `update-nextcloud.sh` | Pull latest images, backup, upgrade, auto-download latest EuroOffice app, integrity check |

## Deploy

On `192.168.2.210` as user `alex`:

```bash
cd /home/alex/nube
./setup-secrets.sh   # first time only
./deploy.sh
```

## Update

```bash
/home/alex/update-nextcloud.sh
```

This script:
- Backs up `/var/www/html` and the MariaDB database.
- Pulls the latest `nextcloud:stable-apache` and `ghcr.io/euro-office/documentserver:latest` images.
- Runs `occ upgrade` and `occ app:update --all`.
- Auto-downloads the latest EuroOffice Nextcloud app from the Nextcloud App Store.
- Re-syncs the EuroOffice JWT secret and settings.
- Runs `occ integrity:check-app eurooffice` and `occ maintenance:repair --include-expensive`.

## Why Nextcloud may stay on 33.0.5 after the script

The update script can only run the version contained in the `nextcloud:stable-apache` Docker image. Nextcloud's web UI may advertise a newer release (e.g. 33.0.6) before Docker Hub publishes that version under the `stable-apache` tag. When the image is updated, the script will upgrade automatically.

## DNS / Pangolin

| Public DNS | Pangolin target |
|---|---|
| `nube.bentomo.es` | `http://192.168.2.210:8081` |
| `eurooffice.nube.bentomo.es` | `http://192.168.2.210:8082` |

Pangolin provides TLS. No internal HTTPS is required.

## Verify

```bash
curl -fsS https://nube.bentomo.es/status.php
curl -fsS https://eurooffice.nube.bentomo.es/healthcheck
docker exec -u www-data nube-nextcloud php occ eurooffice:documentserver
cat /home/alex/nube/secrets/admin_password.txt
```
