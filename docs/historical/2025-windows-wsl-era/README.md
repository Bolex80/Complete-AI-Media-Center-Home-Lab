# Historical 2025 Windows / WSL / VMware Stack

> This directory is a **preserved snapshot** of the home lab as it existed before the 2026 Proxmox migration. It is kept for historical reference and because the compose files and guides are useful starting points for anyone running a similar Windows-centric stack.

## What changed in 2026

- The Windows 11 host + Hyper-V + VMware + WSL2 layer cake was replaced by **Proxmox VE** on the main server.
- The agent core (Hermes, Honcho, Wiki, Nesquena) moved from a Docker container on WSL2 to native systemd on a dedicated VM (`ai-agents`, `192.168.2.60`).
- The two Oracle Cloud A1 instances were consolidated into a single `bolex-cloud` VPS.
- ZFS replaced Windows Storage Spaces and VMware disks as the primary storage platform.
- Many Docker Compose services were moved into Proxmox **LXC containers** or onto dedicated VMs.

## Contents

| Path | What it is |
|------|------------|
| [`compose/`](compose/) | The original 52 Docker Compose files, organized by host. These are **not actively maintained** but are preserved intact. |
| [`installation/`](installation/) | The six original installation guides for the old host layout. |
| [`high-availability.md`](high-availability.md) | Keepalived and VRRP notes from the 2025 era. |
| [`PROGRESS.md`](PROGRESS.md) | The original repository completion summary. |

## Using the historical compose files

These files were all sanitized (no real passwords/tokens). To reuse them:

1. Copy the relevant compose file to your own environment.
2. Create a `.env` file from the template or example secrets file.
3. Generate secure keys with `openssl rand -hex 32`.
4. Update volume paths to match your own storage layout.

## Important caveats

- Many ports, IPs, and service locations in these guides are now stale.
- Some services no longer run in Docker at all (e.g., agent stack, Vaultwarden on LXC, MeTube on LXC).
- The public reverse proxy is now Pangolin, with a small subset still on NPMPlus. The old Nginx Proxy Manager guides reflect the pre-Pangolin layout.
- The old `openclaw` host is now the `ai-agents` VM.

For the current state, see the top-level [`CURRENT_ARCHITECTURE.md`](../CURRENT_ARCHITECTURE.md) and [`docs/current/`](../current/).
