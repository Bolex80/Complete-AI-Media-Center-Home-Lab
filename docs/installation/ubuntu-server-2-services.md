# Ubuntu Server 2 Services

This server hosts personal cloud storage and specialized application services.

## Network Configuration

- **Hostname:** Bentomo-CLOUD
- **IP Address:** 192.168.2.202
- **Role:** Dedicated application and storage server

## Services Overview

### NextCloud
**Description:** Self-hosted personal cloud storage solution.
**Purpose:** File sync, share, and collaboration platform (alternative to Google Drive/Dropbox).
**Port:** 8080
**Configuration:** [docker-compose.yml](../docker-compose/nextcloud/docker-compose.yml)

**Key Features:**
- File sync across devices
- Calendar and contacts
- Document collaboration (with OnlyOffice/Collabora)
- End-to-end encryption
- Mobile apps for iOS/Android

**Prerequisites:**
- Dedicated database (PostgreSQL/MySQL)
- Redis for caching
- Persistent storage for user files

**Environment Variables:**
- `NEXTCLOUD_ADMIN_USER`: Admin username
- `NEXTCLOUD_ADMIN_PASSWORD`: Admin password
- `NEXTCLOUD_TRUSTED_DOMAINS`: Your domain(s)

---

### Crafty Controller
**Description:** Minecraft server management panel.
**Purpose:** Easy management of Minecraft servers with web UI.
**Port:** 8443 (HTTPS), 8123 (HTTP)
**Configuration:** [docker-compose.yml](../docker-compose/crafty-controller/docker-compose.yml)

**Key Features:**
- Multiple Minecraft server support
- Web-based console
- Backup automation
- Player statistics
- Plugin/mod management

**Prerequisites:**
- Java runtime (included in image)
- Adequate RAM allocation
- Port forwarding for Minecraft (25565)

---

### Stirling PDF
**Description:** Web-based PDF manipulation tool.
**Purpose:** Self-hosted PDF operations without uploading to external services.
**Port:** 8081
**Configuration:** [docker-compose.yml](../docker-compose/stirling-pdf/docker-compose.yml)

**Key Features:**
- Merge, split, rotate PDFs
- Convert from/to PDF (Word, PowerPoint, Excel, images)
- OCR (Optical Character Recognition)
- Add watermarks and signatures
- PDF compression

---

## Common Configuration

### Docker Network

```bash
docker network create bolex-net
```

### Environment Variables

Create a `.env` file:

```bash
# NextCloud
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=YOUR_SECURE_PASSWORD
NEXTCLOUD_TRUSTED_DOMAINS=cloud.yourdomain.com

# Crafty
CRAFTY_PASSWORD=YOUR_CRAFTY_PASSWORD

# Database (for NextCloud)
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=YOUR_DB_PASSWORD
```

### Starting Services

```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/ubuntu-server-2

# Start individual services
docker-compose -f nextcloud/docker-compose.yml up -d
docker-compose -f crafty-controller/docker-compose.yml up -d
docker-compose -f stirling-pdf/docker-compose.yml up -d
```

---

## Backup Considerations

**Critical Data:**

### NextCloud
- User data directory (files)
- Database (PostgreSQL/MySQL)
- Configuration files
- Redis data (optional, can be regenerated)

**Backup Strategy:**
```bash
#!/bin/bash
BACKUP_DIR="/path/to/backups/nextcloud/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup NextCloud files
docker exec nextcloud tar czf - /var/www/html > "$BACKUP_DIR/nextcloud-files.tar.gz"

# Backup database
docker exec nextcloud-db pg_dump -U nextcloud nextcloud > "$BACKUP_DIR/nextcloud-db.sql"

# Backup user data (if external volume)
tar czf "$BACKUP_DIR/nextcloud-data.tar.gz" /path/to/nextcloud/data
```

### Crafty
- Server world files
- Configuration
- Backups directory

**Backup:**
```bash
tar czf crafty-backup.tar.gz /path/to/crafty/servers /path/to/crafty/backups
```

---

## Troubleshooting

### NextCloud

**Slow Performance:**
1. Enable Redis for file locking
2. Configure OPcache in PHP
3. Enable HTTP/2
4. Use PostgreSQL instead of SQLite
5. Consider external object storage

**Upload Size Limits:**
- Modify in `php.ini`:
  - `upload_max_filesize`
  - `post_max_size`
  - `max_execution_time`

**Trusted Domains Error:**
Add to `config/config.php`:
```php
'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => 'cloud.yourdomain.com',
    2 => '192.168.2.202',
  ),
```

### Crafty

**Server Won't Start:**
1. Check Java version compatibility
2. Verify sufficient RAM allocation
3. Review server logs in Crafty UI
4. Check port conflicts

**Connection Issues:**
- Ensure port 25565 is forwarded in firewall
- Verify Minecraft version compatibility
- Check EULA acceptance (eula.txt)

### Stirling PDF

**OCR Not Working:**
- Ensure Tesseract OCR is properly configured
- Check language packs are installed
- Verify image quality is sufficient

---

## Security Considerations

1. **HTTPS Only**: Use Nginx Proxy Manager or Traefik for SSL termination
2. **Fail2Ban**: Install and configure for SSH and web services
3. **Regular Updates**: Keep containers updated
4. **Firewall**: Restrict ports to necessary services only
5. **Backups**: Encrypt backup files before offsite storage
