# Ubuntu Server 1 Services

This server runs the primary web-facing services and acts as the main reverse proxy for the home lab.

## Network Configuration

- **Hostname:** Bentomo-NET
- **IP Address:** 192.168.2.201
- **Virtual IP (VRRP1):** 192.168.2.3 (HTTP/HTTPS traffic)
- **Role:** Primary for web services, Secondary for DNS

## Services Overview

### Keepalived
**Description:** High availability and load balancing for the web services.
**Purpose:** Ensures failover to Raspberry Pi if this server goes down.
**Configuration:** [high-availability.md](../../high-availability.md)

**Key Points:**
- Master for VRRP1 (HTTP/HTTPS)
- Backup for VRRP2 (DNS/VPN)
- Monitors service health and handles failover

---

### Nginx Proxy Manager
**Description:** Reverse proxy with built-in SSL certificate management.
**Purpose:** Routes external traffic to internal services and handles HTTPS.
**Port:** 81 (admin), 80/443 (proxy)
**Configuration:** [docker-compose.yml](../docker-compose/nginx-proxy-manager/docker-compose.yml)

**Key Features:**
- Web-based configuration UI
- Let's Encrypt SSL automation
- Custom location and redirect support
- Access lists and authentication

**Setup:**
1. Access admin at `http://192.168.2.201:81`
2. Default login: `admin@example.com` / `changeme`
3. Configure proxy hosts for each service
4. Set up SSL certificates

---

### Homer Dashboard
**Description:** Simple static homepage for your homelab.
**Purpose:** Central landing page with links to all services.
**Port:** 8080
**Configuration:** [docker-compose.yml](../docker-compose/homer-dashboard/docker-compose.yml)

**Key Features:**
- YAML-based configuration
- Customizable themes and icons
- Service status indicators
- Group organization

---

### SearXNG
**Description:** Privacy-respecting metasearch engine.
**Purpose:** Aggregate search results from multiple sources without tracking.
**Port:** 8082
**Configuration:** [docker-compose.yml](../docker-compose/searxng/docker-compose.yml)

**Key Features:**
- No user tracking
- Multiple search engine sources
- Customizable filters
- JSON API available

---

### Vaultwarden
**Description:** Unofficial Bitwarden server implementation.
**Purpose:** Self-hosted password manager with sync capabilities.
**Port:** 8083
**Configuration:** [docker-compose.yml](../docker-compose/vaultwarden/docker-compose.yml)

**Key Features:**
- Full Bitwarden compatibility
- Web vault, browser extensions, mobile apps
- Organization and sharing support
- Encrypted storage

---

### Secondary PiHole
**Description:** Secondary DNS sinkhole and ad blocker.
**Purpose:** Backup DNS server synced with primary PiHole on Raspberry Pi.
**Port:** 8084 (web), 53 (DNS)
**Configuration:** [docker-compose.yml](../docker-compose/pihole/docker-compose.yml)

**Key Features:**
- DHCP server capability
- Custom blocklists
- Query logging and statistics
- Gravity sync with primary

---

### Uptime Kuma
**Description:** Self-hosted monitoring tool.
**Purpose:** Monitor service uptime and receive alerts.
**Port:** 3001
**Configuration:** [docker-compose.yml](../docker-compose/uptime-kuma/docker-compose.yml)

**Key Features:**
- HTTP/HTTPS/TCP/Ping monitoring
- Email, Discord, Telegram notifications
- Docker container monitoring
- Status pages with custom domains

---

### Beszel System Monitor
**Description:** Lightweight system monitoring hub.
**Purpose:** Monitor server resources and performance.
**Port:** 8090
**Configuration:** [docker-compose.yml](../docker-compose/beszel/docker-compose.yml)

**Key Features:**
- CPU, memory, disk monitoring
- Network statistics
- Historical data
- Agent-based architecture

---

### Speedtest Tracker
**Description:** Automated internet speed testing.
**Purpose:** Monitor internet connection performance over time.
**Port:** 8765
**Configuration:** [docker-compose.yml](../docker-compose/speedtest-tracker/docker-compose.yml)

