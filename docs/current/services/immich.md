# Immich

Self-hosted photo and video library on the GPU VM (`192.168.2.30`).

## Compose location

```bash
ssh alex@192.168.2.30
cd /home/alex/docker/immich
docker compose ps
```

## Key paths

| Path | Purpose |
|------|---------|
| `/home/alex/docker/immich/.env` | Configuration |
| `/mnt/tank-immich/immich` | Immich-managed library (uploads, thumbs, encoded-video) |
| `/mnt/tank-media/Pictures` | External library (All-Years, Fotos-Boda, Hugo, Marcos, Sofia) |

## Important `.env` settings

- `EXTERNAL_LOCATION=/mnt/tank-media/Pictures`
- `MACHINE_LEARNING_MODEL_TTL=31536000` (permanent)
- `PRELOAD__CLIP__TEXTUAL=XLM-Roberta-Base-ViT-B-32__laion5b_s13b_b90k`
- `PRELOAD__CLIP__VISUAL=XLM-Roberta-Base-ViT-B-32__laion5b_s13b_b90k`

## Restart

```bash
cd /home/alex/docker/immich
docker compose down
docker compose up -d
```

## Re-scan external libraries

```bash
# Trigger via API or run immich-photo-sync.sh
```

## Related

- [Benthem Wiki — Immich Storage Layout](https://wiki.benthem.es/concepts/immich-storage-layout)
- [Benthem Wiki — Backup Mechanisms](https://wiki.benthem.es/concepts/backup-mechanisms)
