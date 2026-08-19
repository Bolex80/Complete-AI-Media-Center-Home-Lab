# Current Architecture

> This is the 2026 post-migration architecture. For the pre-2026 Windows/WSL/VMware design, see [`docs/historical/2025-windows-wsl-era/`](docs/historical/2025-windows-wsl-era/).

## Overview

The Benthem home lab is now a **Proxmox-first, ZFS-backed, LXC/VM-based** stack. The agent layer runs natively on a dedicated VM, and public traffic enters through a Pangolin Zero Trust gateway on Oracle Cloud.

```
Internet
   │
   ▼
┌─────────────────────────────────────────┐
│  Oracle Cloud: bolex-cloud (79.72.49.182) │
│  Pangolin + Gerbil + Traefik + CrowdSec   │
└─────────────────────────────────────────┘
   │ Gerbil WG tunnel
   ▼
┌─────────────────────────────────────────┐
│  LAN: 192.168.2.0/24                    │
│                                         │
│  Proxmox Bolex (.5)                     │
│   ├── VM 105  ai-agents (.60)           │
│   ├── VM 100  gpu-vm (.30)              │
│   ├── VM 101  nextcloud (.70)           │
│   ├── VM 102  Windows Server (.25)      │
│   └── LXCs: vaultwarden, searxng,        │
│       metube, seerr, wizarr, tautulli,  │
│       homer, onedrive-sync, ...         │
│                                         │
│  Proxmox N355 (.10)                     │
│   ├── PBS LXC 107 (.15)                 │
│   ├── NPMPlus (auth/guac/nginx/plex/    │
│       theme domains)                    │
│   └── utility LXCs                      │
│                                         │
│  Raspberry Pi fleet (.200, .205)          │
│   Pi-Hole v6, PiVPN, Vaultwarden backup  │
└─────────────────────────────────────────┘
```

## Host inventory

| Host | IP / ID | Role | OS / runtime |
|------|---------|------|--------------|
| **Bolex** | `192.168.2.5` | Main Proxmox host, ZFS pools, SMB | Proxmox VE |
| **N355** | `192.168.2.10` | Secondary Proxmox host, firewall proxmox, PBS | Proxmox VE |
| **ai-agents** | VM 105, `.60` | Agent gateway (Hermes, Honcho, Wiki, Nesquena, Bridge API, Direct Comm) | Ubuntu, native systemd |
| **gpu-vm** | VM 100, `.30` | AI/ML workloads with RTX 4060 Ti passthrough | Ubuntu, Docker |
| **nextcloud** | VM 101, `.70` | Nextcloud AIO + EuroOffice | Ubuntu, Docker |
| **Windows Server** | VM 102, `.25` | qBittorrent, VPN, *arr stack | Windows Server 2025 |

## ZFS pools on Bolex

| Pool | Layout | Role |
|------|--------|------|
| `tank-media` | 3 × 12 TB RAIDZ1 | Media, pictures, documents mirror |
| `tank-immich` | 2 × 1 TB mirror | Immich-managed library |
| `tank-fast` | 2 TB NVMe | VM/LXC disks, databases, fast documents |
| `tank-backup` | 3 × 3 TB RAIDZ1 | Backup target for all automated backups |

## Network services

| Service | Host | Notes |
|---------|------|-------|
| Pi-Hole v6 (primary) | PiNet1 `.200` | DNS sinkhole + DHCP |
| Pi-Hole v6 (backup) | PiNet2 `.205` | Nebula-sync replica |
| PiVPN / WireGuard | PiNet1 `.200` | Family VPN, UDP 51820 |
| OPNsense | N355 `.1` | Firewall / router |
| Keepalived VIPs | `.3` (HTTP), `.4` (DNS/VPN) | VRRP failover |

## Reverse proxy topology

Most public services route through **Pangolin** on `bolex-cloud`. A small subset is served directly by **NPMPlus** on N355:

