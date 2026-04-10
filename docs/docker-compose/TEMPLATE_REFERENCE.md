# Docker Compose Template Reference

This document provides standardized templates for creating new service configurations.

## Basic Template

```yaml
services:
  service-name:
    image: owner/image:tag
    container_name: service-name
    networks:
      - bolex-net
    restart: unless-stopped
    ports:
      - "HOST_PORT:CONTAINER_PORT"
    environment:
      - ENV_VAR_NAME=${ENV_VAR_NAME:-default_value}
    volumes:
      - ./local-data:/container/path

networks:
  bolex-net:
    external: true

volumes:
  service-data:
    name: service-data
```

## GPU-Enabled Template (NVIDIA)

```yaml
services:
  ai-service:
    image: owner/image:tag-cuda
    container_name: ai-service
    networks:
      - bolex-net
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
    volumes:
      - ./data:/app/data
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

networks:
  bolex-net:
    external: true
```

## Database + Web App Template

```yaml
services:
  app:
    image: app:latest
    container_name: app
    networks:
      - bolex-net
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./app-data:/var/www/html
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    container_name: app-db
    networks:
      - bolex-net
    restart: unless-stopped
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./db-data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${DB_USER} -d ${DB_NAME}']
      interval: 5s
      timeout: 5s
      retries: 10

networks:
  bolex-net:
    external: true
```

## Reverse Proxy + SSL Template

```yaml
services:
  app:
    image: app:latest
    container_name: app
    networks:
      - bolex-net
    restart: unless-stopped
    environment:
      - VIRTUAL_HOST=app.yourdomain.com
      - LETSENCRYPT_HOST=app.yourdomain.com
      - LETSENCRYPT_EMAIL=admin@yourdomain.com

  nginx-proxy:
    image: nginxproxy/nginx-proxy:latest
    container_name: nginx-proxy
    networks:
      - bolex-net
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./certs:/etc/nginx/certs
      - ./vhost.d:/etc/nginx/vhost.d
      - ./html:/usr/share/nginx/html

  letsencrypt:
    image: nginxproxy/acme-companion:latest
    container_name: letsencrypt
    networks:
      - bolex-net
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./certs:/etc/nginx/certs
      - ./acme:/etc/acme.sh
    environment:
      - NGINX_PROXY_CONTAINER=nginx-proxy

networks:
  bolex-net:
    external: true
```

## Healthcheck Template

```yaml
services:
  service:
    image: app:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## Environment Variables Best Practices

1. **Use .env files** for sensitive data
2. **Default values** for non-sensitive configs: `${VAR:-default}`
3. **Document all variables** in service documentation
4. **Never commit** actual secrets to Git

## Common Environment Variables

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=dbuser
DB_PASSWORD=YOUR_DB_PASSWORD

# Application
TZ=Europe/Madrid
PUID=1000
PGID=1000

# Security
ADMIN_TOKEN=YOUR_ADMIN_TOKEN
JWT_SECRET=YOUR_JWT_SECRET
ENCRYPTION_KEY=YOUR_ENCRYPTION_KEY

# External Services
API_KEY=YOUR_API_KEY
WEBHOOK_URL=https://your-webhook-url

# Cloudflare
CF_API_TOKEN=YOUR_CF_API_TOKEN
CF_ZONE_ID=YOUR_ZONE_ID
```

## Volume Naming Convention

```yaml
volumes:
  # Named volumes (Docker managed)
  service-data:
    name: service-data
    
  # Bind mounts (Host filesystem)
  - ./relative/path:/container/path
  - /absolute/path:/container/path
  
  # Read-only mounts
  - ./config:/etc/app:ro
  
  # External volumes
  external-volume:
    external: true
```

## Network Configuration

```yaml
# External network (shared across services)
networks:
  bolex-net:
    external: true

# Internal-only network
networks:
  backend:
    internal: true
    
# Custom network with specific config
networks:
  custom:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Security Hardening Template

```yaml
services:
  secure-app:
    image: app:latest
    read_only: true                    # Read-only filesystem
    cap_drop:                          # Drop all capabilities
      - ALL
    cap_add:                           # Add only required capabilities
      - CHOWN
      - SETGID
      - SETUID
    security_opt:
      - no-new-privileges:true
    user: "1000:1000"                  # Run as non-root
    sysctls:
      - net.core.somaxconn=1024
    ulimits:
      nofile:
        soft: 64000
        hard: 64000
```

## Labels for Monitoring

```yaml
services:
  app:
    image: app:latest
    labels:
      - "com.bolex80.service=app-name"
      - "com.bolex80.server=wsl2"
      - "com.bolex80.critical=true"
      - "com.bolex80.backup=true"
      - "com.bolex80.gpu=true"  # if GPU enabled
      - "traefik.enable=true"   # if using Traefik
      - "traefik.http.routers.app.rule=Host(`app.yourdomain.com`)"
```
