# ZFS Pools

All storage on the Proxmox hosts is managed with ZFS.

## Pool layout on Bolex

| Pool | Devices | Role | Compression | Notes |
|------|---------|------|-------------|-------|
| `rpool` | 1 × 1 TB SATA SSD | Proxmox root | on | OS and local VM/LXC metadata |
| `tank-fast` | 1 × 2 TB M.2 NVMe | Fast VM/LXC disks, DBs | on | Single-disk performance pool |
| `tank-immich` | 2 × 1 TB M.2 NVMe (mirror) | Immich-managed library | on | Redundant fast storage for photos |
| `tank-media` | 3 × 12 TB HDD (RAIDZ1) | Media, pictures, documents mirror | on | Bulk storage for movies, TV, music, pictures |
| `tank-backup` | 3 × 3 TB HDD (RAIDZ1) | Backup target | on | Strict backup-only pool, not shared |

## Datasets of note

| Dataset | Pool | Purpose |
|---------|------|---------|
| `tank-media/multimedia/Music` | tank-media | Music library (MeTube downloads + curated) |
| `tank-media/Pictures` | tank-media | Immich external library (All-Years, Fotos-Boda, Hugo, Marcos, Sofia) |
| `tank-media/backup` | tank-media | Secondary app-config and security backups |
| `tank-fast/documents` | tank-fast | Live documents (OneDrive sync source) |
| `tank-backup/immich` | tank-backup | 3rd copy of Immich library |
| `tank-backup/Pictures` | tank-backup | 3rd copy of pictures |
| `tank-backup/music` | tank-backup | Music backup |
| `tank-backup/vm` | tank-backup | Proxmox vzdump images |

## SMB shares

| Share | Dataset | Access |
|-------|---------|--------|
| `documents` | `tank-fast/documents` | RW |
| `media` | `tank-media/multimedia` | RW |
| `backup` | `tank-media/backup` | RW |
| `immich` | `tank-immich` | RW |
| `restore` | USB mount | RO |

`tank-backup` is intentionally **not shared**.

## Useful commands

```bash
# Pool status
zpool status

# Space usage
zfs list -o name,used,available,referenced,mountpoint

# Snapshots
zfs list -t snapshot | head

# Create manual snapshot
zfs snapshot tank-media@pre-change-$(date +%Y%m%d-%H%M)
```
