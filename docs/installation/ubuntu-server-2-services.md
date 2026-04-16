# Ubuntu Server 2 Services (Nextcloud AIO)

This server hosts Nextcloud AIO (All-in-One), Crafty Controller (Minecraft), and Dockhand (Docker management).

## Network Configuration

- **Hostname:** nextcloudaio
- **IP Address:** 192.168.2.210
- **Architecture:** x86_64
- **RAM:** 7.7 GB
- **Storage:** 391 GB (LVM)
- **Role:** Personal cloud, game servers, Docker management hub

> ⚠️ **Important:** This server runs **Nextcloud AIO** (All-in-One), NOT a standard Nextcloud docker-compose setup. The AIO mastercontainer manages all sub-containers automatically. Do NOT attempt to start/stop individual AIO containers manually.

---

## Services Overview

| # | Service | Port | Status | Compose |
|---|---------|------|--------|---------|
| 1 | Nextcloud AIO (master) | 8080 | ✅ Running | [Link](../docker-compose/ubuntu-server-2/nextcloud-aio/docker-compose.yml) |
| 2 | Nextcloud AIO Apache | 11000 | ✅ Running | Managed by AIO |
| 3 | Nextcloud AIO Nextcloud | — | ✅ Running | Managed by AIO |
| 4 | Nextcloud AIO PostgreSQL | — | ✅ Running | Managed by AIO |
| 5 | Nextcloud AIO Redis | — | ✅ Running | Managed by AIO |
| 6 | Nextcloud AIO Collabora | — | ✅ Running | Managed by AIO |
| 7 | Nextcloud AIO ClamAV | — | ✅ Running | Managed by AIO |
| 8 | Nextcloud AIO Imaginary | — | ✅ Running | Managed by AIO |
| 9 | Nextcloud AIO Notify Push | — | ✅ Running | Managed by AIO |
| 10 | Nextcloud AIO Whiteboard | — | ✅ Running | Managed by AIO |
| 11 | Crafty Controller | 8123/8443 | ✅ Running | [Link](../docker-compose/ubuntu-server-2/crafty-controller/docker-compose.yml) |
| 12 | Dockhand | 3000 | ✅ Running | [Link](../docker-compose/ubuntu-server-2/dockhand/docker-compose.yml) |

### Infrastructure Agents

| Service | Port | Notes |
|---------|------|-------|
| Beszel Agent | — | System metrics reporter |
| Portainer | 8000/9443 | Docker management UI |
| Hawser clients | — | Connect to Dockhand for Docker management |

---

## Service Details

### Nextcloud AIO
**Description:** Complete Nextcloud deployment managed by a single mastercontainer.
**Domain:** nube.bentomo.es
**AIO Admin:** http://192.168.2.210:8080
**Nextcloud Access:** https://nube.bentomo.es (proxied via port 11000)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-2/nextcloud-aio/docker-compose.yml)

**Architecture:**
The AIO mastercontainer (`nextcloud/all-in-one:latest`) orchestrates 9 sub-containers:
- **Apache** — Reverse proxy for Nextcloud, listens on port 11000
- **Nextcloud** — Main application (Nextcloud 32.0.8, PHP 8.3)
- **PostgreSQL** — Database backend (aio-postgresql)
- **Redis** — Caching and session management
- **Collabora** — Online document editing (LibreOffice-based)
- **ClamAV** — Antivirus scanning for uploaded files
- **Imaginary** — Image processing and preview generation
- **Notify Push** — Real-time push notifications
- **Whiteboard** — Collaborative whiteboard

**Key Environment Variables (set on mastercontainer):**
- `APACHE_PORT=11000` — Apache listening port
- `APACHE_IP_BINDING=192.168.2.210` — Bind to server IP
- `NEXTCLOUD_MOUNT=/mnt/external` — External storage mount point

**Key Configuration (managed by AIO, not in compose):**
- `NC_DOMAIN=nube.bentomo.es`
- `OVERWRITEPROTOCOL=https`
- `PHP_UPLOAD_LIMIT=16G`
- `PHP_MEMORY_LIMIT=512M`
- `COLLABORA_ENABLED=yes`, `CLAMAV_ENABLED=yes`, `IMAGINARY_ENABLED=yes`
- `WHITEBOARD_ENABLED=yes`
- `UPDATE_NEXTCLOUD_APPS=yes`
- Startup apps: deck, twofactor_totp, tasks, calendar, contacts, notes

**Setup:**
1. Start the mastercontainer: `docker compose up -d`
2. Access AIO admin at `http://192.168.2.210:8080`
3. Get the initial admin password from: `docker exec nextcloud-aio-mastercontainer cat /var/www/html/cron.php | grep 'AIO_PASSWORD'`
4. Configure domain, SSL, and sub-containers through the AIO interface
5. AIO will automatically start and manage all sub-containers

**External Storage:**
Mounted at `/mnt/external` inside the Nextcloud container. Configure via AIO admin.

