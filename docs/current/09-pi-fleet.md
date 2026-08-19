# Pi Fleet

The Raspberry Pi fleet provides network-critical services (DNS, VPN, password-manager replica) with physical separation from the main server.

## Hosts

| Name | IP | Role | Status |
|------|----|------|--------|
| **PiNet1** | `192.168.2.200` | Primary Pi-Hole v6, PiVPN master, Vaultwarden replica | Active |
| **PiNet2** | `192.168.2.205` | Pi-Hole v6 backup, Vaultwarden replica | Active |

## PiNet1 services

- **Pi-Hole v6** — primary DNS sinkhole, ad blocker, DHCP server
- **PiVPN / WireGuard** — family VPN server (`wg0`, UDP 51820)
- **Vaultwarden** — password manager replica (`pass.benthem.es` fallback)
- Docker: SearXNG, Homer Dashboard, Cloudflare DDNS, WatchTower

## PiNet2 services

- Pi-Hole v6 backup (Nebula-sync replica)
- Vaultwarden replica
- Docker: SearXNG, Homer Dashboard, etc.

## High availability

- **DNS:** Keepalived VIP `192.168.2.4` fails over from PiNet1 → PiNet2
- **VPN:** PiNet1 is the master endpoint; PiNet2 can be used as a secondary endpoint with a different forwarded WAN port
- **Vaultwarden:** live sync from LXC 202 main to both Pis weekly

## Related

- [Benthem Wiki — PiNet Infrastructure](https://wiki.benthem.es/concepts/pinet-infrastructure)
- [Benthem Wiki — Keepalived VIP Failover](https://wiki.benthem.es/concepts/keepalived-vip-failover)
