#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/alex/nube"
cd "$PROJECT_DIR"

for f in secrets/admin_password.txt secrets/db_password.txt secrets/db_root_password.txt secrets/eurooffice_jwt.txt; do
    [[ -f "$f" ]] || { echo "Missing $f; run ./setup-secrets.sh first"; exit 1; }
done

echo "=== Tear down old Nextcloud/EuroOffice leftovers ==="
./teardown.sh

echo "=== Removing stale Nextcloud/EuroOffice images to force fresh pull ==="
docker rmi nextcloud:stable-apache ghcr.io/euro-office/documentserver:latest 2>/dev/null || true

echo "=== Starting stack ==="
docker compose pull
docker compose up -d --wait

echo "=== Waiting for Nextcloud ==="
for i in $(seq 1 120); do
    if curl -fsS http://127.0.0.1:8081/status.php >/dev/null 2>&1; then
        echo "Nextcloud is ready"
        break
    fi
    echo "Waiting... ($i)"
    sleep 5
done
if ! curl -fsS http://127.0.0.1:8081/status.php >/dev/null 2>&1; then
    echo "Nextcloud did not become ready on port 8081"
    docker compose logs nextcloud
    exit 1
fi

echo "=== Installing EuroOffice app ==="
# Custom app code is in ./custom_apps/eurooffice; mount is already in place but ownership may need fix
docker exec nube-nextcloud chown -R www-data:www-data /var/www/html/custom_apps
# Wait until occ is usable
for i in $(seq 1 30); do
    if docker exec -u www-data nube-nextcloud php occ status >/dev/null 2>&1; then
        break
    fi
    sleep 2
done
docker exec -u www-data nube-nextcloud php occ app:enable eurooffice

echo "=== EuroOffice JWT secret ==="
# Secret is persisted in named volume nube_eurooffice_data at /var/www/euro-office/Data/.private/jwt_secret
for i in $(seq 1 60); do
    JWT_SECRET=$(docker run --rm -v nube_eurooffice_data:/data alpine sh -c 'cat /data/.private/jwt_secret 2>/dev/null' 2>/dev/null || true)
    if [[ -n "$JWT_SECRET" ]]; then
        break
    fi
    sleep 2
done
if [[ -z "$JWT_SECRET" ]]; then
    echo "Could not read EuroOffice JWT secret from nube_eurooffice_data volume"
    exit 1
fi

echo "=== Configuring EuroOffice app ==="
docker exec -u www-data nube-nextcloud php occ config:app:set eurooffice DocumentServerUrl          --value "https://eurooffice.nube.bentomo.es/"
docker exec -u www-data nube-nextcloud php occ config:app:set eurooffice DocumentServerInternalUrl  --value "http://nube-eurooffice/"
docker exec -u www-data nube-nextcloud php occ config:app:set eurooffice StorageUrl                 --value "http://nube-nextcloud/"
docker exec -u www-data nube-nextcloud php occ config:app:set eurooffice verify_peer_off            --value "true"
docker exec -u www-data nube-nextcloud php occ config:app:set eurooffice jwt_secret                 --value "$JWT_SECRET"
docker exec -u www-data nube-nextcloud php occ config:app:delete eurooffice settings_error 2>/dev/null || true

echo "=== Nextcloud system settings ==="
docker exec -u www-data nube-nextcloud php occ config:system:set trusted_domains 1 --value nube-nextcloud || true
docker exec -u www-data nube-nextcloud php occ config:system:set trusted_proxies 0 --value 172.0.0.0/8 || true
docker exec -u www-data nube-nextcloud php occ config:system:set trusted_proxies 1 --value 192.0.0.0/8 || true
docker exec -u www-data nube-nextcloud php occ config:system:set trusted_proxies 2 --value 10.0.0.0/8 || true
docker exec -u www-data nube-nextcloud php occ config:system:set trusted_proxies 3 --value 192.168.0.0/16 || true
docker exec -u www-data nube-nextcloud php occ config:system:set memcache.locking --value \\OC\\Memcache\\Redis || true
docker exec -u www-data nube-nextcloud php occ config:system:set memcache.distributed --value \\OC\\Memcache\\Redis || true
docker exec -u www-data nube-nextcloud php occ config:system:set redis host --value redis || true
docker exec -u www-data nube-nextcloud php occ config:system:set redis port --value 6379 --type integer || true

echo "=== Verification ==="
curl -fsS http://127.0.0.1:8081/status.php
curl -fsS http://127.0.0.1:8082/healthcheck
docker exec -u www-data nube-nextcloud php occ eurooffice:documentserver

echo ""
echo "=== Deploy complete ==="
echo "Nextcloud: https://nube.bentomo.es (admin: alex)"
echo "Admin password: $PROJECT_DIR/secrets/admin_password.txt"
echo "EuroOffice: https://eurooffice.nube.bentomo.es"