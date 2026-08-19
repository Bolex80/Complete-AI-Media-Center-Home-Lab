# Plex

Plex Media Server is available at `https://plex.bolex.es` (via NPMPlus on N355) and `http://192.168.2.30:32400` from the LAN.

## Location

The Plex front-end runs in the GPU VM (`192.168.2.30`) with library data on `tank-media`.

## Library structure

On `tank-media/multimedia`:

- `Movies HD`
- `Movies 4K`
- `Movies Spanish`
- `Cartoons HD`
- `Documentaries`
- `TV Shows`
- `TV Shows 4K`
- `TV Shows Spanish`
- `Music`

## Requests / onboarding

- **Seerr** (`192.168.2.41:5055`) for media requests
- **Wizarr** (`192.168.2.42:5690`) for onboarding invites

## Stats

- **Tautulli** at `192.168.2.80:8181` for viewing stats and weekly newsletters.

## Related

- [Benthem Wiki — Plex Integration](https://wiki.benthem.es/entities/plex-integration)
- [Benthem Wiki — Media Pipeline](https://wiki.benthem.es/projects/plex-media-requests-pipeline)
