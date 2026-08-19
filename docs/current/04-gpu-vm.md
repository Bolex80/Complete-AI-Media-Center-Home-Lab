# GPU VM

The GPU VM (`gpu-vm`, `192.168.2.30`) is an Ubuntu VM on Bolex with the NVIDIA RTX 4060 Ti 16 GB passed through. It hosts all CUDA-dependent and AI/ML services.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| Ollama | `11434` | Local LLM inference server |
| Immich server + machine-learning | `2283` | Photo/video library with AI search and GPU transcoding |
| Open WebUI | `4000` | Chat interface for Ollama |
| LiteLLM | `4001` | Multi-provider LLM proxy |
| Qdrant | `6333` | Vector database for RAG |
| n8n | `5678` | Workflow automation |
| Postgres | `5432` | Shared DB for n8n, LiteLLM |
| Tika | `9998` | Document parsing |
| Edge-TTS proxy | `5050` | Fast text-to-speech |

## GPU allocation

Current resident VRAM budget (~7.1 GB / 16 GB used):

- Ollama `gemma4:e4b-128k` + `nomic-embed-text-v2-moe` ≈ 5.4 GB
- Immich ML (CLIP `XLM-Roberta-Base-ViT-B-32`) ≈ 1.8 GB

Both Ollama and the CLIP model are kept resident (`OLLAMA_KEEP_ALIVE=-1`, `MACHINE_LEARNING_MODEL_TTL=31536000`).

## Management

```bash
# From ai-agents or LAN
ssh alex@192.168.2.30

# Check GPU
nvidia-smi

# Restart Ollama
cd /home/alex/docker/ollama && docker compose restart

# Restart Immich
cd /home/alex/docker/immich && docker compose restart
```

## Data paths

| Path | Purpose |
|------|---------|
| `/home/alex/docker/ollama` | Ollama compose + models |
| `/home/alex/docker/immich` | Immich compose + `.env` |
| `/home/alex/docker/qdrant` | Qdrant storage |
| `/mnt/tank-media/Pictures` | Immich external library (NFS from Bolex) |
| `/mnt/tank-immich/immich` | Immich-managed originals (NFS from Bolex) |

## Related

- [Benthem Wiki — Immich storage layout](https://wiki.benthem.es/concepts/immich-storage-layout)
- [Benthem Wiki — Model configuration](https://wiki.benthem.es/concepts/model-configuration)
- [Benthem Wiki — Qdrant RAG](https://wiki.benthem.es/concepts/qdrant-rag)
