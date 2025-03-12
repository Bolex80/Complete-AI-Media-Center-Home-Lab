# **COMPLETE AI MEDIA CENTER HOME LAB**

## Table of Contents
1. [Overview](#overview)
2. [Main Specs](#main-specs)
3. [Services running in the Raspberry Pi (bare-metal)](#services-running-in-the-raspberry-pi-bare-metal)
   - [Pi-Hole](#pi-hole)
   - [PiVPN](#pivpn)
   - [Keepalived](#keepalived)
4. [Services running in the Raspberry Pi with Docker](#services-running-in-the-raspberry-pi-with-docker)
   - [Cloudflare DDNS](#cloudflare-ddns)
   - 
5. [Services in the Main Server](#services-in-the-main-server)
   - [Service 1](#service-1)
     - [Description](#description)
     - [Configuration](#configuration)
   - [Service 2](#service-2)
     - [Description](#description)
     - [Configuration](#configuration)4
6. [Getting Started](#getting-started)

## Overview

I would like to provide an overview on how I have deployed and manage my homelab services in my main server.

Contrary to everyone's home server I am running it completly different and for very specific reasons.

My project begun back in 2009 with Windows Media Center, then it progressed to XBCM, then Kodi, then PLEX and from there on... with many hardware updates, it became my cloud instance, my photo library, my AI GPT, my DNS server, my VPN client, my password manager, etc... 

The ultimate goal is with a modest spec-like server and a couple of Raspbery Pi's. Have a complete professional setup that can handle all my needs.

## Main Specs

### Complementary Servers 🤖
- Raspberry Pi4 with 2GB running [Wireguard with PiVPN](https://www.pivpn.io/) and [PiHole](https://pi-hole.net/) as well as serving as backup Search engine ([SearXNG](https://github.com/searxng/searxng)) and Password Vault ([Vaultwarden](https://github.com/dani-garcia/vaultwarden)).
- Secondary backup Rasberry Pi 4 - Same specs and I do weekly SD Card backups. 
    This Raspberry is not connected. In case of failure it is a cold swap.

### Main Server 🖥️
- AMD Ryzen 9 5900X
- 64 GB RAM
- 1 TB M.2 NVMe Drive for the OS (1TB) (Windows 11)
- 1 TB M.2 NVMe Drive for Virtual Machines
- 500 GB M.2 NVMe Drive for Next Cloud
- 1 TB SSD for Windows Server 2025 Virtual Machine
- 3x 12TB HDD in a Parity Storage Space (main drive for Media)
- 3x 3TB HDD in a Parity Storage Space for Backup
- Bluray RE drive (for legacy reasons)

The configuaration might seem completly overhead and might look messy. But after fine tuning, it covers perfectly well all my needs and runs on an average of 180-200 W (this includes, the raspberry, the swith, the 2 routers, and the TV Decoder)

- **Main OS** (windows 11) is used for regular office work via RDP and acts as hypervisor.
- **Hyper-V** is used to manage a windows server 2025 that is used for downloads.
- **VMware Workstation Pro** manages the linux servers (3 in total).
- **WSL2 - Docker Desktop** Manages the AI, the image server and other services that are resource hungry.


## Services running in the Raspberry Pi (bare-metal)

### Pi-hole
**Description:** The Pi-hole® is a DNS sinkhole that protects your devices from unwanted content. I also use it as DHCP in my network.
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
**Description:** Keepalived is a routing software to provide simple and robust facilities for loadbalancing and high-availability to Linux systems. Loadbalancing framework relies on well-known and widely used Linux Virtual Server (IPVS) kernel module.

In my configuration, the Raspberry Pi will act as secondary device.
The reason for this configuration is that my PiHole is more likely to survive random crashes and therefore I need the basic services always available.
These are:
  - Pi-hole
  - Nginx Proxy Manager
  - SearXNG
  - Vaultwarden

More info here: https://www.keepalived.org/

**Configuration:**
Install Keepalived on both servers where you’d like High Availability.

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

===========================================

## Services running in the Raspberry Pi with Docker

📡
**This next section will include the services running in docker**
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

```bash
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


