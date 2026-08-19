# Raspberry Pi Services

Both Raspberry Pi nodes (PiNet1 and PiNet2) run an identical Docker stack for HA failover via Keepalived. PiNet1 is the **VRRP2 Master** (DNS/VPN) and **VRRP1 Backup** (HTTP/HTTPS). PiNet2 is the **VRRP2 Backup** (DNS/VPN).

## Hardware Configuration

- **PiNet1:** 192.168.2.200 (VRRP2 Master — DNS/VPN)
- **PiNet2:** 192.168.2.205 (VRRP2 Backup — DNS/VPN)
- **Architecture:** ARM64 (aarch64) — Raspberry Pi 4
- **RAM:** 1.8 GB each
- **Storage:** 64 GB SSD (external)
- **Virtual IPs:** 192.168.2.3 (HTTP/HTTPS), 192.168.2.4 (DNS/VPN)

> ⚠️ **RAM Warning:** Both Pis run near capacity (~1.8 GB). Monitor carefully when adding services.

## Bare-Metal Services (PiNet1 only)

### Pi-Hole (Primary DNS)
**Description:** DNS sinkhole and ad blocker running directly on PiNet1 (not in Docker).
**Port:** 53 (DNS), 80 (web UI)
**Version:** v6.4.1 (Core), v6.5 (Web), v6.6 (FTL)

```bash
curl -sSL https://install.pi-hole.net | bash
```

**Configuration:**
- Acts as DHCP server for the network
- Syncs configuration to PiNet2 and Bentomo_NET via Nebula Sync
- Uses Unbound (on Bentomo_NET, port 5335) as upstream DNS resolver

### PiVPN (WireGuard)
**Description:** WireGuard VPN server running on PiNet1.
**Interface:** `wg0` — `10.179.38.1/24`
**Configuration:** Managed via `pivpn` CLI tool.

```bash
curl -L https://install.pivpn.io | bash
```

### Keepalived
**Description:** High availability via VRRP.
**Configuration:** See [high-availability.md](../../high-availability.md)

> ⚠️ **Security:** Keepalived auth passwords use env vars — see `secrets.example.env`.

**PiNet1 roles:**
- VRRP1 (HTTP/HTTPS): **BACKUP** (192.168.2.3)
- VRRP2 (DNS/VPN): **MASTER** (192.168.2.4)

**PiNet2 roles:**
- VRRP2 (DNS/VPN): **BACKUP** (192.168.2.4)

---

## Docker Services

Both PiNet1 and PiNet2 run the **same Docker stack** for failover. If PiNet1 goes down, PiNet2 takes over DNS/VPN via Keepalived, and Bentomo_NET takes over HTTP/HTTPS.

| # | Service | Port (PiNet1) | Port (PiNet2) | Compose |
|---|---------|----------------|----------------|---------|
| 1 | Nginx Proxy Manager | 80/81/443 | 80/81/443 | [Link](../docker-compose/raspberry-pi/nginx-proxy-manager/docker-compose.yml) |
| 2 | SearXNG | 8070 | 8070 | [Link](../docker-compose/raspberry-pi/searxng/docker-compose.yml) |
| 3 | Vaultwarden | 8100 | 8100 | [Link](../docker-compose/raspberry-pi/vaultwarden/docker-compose.yml) |
| 4 | Homer Dashboard | 8081 | 8081 | [Link](../docker-compose/raspberry-pi/homer-dashboard/docker-compose.yml) |
| 5 | Cloudflare DDNS | — | — | [Link](../docker-compose/raspberry-pi/cloudflare-ddns/docker-compose.yml) |
| 6 | Beszel Agent | — | — | [Link](../docker-compose/raspberry-pi/beszel/docker-compose.yml) |
| 7 | WatchTower | — | — | [Link](../docker-compose/raspberry-pi/watchtower/docker-compose.yml) |
| 8 | WatchYourLAN | 8840 | 8840 | [Link](../docker-compose/raspberry-pi/watchyourlan/docker-compose.yml) |

### Infrastructure Agents (not in compose files — managed by Pangolin/Dockhand)

| Service | Port | Notes |
|---------|------|-------|
| Newt | 2112 | Pangolin tunnel agent |
| Hawser | 2376 | Docker TLS proxy (connects to Dockhand on Nextcloud server) |

---

## Service Details

### Nginx Proxy Manager
**Description:** Reverse proxy with SSL certificate management. Runs on both Pis for HA failover.
**Port:** 80 (HTTP), 81 (admin), 443 (HTTPS)
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/nginx-proxy-manager/docker-compose.yml)

**Note:** `DISABLE_IPV6=true` is set in the running config.

