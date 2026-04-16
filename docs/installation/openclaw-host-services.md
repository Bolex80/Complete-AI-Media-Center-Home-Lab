# OpenClaw Host — AI Agent Gateway

This server runs the OpenClaw gateway — the AI agent platform that powers Samantha and Clawdio.

## Network Configuration

- **Hostname:** openclaw
- **IP Address:** 192.168.2.60
- **Architecture:** x86_64 (VMware virtual machine)
- **RAM:** 3.8 GB (1.0 GB used, 2.7 GB available)
- **Storage:** 96 GB LVM (12 GB used, 13% — healthy)
- **OS:** Ubuntu (VMware guest)

---

## What is OpenClaw?

OpenClaw is a self-hosted AI agent gateway that connects LLM models to messaging platforms (Telegram, Discord, web UI). It supports multiple agents, skills, memory, and tool execution.

**Key URLs:**
- Docs: https://docs.openclaw.ai
- Source: https://github.com/openclaw/openclaw
- Skills registry: https://clawhub.ai

---

## Services

### OpenClaw Gateway
**Description:** The core daemon that manages agent sessions, tool execution, and message routing.
**Installation:** npm global (`openclaw@2026.4.12`)
**Runtime:** Node.js v22.22.2
**Config:** `/home/clawdio/.openclaw/openclaw.json`
**Port:** 18789 (gateway API)

**Agents configured:**

| Agent | Model | Purpose |
|-------|-------|---------|
| Clawdio | ollama/minimax-m2.7:cloud | Default assistant |
| Samantha | ollama/glm-5.1:cloud | Coding/debugging specialist |

**Channels:**
- Telegram (primary)
- Web UI (Control UI)

**Key directories:**
- `/home/clawdio/.openclaw/` — Gateway config, credentials, media
- `/home/clawdio/.openclaw/workspace/` — Clawdio's workspace
- `/home/clawdio/.openclaw/workspace-samantha/` — Samantha's workspace
- `/home/clawdio/.openclaw/credentials/` — API keys, GitHub PAT
- `/home/clawdio/.openclaw/canvas/` — Web UI hosted embeds
- `/home/clawdio/.openclaw/cron/` — Scheduled tasks

### System Status Cron
**Description:** Daily health check script that pings all servers and sends a Telegram report.
**Schedule:** 07:00 UTC (09:00 Madrid) daily
**Script:** `/home/clawdio/.openclaw/workspace/scripts/system-status.sh`

**Monitors:**
- OpenClaw (192.168.2.60)
- PiNet1 (192.168.2.200)
- PiNet2 (192.168.2.205)
- Bentomo_Net (192.168.2.201)
- Nextcloud (192.168.2.210)

**Reports:** Disk usage, memory usage, uptime, pending OS updates, stopped containers

---

## Installation Reference

```bash
# Install Node.js (if not already)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install OpenClaw globally
npm install -g openclaw

# Initialize
openclaw init

# Configure gateway
openclaw gateway start
```

---

## SSH Access

```bash
ssh -i /home/clawdio/.ssh/clawdio_agent clawdio@192.168.2.60
```

---

## Key Files

| File | Purpose |
|------|---------|
| `openclaw.json` | Main configuration (agents, gateway, channels) |
| `workspace/SOUL.md` | Clawdio's personality |
| `workspace-samantha/SOUL.md` | Samantha's personality |
| `workspace/TOOLS.md` | Server inventory and SSH keys |
| `workspace/scripts/system-status.sh` | Daily health check |
| `credentials/github-netrc` | GitHub PAT for repo access |

---

## Maintenance

**Check gateway status:**
```bash
openclaw gateway status
```

**Restart gateway:**
```bash
openclaw gateway restart
```

**Update OpenClaw:**
```bash
npm update -g openclaw
openclaw gateway restart
```

**View logs:**
```bash
ls -la /home/clawdio/.openclaw/logs/
```