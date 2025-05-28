# STEPS TO SETUP 3 SERVERS WITH HIGH AVAILABILITY USING KEEPALIVED

## Initial considerations:

### Network Equipment:
- Router IP (Gateway and DHCP): 192.168.2.1
- Managed Switch: 192.168.2.2

### Pihole 1: 
- Hostname: Pinet1
- 192.168.2.200

    - Primary device for: Primary DNS Server with Pihole 1 & Wireguard
    - Backup device for: NGINX Proxy Manager, Vaultwarden, Bentomo Search & Homer

### Bentomo-NET
- Hostname: Bentomo-NET
- IP: 192.168.2.201

    - Primary device for: Most services including: NGINX Proxy Manager, Bentomo Search, Vaultwarden, etc.
    - Secondary DNS Server with Pihole 2

### Backup - Pihole 2:
- Hostname: PiNet2
- IP: 192.168.2.205

    - Backup device for Pihole 1: Backup DNS server with Pihole 3 & Wireguard
    - Backup device for: NGINX Proxy Manager, Vaultwarden, Bentomo Search & Homer (If Pihole1 fails, these services will only store backup information)

### Virtual IPs:
- VRRP1: 192.168.2.3 (HTTP/HTTPS traffic)
- VRRP2: 192.168.2.4 (VPN traffic & DNS requests)


--- 




## Installing keepalived with 2 different vrrp instances:

VRRP1 HTTP
Machine 1, router_id: Bentomo-NET. This vrrp instance is named HTTP. This machine is master and has a physical IP of 192.168.2.201
Machine 2, router_id: PiNet1. VRRP instance HTTP. This machine is backup and has a physical IP of 192.168.2.200.
This Vrrp has a Virtual IP of 192.168.2.3

VRRP2 VPN-DNS.
Machine 2, router_id: PiNet1. This VRRP instance is named VPN-DNS. This machine is master of this vrrp and has a physical IP of 192.168.2.200. This machine is also the backup for the other vrrp instance (Bentomo-NET).
Machine 3, router_id: PiNet2. This VRRP instance is for VPN-DNS. This machine is the backup and has a physical IP of 192.168.2.205.
This vrrp instance named VPN-DNS will have a virtual IP of 192.168.2.4
How would I set up the configuration file of keepalived.conf

To configure Keepalived with two distinct VRRP instances (HTTP and VPN) across three machines, here's a structured setup:

---

### **Machine 1 (Bentomo-NET, 192.168.2.201) Configuration**

**Physical IP:** 192.168.2.201
**File:** `/etc/keepalived/keepalived.conf`

```bash
global_defs {
    router_id Bentomo-NET
}

vrrp_instance HTTP {
  state MASTER
  interface ens33                    # Correct interface for Bentomo-NET
  virtual_router_id 51               # Unique ID for HTTP instance
  priority 100                       # Higher than backup
  advert_int 1
  unicast_src_ip 192.168.2.201
  unicast_peer {
    192.168.2.200
  }
  authentication {
    auth_type PASS
    auth_pass Lw7Oo8PQ            # 8-char password for HTTP group
  }
  virtual_ipaddress {
    192.168.2.3/24
  }
}
```

---

### **Machine 2 (PiNet1, 192.168.2.200) (HTTP Backup + VPN Master) Configuration**

**Physical IP:** 192.168.2.200
**File:** `/etc/keepalived/keepalived.conf`

```bash
global_defs {
    router_id PiNet1
}

vrrp_instance HTTP {
  state BACKUP
  interface eth0                     # Correct interface for PiNet1
  virtual_router_id 51               # Matches HTTP instance group
  priority 90                        # Lower than master
  advert_int 1
  unicast_src_ip 192.168.2.200
  unicast_peer {
    192.168.2.201
  }
  authentication {
    auth_type PASS
    auth_pass Lw7Oo8PQ            # Same as HTTP master
  }
  virtual_ipaddress {
    192.168.2.3/24
  }
}

vrrp_instance VPN-DNS {
  state MASTER
  interface eth0                     # Correct interface for PiNet1
  virtual_router_id 52               # Unique ID for VPN instance
  priority 100                       # Higher than backup
  advert_int 1
  unicast_src_ip 192.168.2.200
  unicast_peer {
    192.168.2.205
  }
  authentication {
    auth_type PASS
    auth_pass 7xvzUPLR             # 8-char password for VPN group
  }
  virtual_ipaddress {
    192.168.2.4/24
  }
}


```

---

### **Machine 3 (PiNet2, 192.168.2.205) (VPN-DNS Backup) Configuration**

**Physical IP:** 192.168.2.205
**File:** `/etc/keepalived/keepalived.conf`

```bash
global_defs {
    router_id PiNet2
}

vrrp_instance VPN-DNS {
  state BACKUP
  interface eth0
  virtual_router_id 52               # Matches VPN instance group
  priority 90                        # Lower than master
  advert_int 1
  unicast_src_ip 192.168.2.205
  unicast_peer {
    192.168.2.200
  }

  authentication {
    auth_type PASS
    auth_pass 7xvzUPLR             # Same as VPN master
  }
  virtual_ipaddress {
    192.168.2.4/24
  }
}

```

---

### **Key Configuration Notes**

1. **Interface:** Replace `eth0` with the actual network interface name (e.g., `ens192`).
2. **Authentication:**
    - Use unique passwords per VRRP group (HTTP: `MyPass123`, VPN: `MyPass456`).
3. **Virtual Router IDs:**
    - `virtual_router_id` must match across instances in the same group (51 for HTTP, 52 for VPN).
4. **Priority Hierarchy:**
    - Master nodes have higher priority (e.g., 150 vs. 100 for backups).

---

### **Post-Configuration Steps**

1. Restart Keepalived on all machines:

```bash
sudo systemctl restart keepalived
```

2. Verify VIP assignment:

```bash
ip a show eth0                  # Check for VIPs on the interface
```

3. Checking if all working correctly:
```bash
sudo apt install tcpdump

sudo tcpdump -i eth0 vrrp

journalctl -u keepalived --since "5 minutes ago"

```