"""
Samantha's Stats Dashboard — FastAPI Backend
Receives metrics pushes from the collector, stores in SQLite, serves API
"""
import os
import json
import sqlite3
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional

DB_PATH = os.environ.get("DB_PATH", "/data/metrics.db")
API_KEY = os.environ.get("API_KEY", "changeme")

app = FastAPI(title="Fleet Stats Dashboard", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Database ---
def get_db():
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    return db

def init_db():
    db = get_db()
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

init_db()

# --- Models ---
class MetricPush(BaseModel):
    api_key: str
    timestamp: str
    servers: dict  # {"PiNet1": {...}, "OpenClaw": {...}, ...}

class ServerMetrics(BaseModel):
    uptime_hours: float = 0
    disk_pct: float = 0
    mem_pct: float = 0
    cpu_pct: float = 0
    load_1m: float = 0
    docker_running: int = 0
    docker_total: int = 0
    docker_unhealthy: list = []
    updates: int = 0
    update_list: list = []

# --- API ---

@app.post("/api/push")
async def push_metrics(payload: MetricPush):
    if payload.api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    db = get_db()
    ts = payload.timestamp
    for server, data in payload.servers.items():
        db.execute(
            "INSERT INTO metrics (timestamp, server, data) VALUES (?, ?, ?)",
            (ts, server, json.dumps(data))
        )
    
    # Keep only last 7 days of data
    cutoff = (datetime.utcnow() - timedelta(days=7)).isoformat()
    db.execute("DELETE FROM metrics WHERE timestamp < ?", (cutoff,))
    db.commit()
    db.close()
    
    return {"status": "ok", "servers": len(payload.servers)}

@app.get("/api/latest")
async def get_latest():
    db = get_db()
    rows = db.execute("""
        SELECT m.server, m.timestamp, m.data
        FROM metrics m
        INNER JOIN (
            SELECT server, MAX(timestamp) as ts
            FROM metrics
            GROUP BY server
        ) latest ON m.server = latest.server AND m.timestamp = latest.ts
    """).fetchall()
    db.close()
    
    result = {}
    for row in rows:
        result[row["server"]] = {
            "timestamp": row["timestamp"],
            "data": json.loads(row["data"])
        }
    return result

@app.get("/api/history/{server}")
async def get_history(server: str, hours: int = 24):
    since = (datetime.utcnow() - timedelta(hours=hours)).isoformat()
    db = get_db()
    rows = db.execute(
        "SELECT timestamp, data FROM metrics WHERE server = ? AND timestamp > ? ORDER BY timestamp",
        (server, since)
    ).fetchall()
    db.close()
    
    return [{"timestamp": r["timestamp"], **json.loads(r["data"])} for r in rows]

@app.get("/api/servers")
async def list_servers():
    db = get_db()
    rows = db.execute(
        "SELECT DISTINCT server FROM metrics ORDER BY server"
    ).fetchall()
    db.close()
    return [r["server"] for r in rows]

# --- Frontend ---
@app.get("/")
async def serve_index():
    return FileResponse("/app/frontend/index.html")

@app.get("/{path:path}")
async def serve_static(path: str):
    filepath = f"/app/frontend/{path}"
    if os.path.isfile(filepath):
        return FileResponse(filepath)
    raise HTTPException(404)