# 2 - Van Container naar Image: De Dockerfile Journey

## Inleiding: Het shipping probleem

Stel je voor: je hebt een mooie website gebouwd en je wilt deze delen met de wereld. Je hebt geleerd hoe je Docker containers kunt draaien met volumes en poorten, maar er is een probleem...

**Het scenario:**
- Je hebt een eenvoudige HTML website in `../03-Compose/compose-files/1-fe/index.html`
- Je kunt deze lokaal draaien met `docker run` en volume mounting
- Maar hoe deel je dit met je team? Met productie? Met klanten?

**Het probleem:**
```bash
# Dit werkt lokaal...
docker run -p 8080:80 -v "$(pwd)/../03-Compose/compose-files/1-fe/index.html:/usr/share/nginx/html/index.html:ro" nginx

# Maar wat stuur je naar productie? Een ZIP bestand met instructies?
# "Hallo, pak dit uit, installeer Docker, en run dit commando..."
```

**In dit hoofdstuk leer je:**
- Waarom volumes niet genoeg zijn voor distributie
- Hoe je van container naar image gaat
- De kunst van het schrijven van Dockerfiles
- Het Docker layer systeem
- Multi-stage builds voor optimale images
- Best practices voor productieklare containers

---

## Fase 1: Het distributie dilemma

### De huidige situatie: Volume mounting

Momenteel run je de website zo:

```bash
cd ../03-Compose/compose-files
docker run --rm -p 8080:80 \
  -v "$(pwd)/1-fe/index.html:/usr/share/nginx/html/index.html:ro" \
  nginx:1.27-alpine
```

**Wat gebeurt er hier:**
1. Docker start een nginx container
2. Jouw lokale HTML wordt "gemount" in de container
3. Nginx serveert jouw bestand
4. Website draait op http://localhost:8080

**Waarom dit niet schaalbaar is:**
- ❌ **Afhankelijk van lokale bestanden**: Werkt alleen op jouw machine
- ❌ **Geen distributie mogelijk**: Kan niet naar andere servers
- ❌ **Handmatige setup**: Iedereen moet commando's kennen
- ❌ **Niet reproduceerbaar**: Verschillende versies op verschillende machines
- ❌ **Geen CI/CD**: Kan niet geautomatiseerd worden

### Het doel: Een distribueerbare image

**Wat we willen bereiken:**
```bash
# In plaats van dit complexe commando...
docker run -p 8080:80 -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" nginx

# Willen we dit simpele commando...
docker run -p 8080:80 mijn-website:v1.0
```

**Voordelen van een eigen image:**
- ✅ **Self-contained**: Alles zit in de image
- ✅ **Reproduceerbaar**: Exact dezelfde omgeving overal
- ✅ **Versioneerbaar**: `v1.0`, `v1.1`, `latest`
- ✅ **Distribueerbaar**: Kan naar registries (Docker Hub, ECR, etc.)
- ✅ **CI/CD ready**: Kan geautomatiseerd worden gebouwd

---

## Fase 2: Van container naar image - De handmatige manier

### Methode 1: Container modificatie en commit

**Het oude handmatige proces:**

```bash
# Stap 1: Start een basis container
docker run -it --name website-builder nginx:1.27-alpine sh

# Stap 2: Ga in de container en maak wijzigingen
# (In een nieuwe terminal)
docker exec -it website-builder sh

# Binnen de container:
cd /usr/share/nginx/html
rm index.html
echo "<h1>Mijn website</h1><p>Versie 1.0</p>" > index.html
exit

# Stap 3: Stop de container
docker stop website-builder

# Stap 4: Commit de wijzigingen naar een nieuwe image
docker commit website-builder mijn-website:v1.0

# Stap 5: Test de nieuwe image
docker run --rm -p 8080:80 mijn-website:v1.0

# Stap 6: Cleanup
docker rm website-builder
```

