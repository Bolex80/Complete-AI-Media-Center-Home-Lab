# Media Pipeline

The media pipeline is event-driven: the Windows Server VM acquires content, and an HTTP listener on Bolex promotes it into the final Plex library.

## Flow

1. **Request** — Seerr (`192.168.2.41`) receives a movie/TV request.
2. **Acquisition** — Radarr/Sonarr send the request to Prowlarr indexers and push to qBittorrent on Windows Server `.25`.
3. **Download** — qBittorrent downloads into a staging folder.
4. **Import** — Radarr/Sonarr rename and move into the staging "temp" library.
5. **Promotion** — On import completion, Radarr/Sonarr fire a webhook to the **media promotion listener** on Bolex (`media-promote.service`, port 8765).
6. **Final library** — The listener routes the file by genre into the correct Plex folder on `tank-media`:
   - 4K → `Movies 4K` / `TV Shows 4K`
   - Spanish → `Movies Spanish` / `TV Shows Spanish`
   - Animation → `Cartoons HD`
   - Documentary → `Documentaries/...`
   - Generic → `Movies HD` / `TV Shows`

## Services

| Service | Host | Port | Role |
|---------|------|------|------|
| Seerr | LXC `.41` | `5055` | Request UI |
| Wizarr | LXC `.42` | `5690` | Plex onboarding invites |
| Radarr | Windows VM `.25` | `7878` | Movies |
| Sonarr | Windows VM `.25` | `8989` | TV |
| Prowlarr | Windows VM `.25` | `9696` | Indexers |
| qBittorrent | Windows VM `.25` | `8080` | Downloads |
| Plex | GPU VM `.30` / Windows VM `.25` | `32400` | Playback |
| Tautulli | LXC `.80` / `:8181` | Stats and newsletter |
| Media promote listener | Bolex host | `8765` | Webhook → file promotion |

## qBittorrent seed policy

qBittorrent is configured to auto-remove torrents (and their files) once a ratio of `1.0` is reached. This clears staging leftovers after the library copy is made.

## Related

- [Benthem Wiki — RR Suite](https://wiki.benthem.es/concepts/rr-suite)
- [Benthem Wiki — Plex Integration](https://wiki.benthem.es/entities/plex-integration)
- [Benthem Wiki — MeTube MP3 Pipeline](https://wiki.benthem.es/concepts/metube-mp3-pipeline)
- Project: [`plex-media-requests-pipeline`](https://wiki.benthem.es/projects/plex-media-requests-pipeline)
