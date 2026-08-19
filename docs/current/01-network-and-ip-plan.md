# Network and IP Plan

Canonical IP assignments for the Benthem LAN (`192.168.2.0/24`).

## Reserved / network infrastructure

| IP | Role |
|----|------|
| `192.168.2.1` | OPNsense router / firewall (N355) |
| `192.168.2.3` | Keepalived VIP — HTTP (NPMPlus `.100` → `.200` backup) |
| `192.168.2.4` | Keepalived VIP — DNS/VPN (`.200` → `.205`) |
| `192.168.2.5` | Bolex Proxmox host |
| `192.168.2.10` | N355 Proxmox host |

## VMs on Bolex

| IP / ID | Name | Role |
|-----------|------|------|
| VM 100 / `.30` | gpu-vm | RTX 4060 Ti passthrough — Ollama, Immich, Qdrant, n8n, Open WebUI |
| VM 101 / `.70` | nextcloud | Nextcloud AIO + EuroOffice |
| VM 102 / `.25` | Windows Server 2025 | qBittorrent, VPN, *arr stack, Plex (frontend) |
| VM 105 / `.60` | ai-agents | Hermes, Honcho, Wiki, Nesquena, Bridge API, Direct Comm |

## LXCs and utility hosts on Bolex

| IP | Service | Notes |
|----|---------|-------|
| `.20` | auth | `auth.bolex.es` (via NPMPlus on N355) |
| `.30` | gpu-vm | see above |
| `.41` | seerr | Plex media requests |
| `.42` | wizarr | Plex onboarding |
| `.43` | nebula-sync | Pi-hole v6 replication |
| `.50` | vaultwarden | `pass.bentomo.es` main |
| `.52` | metube | YouTube downloader |
| `.53` | searxng | `search.benthem.es` |
| `.54` | onedrive-sync | rclone bisync to OneDrive |
| `.80` | tautulli | Plex stats (LXC 212) |

## Other hosts

| IP | Host | Role |
|----|------|------|
| `.7` | Pi-hole replica | Nebula-sync replica |
| `.15` | PBS | Proxmox Backup Server (LXC 107 inside N355) |
| `.40` | homer | Homer dashboard (LXC 201) |
| `.70` | nextcloud | Nextcloud AIO VM 101 |
| `.100` | npmplus | Nginx Proxy Manager Plus on N355 |
| `.200` | PiNet1 | Pi-Hole v6 primary, PiVPN, Vaultwarden replica |
| `.205` | PiNet2 | Pi-Hole backup, Vaultwarden replica |

## Public edge

| Name | IP / domain | Role |
|------|-------------|------|
| `bolex-cloud` | `79.72.49.182` | Oracle Cloud VPS — Pangolin + Gerbil + Traefik + CrowdSec |
| `wg0` | `85.55.68.44:51820` | PiVPN WireGuard (primary) |
| Gerbil | `79.72.49.182:51822` | Pangolin tunnel backplane |

## Reverse-proxy mapping

See [`../concepts/reverse-proxy-topology`](https://wiki.benthem.es/concepts/reverse-proxy-topology) for which public domain is served by Pangolin vs NPMPlus.