**Problemen met deze aanpak:**
- 🔥 **Niet reproduceerbaar**: Handmatige stappen kunnen vergeten worden
- 🔥 **Geen documentatie**: Niemand weet wat er precies is gedaan
- 🔥 **Foutgevoelig**: Menselijke fouten creëpen erin
- 🔥 **Niet automatiseerbaar**: Geen deel van CI/CD pipeline
- 🔥 **Geen versie controle**: Moeilijk om wijzigingen bij te houden

### Methode 2: De Dockerfile manier

**De moderne, scriptbare aanpak:**

```dockerfile
# Dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```bash
# Build het image
docker build -t mijn-website:v1.0 .

# Run het image
docker run --rm -p 8080:80 mijn-website:v1.0
```

**Voordelen van Dockerfile:**
- ✅ **Reproduceerbaar**: Script produceert altijd hetzelfde resultaat
- ✅ **Gedocumenteerd**: Dockerfile IS de documentatie
- ✅ **Versie gecontroleerd**: Dockerfile gaat in git
- ✅ **Automatiseerbaar**: Kan door CI/CD systemen worden uitgevoerd
- ✅ **Transparant**: Iedereen ziet wat er gebeurt

---

## Fase 3: Dockerfile fundamenten

### Anatomie van een Dockerfile

Een Dockerfile is een tekstbestand met instructies voor het bouwen van een Docker image. Elke instructie creëert een nieuwe "layer" in het image.

**Basis structuur:**
```dockerfile
# Commentaar: Dit is een uitleg
INSTRUCTIE argument
INSTRUCTIE argument met meerdere woorden
INSTRUCTIE ["argument", "met", "array", "syntax"]
```

### De essentiële instructies

#### 1. FROM - Het fundament

```dockerfile
FROM nginx:1.27-alpine
```

**Wat het doet:**
- Definieert het basis image
- Moet altijd de eerste instructie zijn (behalve commentaar)
- Alles wat volgt bouwt voort op dit basis image

**Varianten:**
```dockerfile
# Specifieke versie (aanbevolen)
FROM nginx:1.27-alpine

# Laatste versie (riskant voor productie)
FROM nginx:latest

# Lege basis (voor scratch builds)
FROM scratch

# Multi-stage build basis
FROM node:18 AS builder
```

#### 2. COPY - Bestanden toevoegen

```dockerfile
COPY index.html /usr/share/nginx/html/
```

**Wat het doet:**
- Kopieert bestanden van host naar container
- Respecteert .dockerignore bestand
- Creëert directories als ze niet bestaan

**Varianten:**
```dockerfile
# Enkel bestand
COPY index.html /usr/share/nginx/html/index.html

# Meerdere bestanden
COPY index.html style.css /usr/share/nginx/html/

# Hele directory
COPY ./website/ /usr/share/nginx/html/

# Met ownership
COPY --chown=nginx:nginx index.html /usr/share/nginx/html/

