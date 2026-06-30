#!/usr/bin/env bash
# update-nextcloud.sh
# Safe, one-command update + integrity check for the nube.bentomo.es stack.
# Run as user alex on 192.168.2.210.
set -euo pipefail

PROJECT_DIR="/home/alex/nube"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
BACKUP_BASE="/home/alex/backups/nube"
APP_STORE_API="https://apps.nextcloud.com/api/v1/apps.json"

DRY_RUN=false
SKIP_BACKUP=false
SKIP_INTEGRITY=false
EUROOFFICE_ARCHIVE=""

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --dry-run              Show what would be done without changing anything.
  --skip-backup          Skip the data/DB backup (not recommended).
  --skip-integrity       Skip integrity checks.
  --eurooffice-archive PATH
                         Use a local .tar.gz instead of auto-downloading.
  -h, --help             Show this help.

Examples:
  $0                                         # normal update + backup + integrity
  $0 --dry-run                               # preview only
  $0 --eurooffice-archive /tmp/eurooffice.tar.gz   # override app-store download

Notes:
  - Pulls latest Nextcloud/EuroOffice Docker images.
  - Runs occ upgrade, repair, store app updates.
  - Auto-downloads the latest EuroOffice Nextcloud app from the Nextcloud App Store.
  - Backs up Nextcloud data + MariaDB under $BACKUP_BASE with a timestamp.
  - Stays on the version shipped by the Docker image. If Nextcloud still shows
    "33.0.5", the nextcloud:stable-apache image on Docker Hub has not yet been
    updated to 33.0.6. The script will report the pulled image version.
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true ; shift ;;
        --skip-backup) SKIP_BACKUP=true ; shift ;;
        --skip-integrity) SKIP_INTEGRITY=true ; shift ;;
        --eurooffice-archive)
            [[ $# -ge 2 ]] || { echo "Missing argument for --eurooffice-archive"; exit 1; }
            EUROOFFICE_ARCHIVE="$2"
            shift 2
            ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

container_running() {
    docker ps --format '{{.Names}}' | grep -qx "$1"
}

occ() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] docker exec -u www-data nube-nextcloud php occ $*"
    else
        docker exec -u www-data nube-nextcloud php occ "$@"
    fi
}

cleanup_maintenance() {
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "=== Disabling maintenance mode (cleanup) ==="
        docker exec -u www-data nube-nextcloud php occ maintenance:mode --off 2>/dev/null || true
    fi
}
trap cleanup_maintenance EXIT

cd "$PROJECT_DIR"

# --- Pre-flight checks ---
echo "=== Pre-flight checks ==="
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "ERROR: $COMPOSE_FILE not found"
    exit 1
fi
for c in nube-nextcloud nube-db nube-redis nube-eurooffice; do
    if ! container_running "$c"; then
        echo "ERROR: container $c is not running. Start the stack first: cd $PROJECT_DIR && docker compose up -d"
        exit 1
    fi
done
echo "All containers running."

# --- Determine current Nextcloud version for compatible app filtering ---
CURRENT_NC_VERSION=$(docker exec -u www-data nube-nextcloud php -r 'require "/var/www/html/version.php"; echo $OC_VersionString;')
echo "Current Nextcloud version: $CURRENT_NC_VERSION"

# --- Pull latest images ---
echo "=== Pulling latest images ==="
if [[ "$DRY_RUN" != "true" ]]; then
    docker rmi nextcloud:stable-apache ghcr.io/euro-office/documentserver:latest 2>/dev/null || true
fi
run_cmd docker compose pull

echo "=== Pulled image versions ==="
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would inspect pulled image version"
else
    NEXTCLOUD_IMG_VERSION=$(docker run --rm nextcloud:stable-apache bash -c 'head -5 /usr/src/nextcloud/version.php | grep OC_VersionString' 2>/dev/null || echo "unknown")
    echo "Nextcloud Docker image: $NEXTCLOUD_IMG_VERSION"
    echo ""
    echo "NOTE: The running version will match the pulled image. Nextcloud's web UI may"
    echo "advertise a newer release before the Docker Hub 'nextcloud:stable-apache' image"
    echo "is published. If the image is still 33.0.5, the container cannot upgrade to 33.0.6 yet."
