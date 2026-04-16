# Ubuntu Server 1 Services (Bentomo-NET)

This server runs the primary web-facing services and acts as the main reverse proxy for the home lab.

## Network Configuration

- **Hostname:** Bentomo-NET
- **IP Address:** 192.168.2.201
- **Virtual IP (VRRP1):** 192.168.2.3 (HTTP/HTTPS traffic)
- **Role:** Primary for web services, Secondary for DNS
- **Architecture:** x86_64
- **Resources:** 3.8 GB RAM, 96 GB disk

## Services Overview

| # | Service | Port | Status | Compose |
|---|---------|------|--------|---------|
| 1 | Nginx Proxy Manager | 80/81/443 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/nginx-proxy-manager/docker-compose.yml) |
| 2 | Homer Dashboard | 8080 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/homer-dashboard/docker-compose.yml) |
| 3 | SearXNG | 8070 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/searxng/docker-compose.yml) |
| 4 | Vaultwarden | 8100 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/vaultwarden/docker-compose.yml) |
| 5 | Pi-Hole + Unbound | 53/83/5443/5335 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/pihole/docker-compose.yml) |
| 6 | Uptime Kuma | 3001 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/uptime-kuma/docker-compose.yml) |
| 7 | Beszel | 8050 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/beszel/docker-compose.yml) |
| 8 | Speedtest Tracker | 8085/8443 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/speedtest-tracker/docker-compose.yml) |
| 9 | Cloudflare DDNS | — | ✅ Running | [Link](../docker-compose/ubuntu-server-1/cloudflare-ddns/docker-compose.yml) |
| 10 | IT Tools | 8090 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/it-tools/docker-compose.yml) |
| 11 | Theme Park | 8082/4443 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/themepark/docker-compose.yml) |

### Monitoring & Observability

| # | Service | Port | Status | Compose |
|---|---------|------|--------|---------|
| 12 | Grafana | 3005 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/grafana/docker-compose.yml) |
| 13 | Prometheus | 9090 | ✅ Running | Included in Grafana compose |
| 14 | GoAccess | 7889/7890 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/goaccess/docker-compose.yml) |

### Network & UPS Monitoring

| # | Service | Port | Status | Compose |
|---|---------|------|--------|---------|
| 15 | NUT WebGUI | 9000 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/nut-webgui/docker-compose.yml) |
| 16 | PeaNUT | 9001 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/peanut/docker-compose.yml) |
| 17 | OpenSpeedTest | 3000/3011 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/openspeedtest/docker-compose.yml) |

### Utilities

| # | Service | Port | Status | Compose |
|---|---------|------|--------|---------|
| 18 | LinkStack | 8190/8191 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/linkstack/docker-compose.yml) |
| 19 | Nebula Sync | — | ✅ Running | [Link](../docker-compose/ubuntu-server-1/nebula-sync/docker-compose.yml) |
| 20 | Portainer | 8000/9443 | ✅ Running | [Link](../docker-compose/ubuntu-server-1/portainer/docker-compose.yml) |

### Infrastructure Agents

| Service | Port | Notes |
|---------|------|-------|
| Beszel Agent | — | System metrics reporter for Beszel hub |
| Newt | 2112 | Pangolin tunnel agent |
| Hawser | 2376 | Docker TLS proxy agent |

---

## Service Details

### Keepalived
**Description:** High availability and load balancing for the web services.
**Purpose:** Ensures failover to Raspberry Pi if this server goes down.
**Configuration:** [high-availability.md](../../high-availability.md)

> ⚠️ **Security:** Keepalived auth passwords are stored in `secrets.example.env` — never commit real passwords to the repo.

**Key Points:**
- Master for VRRP1 (HTTP/HTTPS)
- Backup for VRRP2 (DNS/VPN)
- Monitors service health and handles failover

---

### Nginx Proxy Manager
**Description:** Reverse proxy with built-in SSL certificate management.
**Purpose:** Routes external traffic to internal services and handles HTTPS.
**Port:** 81 (admin), 80/443 (proxy)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/nginx-proxy-manager/docker-compose.yml)

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

**Note:** NPM also proxies Minecraft (25565-25566) and Bedrock (19132/udp) ports.