# Uit andere stage (multi-stage)
COPY --from=builder /app/dist /usr/share/nginx/html/
```

#### 3. ADD - Geavanceerde bestanden toevoegen

```dockerfile
ADD https://example.com/script.js /usr/share/nginx/html/
ADD archive.tar.gz /opt/
```

**Verschil met COPY:**
- Kan URLs downloaden
- Extraheert automatisch tar/gzip bestanden
- **Best practice**: Gebruik COPY tenzij je ADD's speciale functies nodig hebt

#### 4. WORKDIR - Werkdirectory instellen

```dockerfile
WORKDIR /usr/share/nginx/html
COPY . .
```

**Wat het doet:**
- Stelt working directory in voor volgende instructies
- Creëert directory als deze niet bestaat
- Vergelijkbaar met `cd` commando

**Voorbeeld progressie:**
```dockerfile
FROM nginx:1.27-alpine
WORKDIR /usr/share/nginx/html    # pwd is nu /usr/share/nginx/html
COPY index.html .                # Kopieert naar /usr/share/nginx/html/index.html
WORKDIR /etc/nginx               # pwd is nu /etc/nginx
COPY nginx.conf .                # Kopieert naar /etc/nginx/nginx.conf
```

#### 5. RUN - Commando's uitvoeren

```dockerfile
RUN apk add --no-cache curl
```

**Wat het doet:**
- Voert commando uit tijdens build tijd
- Elke RUN instructie creëert een nieuwe layer
- Resultaat wordt opgeslagen in de image

**Optimalisatie technieken:**
```dockerfile
# Slecht: Meerdere layers
RUN apk update
RUN apk add curl
RUN apk add nano
RUN rm -rf /var/cache/apk/*

# Goed: Eén layer
RUN apk update && \
    apk add --no-cache curl nano && \
    rm -rf /var/cache/apk/*

# Nog beter: Met line breaks voor leesbaarheid
RUN apk update \
    && apk add --no-cache \
        curl \
        nano \
        htop \
    && rm -rf /var/cache/apk/*
```

#### 6. CMD - Standaard commando

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

**Wat het doet:**
- Definieert het standaard commando wanneer container start
- Kan overschreven worden door docker run argumenten
- Slechts één CMD per Dockerfile (laatste wint)

**Vormen:**
```dockerfile
# Exec form (aanbevolen)
CMD ["nginx", "-g", "daemon off;"]

# Shell form
CMD nginx -g "daemon off;"

# Parameters voor ENTRYPOINT
CMD ["--help"]
```

#### 7. ENTRYPOINT - Vaste entry point

```dockerfile
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
```

**Verschil met CMD:**
- ENTRYPOINT kan NIET overschreven worden
- CMD wordt gebruikt als default argumenten voor ENTRYPOINT
- Combinatie geeft flexibiliteit

**Voorbeeld:**
```dockerfile
FROM nginx:1.27-alpine
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]

# docker run my-image          → nginx -g "daemon off;"
# docker run my-image -t       → nginx -t
# docker run my-image -h       → nginx -h
```

#### 8. EXPOSE - Poorten documenteren

```dockerfile
EXPOSE 80
EXPOSE 443
EXPOSE 8080/tcp
EXPOSE 53/udp
```

**Wat het doet:**
- Documenteert welke poorten de container gebruikt
- Publiceert GEEN poorten automatisch
- Metadata voor tooling en documentatie

#### 9. ENV - Environment variabelen

```dockerfile
ENV NODE_ENV=production
ENV API_URL=https://api.example.com
ENV PORT 3000
```

**Gebruik in andere instructies:**
```dockerfile
ENV APP_HOME=/app
WORKDIR $APP_HOME
COPY package*.json $APP_HOME/
```

#### 10. ARG - Build argumenten

```dockerfile
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}

ARG BUILD_DATE
ARG VERSION
LABEL build_date=$BUILD_DATE
LABEL version=$VERSION
```

**Build met argumenten:**
```bash
docker build \
  --build-arg NODE_VERSION=20 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=1.2.3 \
  -t my-app:1.2.3 .
```

#### 11. USER - Security context

```dockerfile
RUN addgroup -g 1001 -S nginx-group
RUN adduser -S nginx-user -u 1001 -G nginx-group
USER nginx-user
```

**Waarom belangrijk:**
- Containers draaien standaard als root
- Security best practice: gebruik non-root users
- Vermindert attack surface

#### 12. VOLUME - Data persistence

```dockerfile
VOLUME ["/data", "/logs"]
```

**Wat het doet:**
- Markeert directories als volume mount points
- Data in deze directories is persistent
- Kan gemount worden door host of andere containers

---

## Fase 4: Het Docker Layer systeem

### Hoe Docker layers werken

**Elke Dockerfile instructie = Een nieuwe layer:**

```dockerfile
FROM nginx:1.27-alpine          # Layer 1: Basis image
COPY index.html /usr/share/nginx/html/  # Layer 2: HTML bestand
RUN apk add --no-cache curl     # Layer 3: Curl installatie
EXPOSE 80                       # Layer 4: Metadata (geen echte layer)
CMD ["nginx", "-g", "daemon off;"]  # Layer 5: Default commando
```

**Visualisatie van layers:**
```
┌─────────────────────────────────────┐
│ Layer 5: CMD nginx -g daemon off;  │
├─────────────────────────────────────┤
│ Layer 4: (EXPOSE 80 - metadata)    │
├─────────────────────────────────────┤
│ Layer 3: RUN apk add curl          │
├─────────────────────────────────────┤
│ Layer 2: COPY index.html            │
├─────────────────────────────────────┤
│ Layer 1: FROM nginx:1.27-alpine    │
└─────────────────────────────────────┘
```

### Layer caching

**Docker hergebruikt layers die niet zijn veranderd:**

```dockerfile
# Stel je wijzigt alleen de HTML...
FROM nginx:1.27-alpine          # ✅ Cache hit
COPY index.html /usr/share/nginx/html/  # ❌ Cache miss (bestand veranderd)
RUN apk add --no-cache curl     # ❌ Rebuild (alles erna moet opnieuw)
```

**Optimale volgorde voor caching:**
```dockerfile
# Slecht: Dependencies installeren na COPY
FROM node:18
COPY . /app                     # Elke code wijziging breekt cache
WORKDIR /app
RUN npm install                 # Npm install elke keer opnieuw

# Goed: Dependencies eerst installeren
FROM node:18
WORKDIR /app
COPY package*.json ./           # Alleen bij dependency wijzigingen
RUN npm install                 # Gecached tenzij package.json wijzigt
COPY . .                        # Code wijzigingen breken cache pas hier
```

### Layer grootte optimalisatie

**Kleine layers = snellere builds en deployments:**

```dockerfile
# Slecht: Grote layers door cleanup in aparte instructie
RUN apt-get update
RUN apt-get install -y curl nginx
RUN rm -rf /var/lib/apt/lists/*

# Goed: Alles in één layer met cleanup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

**Layer grootte inspecteren:**
```bash
# Bekijk layers van een image
docker history my-image:latest

# Gedetailleerde layer informatie
docker image inspect my-image:latest
```

---

## Fase 5: Praktische Dockerfile voorbeelden

### Voorbeeld 1: Eenvoudige statische website

**Onze huidige situatie: HTML bestand serveren**

```dockerfile
# Dockerfile voor statische website
FROM nginx:1.27-alpine

# Kopieer website bestanden
COPY index.html /usr/share/nginx/html/index.html

# Optioneel: Custom nginx configuratie
# COPY nginx.conf /etc/nginx/nginx.conf

# Documenteer de poort
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

**Bouwen en testen:**
```bash
# In de directory met Dockerfile en index.html
docker build -t mijn-website:v1.0 .

# Testen
docker run --rm -p 8080:80 mijn-website:v1.0

# Verificatie
curl http://localhost:8080
```

### Voorbeeld 2: Node.js applicatie

**Volledig voorbeeld voor een Node.js app:**

```dockerfile
# Use official Node.js runtime
FROM node:18-alpine

# Metadata
LABEL maintainer="jouw-email@example.com"
LABEL version="1.0.0"
LABEL description="Mijn Node.js applicatie"

# Installeer systeem dependencies
RUN apk add --no-cache \
    dumb-init \
    curl

# Maak non-root user voor security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Kopieer package files en installeer dependencies
# (Dit gebeurt voor code copy voor betere caching)
COPY --chown=nodejs:nodejs package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Kopieer applicatie code
COPY --chown=nodejs:nodejs . .

# Switch naar non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Expose poort
EXPOSE 3000

# Start applicatie met dumb-init voor proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
```

### Voorbeeld 3: Python Flask applicatie

```dockerfile
FROM python:3.11-slim

# Installeer systeem dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        libc6-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Maak user
RUN useradd --create-home --shell /bin/bash app

# Working directory
WORKDIR /home/app

# Requirements installeren (caching optimalisatie)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Applicatie code
COPY --chown=app:app . .

# Switch naar non-root
USER app

EXPOSE 5000

CMD ["python", "app.py"]
```

---

## Fase 6: Multi-stage builds

### Het probleem met grote development images

**Traditionele build met development tools:**
```dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install              # Inclusief devDependencies
COPY . .
RUN npm run build           # Build tools blijven in image
EXPOSE 3000
CMD ["npm", "start"]
```

**Problemen:**
- 🔥 **Grote image size**: Development tools blijven in productie image
- 🔥 **Security risico**: Onnodige tools en dependencies
- 🔥 **Slow deployments**: Grote images betekenen langere push/pull tijden

### Multi-stage build oplossing

**Scheiding van build en runtime:**

```dockerfile
# Stage 1: Build stage
FROM node:18 AS builder
WORKDIR /app

# Installeer alle dependencies (inclusief dev)
COPY package*.json ./
RUN npm ci

# Kopieer source code en build
COPY . .
RUN npm run build

# Stage 2: Production stage
FROM node:18-alpine AS production
WORKDIR /app

# Installeer alleen productie dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Kopieer alleen de gebouwde bestanden uit build stage
COPY --from=builder /app/dist ./dist

# Security: non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs
USER nodejs

EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### Praktisch voorbeeld: React applicatie

```dockerfile
# Stage 1: Build React app
FROM node:18 AS build
WORKDIR /app

# Dependencies installeren
COPY package*.json ./
RUN npm ci

# Source code en build
COPY . .
RUN npm run build

# Stage 2: Serve met nginx
FROM nginx:1.27-alpine AS production

# Kopieer build output naar nginx
COPY --from=build /app/build /usr/share/nginx/html

# Custom nginx configuratie voor SPA
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Nginx configuratie voor SPA (nginx.conf):**
```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        # SPA routing: alle requests naar index.html
        location / {
            try_files $uri $uri/ /index.html;
        }

        # Caching voor static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### Voordelen van multi-stage builds

**Size vergelijking:**
```bash
# Single stage build
docker build -t my-app:single-stage .
# Image size: ~500MB (met development tools)

# Multi-stage build
docker build -t my-app:multi-stage --target production .
# Image size: ~150MB (alleen runtime)

# Size vergelijking
docker images | grep my-app
```

**Security voordelen:**
- ✅ **Kleinere attack surface**: Geen development tools
- ✅ **Fewer vulnerabilities**: Minder geïnstalleerde packages
- ✅ **Clean runtime**: Alleen wat nodig is voor productie

### Geavanceerde multi-stage technieken

**Verschillende targets voor verschillende omgevingen:**

```dockerfile
# Base stage
FROM node:18 AS base
WORKDIR /app
COPY package*.json ./

# Development stage
FROM base AS development
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]

# Build stage
FROM base AS build
RUN npm ci
COPY . .
RUN npm run build
RUN npm run test

# Production stage
FROM node:18-alpine AS production
WORKDIR /app
RUN npm ci --only=production
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/server.js"]

# Testing stage
FROM build AS testing
RUN npm run test:coverage
CMD ["npm", "run", "test:watch"]
```

**Bouwen van specifieke stages:**
```bash
# Development image
docker build --target development -t my-app:dev .

# Production image  
docker build --target production -t my-app:prod .

# Testing image
docker build --target testing -t my-app:test .
```

---

## Fase 7: .dockerignore - Het vergeten hulpmiddel

### Waarom .dockerignore belangrijk is

**Zonder .dockerignore wordt ALLES gekopieerd:**
```bash
# In project directory
ls -la
# .git/
# node_modules/
# *.log
# coverage/
# README.md
# src/
# ...EVERYTHING
```

**Build context wordt enorm:**
```bash
docker build .
# Sending build context to Docker daemon 2.5GB
# (Inclusief .git, node_modules, logs, etc.)
```

### .dockerignore syntax

**Basis .dockerignore bestand:**
```bash
# Version control
.git
.gitignore

# Dependencies
node_modules
npm-debug.log*

# Build outputs
dist
build
coverage

# Environment files
.env
.env.local
.env.production

# IDE files
.vscode
.idea
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
logs
*.log

# Documentation
README.md
*.md
docs/

# Docker files (don't copy Dockerfile into image)
Dockerfile
.dockerignore
docker-compose.yml
```

**Geavanceerde patterns:**
```bash
# Negatie (!) om specifieke bestanden toch mee te nemen
node_modules
!node_modules/needed-package

# Wildcards
*.tmp
temp*

# Directory patterns
**/logs
**/coverage

