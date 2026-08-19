# Services Runbooks

Quick operational guides for the most important current services.

## Available runbooks

| Service | File | Notes |
|---------|------|-------|
| Immich | [`services/immich.md`](services/immich.md) | Photo/video library on GPU VM |
| Nextcloud | [`services/nextcloud.md`](services/nextcloud.md) | Nextcloud AIO on VM 101 |
| Plex | [`services/plex.md`](services/plex.md) | Media server |
| Vaultwarden | [`services/vaultwarden.md`](services/vaultwarden.md) | Password manager on LXC 202 |
| MeTube | [`services/metube.md`](services/metube.md) | YouTube downloader on LXC 203 |
| SearXNG | [`services/searxng.md`](services/searxng.md) | Self-hosted search on LXC 203 |

## Quick service restart cheat sheet

```bash
# LXCs (pct from Proxmox host)
pct stop 202 && pct start 202   # vaultwarden
pct stop 203 && pct start 203   # metube
pct stop 205 && pct start 205    # wizarr
pct stop 212 && pct start 212    # tautulli

# VMs (qm from Proxmox host)
qm stop 100 && qm start 100     # gpu-vm
qm stop 101 && qm start 101     # nextcloud
qm stop 105 && qm start 105     # ai-agents

# Native systemd services on ai-agents
systemctl --user restart hermes-gateway.service
systemctl restart wiki-frontend.service
systemctl restart honcho-api.service
```

## Troubleshooting

For operational problems, check the Benthem Wiki incident log and the relevant service page first:
[https://wiki.benthem.es/log](https://wiki.benthem.es/log)