---

### Crafty Controller
**Description:** Minecraft server management panel.
**Port:** 8123 (HTTP), 8443 (HTTPS)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-2/crafty-controller/docker-compose.yml)

**Key Features:**
- Multiple Minecraft server support
- Web-based console
- Backup automation
- Player statistics
- Plugin/mod management

**Minecraft Ports:**
- Java: 25500-25600 (101 ports for multiple servers)
- Bedrock: 19132/udp

**Volumes:**
- `./servers` — Minecraft world files
- `./config` — Crafty configuration
- `./backups` — Automated backups
- `./logs` — Server logs

---

### Dockhand
**Description:** Docker container management hub with Hawser agents.
**Port:** 3000
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-2/dockhand/docker-compose.yml)

**Architecture:**
- Dockhand server (web UI + API) with PostgreSQL backend
- Hawser agents on each server connect via WebSocket
- Provides centralized Docker compose stack management

**Hawser Agents Connected:**
| Agent | Server | Name |
|-------|--------|------|
| Hawser | PiNet1 (192.168.2.200) | Pi-NET-1 |
| Hawser | PiNet2 (192.168.2.205) | (identical) |
| Hawser | Bentomo_NET (192.168.2.201) | (identical) |
| Hawser | Bolex-Cloud-2 (130.110.233.63) | Oracle-Cloud-2 |

**Note:** The Dockhand `DATABASE_URL` contains a password — use `.env` file in production.

---

## What's NOT on this server

> ⚠️ **Correction from original docs:**

- **Stirling PDF** — was listed here but is actually running on **Bolex-Cloud-1** (79.72.49.182:8090). See [Bolex-Cloud-1 docs](oracle-cloud-bolex1-services.md).
- **Borg Backup / Watchtower** — Nextcloud AIO includes its own backup and update mechanisms. The `nextcloud-aio-borgbackup` and `nextcloud-aio-watchtower` containers are intentionally excluded from routine management.

---

## Port Reference

| Service | Host Port | Container Port | Notes |
|---------|-----------|-----------------|-------|
| AIO Master | 8080 | 8080 | Admin interface only |
| AIO Apache | 11000 | 11000 | Nextcloud web (bound to 192.168.2.210) |
| Crafty HTTP | 8123 | 8123 | Web UI |
| Crafty HTTPS | 8443 | 8443 | Web UI |
| Crafty Java | 25500-25600 | 25500-25600 | Minecraft servers |
| Crafty Bedrock | 19132 | 19132 | Bedrock (UDP) |
| Dockhand | 3000 | 3000 | Management hub |
| Portainer | 8000 | 8000 | Agent |
| Portainer | 9443 | 9443 | Web UI |

---

## Backup Considerations

**Critical Data:**
- Nextcloud AIO data volumes (`nextcloud_aio_nextcloud`, `nextcloud_aio_nextcloud_data`)
- PostgreSQL data (managed by AIO)
- Crafty servers and backups directories
- Dockhand PostgreSQL database

**Nextcloud AIO Backup:**
AIO includes built-in Borg backup. Configure through the AIO admin interface.
**Ignored containers:** `nextcloud-aio-borgbackup`, `nextcloud-aio-watchtower`

**Manual Backup (Crafty):**
```bash
tar czf crafty-backup-$(date +%Y%m%d).tar.gz /path/to/crafty/servers /path/to/crafty/backups
```

---

## Troubleshooting

### Nextcloud AIO

**Can't access AIO admin:**
1. Verify mastercontainer is running: `docker ps | grep nextcloud-aio-mastercontainer`
2. Check port 8080 is available: `ss -tlnp | grep 8080`
3. Review logs: `docker logs nextcloud-aio-mastercontainer`

**Sub-containers not starting:**
1. Access AIO admin and check start/restart buttons
2. Review individual container logs: `docker logs nextcloud-aio-nextcloud`
3. Check `APACHE_IP_BINDING` matches the server's actual IP

**Slow Performance:**
1. Verify Redis is running
2. Check PHP memory: `PHP_MEMORY_LIMIT=512M` (increase if needed)
3. Monitor PostgreSQL: `docker exec nextcloud-aio-database psql -U nextcloud -c "SELECT version();"`

### Crafty

**Server Won't Start:**
1. Check Java version compatibility in Crafty UI
2. Verify sufficient RAM (Minecraft needs 1-4GB per server)
3. Review server logs in Crafty UI
4. Check port conflicts: `ss -tlnp | grep 25565`

---

## Security Considerations

1. **HTTPS Only:** Nextcloud is accessed via HTTPS through the AIO Apache container
2. **AIO Admin:** Port 8080 should NOT be exposed to the internet — internal access only
3. **Crafty:** Use HTTPS (8443) for the web UI
4. **Dockhand:** Contains database credentials — secure the `.env` file
5. **Portainer:** Uses its own HTTPS (9443) — change default password on first login