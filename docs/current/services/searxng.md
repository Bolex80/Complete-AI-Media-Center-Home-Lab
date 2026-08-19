# SearXNG

Self-hosted metasearch engine.

## Instances

| Host | IP | Public domain |
|------|-----|---------------|
| LXC 203 (Bolex) | `192.168.2.53` | `search.benthem.es` via Pangolin |
| PiNet1 | `192.168.2.200` | backup |
| PiNet2 | `192.168.2.205` | backup |

## Restart

```bash
pct stop 203 && pct start 203
```

## Hermes integration

Hermes uses SearXNG as its default web search backend (`searxng_url: http://192.168.2.53:8070`).