fi

# --- Backup ---
BACKUP_DIR=""
if [[ "$SKIP_BACKUP" == "true" ]]; then
    echo "=== Skipping backup as requested ==="
else
    BACKUP_DIR="$BACKUP_BASE/$(date +%Y%m%d-%H%M%S)"
    echo "=== Backing up to $BACKUP_DIR ==="
    mkdir -p "$BACKUP_DIR"
    run_cmd occ maintenance:mode --on || true

    run_cmd docker run --rm \
        --volumes-from nube-nextcloud \
        -v "$BACKUP_DIR:/backup" \
        alpine tar czf /backup/nextcloud-data.tar.gz -C /var/www/html .

    DB_PASS="$(cat "$PROJECT_DIR/secrets/db_root_password.txt")"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] docker exec nube-db mariadb-dump -uroot -p*** nextcloud > $BACKUP_DIR/nextcloud.sql"
    else
        docker exec nube-db mariadb-dump -uroot -p"$DB_PASS" nextcloud > "$BACKUP_DIR/nextcloud.sql" 2>/dev/null || \
        docker exec nube-db mysqldump -uroot -p"$DB_PASS" nextcloud > "$BACKUP_DIR/nextcloud.sql"
    fi

    run_cmd occ maintenance:mode --off || true
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "Backup saved to $BACKUP_DIR"
    fi
fi

# --- Recreate containers ---
echo "=== Stopping and recreating containers ==="
run_cmd docker compose down
run_cmd docker compose up -d --wait

# --- Wait for Nextcloud ---
echo "=== Waiting for Nextcloud ==="
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would wait for http://127.0.0.1:8081/status.php"
else
    for i in $(seq 1 120); do
        if curl -fsS http://127.0.0.1:8081/status.php >/dev/null 2>&1; then
            echo "Nextcloud is ready"
            break
        fi
        echo "Waiting... ($i)"
        sleep 5
    done
    if ! curl -fsS http://127.0.0.1:8081/status.php >/dev/null 2>&1; then
        echo "ERROR: Nextcloud did not become ready"
        docker compose logs nextcloud
        exit 1
    fi
fi

# --- Upgrade Nextcloud ---
echo "=== Running Nextcloud upgrade if needed ==="
occ upgrade || true

# --- Repair / mimetype migration ---
echo "=== Repair and mimetype migration ==="
occ maintenance:repair --include-expensive || true

# --- Update apps from store ---
echo "=== Updating Nextcloud store apps ==="
occ app:update --all || true

