# Nginx Reverse Proxy Examples

Deze directory bevat praktische voorbeelden voor de Nginx reverse proxy tutorial.

## Bestanden

### Configuratie Bestanden
- `nginx-basic.conf` - Basis reverse proxy configuratie
- `nginx-ssl.conf` - SSL geconfigureerde reverse proxy
- `docker-compose.yml` - Complete Docker Compose setup

### Scripts
- `setup-demo.sh` - Automatische demo setup met containers
- `generate-ssl.sh` - SSL certificaat generatie voor testing

## Quick Start

### 1. Basis Demo
```bash
./setup-demo.sh
```

Bezoek vervolgens:
- http://app1.localhost
- http://app2.localhost

### 2. SSL Demo
```bash
# Genereer SSL certificaten
./generate-ssl.sh

# Start met Docker Compose
docker-compose up -d
```

### 3. Manual Setup
```bash
# Start backend containers
docker run -d --name webapp1 -p 8081:80 nginx:alpine
docker run -d --name webapp2 -p 8082:80 nginx:alpine

# Start nginx proxy
docker run -d --name nginx-proxy \
  -p 80:80 \
  -v $(pwd)/nginx-basic.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine
```

## Hosts File

Voor lokale testing, voeg toe aan `/etc/hosts`:
```
127.0.0.1 app1.localhost
127.0.0.1 app2.localhost
```

## Cleanup

```bash
# Stop alle containers
docker stop webapp1 webapp2 nginx-proxy
docker rm webapp1 webapp2 nginx-proxy

# Of met Docker Compose
docker-compose down
```