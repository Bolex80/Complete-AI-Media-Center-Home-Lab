# Backup Strategy

The backup strategy is **layered and automated**: VM images, Restic dedup, and rsync timers cover different failure modes.

## Jobs

| # | System | Managed by | Schedule | Source → Target |
|---|--------|------------|----------|-----------------|
| 1 | Bolex PVE VM/LXC backup | Proxmox vzdump | Daily 02:00 | all VMs+LXCs → `tank-backup/vm` |
| 2 | N355 PVE VM/LXC backup | Proxmox vzdump | Daily 21:00/23:00/02:00 | N355 guests → local + PBS + rsync → `tank-backup/vm` |
| 3 | PBS datastore | PBS LXC 107 | via N355 21:00 | N355 guests → PBS `.15` datastore |
| 4 | Immich library | systemd timer | Daily 03:00 + 03:45 | `tank-immich` → `tank-media/immich` → `tank-backup/immich` |
| 5 | Pictures (external library) | systemd timer + inotify watcher | Daily 04:00 + real-time | `tank-media/Pictures` → `tank-backup/Pictures` |
| 6 | tank-media/backup | systemd timer | Daily 04:30 | `tank-media/backup` → `tank-backup/backup` |
| 7 | Music | systemd timer | Daily 04:45 | `tank-media/multimedia/Music` → `tank-backup/music` |
| 8 | Documents | systemd timer | Daily 05:00 | `tank-fast/documents` → `tank-media/documents` + `tank-backup/documents` |
| 9 | Raspberry Pi Restic | Pi local cron | Weekly Sun 02:00 | PiNet1 + PiNet2 → `tank-backup/restic` |
| 10 | Vaultwarden sync | Bolex cron | Weekly Sun 00:30 | LXC 202 → `tank-backup/Vaultwarden` + Pi replicas |
| 11 | ai-agents app backup | user cron | Daily 03:10 | `hermes_data`+`.hermes`+`workspace` → `tank-backup/Agents-backup/AiAgents` |
| 12 | bolex-cloud offsite | ai-agents cron pull | Daily 03:40 | `bolex-cloud:backups/` → `tank-backup/bolex-cloud` |
| 13 | Pi Restic monitor | Hermes cron | Weekly Sun 06:00 | health-check PiNet restic repos |

## Quick checks (on Bolex host)

```bash
# Recent PVE dumps
ls -laht /mnt/tank-backup/vm/dump/ | head

# Recent Immich library logs
tail -3 /var/log/immich-library-sync.log
tail -3 /var/log/immich-library-backup.log

# Active timers
systemctl list-timers immich-library-sync immich-library-backup pictures-backup media-backup-to-tank-backup music-backup documents-sync --no-pager
```

## Known gaps

| # | System | Status |
|---|--------|--------|
| 1 | Honcho file-level dump (ai-agents) | Missing — covered by VM image backup |
| 2 | OPNSense config export | Not explicitly backed up |
| 3 | Home Assistant backup addon | VM image only, addon not verified |
| 4 | PBS independence | PBS is on N355 itself — not off-host |

## Related

- [Benthem Wiki — Backup Mechanisms](https://wiki.benthem.es/concepts/backup-mechanisms)
- [Benthem Wiki — Immich Storage Layout](https://wiki.benthem.es/concepts/immich-storage-layout)
