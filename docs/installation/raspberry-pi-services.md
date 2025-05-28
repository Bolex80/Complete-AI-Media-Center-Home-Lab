
# Services on the Raspberry Pi (bare-metal)

**Description:** The `Pi-hole`® is a DNS sinkhole that protects your devices from unwanted content. I also use it as DHCP in my network.
The configuration is prety straight forward. In this case I run it directly on the Raspberry Pi.
More info here: https://pi-hole.net/

**Configuration:**
```bash
curl -sSL https://install.pi-hole.net | bash
```

### PiVPN
**Description:** The simplest way to setup and manage a VPN, designed for Raspberry Pi. This uses Wireguard to connect to my home server securely.
Configuration is very simple, just follow the instructions.
More info here: https://www.pivpn.io/

**Configuration:**
Configuring Keepalived for High Availability
Keepalived is designed to run on two separate hosts but share a virtual IP address. This ensures that if one goes down (the master), the backup will take over using the same virtual IP.

```bash
curl -L https://install.pivpn.io | bash
```

### KeepAlived
**Description:** `Keepalived` is a routing software to provide simple and robust facilities for loadbalancing and high-availability to Linux systems. Loadbalancing framework relies on well-known and widely used Linux Virtual Server (IPVS) kernel module.

In my configuration, the Raspberry Pi will act as secondary device.
The reason for this configuration is that my PiHole is more likely to survive random crashes and therefore I need the basic services always available.
These are:
  - Pi-hole
  - Nginx Proxy Manager
  - SearXNG
  - Vaultwarden

More info here: https://www.keepalived.org/

**Configuration:**
Install `Keepalived` on both servers where you’d like High Availability.

```bash
apt install keepalived
```
Get the interface name (I used ens3, yours might be different), then modify the config file

```bash
ip a
nano /etc/keepalived/keepalived.conf
```
Paste this information into the configuration file of the master and modify it as needed.
- In my case my master device (which is not my Raspberry Pi, but the main server) is: ens33
- Pihole which in this case will be slave: eth0

```bash
vrrp_instance VI_1 {
  state MASTER
  interface ens33 #Ensure you use the correct interface name
  virtual_router_id 20
  advert_int 1
  unicast_src_ip 192.168.2.201 # This is where I have my main Server
  unicast_peer {
    192.168.2.200 #This is my PiHole IP
  }
  priority 150
  authentication {
    auth_type PASS
    auth_pass Lw7Oo8PQ
  }
  virtual_ipaddress {
    192.168.2.3/24
  }
}
```

----

## Services on the Raspberry Pi with Docker

📡
**This next section will include the services running on docker**
📡

If you need help installing docker on the raspberry pi, you can find information in the following link: 
https://www.dotruby.com/articles/how-to-install-docker-and-docker-compose-on-raspberry-pi


### Cloudflare DDNS
**Description:** A feature-rich and robust Cloudflare DDNS updater with a small footprint. The program will detect your machine’s public IP addresses and update DNS records using the Cloudflare API.
Configuration is very simple, just follow the instructions.
More info here: https://github.com/favonia/cloudflare-ddns

**Configuration:**
It is best to follow the instructions from their [github page](https://github.com/favonia/cloudflare-ddns), that way you can configure it as it best suits you and it will help you with the Cloudflare API tokens.

#### docker-compose.yml file

```yaml
services:
  cloudflare-ddns:
    image: favonia/cloudflare-ddns:latest
    # Choose the appropriate tag based on your need:
    # - "latest" for the latest stable version (which could become 2.x.y
    #   in the future and break things)
    # - "1" for the latest stable version whose major version is 1
    # - "1.x.y" to pin the specific version 1.x.y
    network_mode: host
    # This bypasses network isolation and makes IPv6 easier (optional; see below)
    restart: always
    # Restart the updater after reboot
    user: "1000:1000"
    # Run the updater with specific user and group IDs (in that order).
    # You can change the two numbers based on your need.
    read_only: true
    # Make the container filesystem read-only (optional but recommended)
    cap_drop: [all]
    # Drop all Linux capabilities (optional but recommended)
    security_opt: [no-new-privileges:true]
    # Another protection to restrict superuser privileges (optional but recommended)
    environment:
      - CF_API_TOKEN=<put your token from cloudflare here> #instructions on how to get this API token are detailed in the github page
        # Your Cloudflare API token
      - DOMAINS=<whatever-you-have.com, domain2.net>
        # Your domains (separated by commas)
      - PROXIED=false
        # Tell Cloudflare to cache webpages and hide your IP (optional)

```


