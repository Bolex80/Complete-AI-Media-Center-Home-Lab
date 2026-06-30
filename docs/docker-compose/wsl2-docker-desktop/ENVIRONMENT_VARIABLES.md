# Environment Variables Template

This directory contains templates for environment variables used across the WSL2 Docker Desktop services.

## Main Environment File (.env)

Create a `.env` file in the root of your WSL2 home directory (`~/bolex-ai/.env`):

```bash
# ========================================
# PostgreSQL Configuration
# ========================================
POSTGRES_USER=your_postgres_username
POSTGRES_PASSWORD=YOUR_SECURE_POSTGRES_PASSWORD
POSTGRES_DB=n8n

# ========================================
# N8N Configuration
# ========================================
N8N_ENCRYPTION_KEY=YOUR_N8N_ENCRYPTION_KEY_HERE
N8N_USER_MANAGEMENT_JWT_SECRET=YOUR_JWT_SECRET_HERE
```

## Service-Specific Environment Files

### 1. PostgreSQL (`postgres/.env`)

```bash
POSTGRES_USER=your_postgres_username
POSTGRES_PASSWORD=YOUR_SECURE_POSTGRES_PASSWORD
POSTGRES_MULTIPLE_DATABASES=n8n,litellm
POSTGRES_DB=postgres
```

**Note:** The `init-multiple-databases.sh` script uses `POSTGRES_MULTIPLE_DATABASES` to create multiple databases on first startup.

---

### 2. N8N (`n8n/.env`)

```bash
# PostgreSQL Connection
POSTGRES_USER=your_postgres_username
POSTGRES_PASSWORD=YOUR_SECURE_POSTGRES_PASSWORD

# Authentication (Generate strong random keys)
N8N_ENCRYPTION_KEY=YOUR_N8N_ENCRYPTION_KEY_HERE
N8N_USER_MANAGEMENT_JWT_SECRET=YOUR_JWT_SECRET_HERE
```

**To generate secure keys:**
```bash
openssl rand -hex 32
```

---

### 3. LiteLLM (`litellm/.env`)

```bash
LITELLM_MASTER_KEY="sk-YOUR_LITELLM_MASTER_KEY"
LITELLM_SALT_KEY="sk-YOUR_LITELLM_SALT_KEY"

# UI Access
UI_USERNAME=admin
UI_PASSWORD=YOUR_UI_PASSWORD

# PostgreSQL Connection
POSTGRES_USER=your_postgres_username
POSTGRES_PASSWORD=YOUR_SECURE_POSTGRES_PASSWORD
POSTGRES_DB=litellm

# Ollama
OLLAMA_API_BASE=http://ollama:11434

# Drop unknown parameters
LITELLM_DROP_PARAMS=true
```

---

### 4. Immich (`immich/.env`)

```bash
# ========================================
# STORAGE LOCATIONS
# ========================================
UPLOAD_LOCATION=/path/to/immich/upload
BASE_PATH=/path/to/immich
DB_DATA_LOCATION=./postgres

# ========================================
# GPU & HARDWARE ACCELERATION
# ========================================
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
IMMICH_NVENC_ENABLED=true

# ========================================
# MACHINE LEARNING SETTINGS
# ========================================
# 0 = Keep models in VRAM forever (uses 2-4GB VRAM)
# 600 = Unload after 10 minutes of inactivity
MACHINE_LEARNING_MODEL_TTL=0

# CLIP Model for Smart Search
# Options: ViT-B-32__openai, ViT-H-14-378-quickgelu__dfn5b, ViT-SO400M-16-SigLIP-384__webli
MACHINE_LEARNING_CLIP_MODEL_NAME=ViT-SO400M-16-SigLIP-384__webli

# Facial Recognition Model
# Options: buffalo_s (fast), buffalo_m (balanced), buffalo_l (accurate)
MACHINE_LEARNING_FACIAL_RECOGNITION_MODEL_NAME=buffalo_l
MACHINE_LEARNING_FACIAL_RECOGNITION_MIN_SCORE=0.5

# ========================================
# SYSTEM SETTINGS
# ========================================
TZ=Europe/Madrid
IMMICH_VERSION=release

# ========================================
# DATABASE CONNECTION
# ========================================
DB_USERNAME=postgres
DB_DATABASE_NAME=immich
DB_PASSWORD=YOUR_IMMICH_DB_PASSWORD

# ========================================
# REDIS CONNECTION
# ========================================
REDIS_HOSTNAME=immich_redis
REDIS_PORT=6379

# ========================================
# PERMISSIONS
# ========================================
PUID=1000
PGID=1000
```

---

### 5. Open WebUI (`open-webui/.env`)

```bash
# TTS Configuration
TTS_API_KEY=YOUR_TTS_API_KEY_HERE

# OpenAI API Key (if using external providers)
OPENAI_API_KEY=YOUR_OPENAI_API_KEY_HERE
```

---

### 6. Tika (`tika/.env`)

```bash
TAG=latest
```

---

## Security Best Practices

1. **Never commit .env files to Git** - Add `.env` to `.gitignore`
2. **Use strong passwords** - Minimum 16 characters, mixed case, numbers, symbols
3. **Generate random keys** - Use `openssl rand -hex 32` for encryption keys
4. **Separate credentials** - Don't reuse passwords across services
5. **Restrict file permissions** - `chmod 600 .env`

## Generating Secure Keys

```bash
# For N8N and JWT secrets
openssl rand -hex 32

# For LiteLLM master key
openssl rand -hex 16 | sed 's/^/sk-/' 

# Strong random password
openssl rand -base64 24
```

## Environment Variable Loading

Docker Compose automatically loads `.env` files from:
1. The current directory (where docker-compose.yml is)
2. The project directory (if specified with `-f`)

For services that need shared variables:
```bash
# Option 1: Create .env in each service directory
# Option 2: Export variables in shell before running docker-compose
export POSTGRES_USER=myuser
export POSTGRES_PASSWORD=mypassword

# Option 3: Use --env-file flag
docker-compose --env-file ../../.env up -d
```

## Troubleshooting

### Variables Not Loading
- Check file is named exactly `.env` (not `env` or `.env.txt`)
- Verify file permissions: `ls -la .env`
- Use explicit path: `docker-compose --env-file ./.env up -d`

### Database Connection Errors
- Ensure PostgreSQL is running before dependent services
- Check credentials match between service .env and postgres .env
- Verify network connectivity: `docker network inspect bolex-net`

### Secrets in Logs
- Docker may print env vars in logs on startup
- Use Docker Secrets for production (not covered here)
- Review logs before sharing: `docker-compose logs 2>&1 | grep -v PASSWORD`
