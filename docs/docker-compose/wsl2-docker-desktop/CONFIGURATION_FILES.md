# Configuration Files Reference

This directory contains essential configuration files for the WSL2 services.

## Required Configuration Files

### 1. LiteLLM Configuration

**File:** `litellm/proxy_server_config.yaml`

This file defines all available LLM models and their configurations.

**Key Sections:**
- `model_list`: Define all available models (Ollama, OpenAI, Anthropic, etc.)
- `litellm_settings`: Global settings for retries, timeouts, telemetry
- `router_settings`: Load balancing and routing strategies
- `general_settings`: Master key, database settings

**Environment Variables Required:**
- `OPENAI_API_KEY`: For OpenAI models
- `ANTHROPIC_API_KEY`: For Claude models
- `GROQ_API_KEY`: For Groq fast inference
- `AZURE_API_KEY`: For Azure OpenAI (if used)
- `OLLAMA_API_BASE`: http://ollama:11434
- `LITELLM_MASTER_KEY`: Your LiteLLM admin key

**Setup:**
1. Copy the template from `litellm/proxy_server_config.yaml`
2. Edit to include only the models you need
3. Set the required environment variables
4. Restart LiteLLM container

---

### 2. Prometheus Configuration

**File:** `litellm/prometheus.yml`

Prometheus monitoring configuration for LiteLLM metrics.

**Default Configuration:**
- Scrapes LiteLLM metrics every 15 seconds
- Accessible at `http://localhost:9090`

---

### 3. Tika Configuration

**File:** `tika/tika-config.xml`

Apache Tika server configuration for document parsing.

**Default Configuration:**
- Runs on port 9998
- Accepts connections from all interfaces (0.0.0.0)

**Customization:**
You can extend this configuration for:
- OCR support (add Tesseract)
- Custom parsers
- Specific MIME type handling
- Logging configuration

See [Tika documentation](https://tika.apache.org/) for advanced options.

---

### 4. PostgreSQL Init Script

**File:** `postgres/init-multiple-databases.sh`

This script automatically creates multiple databases on PostgreSQL startup.

**Usage:**
1. Mount to `/docker-entrypoint-initdb.d/` in the postgres container
2. Set `POSTGRES_MULTIPLE_DATABASES=n8n,litellm` environment variable
3. Databases will be created on first container startup

**Note:** Only runs on fresh database initialization (empty data directory).

---

### 5. Immich Warmup Script

**File:** `immich/warmup-immich-ml.sh`

Pre-loads Immich machine learning models into GPU VRAM.

**Usage:**
```bash
# After starting Immich stack
./warmup-immich-ml.sh
```

This prevents first-request delays by loading CLIP and facial recognition models immediately.

---

### 6. Update Script

**File:** `scripts/update-dockers.sh`

Updates all Docker containers across your WSL2 environment.

**Usage:**
```bash
# Make executable
chmod +x scripts/update-dockers.sh

# Run
./scripts/update-dockers.sh
```

**What it does:**
- Pulls latest images for all services
- Stops running containers
- Starts updated containers
- Maintains persistent data volumes

**Customization:**
Edit the `base_folders` and `bolex_folders` arrays to match your directory structure.

---

## Environment Variables Setup

All configuration files use environment variables for sensitive data. See `ENVIRONMENT_VARIABLES.md` for the complete list.

### Quick Setup

1. **Create main .env file:**
   ```bash
   cd ~/bolex-ai
   nano .env
   ```

2. **Add your credentials:**
   ```bash
   POSTGRES_USER=youruser
   POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD
   # ... etc
   ```

3. **Load in shell:**
   ```bash
   source .env
   ```

4. **Or use with docker-compose:**
   ```bash
   docker-compose --env-file .env up -d
   ```

---

## File Locations Summary

| Service | Config File | Required |
|---------|-------------|----------|
| LiteLLM | `litellm/proxy_server_config.yaml` | Yes |
| LiteLLM | `litellm/prometheus.yml` | No (for monitoring) |
| Tika | `tika/tika-config.xml` | No (default works) |
| Postgres | `postgres/init-multiple-databases.sh` | No (convenience) |
| Immich | `immich/warmup-immich-ml.sh` | No (optimization) |
| All | `scripts/update-dockers.sh` | No (maintenance) |

---

## Security Notes

1. **Never commit real credentials** - Use `.env` files and reference them
2. **Use `os.environ/` prefix** - In LiteLLM config to load from env vars
3. **Restrict file permissions** - `chmod 600` on files with passwords
4. **Rotate keys regularly** - Especially API keys for external services
5. **Use strong passwords** - Minimum 16 characters, randomly generated
