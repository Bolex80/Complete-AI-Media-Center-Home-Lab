# Nextcloud

Nextcloud AIO runs on Proxmox VM 101 (`192.168.2.70`) and replaces the earlier hand-rolled Docker Compose Nextcloud+EuroOffice stack.

## Access

- Web: `https://nube.bentomo.es`
- LAN: `http://192.168.2.70:11000` (Apache)
- Mastercontainer: `http://192.168.2.70:8080`

## Compose location

On VM 101:

```bash
ssh alex@192.168.2.70
cd ~/docker/nextcloud
docker compose ps
```

## Key configuration

- `APACHE_PORT=11000`
- `SKIP_DOMAIN_VALIDATION=true`
- Reverse proxy (Pangolin) → `http://192.168.2.70:11000`
- Tank NFS mounts at `/mnt/tank-*` for External Storage app integration

## Restart

```bash
cd ~/docker/nextcloud
docker compose down
docker compose up -d
```

## Known issues

- `files_external_onedrive` app is removed — it is incompatible with Nextcloud 34 and causes 500 errors.
- External network drives must be exposed through the **External Storage** app because AIO `NEXTCLOUD_MOUNT` does not support NFS.

## Related

- [Benthem Wiki — Nube (Nextcloud) project](https://wiki.benthem.es/projects/nube-bentomo-es)
