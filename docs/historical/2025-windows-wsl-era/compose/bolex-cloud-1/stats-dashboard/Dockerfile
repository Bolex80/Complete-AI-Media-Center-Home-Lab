FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/main.py .
COPY backend/collector.py .
COPY frontend/ /app/frontend/

# SSH keys and config mounted at runtime
VOLUME /ssh-keys
VOLUME /data

EXPOSE 8883

# Start collector (unbuffered) and API server
CMD ["sh", "-c", "python3 -u collector.py & uvicorn main:app --host 0.0.0.0 --port 8883"]