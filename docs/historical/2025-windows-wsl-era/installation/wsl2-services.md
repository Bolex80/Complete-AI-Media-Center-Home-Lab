# Services on WSL2 - Docker Desktop

These services are running on Windows Subsystem for Linux (WSL2) with Docker Desktop. They require higher CPU and GPU resources and are isolated from the main Windows environment for better performance and resource management.

## Prerequisites

1. **WSL2** installed and configured
2. **Docker Desktop** with WSL2 backend enabled
3. **NVIDIA GPU support** (for AI services):
   - NVIDIA drivers installed on Windows
   - CUDA toolkit configured in WSL2
4. **Shared Docker network** (`bolex-net`) created:
   ```bash
   docker network create bolex-net
   ```

## Services Overview

### Ollama
**Description:** Self-hosted Large Language Models (LLMs) runner with GPU acceleration support.
**Purpose:** Local AI inference engine for running models like Llama, Mistral, etc.
**Port:** 11434
**Configuration:** [docker-compose.yml](./docker-compose/ollama/docker-compose.yml)

**Key Features:**
- GPU acceleration via NVIDIA runtime
- Parallel model loading support
- REST API for model inference
- Persistent model storage

**Notes:**
- Models are stored in `./ollama_data` volume
- Environment variables control parallel execution and timeout settings
- Requires NVIDIA Container Toolkit

---

### Open WebUI
**Description:** User-friendly web interface for interacting with Ollama and other LLM backends.
**Purpose:** Web-based chat interface with support for multiple AI providers.
**Port:** 4000
**Configuration:** [docker-compose.yml](./docker-compose/open-webui/docker-compose.yml)

**Key Features:**
- Chat interface for Ollama models
- Integration with LiteLLM for multiple provider support
- TTS (Text-to-Speech) support
- Document processing via Apache Tika

**Environment Variables to Configure:**
- `OPENAI_API_KEY`: Your API key for OpenAI-compatible endpoints
- `TTS_API_KEY`: API key for text-to-speech service

---

### Postgres
**Description:** PostgreSQL database server for application data persistence.
**Purpose:** Centralized database for N8N, LiteLLM, and other services requiring SQL storage.
**Port:** 5432
**Configuration:** [docker-compose.yml](./docker-compose/postgres/docker-compose.yml)

**Key Features:**
- Multiple database support via init script
- Health checks enabled
- Persistent volume storage

**Setup:**
1. Create `init-multiple-databases.sh` script for multiple DB creation
2. Configure environment variables in `.env` file
3. Default databases: `litellm`, `n8n`

---

### LiteLLM
**Description:** Universal API interface for 100+ LLMs. Provides a unified OpenAI-compatible API.
**Purpose:** Proxy and manage multiple AI providers (OpenAI, Anthropic, Azure, local models, etc.).
**Port:** 4001 (mapped to container 4000)
**Configuration:** [docker-compose.yml](./docker-compose/litellm/docker-compose.yml)

**Key Features:**
- Single API key for multiple providers
- Rate limiting and budget management
- Request logging and monitoring (Prometheus included)
- Model fallback and load balancing

**Prerequisites:**
1. Create `proxy_server_config.yaml` with your model configurations
2. Create `.env` file with:
   - `POSTGRES_USER`
   - `POSTGRES_PASSWORD`
   - `LITELLM_MASTER_KEY`

---

### Immich
**Description:** Self-hosted photo and video backup solution with AI-powered features.
**Purpose:** Personal photo library with facial recognition, object detection, and GPU-accelerated transcoding.
**Port:** 2283
**Configuration:** [docker-compose.yml](./docker-compose/immich/docker-compose.yml)

**Key Features:**
- GPU-accelerated video transcoding (NVENC)
- Machine learning for facial recognition
- External library support (read-only mounts)
- Album auto-creation from folder structure

**Prerequisites:**
1. Configure `.env` file with:
   - `IMMICH_VERSION`
   - `UPLOAD_LOCATION`
   - `DB_PASSWORD`
   - `DB_USERNAME`
   - `DB_DATABASE_NAME`
   - `DB_DATA_LOCATION`
   - `MACHINE_LEARNING_MODEL_TTL`

2. Update volume mounts to match your photo storage paths

**External Libraries:**
- Update the paths in `volumes:` section to point to your photo directories
- These are mounted read-only (`:ro`) for safety

---

### N8N
**Description:** Workflow automation tool with AI integration capabilities.
**Purpose:** Automate tasks and create AI-powered workflows with visual node-based editor.
**Port:** 5678
**Configuration:** [docker-compose.yml](./docker-compose/n8n/docker-compose.yml)

**Key Features:**
- Visual workflow builder
- Integration with PostgreSQL for persistence
- External node modules support (axios, qs)
- Backup and shared data volumes

**Environment Variables:**
- `POSTGRES_USER` / `POSTGRES_PASSWORD`: Database credentials
- `N8N_ENCRYPTION_KEY`: Encryption key for sensitive data
- `N8N_USER_MANAGEMENT_JWT_SECRET`: JWT secret for authentication

