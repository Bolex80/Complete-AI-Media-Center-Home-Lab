#!/usr/bin/env bash
set -euo pipefail

# Setup directory and secrets for the new nube.bentomo.es stack on 192.168.2.210
# Run this script as the user who will own the compose project (alex) on .210.

PROJECT_DIR="/home/alex/nube"

mkdir -p "$PROJECT_DIR/secrets"
cd "$PROJECT_DIR"

if [[ ! -f secrets/admin_password.txt ]]; then
    openssl rand -hex 16 > secrets/admin_password.txt
fi
if [[ ! -f secrets/db_password.txt ]]; then
    openssl rand -hex 16 > secrets/db_password.txt
fi
if [[ ! -f secrets/db_root_password.txt ]]; then
    openssl rand -hex 16 > secrets/db_root_password.txt
fi
if [[ ! -f secrets/eurooffice_jwt.txt ]]; then
    openssl rand -base64 32 | tr -d '=+/' | cut -c1-32 > secrets/eurooffice_jwt.txt
fi

chmod 700 secrets
chmod 600 secrets/*.txt

echo "Secrets generated in $PROJECT_DIR/secrets"