| Domain | Proxy | Backend |
|--------|-------|---------|
| `wiki.benthem.es`, `nube.bentomo.es`, `pass.bentomo.es`, `search.benthem.es`, `stats.bolex.es`, ... | Pangolin | via Gerbil tunnel |
| `auth.bolex.es` | NPMPlus | `192.168.2.20:9091` |
| `guac.bolex.es` | NPMPlus | `192.168.2.11:8080` |
| `nginx.bolex.es` | NPMPlus | `192.168.2.100:81` |
| `plex.bolex.es` | NPMPlus | `192.168.2.30:32400` |
| `theme.bentomo.es` | NPMPlus | `192.168.2.48:4443` |

See [`docs/current/01-network-and-ip-plan.md`](docs/current/01-network-and-ip-plan.md) for the full address plan.

## Agent stack

All agents run natively on `ai-agents` VM 105 and share a single Honcho instance.

| Agent | Workspace | Role | Primary model |
|-------|-----------|------|---------------|
| **Hermes** | `hermes` | Orchestrator / main conversational interface | `deepseek-v4-flash:cloud` |
| **Clawdio** | `openclaw` | Executor / right-hand agent | `kimi-k2.7-code:cloud` |
| **Samantha** | `openclaw` | Coding / server management (relayed) | `glm-5.1:cloud` |
| **Emilio** | `openclaw` | Spanish legal/fiscal advisor | `deepseek-v4-flash:cloud` |
| **Junell** | `openclaw` | Personal assistant for Junell | `deepseek-v4-flash:cloud` |

Hermes model fallback chain: `deepseek-v4-flash:cloud` → `kimi-k2.7-code:cloud` → `gemma4:e4b-128k` (ollama-local on GPU VM).

## Backup strategy

13 automated backup jobs run daily/weekly across the fleet:

| # | System | Schedule | Target |
|---|--------|----------|--------|
| 1 | Bolex PVE VM/LXC backup | Daily 02:00 | `tank-backup/vm` |
| 2 | N355 PVE backup | Daily 21:00/23:00/02:00 | Local + PBS + `tank-backup/vm` |
| 3 | Immich library | Daily 03:00 + 03:45 | `tank-immich` → `tank-media` → `tank-backup` |
| 4 | Pictures (external library) | Daily 04:00 + real-time watcher | `tank-media/Pictures` → `tank-backup/Pictures` |
| 5 | tank-media/backup | Daily 04:30 | `tank-media/backup` → `tank-backup/backup` |
| 6 | Music | Daily 04:45 | `tank-media/multimedia/Music` → `tank-backup/music` |
| 7 | Documents | Daily 05:00 | `tank-fast/documents` → `tank-media` + `tank-backup` |
| 8 | Raspberry Pi Restic | Weekly Sun 02:00 | `tank-backup/restic` |
| 9 | Vaultwarden sync | Weekly Sun 00:30 | `tank-backup/Vaultwarden` + Pi replicas |
| 10 | ai-agents app backup | Daily 03:10 | `tank-backup/Agents-backup/AiAgents` |
| 11 | bolex-cloud offsite | Daily 03:40 | `tank-backup/bolex-cloud` |
| 12 | Pi Restic monitor | Weekly Sun 06:00 | Hermes cron |

For details see [`docs/current/10-backup-strategy.md`](docs/current/10-backup-strategy.md) and the [Benthem Wiki backup concept](https://wiki.benthem.es/concepts/backup-mechanisms).

## Where to find more

- Operational runbooks: [`docs/current/services/`](docs/current/services/)
- Network and IP plan: [`docs/current/01-network-and-ip-plan.md`](docs/current/01-network-and-ip-plan.md)
- Proxmox hosts: [`docs/current/02-proxmox-hosts.md`](docs/current/02-proxmox-hosts.md)
- ZFS pools: [`docs/current/03-zfs-pools.md`](docs/current/03-zfs-pools.md)
- GPU VM: [`docs/current/04-gpu-vm.md`](docs/current/04-gpu-vm.md)
- Agent host: [`docs/current/05-ai-agents-host.md`](docs/current/05-ai-agents-host.md)
- Media pipeline: [`docs/current/11-media-pipeline.md`](docs/current/11-media-pipeline.md)
- Living wiki: [https://wiki.benthem.es](https://wiki.benthem.es)
