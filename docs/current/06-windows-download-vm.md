# Windows Download VM

The Windows Server 2025 VM (`192.168.2.25`) is dedicated to media acquisition. It runs qBittorrent behind a VPN and the *arr stack for organizing and monitoring downloads.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| qBittorrent | `8080` | Torrent client (NSSM service under `alex`) |
| Radarr | `7878` | Movie management |
| Sonarr | `8989` | TV management |
| Prowlarr | `9696` | Indexer manager |
| Lidarr | `8686` | Music management |
| FlareSolverr | `8191` | Cloudflare solver for indexers |
| Plex | `32400` | Media server front-end (library itself is on `tank-media`) |

## Integration

- On successful download/import, Radarr/Sonarr fire webhooks to the **media promotion listener** on Bolex, which moves files from staging into the final Plex library structure on `tank-media`.
- The promotion is **event-driven**, not cron-based.

## Management

```powershell
# WinRM from ai-agents / LAN
$pw = ConvertTo-SecureString "[REDACTED]" -AsPlainText -Force
cred = New-Object System.Management.Automation.PSCredential("alex", $pw)
Enter-PSSession -ComputerName 192.168.2.25 -Credential $cred

# qBittorrent WebUI
http://192.168.2.25:8080  (alex / [REDACTED])
```

## Related

- [Benthem Wiki — RR Suite](https://wiki.benthem.es/concepts/rr-suite)
- [Benthem Wiki — Plex integration](https://wiki.benthem.es/entities/plex-integration)
- [Benthem Wiki — Media promotion listener / pipeline](https://wiki.benthem.es/projects/plex-media-requests-pipeline)