# Alleen root niveau
/README.md        # Alleen root README.md
README.md         # Alle README.md bestanden
```

### Impact op build performance

**Voor .dockerignore:**
```bash
$ docker build .
Sending build context to Docker daemon  2.5GB
Step 1/8 : FROM node:18
```

**Na .dockerignore:**
```bash
$ docker build .
Sending build context to Docker daemon  15MB
Step 1/8 : FROM node:18
```

**Benefits:**
- ⚡ **Snellere builds**: Kleinere context = snellere upload naar Docker daemon
- 🔒 **Security**: Geen gevoelige bestanden in image
- 📦 **Kleinere images**: Minder onnodige bestanden
- 🎯 **Focus**: Alleen relevante bestanden in context

---

## Fase 8: Build proces en optimalisatie

### Het docker build commando

**Basis build:**
```bash
docker build -t my-app:latest .
```

**Build met argumenten:**
```bash
docker build \
  --build-arg NODE_VERSION=18 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  -t my-app:v1.2.3 \
  .
```

**Build verschillende stages:**
```bash
# Development build
docker build --target development -t my-app:dev .

# Production build
docker build --target production -t my-app:prod .
```

**Build met custom Dockerfile:**
```bash
docker build -f Dockerfile.prod -t my-app:prod .
```

### Build cache optimalisatie

**Cache effectief gebruiken:**

```dockerfile
# ❌ Slecht: Elke code wijziging vereist dependency reinstall
FROM node:18
COPY . /app
WORKDIR /app
RUN npm install

