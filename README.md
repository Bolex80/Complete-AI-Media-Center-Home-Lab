# Complete AI Media Center Home Lab

![BOLEX-Intro image](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/intro-color.png)

<p align="center">
  <a href="CURRENT_ARCHITECTURE.md"><img src="https://img.shields.io/badge/Hosts-2%20Proxmox%20%2B%20VMs%20%2B%20Pi%20fleet-blue" alt="Hosts"></a>
  <a href="docs/current/services"><img src="https://img.shields.io/badge/Services-30%2B-green" alt="Services"></a>
  <a href="docs/historical/2025-windows-wsl-era"><img src="https://img.shields.io/badge/Historical-2025%20Windows%2FWSL%20stack-orange" alt="Historical"></a>
</p>

## What is this?

A personal, self-hosted home lab built around privacy, AI agents, and media. It began in 2009 with Windows Media Center, moved through XBMC, Kodi, and Plex, and has since grown into a multi-agent, multi-server platform that handles cloud storage, media management, DNS, VPN, password management, AI inference, and more.

In **2026 the stack underwent a major consolidation**: the Windows 11 + Hyper-V + VMware + WSL2 layer cake was replaced with **Proxmox VE + ZFS**, and the agent core moved from a Docker container on WSL2 to native systemd services on a dedicated VM.

| Document | Purpose |
|----------|---------|
| **[`CURRENT_ARCHITECTURE.md`](CURRENT_ARCHITECTURE.md)** | The present-day architecture: Proxmox, ZFS, LXCs, VMs, agents, Pangolin edge, and backups. |
| **[`EVOLUTION.md`](EVOLUTION.md)** | 2009 → 2026 story: why the lab was built, what changed, and why the 2026 migration happened. |
| **[`CHANGELOG.md`](CHANGELOG.md)** | Dated milestones and major changes. |
| **[`docs/current/`](docs/current/)** | Runbooks and service docs for the current stack. |
| **[`docs/historical/2025-windows-wsl-era/`](docs/historical/2025-windows-wsl-era/)** | Preserved snapshot of the old Windows/WSL/VMware design, including the original 52 compose files. |

## Quick status

| Layer | Current platform |
|-------|------------------|
| Edge / Zero Trust | Oracle Cloud `bolex-cloud` with Pangolin + Gerbil + Traefik + CrowdSec |
| Main hypervisor | Proxmox VE on `Bolex` (`.5`) with ZFS pools |
| Secondary hypervisor | Proxmox VE on `N355` (`.10`) with PBS |
| Agent core | `ai-agents` VM 105 (`.60`) — Hermes, Honcho, Wiki, Nesquena natively |
| GPU workloads | GPU VM (`.30`) — Ollama, Immich, Qdrant, n8n, Open WebUI |
| Media pipeline | Windows Server 2025 VM (`.25`) + event-driven promotion to Plex |
| Personal cloud | Nextcloud AIO VM 101 (`.70`) |
| DNS / VPN | PiNet1 (`.200`) / PiNet2 (`.205`) + OPNsense |

## Hardware Specs

The physical fleet behind the lab — currently racked in a TV-cabinet setup, pending a tidy re-housing.

### Complementary Servers 🤖
- **Router / Secondary hypervisor:** Intel i3 N355, 32GB RAM, 2× 1TB M.2 SSD — [Proxmox](https://www.proxmox.com/en/) VE + [OPNsense](https://opnsense.org/) firewall.
- **Main Raspberry Pi 4 (2GB):** [WireGuard + PiVPN](https://www.pivpn.io/), [Pi-hole](https://pi-hole.net/), backup [SearXNG](https://github.com/searxng/searxng), [Vaultwarden](https://github.com/dani-garcia/vaultwarden).
- **Secondary Raspberry Pi 4 (2GB):** same specs, weekly SD-card backups.

Both Pis live in a [GeekPi Cluster Case](https://www.amazon.com/GeeekPi-Raspberry-Cluster-Cooling-Heatsink/dp/B07MW3GM1T) (mini pi-rack).

### Main Server 🖥️
- **CPU:** AMD Ryzen 9 5900X
- **RAM:** 64 GB DDR4
- **GPU:** NVIDIA RTX 4060 Ti 16GB VRAM
- **Motherboard:** ASRock Taichi B550
- **Storage:**
  - 2 TB M.2 NVMe (Windows 11 / Proxmox host OS)
  - 1 TB M.2 NVMe (Virtual Machines)
  - 1 TB M.2 NVMe (NextCloud VM)
  - 1 TB SSD (Windows Server 2025 VM)
  - 3× 12TB HDD parity Storage Space (main media)
  - 3× 3TB HDD parity Storage Space (backup)
- **Other:** Blu-ray RE drive (legacy), 2× 2.5GbE adapters, silent-padding tower case.

### Additional Hardware
- **Firewall:** [CWWK Intel i3 N355](https://cwwk.net/products/12th-gen-intel-firewall-mini-pc-alder-lake-i3-n305-8-core-n200-n100-fanless-soft-router-proxmox-ddr5-4800mhz-4xi226-v-2-5g), 4× 2.5G Ethernet, fanless
- **Switch:** [AMPCOM 2.5GbE managed switch](https://www.ampcom.hk/products/ampcom-2-5gbe-managed-switch-8-port-2-5gbase-t-network-switcher-10g-sfp-slot-uplink-web-management-qos-vlan-lacp-fanless) (8-port + 10G SFP+)
- **WiFi:** [Xiaomi Mesh System AX3000](https://www.mi.com/global/product/xiaomi-mesh-system-ax3000/) (access-point mode)
- **KVM:** [JetKVM](https://jetkvm.com/) remote controller
- **Cooling:** 3× 14" USB power fans
- **UPS 1:** [CyberPower VP1000ELCD](https://www.cyberpower.com/eu/en/product/sku/vp1000elcd) — networking + Pis (~40 min)
- **UPS 2:** [Schneider Electric APC Back-UPS 1200VA](https://www.se.com/il/en/product/BX1200MI-GR/apc-backups-1200va-230v-avr-schuko-sockets/) — main server (~10 min)

### Power Consumption
- **Network equipment:** 50–60W average (routers, Pis, switch, KVM, external HD)
- **Main server idle:** 150–160W (up to 350W under GPU load)
- **Total average:** 200–220W semi-idle

## Living documentation

The detailed, day-to-day operational truth lives in the **Benthem LLM Wiki** at [https://wiki.benthem.es](https://wiki.benthem.es). This repository provides a stable public narrative, historical reference, and runbook snapshot.

## Contributing / Forking

This is a personal homelab. Feel free to fork and adapt for your own setup, but please keep credentials, API keys, and passwords out of any commits. Use environment variables and the templates provided in the historical section as a starting point.

---

<p align="center">
  <i>Built with passion for self-hosting and privacy</i>
</p>

---

## Network Diagrams

High level architecture:
![BOLEX-NET](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/Bolex-NET.png)

Detailed network infrastructure:
![BOLEX-NETWORK](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/BentomoNET-2025.png)

> The high-level diagram above reflects the **2026 Proxmox + ZFS + native agent** architecture. The legacy Windows/WSL/VMware-era diagram is preserved as [`Bolex-NET-legacy.png`](images/Bolex-NET-legacy.png).
