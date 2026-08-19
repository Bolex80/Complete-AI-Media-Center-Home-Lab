# Changelog

| Date | Milestone |
|------|-----------|
| 2009 | Project begins with Windows Media Center |
| 2010s | XBMC → Kodi → Plex evolution |
| 2024–2025 | Layered Windows 11 / Hyper-V / VMware / WSL2 / Proxmox stack reaches full complexity |
| 2026-04-24 | Hermes Agent, Benthem Wiki, and Honcho memory layer established |
| 2026-04-27 | Primary model switches to `deepseek-v4-flash` |
| 2026-05-08 | Wiki established; `kimi-k2.6` tested |
| 2026-05-13 | OpenRouter fallback (`nemotron-3-super-120b`) configured |
| 2026-06-06 | Primary model switches to `kimi-k2.6:cloud`; SSH to BOLEX moves to port 2222 |
| 2026-06-07 | Bidirectional agent comms v3 (NDJSON file protocol) deployed |
| 2026-06-12 | **Major migration**: Hermes/Honcho/Wiki/Bridge/Direct Comm move from WSL2 Docker to native systemd on `ai-agents` (192.168.2.60) |
| 2026-06-13 | Primary model upgraded to `kimi-k2.7-code:cloud` |
| 2026-06-15 | Nesquena WebUI migrated to native systemd |
| 2026-06-17 | Host/VM renamed from `openclaw` to `ai-agents`; user from `clawdio` to `alex` |
| 2026-06-22 | Local fallback `gemma4:e4b-128k` added; Honcho embeddings regenerated |
| 2026-08-01 | Oracle Cloud consolidated to single `bolex-cloud` VPS |
| 2026-08-10 | **BOLEX main server migrated from Windows 11 to Proxmox VE + ZFS** |
| 2026-08-15 | Immich external libraries moved to `tank-media/Pictures`; real-time backup watcher activated |
| 2026-08-17 | Nextcloud AIO moved to VM 101 (192.168.2.70); backup timers formalized; MeTube verified on LXC 203 |
| 2026-08-18 | OneDrive ↔ `tank-fast/documents` rclone bisync implemented on LXC 214 |
| 2026-08-19 | GitHub repo restructured into current + historical tracks; wiki corrected (`ai-agents` = VM 105, model stack, Pangolin/NPMPlus topology) |