**Key Features:**
- Scheduled speed tests
- Historical graphs
- Ookla Speedtest integration
- Notifications for degraded speeds

---

### Cloudflare DDNS
**Description:** Dynamic DNS updater for Cloudflare.
**Purpose:** Keep Cloudflare DNS records updated with public IP changes.
**Configuration:** [docker-compose.yml](../docker-compose/cloudflare-ddns/docker-compose.yml)

**Key Features:**
- IPv4 and IPv6 support
- Multiple domain support
- Proxied/unproxied record toggle
- API token authentication

**Environment Variables:**
- `CF_API_TOKEN`: Your Cloudflare API token
- `DOMAINS`: Comma-separated list of domains to update

---

### IT Tools
**Description:** Collection of handy online utilities for IT professionals.
**Purpose:** Quick access to converters, encoders, network tools, etc.
**Port:** 8085
**Configuration:** [docker-compose.yml](../docker-compose/it-tools/docker-compose.yml)

**Key Features:**
- Base64 encode/decode
- JSON formatter
- Hash generators
- Network calculators
- Regex testers

---

### Themepark
**Description:** Custom themes and skins for applications.
**Purpose:** Unified theme management for supported apps.
**Port:** 8086
**Configuration:** [docker-compose.yml](../docker-compose/themepark/docker-compose.yml)

**Key Features:**
- Multiple theme options
- CSS injection for supported apps
- Dark mode support
- Easy theme switching

---

### Guacamole
**Description:** Clientless remote desktop gateway.
**Purpose:** Browser-based access to RDP, VNC, and SSH connections.
**Port:** 8087
**Configuration:** [docker-compose.yml](../docker-compose/guacamole/docker-compose.yml)

**Key Features:**
- No client software needed
- RDP, VNC, SSH support
- Session recording
- Multi-factor authentication

---

## Common Configuration

### Docker Network

Create the shared network:

```bash
docker network create bolex-net
```

### Environment Variables

Create a `.env` file:

```bash
# Cloudflare
CF_API_TOKEN=your_cloudflare_api_token
DOMAINS=your-domain.com

# PiHole
PIHOLE_WEBPASSWORD=your_admin_password
PIHOLE_SERVER_IP=192.168.2.201

# Vaultwarden
ADMIN_TOKEN=your_admin_token_here
SIGNUPS_ALLOWED=false
```

### Starting Services

```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/ubuntu-server-1

# Start all services
for dir in */; do
  (cd "$dir" && docker-compose up -d)
done

# Or individually
docker-compose -f nginx-proxy-manager/docker-compose.yml up -d
```

---

## Backup Considerations

**Critical Data:**
- `./nginx-proxy-manager-data` - Proxy configurations and SSL certs
- `./vaultwarden-data` - Encrypted password vaults
- `./pihole-data` - DNS configuration and blocklists
- `./uptime-kuma-data` - Monitoring history and settings
- `./homer-config` - Dashboard configuration
- `./beszel-data` - System monitoring data

**Backup Script:**
```bash
#!/bin/bash
BACKUP_DIR="/path/to/backups/ubuntu-server-1/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup volumes
docker run --rm -v nginx-proxy-manager-data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/nginx-proxy-manager.tar.gz -C /data .
docker run --rm -v vaultwarden-data:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/vaultwarden.tar.gz -C /data .
# ... etc
```

---

## Troubleshooting

### Services Not Accessible
1. Check Nginx Proxy Manager proxy host configuration
2. Verify service is running: `docker-compose ps`
3. Check logs: `docker-compose logs -f`
4. Test internal access: `curl http://localhost:PORT`

### SSL Certificate Issues
1. Verify DNS points to server
2. Check firewall allows port 80 for ACME challenge
3. Review NPM logs for Let's Encrypt errors
4. Try DNS challenge if HTTP fails

### High Availability Failover
1. Check Keepalived status: `sudo systemctl status keepalived`
2. Verify VRRP communication: `sudo tcpdump -i eth0 vrrp`
3. Check VIP assignment: `ip a show eth0`
4. Review logs: `sudo journalctl -u keepalived`
