# Nube fresh-install runbook

## Prerequisites
- DNS: `nube.bentomo.es` and `eurooffice.nube.bentomo.es` point to `192.168.2.210`
- Pangolin: `nube.bentomo.es -> http://192.168.2.210:8081`, `eurooffice.nube.bentomo.es -> http://192.168.2.210:8082`
- Run everything as user `alex` on `192.168.2.210`

## Files
| File | Purpose |
|---|---|
| `docker-compose.yml` | MariaDB, Redis, Nextcloud, EuroOffice |
| `setup-secrets.sh` | Generates admin/DB/JWT secrets (run first) |
| `teardown.sh` | Stops and removes the nube stack and leftovers |
| `deploy.sh` | One-command deploy/refresh (runs teardown, then deploys) |
| `/home/alex/update-nextcloud.sh` | Pulls latest images, backs up, upgrades, repairs, integrity-checks |

## Deploy
```bash
ssh alex@192.168.2.210
cd /home/alex/nube
./setup-secrets.sh   # only first time or if you want new secrets
./deploy.sh
```

## Update Nextcloud/EuroOffice
```bash
ssh alex@192.168.2.210
/home/alex/update-nextcloud.sh
```
This pulls latest images, backs up data + DB, runs the upgrade, repairs, updates apps, re-syncs the EuroOffice JWT secret, and checks integrity.

## Reset / start over
```bash
./teardown.sh
./setup-secrets.sh   # optional
./deploy.sh
```

## Verify
```bash
curl -fsS https://nube.bentomo.es/status.php
curl -fsS https://eurooffice.nube.bentomo.es/healthcheck
docker exec -u www-data nube-nextcloud php occ eurooffice:documentserver
cat /home/alex/nube/secrets/admin_password.txt
```

## Test
1. Log in to https://nube.bentomo.es as `alex`.
2. Create a new document or upload a `.docx`.
3. Open it — EuroOffice editor should load.

## Troubleshooting
- If the editor shows "Download failed", check Pangolin is not stripping `Authorization` headers and that both DNS names resolve to `.210`.
- If Nextcloud says "Nextcloud Office cannot be reached", check the EuroOffice health endpoint and the app settings.
- EuroOffice JWT secret is persisted in the `nube_eurooffice_data` Docker volume. Do not delete that volume unless you want to regenerate the secret and re-run `./deploy.sh`.
