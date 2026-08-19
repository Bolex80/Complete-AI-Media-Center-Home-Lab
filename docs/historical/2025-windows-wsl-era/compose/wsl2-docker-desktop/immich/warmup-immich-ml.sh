#!/bin/bash

# Warmup script for Immich Machine Learning models
# Pre-loads models into GPU VRAM to avoid first-request delays
# Run this after starting the Immich stack

echo "Waiting for Immich ML service to be ready..."
sleep 10  # Wait for container initialization

# Trigger CLIP model loading (Smart Search)
curl -X POST http://localhost:3003/predict \
  -H "Content-Type: application/json" \
  -d '{"type":"clip","text":"warmup"}' \
  --silent --output /dev/null

# Trigger Facial Recognition model loading
curl -X POST http://localhost:3003/predict \
  -H "Content-Type: application/json" \
  -d '{"type":"facial-recognition","faces":[]}' \
  --silent --output /dev/null

echo "ML Models pre-loaded into VRAM"
echo "Immich is ready for use!"
