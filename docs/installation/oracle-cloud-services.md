# Oracle Cloud Services

These services run on Oracle Cloud Infrastructure (OCI) free tier instances to provide Zero Trust security and offsite redundancy.

## Infrastructure

### Instance 1
- **Type:** VM.Standard.A1.Flex (Ampere Altra processor)
- **Specs:** 2 Cores, 16GB RAM
- **OS:** Ubuntu Server
- **Purpose:** Primary cloud services

### Instance 2
- **Type:** VM.Standard.A1.Flex (Ampere Altra processor)
- **Specs:** 2 Cores, 8GB RAM
- **OS:** Ubuntu Server
- **Purpose:** Secondary/backup services

## Network Architecture

The Oracle Cloud instances provide:
1. **Zero Trust Access**: Services not directly exposed to internet
2. **Pangolin Tunnel**: Secure WireGuard-based access to home services
3. **CrowdSec Monitoring**: Collective security intelligence
4. **Public DNS**: PiHole accessible from anywhere via Pangolin

## Services Overview

### Pi-Hole (Cloud)
**Description:** DNS sinkhole and ad blocker.
**Purpose:** Ad blocking and DNS resolution when away from home.
**Port:** 53 (DNS)
**Configuration:** See [Raspberry Pi PiHole guide](../raspberry-pi-services.md#pi-hole)

**Key Differences from On-Prem:**
- Configured for public access through Pangolin
- Restricted query logging for privacy
- Synced blocklists with home instances

---

### PiVPN (Cloud)
**Description:** WireGuard VPN server.
**Purpose:** Secure connection to home network when traveling.
**Port:** 51820/UDP
**Configuration:** See [Raspberry Pi PiVPN guide](../raspberry-pi-services.md#pivpn)

**Key Features:**
- Split tunneling available
- QR code generation for mobile clients
- Pre-shared key support
- Client management via CLI

---

### SearXNG (Cloud)
**Description:** Public metasearch engine instance.
**Purpose:** Search without tracking from any device.
**Port:** 8080 (internal)
**Configuration:** [docker-compose.yml](../docker-compose/searxng/docker-compose.yml)

**Public Access:**
- Exposed via Pangolin with domain authentication
- Rate limited for abuse prevention
- No persistent search history

---

### Pangolin
**Description:** Identity-based remote access platform.
**Purpose:** Secure, seamless connectivity to private resources without VPN.
**Website:** https://pangolin.net/

**Key Features:**
- Built on WireGuard
- Identity-based access control
- No port forwarding required
- Audit logging
- Supports multiple resource types (HTTP, TCP, UDP)

**Architecture:**
```
[User] --> [Pangolin Server (Oracle Cloud)] --> [Pangolin Client (Home)] --> [Internal Services]
```

**Configuration:**
1. Install Pangolin server on Oracle Cloud
2. Install Pangolin client on home network (behind firewall)
3. Configure resources in Pangolin dashboard
4. Share access with users via identity provider

---

### CrowdSec
**Description:** Crowdsourced intrusion prevention system.
**Purpose:** Detect and block malicious IPs across all infrastructure.
**Website:** https://www.crowdsec.net/

**Key Features:**
- Real-time threat detection
- Community-based intelligence
- Multi-server synchronization
- Automatic remediation (ban actions)
- Works with firewalls and reverse proxies

**Architecture:**
```
[All Servers] --> [Local API] --> [Central API] --> [CrowdSec Community]
```

**Setup Overview:**
1. Install CrowdSec agent on each server
2. Configure parsers and scenarios
3. Connect to local API (on Oracle Cloud)
4. Share signals with CrowdSec community
5. Configure remediation (firewall, Nginx bouncer, etc.)

---

## Security Configuration

### Firewall Rules (Oracle Cloud Security Lists)

**Ingress:**
- 22/TCP (SSH) - Restricted to your IP
- 80/TCP (HTTP) - For Let's Encrypt/redirects
- 443/TCP (HTTPS) - For Pangolin/web services
- 51820/UDP (WireGuard) - For PiVPN

**Egress:**
- Allow all (for updates, API calls, etc.)

### SSH Hardening

```bash
# Edit /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

### Fail2Ban

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Configure /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

---

## Deployment Guide

### Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Create shared network
docker network create bolex-net

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 51820/udp
sudo ufw enable
```

### Pangolin Installation

```bash
# Download and install Pangolin
wget https://github.com/fosrl/pangolin/releases/latest/download/pangolin-linux-amd64
sudo mv pangolin-linux-amd64 /usr/local/bin/pangolin
sudo chmod +x /usr/local/bin/pangolin

# Generate config
sudo pangolin config generate

# Edit configuration
sudo nano /etc/pangolin/config.yml

# Start Pangolin
sudo systemctl enable pangolin
sudo systemctl start pangolin
```

### CrowdSec Installation

```bash
# Install CrowdSec
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt install -y crowdsec

# Install bouncers
sudo apt install -y crowdsec-firewall-bouncer-iptables

# Register to Central API
sudo cscli console enroll YOUR_ENROLLMENT_KEY

# Start CrowdSec
sudo systemctl enable crowdsec
sudo systemctl start crowdsec
```

---

## High Availability

### Synchronization Strategy

**PiHole:**
- Use Gravity Sync to sync between Oracle Cloud and home instances
- Configured as secondary/tertiary DNS

**CrowdSec:**
- Multi-server setup with centralized local API
- Decisions propagated across all agents

### Backup Considerations

**Critical Data:**
- Pangolin configuration
- CrowdSec decisions and configurations
- PiHole custom blocklists and local DNS
- PiVPN client configurations

**Backup Script:**
```bash
#!/bin/bash
BACKUP_DIR="/backups/oracle-cloud/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup Pangolin config
tar czf "$BACKUP_DIR/pangolin.tar.gz" /etc/pangolin

# Backup CrowdSec
cscli backup "$BACKUP_DIR/crowdsec-backup.tar.gz"

# Backup PiHole (if running)
docker exec pihole pihole -a -t > "$BACKUP_DIR/pihole-backup.tar.gz"
```

---

## Monitoring

### Uptime Kuma (Optional)

Monitor Oracle Cloud instances from home:

```yaml
# Add to home Uptime Kuma
monitors:
  - name: "Oracle Cloud Instance 1"
    type: ping
    hostname: "oracle-instance-1-ip"
  - name: "Oracle Cloud Instance 2"
    type: ping
    hostname: "oracle-instance-2-ip"
  - name: "Pangolin"
    type: http
    url: "https://pangolin.yourdomain.com"
```

---

## Troubleshooting

### Pangolin Connection Issues

1. Verify WireGuard kernel module: `sudo modprobe wireguard`
2. Check Pangolin logs: `sudo journalctl -u pangolin -f`
3. Verify firewall rules allow traffic
4. Check resource access policies

### CrowdSec False Positives

1. Check decisions: `sudo cscli decisions list`
2. Add whitelists for trusted IPs
3. Review acquisition configuration
4. Disable specific scenarios if needed

### High Memory Usage

Oracle Cloud free tier has limited resources:
1. Monitor with `htop` or `free -h`
2. Adjust service limits
3. Consider swapping to disk if needed
4. Scale down to fewer services per instance

---

## Cost Considerations

Oracle Cloud free tier includes:
- 2 AMD-based Compute VMs (1/8 OCPU, 1 GB RAM each)
- 4 ARM-based Ampere A1 cores and 24 GB of memory
- 200 GB block storage

**Tips:**
- Use ARM instances for better resource allocation
- Monitor always-free resource usage
- Set up billing alerts
- Consider reserved capacity if upgrading
