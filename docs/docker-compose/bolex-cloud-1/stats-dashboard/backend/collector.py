#!/usr/bin/env python3
"""
Samantha's Fleet Collector — runs inside dashboard container on Nextcloud
Uses SSH config aliases for clean connections to all servers
Polls all servers every 60s, stores metrics in SQLite
"""
import json
import sqlite3
import subprocess
import sys
import time
import os
from datetime import datetime, timezone, timedelta

DB_PATH = os.environ.get("DB_PATH", "/data/metrics.db")
INTERVAL = 60

# Server configs using SSH config aliases from Nextcloud
# SSH config is mounted at /ssh-keys/config, identity files at /ssh-keys/
SERVERS = {
    "PiNet1":        {"alias": "pi-1"},
    "PiNet2":        {"alias": "pi-2"},
    "Bentomo_Net":   {"alias": "bentomo-net"},
    "Nextcloud":     {"alias": "nextcloud"},
    "OpenClaw":      {"alias": "openclaw-host"},
    "Bolex-Cloud-1": {"alias": "bc1"},
    "Bolex-Cloud-2": {"alias": "bc2"},
    "WSL2":          {"alias": "wsl"},
}

# For self-monitoring (Nextcloud local metrics)
SELF_CMD = r'''
UPTIME_SEC=$(cat /proc/uptime | awk '{print int($1)}')
UPTIME_HRS=$((UPTIME_SEC / 3600))
DISK_PCT=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
MEM_INFO=$(free | grep Mem)
MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
if [ "$MEM_TOTAL" -gt 0 ] 2>/dev/null; then
    MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
else
    MEM_PCT=0
fi
CPU_PCT=$(cat /proc/stat | head -1; sleep 1; cat /proc/stat | head -1 | awk '{print $2+$4, $2+$4+$5}')
CPU_PCT=$(echo "$CPU_PCT" | awk 'NR==1{u1=$1;t1=$2} NR==2{u2=$1;t2=$2; if(t2-t1>0) printf "%.0f", (u2-u1)*100/(t2-t1); else print 0}')
LOAD_1M=$(cat /proc/loadavg | awk '{print $1}')
DOCK_RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
DOCK_TOTAL=$(docker ps -a --format '{{.Names}}' 2>/dev/null | wc -l)
DOCK_UNHEALTHY=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v 'Listing...' | grep -c -v '^$')
echo "{\"uptime_hours\":$UPTIME_HRS,\"disk_pct\":$DISK_PCT,\"mem_pct\":$MEM_PCT,\"cpu_pct\":${CPU_PCT:-0},\"load_1m\":$LOAD_1M,\"docker_running\":$DOCK_RUNNING,\"docker_total\":$DOCK_TOTAL,\"docker_unhealthy\":\"$DOCK_UNHEALTHY\",\"updates\":$UPDATES}"
'''

REMOTE_CMD = r'''
UPTIME_SEC=$(cat /proc/uptime | awk '{print int($1)}')
UPTIME_HRS=$((UPTIME_SEC / 3600))
DISK_PCT=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
MEM_INFO=$(free | grep Mem)
MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
if [ "$MEM_TOTAL" -gt 0 ] 2>/dev/null; then
    MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
else
    MEM_PCT=0
fi
CPU_PCT=$(cat /proc/stat | head -1; sleep 1; cat /proc/stat | head -1 | awk '{print $2+$4, $2+$4+$5}')
CPU_PCT=$(echo "$CPU_PCT" | awk 'NR==1{u1=$1;t1=$2} NR==2{u2=$1;t2=$2; if(t2-t1>0) printf "%.0f", (u2-u1)*100/(t2-t1); else print 0}')
LOAD_1M=$(cat /proc/loadavg | awk '{print $1}')
DOCK_RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
DOCK_TOTAL=$(docker ps -a --format '{{.Names}}' 2>/dev/null | wc -l)
DOCK_UNHEALTHY=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
UPDATES=$(apt list --upgradable 2>/dev/null | grep -v 'Listing...' | grep -c -v '^$')
echo "{\"uptime_hours\":$UPTIME_HRS,\"disk_pct\":$DISK_PCT,\"mem_pct\":$MEM_PCT,\"cpu_pct\":${CPU_PCT:-0},\"load_1m\":$LOAD_1M,\"docker_running\":$DOCK_RUNNING,\"docker_total\":$DOCK_TOTAL,\"docker_unhealthy\":\"$DOCK_UNHEALTHY\",\"updates\":$UPDATES}"
'''


def ssh_exec(alias, cmd, timeout=15):
    """Execute command on remote server using SSH config alias"""
    args = [
        "ssh", "-F", "/ssh-keys/config",
        "-o", "StrictHostKeyChecking=no",
        "-o", f"ConnectTimeout={timeout}",
        alias, cmd
    ]
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout+5)
        if result.returncode == 0 and result.stdout.strip():
            for line in result.stdout.strip().split('\n'):
                line = line.strip()
                if line.startswith('{'):
                    return json.loads(line)
    except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception):
        pass
    return None


def local_exec(cmd):
    """Execute command locally (for self-monitoring)"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        if result.returncode == 0 and result.stdout.strip():
            for line in result.stdout.strip().split('\n'):
                line = line.strip()
                if line.startswith('{'):
                    return json.loads(line)
    except Exception:
        pass
    return None


def collect_all():
    """Collect metrics from all servers via SSH"""
    servers = {}
    for name, config in SERVERS.items():
        data = ssh_exec(config["alias"], REMOTE_CMD)
        if data:
            unhealthy = data.get("docker_unhealthy", "")
            data["docker_unhealthy"] = [x.strip() for x in unhealthy.split(",") if x.strip()]
            servers[name] = data
        else:
            servers[name] = {"offline": True}
    return servers


def store_metrics(servers, db_path=DB_PATH):
    """Store metrics in SQLite"""
    db = sqlite3.connect(db_path)
    ts = datetime.now(timezone.utc).isoformat()
    for server, data in servers.items():
        db.execute(
            "INSERT INTO metrics (timestamp, server, data) VALUES (?, ?, ?)",
            (ts, server, json.dumps(data))
        )
    cutoff = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
    db.execute("DELETE FROM metrics WHERE timestamp < ?", (cutoff,))
    db.commit()
    db.close()


def init_db(db_path=DB_PATH):
    """Initialize the SQLite database"""
    db = sqlite3.connect(db_path)
    db.execute("""
        CREATE TABLE IF NOT EXISTS metrics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            server TEXT NOT NULL,
            data TEXT NOT NULL
        )
    """)
    db.execute("CREATE INDEX IF NOT EXISTS idx_metrics_server_ts ON metrics(server, timestamp)")
    db.commit()
    db.close()


def main():
    print(f"🧚‍♀️ Fleet collector starting — polling {len(SERVERS)} servers every {INTERVAL}s", flush=True)
    init_db()
    while True:
        try:
            servers = collect_all()
            online = sum(1 for v in servers.values() if not v.get("offline"))
            store_metrics(servers)
            print(f"[{datetime.now(timezone.utc).isoformat()}] {online}/{len(servers)} servers online", flush=True)
        except Exception as e:
            print(f"[ERROR] {e}", file=sys.stderr, flush=True)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()