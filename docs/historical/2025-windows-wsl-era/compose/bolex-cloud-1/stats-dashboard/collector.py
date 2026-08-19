#!/usr/bin/env python3
"""
Samantha's Stats Collector — runs on OpenClaw host
Polls all 8 servers via SSH every 60s, pushes to dashboard API
"""
import json
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone

# Config
API_URL = "http://79.72.49.182:8883/api/push"
API_KEY = "changeme"  # Must match dashboard's API_KEY env var
INTERVAL = 60  # seconds

# SSH configs
SSH_KEY = "/home/clawdio/.ssh/clawdio_agent"
ORACLE_KEY1 = "/home/clawdio/.ssh/Bolex-Cloud-1-Private-2025-12-09.key"
ORACLE_KEY2 = "/home/clawdio/.ssh/Bolex-Cloud-2-Private.key"

SERVERS = {
    "PiNet1":        {"ip": "192.168.2.200", "user": "clawdio", "key": SSH_KEY},
    "PiNet2":        {"ip": "192.168.2.205", "user": "clawdio", "key": SSH_KEY},
    "Bentomo_Net":   {"ip": "192.168.2.201", "user": "clawdio", "key": SSH_KEY},
    "Nextcloud":     {"ip": "192.168.2.210", "user": "clawdio", "key": SSH_KEY},
    "OpenClaw":      {"ip": "192.168.2.60",  "user": "clawdio", "key": SSH_KEY},
    "Bolex-Cloud-1": {"ip": "79.72.49.182",  "user": "alex", "key": ORACLE_KEY1},
    "Bolex-Cloud-2": {"ip": "130.110.233.63","user": "alex", "key": ORACLE_KEY2},
}

WSL2 = {"ip": "localhost", "port": "2222", "user": "alex", "key": SSH_KEY}

REMOTE_CMD = r'''
UPTIME_SEC=$(cat /proc/uptime | awk '{print int($1)}')
UPTIME_HRS=$((UPTIME_SEC / 3600))
DISK_PCT=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
MEM_PCT=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')
CPU_PCT=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", 100-$8}' | sed 's/\.//g')
LOAD_1M=$(cat /proc/loadavg | awk '{print $1}')
DOCK_RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
DOCK_TOTAL=$(docker ps -a --format '{{.Names}}' 2>/dev/null | wc -l)
DOCK_UNHEALTHY=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v 'Listing...' | grep -c -v '^$')
echo "{\"uptime_hours\":$UPTIME_HRS,\"disk_pct\":$DISK_PCT,\"mem_pct\":$MEM_PCT,\"cpu_pct\":${CPU_PCT:-0},\"load_1m\":$LOAD_1M,\"docker_running\":$DOCK_RUNNING,\"docker_total\":$DOCK_TOTAL,\"docker_unhealthy\":\"$DOCK_UNHEALTHY\",\"updates\":$UPDATES}"
'''


def ssh_exec(server_config, cmd, timeout=10):
    """Execute command on remote server via SSH"""
    args = [
        "ssh", "-o", "StrictHostKeyChecking=no",
        "-o", f"ConnectTimeout={timeout}",
        "-i", server_config["key"],
    ]
    if "port" in server_config:
        args += ["-p", server_config["port"]]
    args += [f"{server_config['user']}@{server_config['ip']}", cmd]

    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout+5)
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout.strip())
    except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception) as e:
        pass
    return None


def collect_all():
    """Collect metrics from all servers"""
    servers = {}

    # Local + Oracle servers
    for name, config in SERVERS.items():
        data = ssh_exec(config, REMOTE_CMD)
        if data:
            # Parse unhealthy list
            unhealthy = data.get("docker_unhealthy", "")
            data["docker_unhealthy"] = [x.strip() for x in unhealthy.split(",") if x.strip()]
            servers[name] = data
        else:
            servers[name] = {"offline": True}

    # WSL2 (via reverse tunnel)
    wsl2_data = ssh_exec(WSL2, REMOTE_CMD)
    if wsl2_data:
        unhealthy = wsl2_data.get("docker_unhealthy", "")
        wsl2_data["docker_unhealthy"] = [x.strip() for x in unhealthy.split(",") if x.strip()]
        servers["WSL2"] = wsl2_data
    else:
        servers["WSL2"] = {"offline": True}

    return servers


def push_metrics(servers):
    """Push metrics to the dashboard API"""
    payload = {
        "api_key": API_KEY,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "servers": servers,
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.status == 200
    except Exception as e:
        print(f"[ERROR] Push failed: {e}", file=sys.stderr)
        return False


def main():
    print(f"🧚‍♀️ Stats collector starting — pushing to {API_URL} every {INTERVAL}s")
    while True:
        try:
            servers = collect_all()
            online = sum(1 for v in servers.values() if not v.get("offline"))
            print(f"[{datetime.utcnow().isoformat()}] Collected: {online}/{len(servers)} servers online")
            push_metrics(servers)
        except Exception as e:
            print(f"[ERROR] Collection failed: {e}", file=sys.stderr)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()