# ✅ Goed: Dependencies worden gecached
FROM node:18
WORKDIR /app
COPY package*.json ./          # Alleen als dependencies wijzigen
RUN npm ci                     # Deze layer wordt gecached
COPY . .                       # Code wijzigingen breken cache hier
```

**BuildKit voor betere performance:**
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
docker build .

# Of per commando
DOCKER_BUILDKIT=1 docker build .
```

### Build argumenten en variabelen

**Flexibele builds met ARG:**
```dockerfile
ARG NODE_VERSION=18
ARG APP_PORT=3000

FROM node:${NODE_VERSION}

WORKDIR /app

ARG BUILD_DATE
ARG VERSION
ARG COMMIT_SHA

# Labels voor metadata
LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.revision=$COMMIT_SHA

ENV PORT=$APP_PORT

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE $APP_PORT

CMD ["node", "server.js"]
```

**Build met CI/CD metadata:**
```bash
docker build \
  --build-arg NODE_VERSION=18 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=$CI_COMMIT_TAG \
  --build-arg COMMIT_SHA=$CI_COMMIT_SHA \
  -t my-app:$CI_COMMIT_TAG \
  .
```

### Image grootte optimalisatie

**Technieken voor kleinere images:**

1. **Alpine Linux basis images:**
```dockerfile
# Groot: ~900MB
FROM node:18

# Klein: ~150MB  
FROM node:18-alpine
```

