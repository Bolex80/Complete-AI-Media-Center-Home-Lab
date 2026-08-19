# LXC Services

Most lightweight services have been moved from full Docker Compose stacks on Ubuntu VMs into unprivileged Proxmox LXCs. Many were installed via [Proxmox Helper Scripts](https://helper-scripts.com/).

## LXCs on Bolex

| LXC # / IP | Name | Purpose | Public domain |
|------------|------|---------|---------------|
| `.20` | auth | Authentication portal | `auth.bolex.es` (NPMPlus) |
| `.41` | seerr | Plex media requests | via Pangolin |
| `.42` | wizarr | Plex onboarding invites | via Pangolin |
| `.43` | nebula-sync | Pi-hole v6 replication | internal |
| `.50` | vaultwarden | Password manager | `pass.bentomo.es` |
| `.52` | metube | YouTube downloader | internal |
| `.53` | searxng | Metasearch engine | `search.benthem.es` |
| `.54` | onedrive-sync | rclone bisync to OneDrive | internal |
| `.80` | tautulli | Plex stats/newsletter | via Pangolin |

## LXCs / services on N355

| IP / ID | Name | Purpose |
|---------|------|---------|
| `.7` | pihole-replica | Pi-hole v6 replica |
| `.15` / LXC 107 | pbs | Proxmox Backup Server |
| `.100` | npmplus | Nginx Proxy Manager Plus (direct domains) |
| `.200` / LXC 201 | homer | Homer dashboard |
| `.48` | themepark | Theme Park theming service (`theme.bentomo.es` via NPMPlus) |

## Per-service runbooks

Detailed runbooks for the most important services:

- [`services/immich.md`](services/immich.md)
- [`services/nextcloud.md`](services/nextcloud.md)
- [`services/plex.md`](services/plex.md)
- [`services/vaultwarden.md`](services/vaultwarden.md)
- [`services/metube.md`](services/metube.md)
- [`services/searxng.md`](services/searxng.md)

## Typical LXC management

```bash
# From ai-agents (use central SSH key)
ssh alex@192.168.2.52        # metube
pct exec 203 -- bash         # from Proxmox host

# Restart a service
systemctl restart vaultwarden

# View logs
journalctl -u vaultwarden -f
```
