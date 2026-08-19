# Pangolin and the Edge

Public traffic enters through a single Oracle Cloud VPS called `bolex-cloud` (`79.72.49.182`).

## Stack on bolex-cloud

| Service | Purpose |
|---------|---------|
| Pangolin | Zero Trust reverse proxy, SSO, resource management |
| Gerbil | WireGuard tunnel daemon |
| Traefik | TLS termination and HTTP routing |
| CrowdSec | Intrusion detection (reads Traefik logs) |
| GeoIP Update | MaxMind GeoLite2 refresh |

## Routing chain

```
Client → bolex-cloud (Pangolin auth) → Gerbil WireGuard tunnel → Traefik → LAN backend
```

## Gerbil

- Public UDP port: `51822`
- Backends terminate inside the LAN at the correct host/VM/LXC
- Replaces the older public-facing Nginx Proxy Manager stack

## Direct exceptions (NPMPlus on N355)

A small number of services bypass Pangolin and are served directly by NPMPlus on N355:

- `auth.bolex.es` → `192.168.2.20:9091`
- `guac.bolex.es` → `192.168.2.11:8080`
- `nginx.bolex.es` → `192.168.2.100:81`
- `plex.bolex.es` → `192.168.2.30:32400`
- `theme.bentomo.es` → `192.168.2.48:4443`

Everything else routes through Pangolin.

## Management

```bash
# SSH to bolex-cloud (from Clawdio / ai-agents)
ssh alex@79.72.49.182

# Restart Pangolin stack
cd ~/docker/pangolin && docker compose restart

# View CrowdSec decisions
docker exec -it crowdsec cscli decisions list
```

## Related

- [Benthem Wiki — Oracle VPS Fleet](https://wiki.benthem.es/concepts/oracle-vps-fleet)
- [Benthem Wiki — Reverse Proxy Topology](https://wiki.benthem.es/concepts/reverse-proxy-topology)