2. **Multi-stage builds:**
```dockerfile
FROM node:18 AS builder
# ... build steps

FROM node:18-alpine AS production
COPY --from=builder /app/dist ./dist
```

3. **Package cleanup:**
```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

4. **Distroless images voor ultieme security:**
```dockerfile
FROM gcr.io/distroless/nodejs18-debian11
COPY --from=builder /app/dist /app
WORKDIR /app
CMD ["server.js"]
```

### Build debugging

**Inspecteer build stappen:**
```bash
# Bekijk build geschiedenis
docker history my-app:latest

# Debug build met intermediate containers
docker build --no-cache .

# Stop build bij specifieke stage voor debugging
docker build --target development .
docker run -it my-app:dev sh
```

**Troubleshooting veelvoorkomende problemen:**

1. **"COPY failed: no such file or directory"**
```bash
# Check build context
docker build --no-cache --progress=plain .

# Verify .dockerignore
cat .dockerignore
```

2. **"Package not found" errors:**
```dockerfile
# Update package index voor installaties
RUN apt-get update && apt-get install -y package-name

# Voor Alpine
RUN apk update && apk add package-name
```

3. **Permission denied errors:**
```dockerfile
# Set correct ownership
COPY --chown=user:group file destination

# Or fix permissions
RUN chown -R user:group /app
```

---

## Fase 9: Security best practices

### Container security fundamentals

**1. Non-root gebruikers:**
```dockerfile
# Maak dedicated user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Switch naar non-root
USER appuser