---

### Homer Dashboard
**Description:** Simple static homepage for your homelab.
**Purpose:** Central landing page with links to all services.
**Port:** 8080
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/homer-dashboard/docker-compose.yml)

**Key Features:**
- YAML-based configuration
- Customizable themes and icons
- Service status indicators
- Group organization

---

### SearXNG
**Description:** Privacy-respecting metasearch engine.
**Purpose:** Aggregate search results from multiple sources without tracking.
**Port:** 8070 (mapped to container 8080)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/searxng/docker-compose.yml)

**Key Features:**
- No user tracking
- Multiple search engine sources
- Customizable filters
- JSON API available
- Paired with Valkey (Redis-compatible) for caching

**Environment:**
- `SEARXNG_BASE_URL`: Set to your search domain (e.g., `https://search.benthem.es/`)
- Custom `settings.yml` for search engine configuration
- Optional: custom logo (`searxng.png`)

---

### Vaultwarden
**Description:** Unofficial Bitwarden server implementation.
**Purpose:** Self-hosted password manager with sync capabilities.
**Port:** 8100 (mapped to container 80)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/vaultwarden/docker-compose.yml)

**Key Features:**
- Full Bitwarden compatibility
- Web vault, browser extensions, mobile apps
- Organization and sharing support
- Push notifications via Bitwarden EU relay

**Environment:**
- `PUSH_ENABLED=true` — enables push notifications
- `PUSH_RELAY_URI` / `PUSH_IDENTITY_URI` — Bitwarden EU relay servers
- `ADMIN_TOKEN` — optional, enables admin panel
- `SIGNUPS_ALLOWED` — set to `false` to disable public signups

---

### Pi-Hole + Unbound
**Description:** Secondary DNS sinkhole with recursive DNS resolver.
**Purpose:** Backup DNS server synced with primary Pi-Hole on Raspberry Pi, with Unbound for DNS resolution.
**Port:** 53 (DNS), 83 (web UI), 5443 (HTTPS), 5335 (Unbound)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/pihole/docker-compose.yml)

**Key Features:**
- DHCP server capability
- Custom blocklists
- Query logging and statistics
- Gravity sync with primary Pi-Hole (via Nebula Sync)
- Unbound provides DNSSEC validation and recursive resolution

**Environment:**
- `PIHOLE_DNS_=unbound#53` — uses Unbound as upstream DNS
- `DNSMASQ_LISTENING=all` — listen on all interfaces
- `WEBPASSWORD` — admin password (see `secrets.example.env`)

**Replication:** Pi-Hole configs are synced across all 3 nodes (PiNet1, Bentomo-NET, PiNet2) via Nebula Sync.

---

### Uptime Kuma
**Description:** Self-hosted monitoring tool.
**Purpose:** Monitor service uptime and receive alerts.
**Port:** 3001
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/uptime-kuma/docker-compose.yml)

**Key Features:**
- HTTP/HTTPS/TCP/Ping monitoring
- Email, Discord, Telegram notifications
- Docker container monitoring
- Status pages with custom domains

---

### Beszel System Monitor
**Description:** Lightweight system monitoring hub.
**Purpose:** Monitor server resources and performance across all nodes.
**Port:** 8050 (mapped to container 8090)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/beszel/docker-compose.yml)

**Key Features:**
- CPU, memory, disk monitoring
- Network statistics
- Historical data
- Agent-based architecture (agents run on each node)

**Note:** `USER_CREATION=true` should be set to `false` after initial setup.

---

### Speedtest Tracker
**Description:** Automated internet speed testing.
**Purpose:** Monitor internet connection performance over time.
**Port:** 8085 (HTTP), 8443 (HTTPS)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/speedtest-tracker/docker-compose.yml)

**Key Features:**
- Scheduled speed tests (hourly by default)
- Historical graphs
- Ookla Speedtest integration
- Notifications for degraded speeds

---

### Cloudflare DDNS
**Description:** Dynamic DNS updater for Cloudflare.
**Purpose:** Keep Cloudflare DNS records updated with public IP changes.
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/cloudflare-ddns/docker-compose.yml)

