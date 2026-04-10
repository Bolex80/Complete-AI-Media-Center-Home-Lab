#!/bin/bash

# Docker Compose Update Script
# Updates all Docker containers in the WSL2 environment
# Usage: ./update-dockers.sh

# List of base directories
base_folders=(
    "/home/YOUR_USERNAME/immich"
    "/home/YOUR_USERNAME/metube"
    "/home/YOUR_USERNAME/8mblocal"
    "/home/YOUR_USERNAME/beszel"
    "/home/YOUR_USERNAME/hawser"
    "/home/YOUR_USERNAME/immich-frame"
    "/home/YOUR_USERNAME/immich-frame-jorge"
)

# List of bolex-ai subdirectories
bolex_folders=(
    "/home/YOUR_USERNAME/bolex-ai/postgres"
    "/home/YOUR_USERNAME/bolex-ai/qdrant"
    "/home/YOUR_USERNAME/bolex-ai/tika"
    "/home/YOUR_USERNAME/bolex-ai/LibreTranslate"
    "/home/YOUR_USERNAME/bolex-ai/Whisper-WebUI"
    "/home/YOUR_USERNAME/bolex-ai/litellm"
    "/home/YOUR_USERNAME/bolex-ai/n8n"
    "/home/YOUR_USERNAME/bolex-ai/ollama"
    "/home/YOUR_USERNAME/bolex-ai/open-webui"
)

update_docker() {
    local dir=$1
    if [ -d "$dir" ]; then
        echo "Updating directory: $dir"
        cd "$dir" || return
        docker compose pull && docker compose down && docker compose up -d
    else
        echo "Directory not found: $dir"
    fi
}

# Run updates for base folders
for folder in "${base_folders[@]}"; do
    update_docker "$folder"
done

# Run updates for bolex-ai folders
for folder in "${bolex_folders[@]}"; do
    update_docker "$folder"
done

echo "All updates completed."