# Voor Alpine
RUN addgroup -g 1001 -S appgroup \
    && adduser -S appuser -u 1001 -G appgroup

# Voor Ubuntu/Debian
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
```

**2. Minimale privileges:**
```dockerfile
# Alleen nodige capabilities
FROM nginx:alpine
RUN apk add --no-cache curl
# Geen sudo, geen package managers in production image
```

**3. Read-only root filesystem:**
```dockerfile
# Maak writable directories
RUN mkdir -p /app/tmp /app/logs \
    && chown appuser:appgroup /app/tmp /app/logs

USER appuser

# Run met read-only root
# docker run --read-only --tmpfs /app/tmp my-app
```

### Vulnerability scanning

**Scan images voor kwetsbaarheden:**
```bash
# Docker Scout (built-in)
docker scout quickview my-app:latest
docker scout cves my-app:latest

# Trivy scanner
trivy image my-app:latest

# Snyk scanner
snyk container test my-app:latest
```

**Security in CI/CD:**
```yaml
# GitHub Actions voorbeeld
name: Security Scan
on: [push]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: docker build -t ${{ github.sha }} .
      - name: Run Trivy scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
```

### Secrets management

**❌ NEVER do this:**
```dockerfile
# SLECHT: Secrets in Dockerfile
ENV DATABASE_PASSWORD=secret123
ENV API_KEY=abc123def456

# SLECHT: Secrets in build args
ARG DATABASE_PASSWORD
ENV DATABASE_PASSWORD=$DATABASE_PASSWORD
```

**✅ Proper secrets handling:**
```dockerfile
# Gebruik environment variabelen tijdens runtime
ENV DATABASE_PASSWORD_FILE=/run/secrets/db_password

# Of verwijs naar secret management systeem
ENV DATABASE_PASSWORD_FROM=vault:secret/db#password
```

**Runtime secrets:**
```bash
# Met Docker secrets (Swarm)
echo "secret123" | docker secret create db_password -
docker service create --secret db_password my-app

# Met environment files
docker run --env-file .env.production my-app

# Met externe secret management
docker run -e DATABASE_PASSWORD="$(vault kv get -field=password secret/db)" my-app
```

---

## Fase 10: Production-ready Dockerfile

### Complete productie voorbeeld

**Volledig geoptimaliseerde Dockerfile voor Node.js:**

```dockerfile
# Multi-stage build for Node.js application
ARG NODE_VERSION=18
ARG ALPINE_VERSION=3.18

