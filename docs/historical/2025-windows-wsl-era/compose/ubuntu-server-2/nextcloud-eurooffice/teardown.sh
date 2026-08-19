#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="/home/alex/nube"
cd "$PROJECT_DIR"

echo "=== Tearing down nube.bentomo.es stack ==="
if [[ -f docker-compose.yml ]]; then
    docker compose down --volumes --remove-orphans 2>/dev/null || true
fi
for c in nube-nextcloud nube-db nube-redis nube-eurooffice pedantic_yonath modest_vaughan nextcloud-aio-nextcloud nextcloud-aio-database nextcloud-aio-redis nextcloud-aio-apache nextcloud-aio-eurooffice; do
    docker rm -f "$c" 2>/dev/null || true
done
for v in $(docker volume ls -q | grep -E 'nextcloud_aio|nube_'); do
    docker volume rm "$v" 2>/dev/null || true
done
echo "=== Teardown complete ==="
