# Evolution of the Home Lab

> A historical narrative of how the Benthem home lab grew from a Windows Media Center box into a Proxmox + ZFS + AI-agent platform.

## 2009 — Media Center beginnings

The project started with **Windows Media Center**, then moved through the classic media-player lineage:

- XBMC
- Kodi
- Plex

Over the years, hardware kept getting upgraded, and the server picked up more responsibilities: cloud storage, photo library, AI chat, DNS, VPN, password manager, and more.

## 2024–2025 — The layered stack

The lab grew into a complex Windows-centric architecture:

| Layer | Platform | Purpose |
|-------|----------|---------|
| Main OS | Windows 11 | Office work via RDP, Hypervisor role |
| Hyper-V | Windows Server 2025 VM | Torrent downloads, VPN connections |
| VMware | 3 Ubuntu Server VMs | Web services, reverse proxy, applications |
| WSL2 + Docker Desktop | 10+ compose stacks | AI/ML workloads (GPU-accelerated) |
| Proxmox | Intel N355 | OPNSense firewall, LXC containers |
| Oracle Cloud | 2× Ubuntu VMs | Zero Trust access, web projects |
| Raspberry Pi | Raspberry Pi OS | DNS, VPN, backup services |

This stack is documented in full at [`docs/historical/2025-windows-wsl-era/`](docs/historical/2025-windows-wsl-era/), including the original 52 Docker Compose files and the six installation guides.

### Why it became inefficient

- Four separate virtualization layers on top of a desktop OS duplicated RAM, storage, scheduling, and networking overhead.
- Windows desktop overhead (UI, updates, Defender, indexing) consumed resources on an always-on server.
- GPU contention between WSL2 Docker, Plex, and video editing created driver and VRAM conflicts.
- WSL2 filesystem friction complicated bind mounts and Docker Desktop credential handling.
- Patch/reboot churn from Windows and Docker Desktop periodically forced long maintenance windows.

## 2026 — Migration to Proxmox and native agents

### Phase 1 — Agent core migration (June)

- **2026-06-12**: Hermes Agent, Honcho, Wiki frontend, Bridge API, and Direct Comm Server moved from a Docker container on WSL2 to **native systemd services** on a dedicated VM (`ai-agents`, `192.168.2.60`).
- **2026-06-15**: Nesquena WebUI migrated to native systemd on the same VM.
- **2026-06-17**: The VM was renamed from `openclaw` to `ai-agents`; the user account from `clawdio` to `alex`. "OpenClaw" was kept only as the legacy Honcho workspace name.

### Phase 2 — Model and reasoning improvements

- **2026-06-13**: Primary model trial of `kimi-k2.7-code:cloud`, chosen for speed and planning gains.
- **2026-06-22**: Local fallback `gemma4:e4b-128k` added on GPU VM Ollama; Honcho embeddings regenerated with `nomic-embed-text-v2-moe:latest`.
- **2026-08-19**: Primary model returned to `deepseek-v4-flash:cloud`, with `kimi-k2.7-code:cloud` as cloud fallback and `gemma4:e4b-128k` as local fallback.

### Phase 3 — Main server Proxmox migration (August)

- **2026-08-01**: Oracle Cloud consolidated from two A1 instances to a single `bolex-cloud` VPS.
- **2026-08-10**: Main server BOLEX migrated from Windows 11 to **Proxmox VE** with ZFS pools (`tank-media`, `tank-immich`, `tank-fast`, `tank-backup`).
- **2026-08-15**: Immich external libraries moved to `tank-media/Pictures`, freeing space and simplifying the backup chain.
- **2026-08-17**: Nextcloud migrated from a hand-rolled Docker Compose stack to **Nextcloud AIO on VM 101** (`192.168.2.70`); MeTube verified on LXC 203; backup timers formalized.
- **2026-08-18**: OneDrive ↔ `tank-fast/documents` two-way sync implemented via rclone bisync on LXC 214.

## Current operating model

The 2026 design is built on a few simple rules:

1. **One main hypervisor per physical server** — Proxmox on both Bolex and N355.
2. **ZFS everywhere** — RAIDZ1 mirrors, datasets, snapshots, and automated send/receive/rsync backups.
3. **Agents run natively** — Hermes, Honcho, Wiki, and Nesquena are systemd services on VM 105, not containers.
4. **GPU workloads isolated** — Plex, Ollama, Immich ML, and Qdrant live in the GPU VM with passthrough.
5. **Public edge is Pangolin** — Zero Trust reverse proxy on Oracle Cloud; a small legacy subset stays on NPMPlus on N355.
6. **Backups are automated and layered** — VM images, Restic, rsync, and real-time watchers.

## Historical archive

The original 2025 Windows/WSL/VMware design is preserved unchanged under [`docs/historical/2025-windows-wsl-era/`](docs/historical/2025-windows-wsl-era/). It is not actively maintained, but it is kept intact because it explains the origins of many services and contains useful compose templates.