---

### Qdrant
**Description:** Vector database for AI applications and semantic search.
**Purpose:** Store and search vector embeddings for RAG (Retrieval-Augmented Generation) workflows.
**Port:** 6333 (REST API), 6334 (gRPC)
**Configuration:** [docker-compose.yml](./docker-compose/qdrant/docker-compose.yml)

**Key Features:**
- High-performance vector search
- Payload filtering
- Horizontal scaling support

---

### Apache Tika
**Description:** Content analysis toolkit for extracting text and metadata from documents.
**Purpose:** Document processing for Open WebUI and other AI applications.
**Port:** 9998
**Configuration:** [docker-compose.yml](./docker-compose/tika/docker-compose.yml)

**Key Features:**
- Extracts text from PDF, Word, Excel, and many other formats
- Metadata extraction
- OCR support for images

---

### LibreTranslate
**Description:** Free and Open Source Machine Translation API.
**Purpose:** Self-hosted translation service supporting multiple languages.
**Port:** 5000
**Configuration:** [docker-compose.yml](./docker-compose/libretranslate/docker-compose.yml)

**Key Features:**
- GPU acceleration support (CUDA version)
- Multiple language support
- API key management
- Configurable rate limiting

**Languages Configured:** Spanish, English, French, German, Dutch, Italian, Polish, Portuguese, Russian
**Loaded Languages:** English, Spanish, Italian (for faster startup)

---

### MeTube
**Description:** Web-based YouTube video and music downloader.
**Purpose:** Download YouTube videos and audio for offline viewing/listening.
**Port:** 8081
**Configuration:** [docker-compose.yml](./docker-compose/metube/docker-compose.yml)

**Key Features:**
- Web UI for yt-dlp
- Cookie support for authenticated downloads
- Path configuration for download location

**Setup:**
1. Create download directory: `/path/to/downloads`
2. Create cookies directory with `cookies.txt` (export from browser)
3. Update volume paths in compose file

---

## Common Configuration

### Environment Variables File (.env)

Create a `.env` file in your WSL2 home directory with the following variables:

```bash
# PostgreSQL
POSTGRES_USER=your_postgres_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_MULTIPLE_DATABASES=litellm,n8n

# Immich
IMMICH_VERSION=release
UPLOAD_LOCATION=/path/to/immich/upload
DB_PASSWORD=your_db_password
DB_USERNAME=your_db_user
DB_DATABASE_NAME=immich
DB_DATA_LOCATION=/path/to/postgres/data
MACHINE_LEARNING_MODEL_TTL=600

# LiteLLM
LITELLM_MASTER_KEY=your_master_key_here

# N8N
N8N_ENCRYPTION_KEY=your_encryption_key
N8N_USER_MANAGEMENT_JWT_SECRET=your_jwt_secret

# Open WebUI / TTS
TTS_API_KEY=your_tts_api_key
```

### Docker Network

All services share the `bolex-net` network. Create it once:

```bash
docker network create bolex-net
```

### Starting Services

To start all WSL2 services:

```bash
cd ~/Complete-AI-Media-Center-Home-Lab/docs/docker-compose/wsl2-docker-desktop

# Start individual services
docker-compose -f ollama/docker-compose.yml up -d
docker-compose -f postgres/docker-compose.yml up -d
docker-compose -f litellm/docker-compose.yml up -d
# ... etc

# Or create a master compose file to start all at once
```

### GPU Support

Ensure NVIDIA Container Toolkit is installed:

```bash
# Install nvidia-container-toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker
```

---

## Backup Considerations

**Critical Data to Backup:**
- `./ollama_data` - Downloaded models
- `./postgres_storage` - All database content
- `./n8n_storage` - Workflow configurations
- `./open-webui-data` - Chat history and settings
- `./qdrant_data` - Vector embeddings
- Immich upload directories

**Backup Script Example:**
```bash
#!/bin/bash
BACKUP_DIR="/mnt/d/Backups/WSL2/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Stop services
docker-compose down

# Copy data directories
cp -r ./ollama_data "$BACKUP_DIR/"
cp -r ./postgres_storage "$BACKUP_DIR/"
# ... etc

# Restart services
docker-compose up -d
```

---

## Troubleshooting

### GPU Not Detected
1. Check NVIDIA drivers on Windows: `nvidia-smi` in PowerShell
2. Check in WSL2: `nvidia-smi`
3. Verify Docker runtime: `docker info | grep -i nvidia`

### Out of Memory
- Reduce `OLLAMA_NUM_PARALLEL` and `OLLAMA_MAX_LOADED_MODELS`
- Adjust Immich machine learning workers
- Monitor with `nvidia-smi` and `htop`

### Database Connection Errors
- Ensure PostgreSQL is started before dependent services
- Check network connectivity: `docker network inspect bolex-net`
- Verify credentials in `.env` file

### Port Conflicts
- Check for conflicts with Windows services
- Use `netstat -an | findstr :PORT` on Windows
- Modify port mappings in compose files if needed