# Stage 1: Base with dependencies
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS base

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache \
        dumb-init \
        curl \
        tzdata \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Stage 2: Dependencies installation
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci --include=dev && npm cache clean --force

# Stage 3: Build application
FROM deps AS build
WORKDIR /app

# Copy source code
COPY . .

# Build application
RUN npm run build

# Run tests
RUN npm run test

# Stage 4: Production runtime
FROM base AS production

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Metadata
LABEL maintainer="your-email@company.com"
LABEL version="1.0.0"
LABEL description="Production Node.js application"

WORKDIR /app

# Copy package files and install only production deps
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy built application from build stage
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist

# Create necessary directories with correct permissions
RUN mkdir -p /app/logs /app/tmp && \
    chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# Expose port
EXPOSE ${PORT}

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

**.dockerignore voor productie:**
```
# Development files
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs (will be generated)
dist
build
coverage
.nyc_output

# Environment files
.env*
!.env.example

# Git
.git
.gitignore

# IDE
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Documentation
README.md
*.md
docs/

# Docker
Dockerfile*
.dockerignore
docker-compose*.yml

# Testing
test/
tests/
__tests__/
*.test.js
*.spec.js

# Logs
logs/
*.log

# Temporary files
tmp/
temp/
```

### CI/CD integratie

**GitHub Actions workflow:**
```yaml
name: Build and Deploy
on:
  push:
    branches: [main]
    tags: ['v*']

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          build-args: |
            BUILD_DATE=${{ fromJSON(steps.meta.outputs.json).labels['org.opencontainers.image.created'] }}
            VERSION=${{ fromJSON(steps.meta.outputs.json).labels['org.opencontainers.image.version'] }}
            COMMIT_SHA=${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## Conclusie: Van experiment naar productie

### De reis die we hebben afgelegd

**We begonnen met het probleem:**
```bash
# Lokaal werkt het...
docker run -p 8080:80 -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" nginx
# Maar hoe delen we dit?
```

**En eindigden met een professionele oplossing:**
```bash
# Reproduceerbaar, veilig, en distribueerbaar
docker run -p 8080:80 my-company/my-app:v1.2.3
```

### Wat je hebt geleerd

**Fundamentele concepten:**
- ✅ **Container vs Image**: Het verschil en wanneer je wat gebruikt
- ✅ **Dockerfile instructies**: Van basis tot geavanceerd
- ✅ **Layer systeem**: Hoe Docker images opgebouwd zijn
- ✅ **Caching optimalisatie**: Snellere builds door slimme volgorde

**Praktische vaardigheden:**
- ✅ **Multi-stage builds**: Productie-optimale images
- ✅ **Security best practices**: Non-root users, vulnerability scanning
- ✅ **Performance optimalisatie**: Kleinere images, snellere builds
- ✅ **CI/CD integratie**: Geautomatiseerde builds en deployments

### Best practices samenvatting

**Development Dockerfile:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
```

**Production Dockerfile:**
```dockerfile
# Multi-stage met security en optimalisatie
FROM node:18-alpine AS base
RUN apk add --no-cache dumb-init
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001 -G nodejs

FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM deps AS build
COPY . .
RUN npm run build && npm run test

FROM base AS production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
USER nodejs
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
EXPOSE 3000
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### De volgende stap

Met deze kennis kun je:
- 🚀 **Professionele images bouwen** voor elk type applicatie
- 🏗️ **CI/CD pipelines opzetten** met geautomatiseerde builds
- 🔒 **Security-first denken** bij container development
- 📈 **Optimaliseren voor performance** en kosten
- 🌍 **Schalen naar productie** met vertrouwen

**Je bent nu klaar voor:**
- Docker Compose orchestratie (zie `../03-Compose/compose.md`)
- Kubernetes deployments
- Container monitoring en logging
- Service mesh architecturen
- Cloud-native development

Docker containers zijn niet langer een mysterie - ze zijn je tool voor moderne software development! 🎉