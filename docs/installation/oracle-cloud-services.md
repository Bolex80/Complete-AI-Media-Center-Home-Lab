# Oracle Cloud Services

Two Oracle Cloud ARM64 (aarch64) VPS instances providing public-facing infrastructure.

---

## Bolex-Cloud-1 — 79.72.49.182

**Purpose:** Web project hosting + infrastructure services
**Architecture:** ARM64 (aarch64)
**OS:** Ubuntu
**RAM:** 15 GB
**User:** alex

### Services Overview

| # | Service | Port | Domain | Compose |
|---|---------|------|--------|---------|
| 1 | Nginx Proxy Manager | 80/81/443 | nginx.benthem.es (admin) | Local only |
| 2 | Benthem Website | 8880 | benthem.es, www.benthem.es | [Link](../docker-compose/bolex-cloud-1/benthem-website/docker-compose.yml) |
| 3 | Gastos Bentomo | 8885 | gastos.bentomo.es | [Link](../docker-compose/bolex-cloud-1/gastos-bentomo/docker-compose.yml) |
| 4 | Sonemos Juntos | 8888 | soñemosjuntos.com, sonemosjuntos.es | [Link](../docker-compose/bolex-cloud-1/sonemosjuntos/docker-compose.yml) |
| 5 | Husoma Web | 8882 | husoma.com, www.husoma.com | [Link](../docker-compose/bolex-cloud-1/husoma-web/docker-compose.yml) |
| 6 | Stirling PDF | 8090 | — | [Link](../docker-compose/bolex-cloud-1/stirling-pdf/docker-compose.yml) |
| 7 | Bentomo Shopping | 3000 | — | [Link](../docker-compose/bolex-cloud-1/bentomo-shopping/docker-compose.yml) |
| 8 | GoAccess | 7880 | go.benthem.es | [Link](../docker-compose/bolex-cloud-1/goaccess/docker-compose.yml) |
| 9 | SearXNG | 8070 | — | Local only |

### Infrastructure Agents

| Service | Port | Notes |
|---------|------|-------|
| Newt | 2112 | Pangolin tunnel agent |
| Hawser | 2376 | Docker TLS proxy → Dockhand on Nextcloud server |
| Valkey | 6379 | Redis-compatible cache for gastos/SearXNG |

### Reverse Proxy Architecture

All 4 web projects route through **Pangolin** on Bolex-Cloud-2 (Zero Trust reverse proxy):

```
Internet → Pangolin (Bolex-Cloud-2) → Gerbil → Traefik
  → benthem.es      → Bolex-Cloud-1:8880
  → gastos.bentomo.es → Bolex-Cloud-1:8885
  → sonemosjuntos.es  → Bolex-Cloud-1:8888
  → husoma.com       → Bolex-Cloud-1:8882
```

NPM on Bolex-Cloud-1 handles local SSL termination and some direct routes (GoAccess, CrowdSec UI).

### Service Details

**Stirling PDF ("Benthem PDF"):**
Custom-branded PDF tool with Spanish locale, no login required. Uses `stirling-pdf:latest-fat` for full feature set (LibreOffice, OCR). Java heap: 2GB-10GB.

**Bentomo Shopping:**
Shopping list app (formerly Koffan). Supports list sharing, offline mode, and PWA install. Auth enabled with configurable max attempts (`LOGIN_MAX_ATTEMPTS=5`).

**GoAccess:**
Real-time log analytics paired with NPM. Reads NPM proxy logs for traffic visualization.

---

## Bolex-Cloud-2 — 130.110.233.63

**Purpose:** Zero Trust reverse proxy + security monitoring
**Architecture:** ARM64 (aarch64)
**OS:** Ubuntu
**User:** alex

### Services Overview

| # | Service | Port | Compose |
|---|---------|------|---------|
| 1 | Pangolin | — | [Link](../docker-compose/oracle-cloud/pangolin/docker-compose.yml) |
| 2 | Gerbil (Pangolin tunnel) | 80/443/6060/8080/51820/21820/25565/19132 | Included in Pangolin compose |
| 3 | Traefik | — | [Link](../docker-compose/oracle-cloud/traefik/docker-compose.yml) |
| 4 | CrowdSec | — | [Link](../docker-compose/oracle-cloud/crowdsec/docker-compose.yml) |
| 5 | GeoIP Update | — | Managed by Pangolin config |

### Infrastructure

| Service | Port | Notes |
|---------|------|-------|
| Hawser | 2376 | Docker TLS proxy → Dockhand |

### Reverse Proxy Chain

```
Client Request
    ↓
Pangolin (Zero Trust Auth + Route Matching)
    ↓
Gerbil (WireGuard Tunnel + Port Exposure)
    ↓
Traefik (TLS Termination + HTTP Routing)
    ↓
Upstream Service (on Bolex-Cloud-1)
```

**Pangolin** handles:
- Zero Trust authentication
- Route matching (domain → upstream)
- WireGuard tunnel management

**Gerbil** handles:
- Port exposure (80, 443, 51820/udp for WireGuard)
- Tunnel relaying

**Traefik** handles:
- TLS termination with Let's Encrypt
- HTTP routing to backends
- Access logging (fed to CrowdSec)

**CrowdSec** handles:
- Log analysis from Traefik
- Threat intelligence sharing
- `crowdsecurity/traefik` collection

**GeoIP Update:**
Downloads MaxMind GeoLite2 databases (Country + ASN) every 72 hours for Traefik geolocation.

---

## SSH Access

```bash
# Bolex-Cloud-1
ssh -i ~/.ssh/Bolex-Cloud-1-Private-2025-12-09.key alex@79.72.49.182

# Bolex-Cloud-2
ssh -i ~/.ssh/Bolex-Cloud-2-Private.key alex@130.110.233.63
```

---

## Common Configuration

### Starting Services

**Bolex-Cloud-1:**
```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/bolex-cloud-1
for dir in */; do
  (cd "$dir" && docker compose up -d)
done
```

**Bolex-Cloud-2:**
```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/oracle-cloud
# Start Pangolin first (includes Gerbil)
docker compose -f pangolin/docker-compose.yml up -d
# Then Traefik and CrowdSec
docker compose -f traefik/docker-compose.yml up -d
docker compose -f crowdsec/docker-compose.yml up -d
```