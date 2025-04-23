# **COMPLETE AI MEDIA CENTER HOME LAB**

![BOLEX-Intro image](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/intro.png)


## Introduction and overview
I would like to provide an overview on how I have deployed and manage my homelab services in my main server.

Contrary to everyone's home server I am running it completly different and for very specific reasons.

My project begun back in 2009 with Windows Media Center, then it progressed to XBCM, then Kodi, then `PLEX` and from there on... with many hardware updates, it became my cloud instance, my photo library, my AI GPT, my DNS server, my VPN client, my password manager, etc... 

The ultimate goal is with a modest spec-like server and a couple of Raspbery Pi's. Have a complete professional setup that can handle all my needs.

## Quick start guide
...

## Hardware specs

### Complementary Servers 🤖
- Raspberry Pi4 with 2GB running [Wireguard with PiVPN](https://www.pivpn.io/) and [PiHole](https://pi-hole.net/) as well as serving as backup Search engine ([SearXNG](https://github.com/searxng/searxng)) and Password Vault ([Vaultwarden](https://github.com/dani-garcia/vaultwarden)).
- Secondary backup Rasberry Pi 4 - Same specs and I do weekly SD Card backups. 


### Main Server 🖥️
- AMD Ryzen 9 5900X
- 64 GB RAM
- GPU0: NVIDIA RTX 4060ti 16GB VRAM
- GPU1: NVIDIA GTX 1650 4GB VRAM
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


## Services Overview

1. [Services on the Raspberry Pi (bare-metal)](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/docs/installation/raspberry-pi-services.md)
   - [Pi-Hole](#pi-hole) - Adblocker - DNS Provider and DHCP Server
   - [PiVPN](#pivpn) - Wireguard VPN
   - [Keepalived](#keepalived) - High Availability Backup Server
   - [Rpi Monitor](#rpi-monitor) - Monitoring Stats for the Raspberry Pi
2. [Services on the Raspberry Pi with Docker](#services-on-the-raspberry-pi-with-docker)
   - [Cloudflare DDNS](#cloudflare-ddns) - Public IP DDNS updater for Cloudflare
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
   - [Ollama](#Ollama) - Large Language Model 
   - [Open WebUI](#open-webui) - web interface for AI Models
   - [Immich](#immich) - Photo & Video Management App
   - [MeTube](#metube) - Youtube Video & Music Downloadar
   - [N8N](#n8n) - AI Workflow Automation
   - [Qdrant](#qdrant) - Vector Database
   - [Apache Tika](#apache-tika) - Text and Metadata extractor
   - [Libre Translate](#libre-translate) - AI Translator

7. [Common services](#common-services) - These are docker containers that are used in all/most machines.
   - [Portainer](#portainer) - Docker Management interface (All Servers)
   - [Redis DB](#redis-db) - Scalable Data Base (Some services use it)
   - [Watchtower](#watchtower) - Automated Docker container updates (All Servers)

8. [Bonus Information](#bonus-information)

## Architecture diagram

![BOLEX-NETWORK](https://github.com/Bolex80/Complete-AI-Media-Center-Home-Lab/blob/main/images/BentomoNET-2025.png)


## Prerequisites