### SearXNG
**Description:** Privacy-respecting metasearch engine. Paired with Valkey (Redis-compatible) for caching.
**Port:** 8070 (mapped to container 8080)
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/searxng/docker-compose.yml)

**Environment:**
- `SEARXNG_BASE_URL=https://search.benthem.es/`
- Valkey configured with `--save 30 1 --loglevel warning`
- Custom `settings.yml` for search engine configuration
- Optional: custom logo (`searxng.png`)

### Vaultwarden
**Description:** Self-hosted Bitwarden-compatible password manager.
**Port:** 8100 (mapped to container 80)
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/vaultwarden/docker-compose.yml)

**Environment:**
- `DOMAIN=https://pass.benthem.es`
- Push notifications optional (uncomment in compose)

### Homer Dashboard
**Description:** Static homelab landing page.
**Port:** 8081 (mapped to container 8080)
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/homer-dashboard/docker-compose.yml)

> **Note:** PiNet1 uses port 8081 (not 8080) to avoid conflict with SearXNG's mapped port on the same host.

### Cloudflare DDNS
**Description:** Dynamic DNS updater for Cloudflare. Runs in host network mode for IPv6 support.
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/cloudflare-ddns/docker-compose.yml)

**Security hardening (already applied):**
- `network_mode: host` for IPv6 support
- `read_only: true` — read-only filesystem
- `cap_drop: [all]` — all Linux capabilities dropped
- `security_opt: [no-new-privileges:true]`

**PiNet1 domains:** `bentomo.es`, `bolex.es`

### Beszel Agent
**Description:** System metrics reporter — connects to Beszel hub on Bentomo_NET (port 8050).
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/beszel/docker-compose.yml)

**Note:** The `KEY` must match the SSH key generated during Beszel hub installation. Set `USER_CREATION=true` for initial setup, then change to `false`.

### WatchTower
**Description:** Automated container image updates with email notifications.
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/watchtower/docker-compose.yml)

**Schedule:** Every Thursday at 16:00 (Europe/Madrid time)

### WatchYourLAN
**Description:** Network device scanner and monitor with authentication (ForAuth).
**Port:** 8840 (WYL), 8800-8801 (ForAuth)
**Configuration:** [docker-compose.yml](../docker-compose/raspberry-pi/watchyourlan/docker-compose.yml)

**Note:** Change `HOST` and `FA_TARGET` for PiNet2 (use `192.168.2.205` instead of `192.168.2.200`). WYL uses `network_mode: host` for ARP scanning.

---

## Port Reference

| Service | Host Port | Container Port | Notes |
|---------|-----------|----------------|-------|
| NPM | 80/81/443 | 80/81/443 | |
| SearXNG | 8070 | 8080 | |
| Vaultwarden | 8100 | 80 | |
| Homer | 8081 | 8080 | Port 8081 to avoid SearXNG conflict |
| WatchYourLAN | 8840 | 8840 | host network mode |
| ForAuth | 8800-8801 | 8800-8801 | |
| Pi-Hole | 53 | 53 | TCP+UDP, bare-metal |
| Pi-Hole Web | 80 | 80 | bare-metal |
| WireGuard | 51820 | — | bare-metal (wg0: 10.179.38.1/24) |

---

## Common Configuration

### Environment Variables

Copy `secrets.example.env` to `.env` and fill in your actual values:

```bash
cp secrets.example.env .env
# Edit .env with your real passwords and tokens
# NEVER commit .env to version control
```

See [secrets.example.env](../docker-compose/raspberry-pi/secrets.example.env) for the full template.

### Starting Services

```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/raspberry-pi

# Start all services
for dir in */; do
  (cd "$dir" && docker compose up -d)
done

# Or individually
docker compose -f nginx-proxy-manager/docker-compose.yml up -d
docker compose -f searxng/docker-compose.yml up -d
```

---

## Deployment Notes

### PiNet2 Setup
PiNet2 runs the **exact same Docker stack** as PiNet1. To deploy:

1. Copy all compose directories to PiNet2
2. Change WatchYourLAN `HOST` and `FA_TARGET` from `192.168.2.200` to `192.168.2.205`
3. Ensure Homer, Vaultwarden, and SearXNG data is synced (they provide failover services)
4. Keepalived handles VIP failover automatically

### Data Synchronization
- **Pi-Hole:** Config replicated via Nebula Sync (runs on Bentomo_Net)
- **Vaultwarden:** Data should be backed up regularly; no active sync between Pis
- **SearXNG:** Settings can differ between nodes; each has its own Valkey cache
- **Homer:** Static dashboard — can be identical on both nodes