**Key Features:**
- IPv4 and IPv6 support
- Multiple domain support
- Proxied/unproxied record toggle
- API token authentication

---

### IT Tools
**Description:** Collection of handy online utilities for IT professionals.
**Purpose:** Quick access to converters, encoders, network tools, etc.
**Port:** 8090 (mapped to container 80)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/it-tools/docker-compose.yml)

**Key Features:**
- Base64 encode/decode
- JSON formatter
- Hash generators
- Network calculators
- Regex testers

---

### Theme Park
**Description:** Custom themes and skins for applications.
**Purpose:** Unified theme management for supported apps.
**Port:** 8082 (HTTP), 4443 (HTTPS)
**Configuration:** [docker-compose.yml](../docker-compose/ubuntu-server-1/themepark/docker-compose.yml)

**Key Features:**
- Multiple theme options
- CSS injection for supported apps
- Dark mode support
- Easy theme switching

---

## Common Configuration

### Environment Variables

Copy `secrets.example.env` to `.env` and fill in your actual values:

```bash
cp secrets.example.env .env
# Edit .env with your real passwords and tokens
# NEVER commit .env to version control
```

See [secrets.example.env](../docker-compose/ubuntu-server-1/secrets.example.env) for the full template.

### Starting Services

```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/ubuntu-server-1

# Start all services
for dir in */; do
  (cd "$dir" && docker compose up -d)
done

# Or individually
docker compose -f nginx-proxy-manager/docker-compose.yml up -d
docker compose -f pihole/docker-compose.yml up -d
```

---

## Port Reference

> ⚠️ **Note:** The ports listed below reflect the **actual running configuration**. Previous documentation had incorrect port assignments.

| Service | Host Port | Container Port | Notes |
|---------|-----------|-----------------|-------|
| NPM | 80/81/443 | 80/81/443 | Also proxies 25565-25566, 19132 |
| Homer | 8080 | 8080 | |
| SearXNG | 8070 | 8080 | |
| Vaultwarden | 8100 | 80 | |
| Pi-Hole DNS | 53 | 53 | TCP+UDP |
| Pi-Hole Web | 83 | 80 | |
| Pi-Hole HTTPS | 5443 | 443 | |
| Unbound | 5335 | 53 | TCP+UDP |
| Uptime Kuma | 3001 | 3001 | |
| Beszel | 8050 | 8090 | |
| Speedtest Tracker | 8085/8443 | 80/443 | |
| IT Tools | 8090 | 80 | |
| Theme Park | 8082/4443 | 80/443 | |
| Grafana | 3005 | 3000 | |
| Prometheus | 9090 | 9090 | |
| GoAccess | 7889/7890 | 7889/80 | |
| OpenSpeedTest | 3000/3011 | 3000/3001 | |
| NUT WebGUI | 9000 | 9000 | |
| PeaNUT | 9001 | 8080 | |
| LinkStack | 8190/8191 | 443 | alex + hugo instances |
| Portainer | 8000/9443 | 8000/9443 | |

---

## Backup Considerations

**Critical Data:**
- NPM data + Let's Encrypt certs (`./nginx-proxy-manager-data/`)
- Vaultwarden data (`./vaultwarden/data/`)
- Pi-Hole configuration (`./pihole/etc-pihole/`, `./pihole/etc-dnsmasq.d/`)
- Uptime Kuma data (`./uptime-kuma-data/`)
- Homer dashboard config (`./homer/assets/`)
- Beszel monitoring data (`./beszel_data/`)

---

## Troubleshooting

### Services Not Accessible
1. Check Nginx Proxy Manager proxy host configuration
2. Verify service is running: `docker compose ps`
3. Check logs: `docker compose logs -f`
4. Test internal access: `curl http://localhost:PORT`

### SSL Certificate Issues
1. Verify DNS points to server
2. Check firewall allows port 80 for ACME challenge
3. Review NPM logs for Let's Encrypt errors
4. Try DNS challenge if HTTP fails

### High Availability Failover
1. Check Keepalived status: `sudo systemctl status keepalived`
2. Verify VRRP communication: `sudo tcpdump -i ens33 vrrp`
3. Check VIP assignment: `ip a show ens33`
4. Review logs: `sudo journalctl -u keepalived`