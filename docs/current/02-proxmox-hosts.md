# Proxmox Hosts

The fleet is built on two Proxmox VE hosts.

## Bolex (`192.168.2.5`)

The main Proxmox host. Hardware from the old Windows 11 workstation:

- **CPU:** AMD Ryzen 9 5900X
- **RAM:** 64 GB DDR4
- **GPU:** NVIDIA RTX 4060 Ti 16 GB (passthrough to GPU VM)
- **Boot:** 1 TB SATA SSD (`rpool`)
- **Fast VM/LXC storage:** 2 TB M.2 NVMe (`tank-fast`)
- **Media pool:** 3 × 12 TB HDD (`tank-media`, RAIDZ1)
- **Backup pool:** 3 × 3 TB HDD (`tank-backup`, RAIDZ1)
- **Immich mirror:** 2 × 1 TB M.2 NVMe (`tank-immich`, mirror)

Runs VM 100 (gpu-vm), VM 101 (nextcloud), VM 102 (Windows Server 2025), VM 105 (ai-agents), and ~13 LXCs.

## N355 (`192.168.2.10`)

The secondary Proxmox host. Smaller, primarily networking and backup focused:

- Intel i3 N355, 32 GB RAM, 2 × 1 TB M.2 SSD
- Runs OPNSense router VM, Proxmox Backup Server LXC 107 (`192.168.2.15`), NPMPlus, and utility LXCs
- N355 backups are pushed to Bolex `tank-backup/vm` and PBS

## Management URLs

| Host | Proxmox UI |
|------|------------|
| Bolex | `https://192.168.2.5:8006` |
| N355 | `https://192.168.2.10:8006` |

## Backup jobs

| Job | Host | Time | Target |
|-----|------|------|--------|
| `backup-bolex-full` | Bolex | 02:00 | `tank-backup/vm` |
| `backup-n355-full` | N355 | 02:00 | local + rsync to Bolex |
| PBS datastore | N355 | 21:00 | `backup-local` |
