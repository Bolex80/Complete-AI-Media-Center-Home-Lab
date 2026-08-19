# Vaultwarden

Self-hosted Bitwarden-compatible password manager.

## Main instance

| Property | Value |
|----------|-------|
| Host | LXC 202 on Bolex, IP `192.168.2.50` |
| Domain | `pass.bentomo.es` (via Pangolin) |
| Fallback | `pass.benthem.es` on PiNet1 / PiNet2 |
| Data path | `/mnt/tank-fast/lxc/subvol-202-disk-0/home/alex/docker/vaultwarden/data/` |

## Sync

A weekly sync (`vaultwarden-sync.sh`, Sun 00:30):

1. Stops the main container.
2. Tars `db.sqlite3`, `attachments/`, `sends/`, `rsa_key.pem`, `icon_cache/` to `tank-backup/Vaultwarden/`.
3. Pushes to PiNet1 and PiNet2 replicas.
4. Restarts all three.

## Restart

```bash
pct stop 202 && pct start 202
# or inside the LXC
docker compose restart
```

## Related

- [Benthem Wiki — Backup Mechanisms](https://wiki.benthem.es/concepts/backup-mechanisms)
