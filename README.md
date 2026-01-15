# **COMPLETE AI MEDIA CENTER HOME LAB**

![BOLEX-Intro image](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/intro-color.png)


## Introduction and overview
I would like to provide an overview on how I have deployed and manage my homelab services in my main server.

Contrary to everyone's home server I am running it completly different and for very specific reasons.

My project begun back in 2009 with Windows Media Center, then it progressed to XBCM, then Kodi, then `PLEX` and from there on... with many hardware updates, it became my cloud instance, my photo library, my AI GPT, my DNS server, my VPN client, my password manager, etc... 

The ultimate goal is with a modest spec-like server and a couple of Raspbery Pi's. Have a complete professional setup that can handle all my needs.

## Disclaimer
This project is provided "as is" without warranty of any kind, express or implied. Use at your own risk. The author is not liable for any damages or losses resulting from the use of this project. 
It is imperative to note that you need to have some pre-knowledge regarding docker, docker compose, containers and how they operatate. This guide has been designed for my own personal usage and is not intended as full guide for Noobs.

## Hardware specs

### Complementary Servers 🤖
- Main Router is an intel i3 N355 with 32GB RAM and 2x 1TB M2 SSD. Running [Proxmox](https://www.proxmox.com/en/) and [OPNSense](https://opnsense.org/) Firewall.
- Main Raspberry Pi4 with 2GB running [Wireguard with PiVPN](https://www.pivpn.io/) and [PiHole](https://pi-hole.net/) as well as serving as backup Search engine ([SearXNG](https://github.com/searxng/searxng)) and Password Vault ([Vaultwarden](https://github.com/dani-garcia/vaultwarden)).
- Secondary backup Rasberry Pi 4 (Same specs and I do weekly SD Card backups).
  
Both running in a [GeekPi Cluster Case](https://www.amazon.com/GeeekPi-Raspberry-Cluster-Cooling-Heatsink/dp/B07MW3GM1T?th=1)  


### Main Server 🖥️
- AMD Ryzen 9 5900X
- 64 GB RAM
- GPU: NVIDIA RTX 4060ti 16GB VRAM
- 2 TB M.2 NVMe Drive for the OS (2TB) (Windows 11)
- 1 TB M.2 NVMe Drive for Virtual Machines
- 1 TB M.2 NVMe Drive for NextCloud VM
- 1 TB SSD for Windows Server 2025 Virtual Machine
- 3x 12TB HDD in a Parity Storage Space (Main Drive for Media)
- 3x 3TB HDD in a Parity Storage Space for Backup
- Bluray RE drive (for legacy reasons)
- 2x 2.5Gb Ethernet adapters

### Additional Hardware
- Firewall [CWWK Intel i3 N355, 4x 2.5G Ethernet. Fanless](https://cwwk.net/products/12th-gen-intel-firewall-mini-pc-alder-lake-i3-n305-8-core-n200-n100-fanless-soft-router-proxmox-ddr5-4800mhz-4xi226-v-2-5g?_pos=1&_sid=7efa4419b&_ss=r&variant=44613920555240)
- Switch [AMPCOM 2.5GbE Managed Switch](https://www.ampcom.hk/products/ampcom-2-5gbe-managed-switch-8-port-2-5gbase-t-network-switcher-10g-sfp-slot-uplink-web-management-qos-vlan-lacp-fanless)
- WiFi Router configured as Access Point [Xiaomi Mesh System AX3000](https://www.mi.com/global/product/xiaomi-mesh-system-ax3000/)
- KVM (Keyboard, Video, Mouse) remote controller [JetKVM](https://jetkvm.com/)
- UPS 1: [CyberPower VP1000ELCD](https://www.cyberpower.com/eu/en/product/sku/vp1000elcd) - Used for Networking devices and the Raspberry Pi's During 40 minutes.
- UPS 2: [Schneider Electric APC Back-UPS 1200VA](https://www.se.com/il/en/product/BX1200MI-GR/apc-backups-1200va-230v-avr-schuko-sockets/) - Used to keep the main server running for at least 10 minutes.



The configuaration might seem completly overhead and might look messy. But after fine tuning, it covers perfectly well all my needs and runs on an average of 200-220 W when semi-idle. 
- The network equipment (Routers,  Raspberry Pis, Swith, KVM and external HD) consume an average of 50-60W.
- Main server in Idle 150-160 W. If I start using the GPU, it will rasise to 350 W aprox.

### Oracle Cloud VMs
Additionally the configuration is supported by 2 additional cloud instances to ensure Zero Trust to most services.

- Instance 1: 2 Cores 16GB RAM (VM.Standard.A1.Flex (Altra processor from Ampere))
- Instance 2: 2 Cores 8GB RAM (VM.Standard.A1.Flex (Altra processor from Ampere))


##

- **Main OS** (windows 11) is used for regular office work via RDP protected by DUO security and acts as hypervisor.
- **Hyper-V** is used to manage a windows server 2025 that is used for Torrent downloads and other external VPN connection needs.
- **VMware Workstation Pro** manages the linux servers (3 in total).
- **WSL2 - Docker Desktop** Manages the AI, the image server and other services that are resource hungry.
- **Proxmox** The main router is running proxmox and has OPNSense firewall virtualized as well as additional LXC containers


## Services Overview

1. [Services on the Raspberry Pi (bare-metal)](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md) - Both Raspeberry Pi's are clones of each other and have the same services running.
   - [Pi-Hole](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md#pi-hole) - Adblocker - DNS Provider and DHCP Server
   - [PiVPN](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md#pivpn) - Wireguard VPN
   - [Keepalived](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/high-availability.md) - High Availability Backup Server
   - [Rpi Monitor](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md#rpi-monitor) - Monitoring Stats for the Raspberry Pi
2. [Services on the Raspberry Pi with Docker](#services-on-the-raspberry-pi-with-docker)
   - [Cloudflare DDNS](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md#cloudflare-ddns) - Public IP DDNS updater for Cloudflare
   - [Nginx Proxy Manager](#nginx-proxy-manager) - Reverse Proxy - used as Backup 
   - [SearXNG](#searxng) - Metasearch Engine - used as Backup
   - [Vaultwarden](#vaultwarden) - Password Manager - used as Backup
   - [Homer Dashboard](#homer-dashboard) - Homepage - used as Backup
3. [Services on the Main Server](#services-running-on-the-main-server) - These are running directly on Windows 11
   - [Plex](#plex) - Home Media Server
   - [Tautulli](#tautulli) - Stats App for Plex
4. [Services on the Ubuntu Server 1](#services-on-the-ubuntu-server-1)
   - [Keepalived](#keepalived) - High Availability - Main Server
   - [Secondary PiHole](#secondary-pihole) - Adblocker - DNS Provider
   - [Nginx Proxy Manager](#nginx-proxy-manager) - Main Reverse Proxy
   - [Homer Dashboard](#homer-dashboard) - Homepage
   - [SearXNG](#searxng) - Metasearch Engine
   - [Vaultwarden](#vaultwarden) - Password Manager
   - [Uptime Kuma](#uptime-kuma) - Monitoring Tool
   - [Beszel System Monitor](#beszel-system-monitor) - Another Monitoring Tool
   - [Speedtest Tracker](#speedtest-tracker) - Internet Connection Performance
   - [Cloudflare DDNS](#cloudflare-ddns) - Public IP DDNS updater for Cloudflare
   - [IT Tools](#it-tools) - Handy IT Tool repository
   - [Themepark](#themepark) - Themes and skins for various Apps
   - [Guacamole](#guacamole) - Remote Desktop Gateway

5. [Services on the Ubuntu Server 2](#services-on-the-ubuntu-server-2)
   - [NextCloud](#nextcloud) - Personal Cloud
   - [Crafty Controller](#crafty-controller) - Minecraft Server
   - [Stirling PDF](#stirling-pdf) - PDF Tools

6. [Services on WSL2 - Docker Desktop](#services-on-wsl2-docker-desktop) - These Require High CPU and GPU usage
   - [Ollama](#Ollama) - Large Language Models locally deployed 
   - [Open WebUI](#open-webui) - Web interface for AI Models
   - [Immich](#immich) - Photo & Video Management App
   - [Postgres](#postgres) - Main database for N8N and LiteLLM
   - [LiteLLM](#litellm) - Interface to access and montior multiple LLMs
   - [MeTube](#metube) - Youtube Video & Music Downloader
   - [N8N](#n8n) - AI Workflow Automation
   - [Qdrant](#qdrant) - Vector Database (used for N8N)
   - [Apache Tika](#apache-tika) - Text and Metadata extractor (used for Open WebUI)
   - [Libre Translate](#libre-translate) - AI Translator

7. [Common services](#common-services) - These are docker containers that are used in all/most machines.
   - [Portainer](#portainer) - Docker Management interface (All Servers)
   - [Redis DB](#redis-db) - Scalable Data Base (Some services use it)
   - [Watchtower](#watchtower) - Automated Docker container updates (All Servers)

8.  [Oracle Cloud Services ](#cloud-services) - These are complementary servers for implementing Zero Trust Security
   - [Pi-Hole](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md#pi-hole) - Adblocker - DNS Provider and DHCP Server
   - [PiVPN](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md#pivpn) - Wireguard VPN
   - [SearXNG](#searxng) - Metasearch Engine - used as public search engine
   - [Pangolin](https://pangolin.net/) - Identity-based remote access platform built on WireGuard that enables secure, seamless connectivity to private and public resources

9. [Bonus Information](#bonus-information)
   - [Backups scripts](#backup-scripts)
   - [Windows Tips & Tricks](#windows-tips-&-tricks)
## Architecture diagram

High level architecture:
![BOLEX-NET](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/Bolex-NET.png)

More detailed network infrastructure:
![BOLEX-NETWORK](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/BentomoNET-2025.png)


