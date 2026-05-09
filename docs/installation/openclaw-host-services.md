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

| Agent | Primary Model | Fallback | Purpose | Location |
|-------|--------------|----------|---------|----------|
| Clawdio | **DeepSeek V4 Flash** (Ollama Cloud) | Kimi K2.6 | Default assistant, system monitoring, file ops, calendar, email, HA, TTS/STT | OpenClaw gateway |
| Samantha | **GLM 5.1** (Ollama Cloud) | Kimi K2.6 | Coding/debugging specialist, web app builder, security audit, fleet monitoring | OpenClaw gateway (separate agent) |
| HermesIO | **Kimi K2.6** (Ollama Cloud) | — | Orchestrator agent. Coordinates multi-agent workflows, maintains shared wiki, delegates tasks via HTTP message bus | WSL2 Docker container (nousresearch/hermes-agent) |
| Emilio | **Kimi K2.6** (Ollama Cloud) | Kimi K2.6 | Spanish-speaking assistant (Junell) | OpenClaw gateway |
| Junell | **DeepSeek V4 Flash** (Ollama Cloud) | Kimi K2.6 | General assistant for Junell | OpenClaw gateway |

**All fallbacks updated to Kimi K2.6** (Kimi K2.5 retired).

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

### ✅ Wiki Knowledge Base
**Description:** A SvelteKit-powered wiki frontend that renders markdown content from `/opt/data/wiki/`. Serves as the knowledge base for the Hermes agent and Samantha's documentation.

**Source:** [benthem-wiki](https://github.com/Bolex80/benthem-wiki)

**Features:**
- Markdown + YAML frontmatter pages
- [[wikilinks]] that resolve against actual file structure
- Client-side full-text search (Fuse.js)
- Dark theme with Tailwind CSS
- Shiki-powered syntax highlighting
- Docker deployment (multi-stage build)

**Wiki content structure:**
```
/opt/data/wiki/
├── index.md                    # Homepage
├── entities/                   # Agent, server, service pages
├── concepts/                   # Technical concept explanations
├── comparisons/                # Side-by-side comparisons
└── queries/                    # How-to guides and Q&A
```

**Deployment:**
```bash
# Clone
cd /opt
gh repo clone Bolex80/benthem-wiki

# Build and run with docker-compose
cd benthem-wiki
docker-compose up -d
```

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

## Agent Communication Protocol

The three agents (HermesIO, Clawdio, Samantha) communicate via an HTTP message bus:

**Architecture:**
- **HermesIO** runs as a Docker container on WSL2 with an autossh reverse tunnel to the OpenClaw host (port 18080)
- **Hermes** hosts a comm server on `0.0.0.0:18080` with GET `/messages` and POST `/message` endpoints
- **Clawdio** polls the bus every 15 minutes (cron job) and responds to delegations
- **Samantha** is relayed through Clawdio (Clawdio delegates tasks to Samantha's workspace)

**Protocol keys:**
- `GET /messages` — Read all messages on the bus
- `POST /message` — Send a message (fields: from, to, content, id)
- Messages are ID-suffixed for ACK tracking
- HermesIO orchestrates; Clawdio relays to Samantha as needed

**Shared Wiki:**
All agents contribute to a shared markdown wiki at `/opt/data/wiki/` (on Hermes container, synced to `~/.hermes/wiki/` on WSL host). The wiki frontend renders this content via the benthem-wiki SvelteKit app.

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