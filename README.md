# **COMPLETE AI MEDIA CENTER HOME LAB**

![BOLEX-Intro image](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/intro-color.png)

<p align="center">
  <a href="#services-overview"><img src="https://img.shields.io/badge/Services-35+-blue" alt="Services"></a>
  <a href="#hardware-specs"><img src="https://img.shields.io/badge/Hardware-Ryzen_9_5900X-green" alt="Hardware"></a>
  <a href="#architecture-overview"><img src="https://img.shields.io/badge/GPU-RTX_4060ti_16GB-orange" alt="GPU"></a>
  <a href="docs/high-availability.md"><img src="https://img.shields.io/badge/HA-Keepalived-red" alt="High Availability"></a>
</p>

## Table of Contents

- [Introduction](#introduction-and-overview)
- [Disclaimer](#disclaimer)
- [Hardware Specs](#hardware-specs)
- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Services Overview](#services-overview)
  - [Raspberry Pi Services](#1-raspberry-pi-services)
  - [Ubuntu Server 1 Services](#2-ubuntu-server-1-services)
  - [Ubuntu Server 2 Services](#3-ubuntu-server-2-services)
  - [WSL2 Services](#4-wsl2-docker-desktop-services)
  - [Oracle Cloud Services](#5-oracle-cloud-services)
  - [Common Services](#6-common-services)
- [Quick Start](#quick-start)
- [Architecture Diagram](#architecture-diagram)
- [Backup Strategy](#backup-strategy)

---

## Introduction and Overview

I would like to provide an overview on how I have deployed and manage my homelab services in my main server.

Contrary to everyone's home server I am running it completely different and for very specific reasons.

My project began back in 2009 with Windows Media Center, then it progressed to XBMC, then Kodi, then `PLEX` and from there on... with many hardware updates, it became my cloud instance, my photo library, my AI GPT, my DNS server, my VPN client, my password manager, etc...

The ultimate goal is with a modest spec-like server and a couple of Raspberry Pi's, to have a complete professional setup that can handle all my needs.

---

## Disclaimer

This project is provided "as is" without warranty of any kind, express or implied. Use at your own risk. The author is not liable for any damages or losses resulting from the use of this project. 

It is imperative to note that you need to have some pre-knowledge regarding docker, docker compose, containers and how they operate. This guide has been designed for my own personal usage and is not intended as a full guide for beginners.

---

## Hardware Specs

### Complementary Servers 🤖
- **Main Router:** Intel i3 N355 with 32GB RAM and 2x 1TB M2 SSD. Running [Proxmox](https://www.proxmox.com/en/) and [OPNSense](https://opnsense.org/) Firewall.
- **Main Raspberry Pi 4:** 2GB RAM running [Wireguard with PiVPN](https://www.pivpn.io/) and [PiHole](https://pi-hole.net/) as well as serving as backup Search engine ([SearXNG](https://github.com/searxng/searxng)) and Password Vault ([Vaultwarden](https://github.com/dani-garcia/vaultwarden)).
- **Secondary Raspberry Pi 4:** Same specs (weekly SD Card backups).
  
Both running in a [GeekPi Cluster Case](https://www.amazon.com/GeeekPi-Raspberry-Cluster-Cooling-Heatsink/dp/B07MW3GM1T?th=1)  

### Main Server 🖥️
- **CPU:** AMD Ryzen 9 5900X
- **RAM:** 64 GB DDR4
- **GPU:** NVIDIA RTX 4060ti 16GB VRAM
- **Storage:**
  - 2 TB M.2 NVMe Drive (Windows 11 - OS)
  - 1 TB M.2 NVMe Drive (Virtual Machines)
  - 1 TB M.2 NVMe Drive (NextCloud VM)
  - 1 TB SSD (Windows Server 2025 VM)
  - 3x 12TB HDD in Parity Storage Space (Main Media Drive)
  - 3x 3TB HDD in Parity Storage Space (Backup Drive)
- **Other:** Bluray RE drive (legacy), 2x 2.5Gb Ethernet adapters

### Additional Hardware
- **Firewall:** [CWWK Intel i3 N355](https://cwwk.net/products/12th-gen-intel-firewall-mini-pc-alder-lake-i3-n305-8-core-n200-n100-fanless-soft-router-proxmox-ddr5-4800mhz-4xi226-v-2-5g), 4x 2.5G Ethernet, Fanless
- **Switch:** [AMPCOM 2.5GbE Managed Switch](https://www.ampcom.hk/products/ampcom-2-5gbe-managed-switch-8-port-2-5gbase-t-network-switcher-10g-sfp-slot-uplink-web-management-qos-vlan-lacp-fanless)
- **WiFi:** [Xiaomi Mesh System AX3000](https://www.mi.com/global/product/xiaomi-mesh-system-ax3000/) (configured as Access Point)
- **KVM:** [JetKVM](https://jetkvm.com/) Remote Controller
- **UPS 1:** [CyberPower VP1000ELCD](https://www.cyberpower.com/eu/en/product/sku/vp1000elcd) - Networking devices and Raspberry Pi's (~40 min runtime)
- **UPS 2:** [Schneider Electric APC Back-UPS 1200VA](https://www.se.com/il/en/product/BX1200MI-GR/apc-backups-1200va-230v-avr-schuko-sockets/) - Main server (~10 min runtime)

### Power Consumption
- **Network Equipment:** 50-60W average (Routers, Raspberry Pis, Switch, KVM, external HD)
- **Main Server Idle:** 150-160W (up to 350W under GPU load)
- **Total Average:** 200-220W when semi-idle

### Oracle Cloud VMs
The configuration is supported by 2 additional cloud instances to ensure Zero Trust access to on-prem services.

- **Instance 1:** 2 Cores + 16GB RAM ([VM.Standard.A1.Flex](https://cloud.oracle.com) - Ampere Altra processor) running Ubuntu Server
- **Instance 2:** 2 Cores + 8GB RAM ([VM.Standard.A1.Flex](https://cloud.oracle.com) - Ampere Altra processor) running Ubuntu Server

---

## Architecture Overview

The homelab is organized into distinct layers, each serving specific purposes:

| Layer | Platform | Purpose |
|-------|----------|---------|
| **Main OS** | Windows 11 | Office work via RDP (DUO security), Hypervisor role |
| **Hyper-V** | Windows Server 2025 VM | Torrent downloads, external VPN connections |
| **VMware** | 3 Ubuntu Servers | Web services, reverse proxy, applications |
| **WSL2** | Docker Desktop | AI/ML workloads (GPU-accelerated) |
| **Proxmox** | Intel N355 | OPNSense firewall, LXC containers |
| **Oracle Cloud** | 2x Ubuntu VMs | Zero Trust access, security services |
| **Raspberry Pi** | Raspberry Pi OS | DNS, VPN, backup services |

---

## Repository Structure

```
Complete-AI-Media-Center-Home-Lab/
├── 📁 docs/
│   ├── 📁 docker-compose/
│   │   ├── 📁 raspberry-pi/          # Raspberry Pi Docker services
│   │   ├── 📁 ubuntu-server-1/     # Main web services
│   │   ├── 📁 ubuntu-server-2/     # Apps & storage
│   │   ├── 📁 wsl2-docker-desktop/ # AI/ML services (✅ Complete)
│   │   │   ├── ollama/
│   │   │   ├── open-webui/
│   │   │   ├── litellm/
│   │   │   ├── postgres/
│   │   │   ├── immich/
│   │   │   ├── n8n/
│   │   │   ├── qdrant/
│   │   │   ├── tika/
│   │   │   ├── libretranslate/
│   │   │   └── metube/
│   │   └── 📁 oracle-cloud/        # Cloud security services
│   ├── 📁 installation/
│   │   ├── raspberry-pi-services.md    # Pi setup guide
│   │   ├── ubuntu-server-1-services.md   # Main server guide
│   │   ├── ubuntu-server-2-services.md   # Storage server guide
│   │   ├── wsl2-services.md          # AI services guide (✅ Complete)
│   │   └── oracle-cloud-services.md  # Cloud services guide
│   └── high-availability.md        # Keepalived HA setup
├── 📁 images/                        # Architecture diagrams
├── README.md                         # This file
└── PROGRESS.md                       # Implementation status
```

---

## Services Overview

### 1. Raspberry Pi Services

📄 **Full Guide:** [raspberry-pi-services.md](docs/installation/raspberry-pi-services.md)

**Bare-metal Services:**
- [Pi-Hole](docs/installation/raspberry-pi-services.md#pi-hole) - DNS sinkhole, ad blocker, DHCP server
- [PiVPN](docs/installation/raspberry-pi-services.md#pivpn) - WireGuard VPN server
- [Keepalived](docs/high-availability.md) - High availability failover
- Rpi Monitor - System monitoring

**Docker Services:**
- [Cloudflare DDNS](docs/installation/raspberry-pi-services.md#cloudflare-ddns) - Dynamic DNS updater
- Nginx Proxy Manager - Reverse proxy (backup)
- SearXNG - Metasearch engine (backup)
- Vaultwarden - Password manager (backup)
- Homer Dashboard - Service homepage (backup)

---

### 2. Ubuntu Server 1 Services

📄 **Full Guide:** [ubuntu-server-1-services.md](docs/installation/ubuntu-server-1-services.md)

| Service | Purpose | Port | Status |
|---------|---------|------|--------|
| Keepalived | HA failover (VRRP1 Master) | - | ✅ Config |
| Nginx Proxy Manager | Main reverse proxy | 81 | ⏳ Compose |
| Homer Dashboard | Service homepage | 8080 | ⏳ Compose |
| SearXNG | Metasearch engine | 8082 | ⏳ Compose |
| Vaultwarden | Password manager | 8083 | ⏳ Compose |
| PiHole (Secondary) | DNS backup | 8084 | ⏳ Compose |
| Uptime Kuma | Service monitoring | 3001 | ✅ Compose |
| Beszel | System monitoring | 8090 | ✅ Compose |
| Speedtest Tracker | Internet performance | 8765 | ⏳ Compose |
| Cloudflare DDNS | Public IP updater | - | ✅ Compose |
| IT Tools | IT utilities | 8085 | ⏳ Compose |
| Themepark | App theming | 8086 | ⏳ Compose |
| Guacamole | Remote desktop gateway | 8087 | ⏳ Compose |

---

### 3. Ubuntu Server 2 Services

📄 **Full Guide:** [ubuntu-server-2-services.md](docs/installation/ubuntu-server-2-services.md)

| Service | Purpose | Port | Status |
|---------|---------|------|--------|
| NextCloud | Personal cloud storage | 8080 | ⏳ Compose |
| Crafty Controller | Minecraft server management | 8443 | ⏳ Compose |
| Stirling PDF | PDF manipulation tools | 8081 | ⏳ Compose |

---

### 4. WSL2 Docker Desktop Services

📄 **Full Guide:** [wsl2-services.md](docs/installation/wsl2-services.md)

**✅ All Docker Compose files complete and sanitized**

| Service | Purpose | Port | GPU |
|---------|---------|------|-----|
| [Ollama](docs/docker-compose/wsl2-docker-desktop/ollama/docker-compose.yml) | Local LLM inference | 11434 | ✅ |
| [Open WebUI](docs/docker-compose/wsl2-docker-desktop/open-webui/docker-compose.yml) | Chat interface for AI | 4000 | - |
| [LiteLLM](docs/docker-compose/wsl2-docker-desktop/litellm/docker-compose.yml) | Multi-LLM proxy | 4001 | - |
| [Postgres](docs/docker-compose/wsl2-docker-desktop/postgres/docker-compose.yml) | Database server | 5432 | - |
| [Immich](docs/docker-compose/wsl2-docker-desktop/immich/docker-compose.yml) | Photo & video management | 2283 | ✅ |
| [N8N](docs/docker-compose/wsl2-docker-desktop/n8n/docker-compose.yml) | Workflow automation | 5678 | - |
| [Qdrant](docs/docker-compose/wsl2-docker-desktop/qdrant/docker-compose.yml) | Vector database | 6333 | - |
| [Apache Tika](docs/docker-compose/wsl2-docker-desktop/tika/docker-compose.yml) | Document parser | 9998 | - |
| [LibreTranslate](docs/docker-compose/wsl2-docker-desktop/libretranslate/docker-compose.yml) | Translation service | 5000 | ✅ |
| [MeTube](docs/docker-compose/wsl2-docker-desktop/metube/docker-compose.yml) | YouTube downloader | 8081 | - |

**Configuration Files:**
- [Environment Variables Template](docs/docker-compose/wsl2-docker-desktop/ENVIRONMENT_VARIABLES.md)
- [Configuration Files Guide](docs/docker-compose/wsl2-docker-desktop/CONFIGURATION_FILES.md)
- [Docker Compose Templates](docs/docker-compose/TEMPLATE_REFERENCE.md)

---

### 5. Oracle Cloud Services

📄 **Full Guide:** [oracle-cloud-services.md](docs/installation/oracle-cloud-services.md)

- **PiHole** - Public DNS (via Pangolin)
- **PiVPN** - Cloud VPN endpoint
- **SearXNG** - Public search engine
- **Pangolin** - Zero Trust access platform
- **CrowdSec** - Collaborative intrusion detection

---

### 6. Common Services

Services running on multiple/all machines:

- **Portainer** - Docker management UI (All Servers)
- **Redis** - In-memory database (WSL2, Immich)
- **Watchtower** - Automatic container updates (All Servers)

---

## Quick Start

### Prerequisites

1. **Docker & Docker Compose** installed on all target machines
2. **WSL2** with Docker Desktop (for AI services)
3. **NVIDIA GPU** with Container Toolkit (for GPU-accelerated services)
4. **Shared Docker network** created:
   ```bash
   docker network create bolex-net
   ```

### Starting Services

**WSL2 Services (AI/ML):**
```bash
cd docs/docker-compose/wsl2-docker-desktop

# Start all AI services
docker-compose -f postgres/docker-compose.yml up -d
docker-compose -f ollama/docker-compose.yml up -d
docker-compose -f litellm/docker-compose.yml up -d
docker-compose -f open-webui/docker-compose.yml up -d
# ... etc
```

**Other Servers:**
See individual [installation guides](docs/installation/) for server-specific instructions.

### Environment Setup

1. Copy environment templates:
   ```bash
   cp docs/docker-compose/wsl2-docker-desktop/ENVIRONMENT_VARIABLES.md ~/bolex-ai/.env.template
   ```

2. Edit `.env` files with your credentials (never commit these!)

3. Generate secure keys:
   ```bash
   openssl rand -hex 32
   ```

---

## Architecture Diagram

High level architecture:
![BOLEX-NET](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/Bolex-NET.png)

Detailed network infrastructure:
![BOLEX-NETWORK](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/BentomoNET-2025.png)

---

## Backup Strategy

### Critical Data to Backup

**WSL2 (AI/ML):**
- `./ollama_data` - Downloaded LLM models
- `./postgres_storage` - N8N and LiteLLM databases
- `./n8n_storage` - Workflow configurations
- `./open-webui-data` - Chat history and settings
- `./qdrant_data` - Vector embeddings
- Immich upload directories

**Ubuntu Server 1 (Web):**
- Nginx Proxy Manager configs and SSL certs
- Vaultwarden encrypted vaults
- PiHole DNS configuration
- Uptime Kuma monitoring history

**Raspberry Pi:**
- Weekly SD card images (via `dd`)
- Gravity sync for PiHole lists

### Automated Backup Script

```bash
#!/bin/bash
# Add to crontab for automated backups
BACKUP_DIR="/path/to/backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Stop containers gracefully
docker-compose down

# Backup data directories
tar czf "$BACKUP_DIR/ollama.tar.gz" ./ollama_data
# ... etc

# Restart services
docker-compose up -d
```

---

## Implementation Status

See [PROGRESS.md](PROGRESS.md) for detailed implementation status and remaining tasks.

| Component | Status | Complete |
|-----------|--------|----------|
| WSL2 Docker Compose | ✅ Done | 10/10 |
| WSL2 Documentation | ✅ Done | Complete |
| Ubuntu Server 1 Docs | ✅ Done | Complete |
| Ubuntu Server 2 Docs | ✅ Done | Complete |
| Oracle Cloud Docs | ✅ Done | Complete |
| Other Docker Compose | ⏳ Pending | 4/22 |
| Raspberry Pi Docker Docs | ⏳ Pending | Partial |

---

## Contributing

This is a personal homelab documentation project. Feel free to:
- Fork and adapt for your own setup
- Submit issues for errors or improvements
- Share your own configurations

**Important:** Never commit actual credentials, API keys, or passwords. Use environment variables and reference the templates provided.

---

<p align="center">
  <i>Built with passion for self-hosting and privacy</i>
</p>
