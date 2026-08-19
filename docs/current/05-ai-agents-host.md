# ai-agents Host

`ai-agents` is **VM 105** on the Bolex Proxmox host (`192.168.2.5`), reachable at `192.168.2.60`. It runs the Benthem multi-agent stack as native systemd services.

## Core services

| Service | systemd unit | Port | Purpose |
|---------|--------------|------|---------|
| Hermes Gateway | `hermes-gateway.service` | Telegram | Main chat interface |
| Hermes Bridge API | `hermes-bridge-api.service` | `8644` | Wiki proxy, cross-workspace conclusions |
| Direct Comm Server | `direct_comm_server.py` | `18080` | Inter-agent HTTP messaging |
| Honcho API | `honcho-api.service` | `8000` | Shared memory layer |
| Honcho Deriver | `honcho-deriver.service` | internal | Background reasoning worker |
| Wiki Frontend | `wiki-frontend.service` | `3000` | Benthem LLM Wiki |
| Nesquena WebUI | `nesquena.service` | `8787` | Hermes WebUI gateway |

## Agents

| Agent | Honcho workspace | Role | Primary model |
|-------|------------------|------|---------------|
| Hermes | `hermes` | Orchestrator / main conversational interface | `deepseek-v4-flash:cloud` |
| Clawdio | `openclaw` | Executor / right-hand agent | `kimi-k2.7-code:cloud` |
| Samantha | `openclaw` | Coding / server management (via Clawdio relay) | `glm-5.1:cloud` |
| Emilio | `openclaw` | Spanish legal/fiscal advisor | `deepseek-v4-flash:cloud` |
| Junell | `openclaw` | Personal assistant for Junell | `deepseek-v4-flash:cloud` |

## Important paths

| Path | Purpose |
|------|---------|
| `~/hermes_data/` | Hermes home (`.env`, `config.yaml`, sessions, logs) |
| `~/hermes_data/skills/` | Installed procedural skills |
| `~/hermes_data/wiki/` | Benthem LLM Wiki markdown source |
| `~/hermes_data/credentials/` | API keys and credentials |
| `~/hermes_data/scripts/` | Cron scripts and utilities |
| `~/.openclaw/workspace/` | Clawdio workspace |
| `~/.openclaw/workspace-samantha/` | Samantha workspace |

## Model stack (Hermes)

1. **Primary:** `deepseek-v4-flash:cloud` (Ollama Cloud)
2. **Fallback 1:** `kimi-k2.7-code:cloud` (Ollama Cloud)
3. **Fallback 2:** `gemma4:e4b-128k` (ollama-local on GPU VM `.30`)

## Management

```bash
# Service status
systemctl --user status hermes-gateway.service
systemctl status honcho-api.service
systemctl status wiki-frontend.service

# Logs
journalctl -u hermes-gateway.service -f
journalctl -u honcho-api.service -f

# Restart gateway
systemctl --user restart hermes-gateway.service
```

## Naming convention

| Name | Meaning |
|------|---------|
| `ai-agents` | The VM / current hostname |
| `192.168.2.60` | The IP address |
| `OpenClaw` | **Only** the legacy Clawdio/Samantha Honcho workspace |
| `clawdio` | **Only** historical paths/usernames |

## Related

- [Benthem Wiki — ai-agents entity](https://wiki.benthem.es/entities/ai-agents)
- [Benthem Wiki — Hermes Agent](https://wiki.benthem.es/entities/hermes-agent)
- [Benthem Wiki — Model configuration](https://wiki.benthem.es/concepts/model-configuration)
- [Benthem Wiki — Agent hierarchy](https://wiki.benthem.es/concepts/agent-hierarchy)