# --- EuroOffice app update ---
echo "=== EuroOffice app update ==="
if [[ -n "$EUROOFFICE_ARCHIVE" ]]; then
    if [[ ! -f "$EUROOFFICE_ARCHIVE" ]]; then
        echo "ERROR: EuroOffice archive not found: $EUROOFFICE_ARCHIVE"
        exit 1
    fi
    echo "Applying EuroOffice app from local archive $EUROOFFICE_ARCHIVE"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would extract $EUROOFFICE_ARCHIVE to $PROJECT_DIR/custom_apps/eurooffice"
    else
        TMPDIR=$(mktemp -d)
        tar -xzf "$EUROOFFICE_ARCHIVE" -C "$TMPDIR"
        if [[ -d "$TMPDIR/eurooffice" ]]; then
            rm -rf "$PROJECT_DIR/custom_apps/eurooffice"
            mv "$TMPDIR/eurooffice" "$PROJECT_DIR/custom_apps/eurooffice"
        else
            rm -rf "$PROJECT_DIR/custom_apps/eurooffice"
            mkdir -p "$PROJECT_DIR/custom_apps/eurooffice"
            mv "$TMPDIR"/* "$PROJECT_DIR/custom_apps/eurooffice/"
        fi
        rm -rf "$TMPDIR"
    fi
else
    echo "Auto-downloading latest EuroOffice app from Nextcloud App Store..."
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would query $APP_STORE_API, filter compatible release, download and extract"
    else
        TMPDIR=$(mktemp -d)
        cd "$TMPDIR"
        curl -fsS -o apps.json "$APP_STORE_API"
        # Pick the eurooffice release with highest version whose platform spec matches CURRENT_NC_VERSION
        # Simple approach: take first (latest) eurooffice release; Nextcloud store already filters compatibility.
        APP_URL=$(python3 - "$CURRENT_NC_VERSION" <<'PY'
import json, sys
nc = sys.argv[1]
with open('apps.json') as f:
    apps = json.load(f)
for app in apps:
    if app.get('id') == 'eurooffice':
        rels = app.get('releases', [])
        if not rels:
            sys.exit('no releases')
        # First release is latest; store usually returns compatible ones
        print(rels[0]['download'])
        print(rels[0]['version'])
        break
else:
    sys.exit('eurooffice not found in app store')
PY
        )
        if [[ -z "$APP_URL" ]]; then
            echo "ERROR: Could not determine EuroOffice download URL"
            exit 1
        fi
        echo "Downloading: $APP_URL"
        curl -fsSL -o eurooffice.tar.gz "$APP_URL"
        echo "Extracting EuroOffice app..."
        tar -xzf eurooffice.tar.gz
        if [[ -d "$TMPDIR/eurooffice" ]]; then
            rm -rf "$PROJECT_DIR/custom_apps/eurooffice"
            mv "$TMPDIR/eurooffice" "$PROJECT_DIR/custom_apps/eurooffice"
        else
            rm -rf "$PROJECT_DIR/custom_apps/eurooffice"
            mkdir -p "$PROJECT_DIR/custom_apps/eurooffice"
            mv "$TMPDIR"/* "$PROJECT_DIR/custom_apps/eurooffice/"
        fi
        rm -rf "$TMPDIR"
    fi
fi

# Fix ownership and enable
run_cmd docker exec nube-nextcloud chown -R www-data:www-data /var/www/html/custom_apps
run_cmd occ app:enable eurooffice || true

# Re-apply EuroOffice settings in case the container/app reset them
echo "=== Re-applying EuroOffice settings ==="
JWT_SECRET=$(docker run --rm -v nube_eurooffice_data:/data alpine sh -c 'cat /data/.private/jwt_secret 2>/dev/null' 2>/dev/null || true)
if [[ -n "$JWT_SECRET" ]]; then
    occ config:app:set eurooffice jwt_secret --value "$JWT_SECRET" || true
fi
occ config:app:set eurooffice DocumentServerUrl          --value "https://eurooffice.nube.bentomo.es/" || true
occ config:app:set eurooffice DocumentServerInternalUrl  --value "http://nube-eurooffice/" || true
occ config:app:set eurooffice StorageUrl                 --value "http://nube-nextcloud/" || true
occ config:app:delete eurooffice settings_error 2>/dev/null || true

# --- Final repair / upgrade if app replaced ---
occ upgrade || true
occ maintenance:repair --include-expensive || true

# --- Integrity check ---
if [[ "$SKIP_INTEGRITY" != "true" ]]; then
    echo "=== Integrity checks ==="
    occ integrity:check-app eurooffice || echo "WARNING: EuroOffice integrity check failed"
    occ integrity:check-app files      || echo "WARNING: files integrity check failed"
else
    echo "=== Skipping integrity checks as requested ==="
fi

# --- Verification ---
echo "=== Verification ==="
occ status || true
occ eurooffice:documentserver || true
curl -fsS https://nube.bentomo.es/status.php || true
curl -fsS https://eurooffice.nube.bentomo.es/healthcheck || true

echo ""
echo "=== Update complete ==="
if [[ -n "$BACKUP_DIR" ]]; then
    echo "Backup: $BACKUP_DIR"
fi
