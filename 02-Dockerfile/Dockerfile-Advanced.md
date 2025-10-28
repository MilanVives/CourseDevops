# Geavanceerde Dockerfile Instructies

## Inleiding

Nu we de basis van Dockerfiles kennen, is het tijd om verder te gaan met meer geavanceerde instructies en technieken. Deze tutorial behandelt minder bekende maar zeer krachtige Dockerfile instructies die je helpen om meer efficiënte, veilige en geoptimaliseerde Docker images te bouwen.

## 1. ARG - Build-time Variabelen

De `ARG` instructie definieert variabelen die tijdens de build-tijd kunnen worden doorgegeven.

### Basis Gebruik

```dockerfile
# Definieer een build argument
ARG NODE_VERSION=18

# Gebruik het argument in FROM
FROM node:${NODE_VERSION}

# Definieer meer argumenten met standaardwaarden
ARG APP_ENV=production
ARG BUILD_DATE
ARG VERSION=1.0.0

# Gebruik argumenten in andere instructies
LABEL build_date=${BUILD_DATE}
LABEL version=${VERSION}
LABEL environment=${APP_ENV}
```

### Build met Argumenten

```bash
# Build met standaardwaarden
docker build -t myapp .

# Build met custom waarden
docker build \
  --build-arg NODE_VERSION=20 \
  --build-arg APP_ENV=development \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VERSION=2.1.0 \
  -t myapp:dev .
```

### Geavanceerd ARG Gebruik

```dockerfile
# Globale ARGs (beschikbaar in alle stages)
ARG BUILDPLATFORM
ARG TARGETPLATFORM

FROM --platform=${BUILDPLATFORM} alpine AS builder
ARG TARGETPLATFORM
RUN echo "Ik bouw op ${BUILDPLATFORM} voor ${TARGETPLATFORM}"

# Stage-specifieke ARGs
FROM node:18 AS runtime
ARG APP_ENV
ARG DEBUG_ENABLED=false

# ARG herdefiniëren na FROM
ARG VERSION
LABEL app.version=${VERSION}
```

## 2. ONBUILD - Trigger Instructies

`ONBUILD` instructies worden uitgevoerd wanneer de image als basis wordt gebruikt voor een andere build.

### Parent Image met ONBUILD

```dockerfile
# mybase:latest
FROM node:18

# Deze instructies worden uitgevoerd in child images
ONBUILD COPY package*.json ./
ONBUILD RUN npm ci --only=production
ONBUILD COPY . .

WORKDIR /app
EXPOSE 3000
CMD ["node", "index.js"]
```

### Child Image

```dockerfile
# Deze build zal automatisch de ONBUILD instructies uitvoeren
FROM mybase:latest

# Automatisch uitgevoerd:
# COPY package*.json ./
# RUN npm ci --only=production  
# COPY . .
```

### Praktisch Voorbeeld

```dockerfile
# Base image voor Node.js apps
FROM node:18-alpine AS nodebase

WORKDIR /app

# Setup voor alle Node.js projecten
ONBUILD COPY package*.json ./
ONBUILD RUN npm ci --only=production && npm cache clean --force
ONBUILD COPY . .
ONBUILD RUN chown -R node:node /app

USER node
EXPOSE 3000
```

## 3. STOPSIGNAL - Graceful Shutdown

Definieer welk signaal naar de container wordt gestuurd om deze stop te zetten.

```dockerfile
FROM nginx:alpine

# Gebruik SIGQUIT voor nginx (standaard is SIGTERM)
STOPSIGNAL SIGQUIT

# Voor Node.js applicaties
# STOPSIGNAL SIGTERM

# Voor Java applicaties  
# STOPSIGNAL SIGTERM
```

### Graceful Shutdown in Node.js

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Zorg voor graceful shutdown
STOPSIGNAL SIGTERM

# Script dat SIGTERM afhandelt
CMD ["node", "server.js"]
```

```javascript
// server.js - graceful shutdown handling
process.on('SIGTERM', () => {
  console.log('SIGTERM ontvangen, server wordt afgesloten...');
  server.close(() => {
    console.log('Server afgesloten');
    process.exit(0);
  });
});
```

## 4. SHELL - Custom Shell

Wijzig de standaard shell voor RUN, CMD en ENTRYPOINT instructies.

### Windows Containers

```dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2019

# Gebruik PowerShell in plaats van cmd
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

RUN Write-Host 'Hello from PowerShell!'

# Of gebruik cmd met specifieke opties
SHELL ["cmd", "/S", "/C"]
RUN echo "Hello from cmd"
```

### Linux met Custom Shell

```dockerfile
FROM ubuntu:20.04

# Gebruik bash met strikte foutafhandeling
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

# Nu zullen alle RUN commands deze shell gebruiken
RUN apt-get update
RUN apt-get install -y python3

# Reset naar standaard shell
SHELL ["/bin/sh", "-c"]
```

## 5. HEALTHCHECK - Container Health Monitoring

Definieer hoe Docker de health van je container kan controleren.

### Basis Healthcheck

```dockerfile
FROM nginx:alpine

# Eenvoudige HTTP healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

# Installeer curl voor healthcheck
RUN apk add --no-cache curl
```

### Geavanceerde Healthcheck

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Custom healthcheck script
COPY healthcheck.js ./

# Geavanceerde healthcheck configuratie
HEALTHCHECK \
  --interval=30s \
  --timeout=10s \
  --start-period=60s \
  --retries=3 \
  CMD node healthcheck.js

EXPOSE 3000
CMD ["node", "server.js"]
```

```javascript
// healthcheck.js
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 5000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0); // Healthy
  } else {
    process.exit(1); // Unhealthy
  }
});

req.on('error', () => {
  process.exit(1); // Unhealthy
});

req.on('timeout', () => {
  req.destroy();
  process.exit(1); // Unhealthy
});

req.end();
```

### Database Healthcheck

```dockerfile
FROM postgres:15-alpine

# PostgreSQL healthcheck
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
  CMD pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} || exit 1
```

## 6. LABEL - Metadata en Annotaties

Voeg metadata toe aan je images voor betere organisatie en automatisering.

### Standaard Labels

```dockerfile
FROM node:18-alpine

# OCI (Open Container Initiative) labels
LABEL org.opencontainers.image.title="My Application"
LABEL org.opencontainers.image.description="Een voorbeeldapplicatie"
LABEL org.opencontainers.image.version="1.2.3"
LABEL org.opencontainers.image.authors="john@example.com"
LABEL org.opencontainers.image.url="https://github.com/user/repo"
LABEL org.opencontainers.image.source="https://github.com/user/repo"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${GIT_COMMIT}"

# Custom labels
LABEL com.company.team="devops"
LABEL com.company.environment="production"
LABEL maintainer="devops@company.com"
```

### Multi-line Labels

```dockerfile
# Efficiënte manier om meerdere labels te definiëren
LABEL org.opencontainers.image.title="My App" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.description="Een geweldige applicatie" \
      maintainer="dev@company.com"
```

### Labels bekijken

```bash
# Bekijk labels van een image
docker image inspect myapp:latest | jq '.[0].Config.Labels'

# Filter images op labels
docker images --filter "label=org.opencontainers.image.version=1.0.0"
```

## 7. Multi-stage Builds Geavanceerd

### Named Stages en Selective Copy

```dockerfile
# Build stage
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Test stage
FROM dependencies AS test
COPY . .
RUN npm test

# Build stage
FROM dependencies AS build
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=build /app/dist /usr/share/nginx/html

# Development stage met alle dependencies
FROM dependencies AS development
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
```

### Build Specific Stages

```bash
# Build alleen de test stage
docker build --target test -t myapp:test .

# Build alleen production
docker build --target production -t myapp:prod .

# Build development
docker build --target development -t myapp:dev .
```

### Cross-platform Builds

```dockerfile
FROM --platform=$BUILDPLATFORM node:18-alpine AS build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN echo "Ik bouw op $BUILDPLATFORM, target is $TARGETPLATFORM"

# Install dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Build application
COPY . .
RUN npm run build

# Runtime stage
FROM --platform=$TARGETPLATFORM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

## 8. .dockerignore Geavanceerd

### Complexe Ignore Patterns

```dockerignore
# Negatie patterns
*
!src/
!package*.json
!public/
!*.config.js

# Specifieke uitzonderingen
**/*.log
**/*.tmp
!important.log

# Conditionele patterns
**/.git
**/node_modules
**/.env.local
**/.env.*.local

# Build artifacts
dist/
build/
*.tgz
*.tar.gz

# Test files
**/__tests__/
**/*.test.js
**/*.spec.js
coverage/

# Documentation
docs/
*.md
!README.md

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db
```

## 9. Security Best Practices

### Non-root User

```dockerfile
FROM node:18-alpine

# Maak een specifieke user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs

WORKDIR /app

# Kopieer en installeer als root
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Verander ownership
COPY --chown=nodejs:nodejs . .

# Switch naar non-root user
USER nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

### Minimale Attack Surface

```dockerfile
FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Distroless image voor minimale attack surface
FROM gcr.io/distroless/nodejs18-debian11

WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./

EXPOSE 3000
CMD ["dist/server.js"]
```

### Secrets Handling

```dockerfile
FROM alpine:latest

# NOOIT secrets in de image
# FOUT: ENV DATABASE_PASSWORD=secret123

# Gebruik mount secrets (BuildKit)
RUN --mount=type=secret,id=db_password \
    DB_PASSWORD=$(cat /run/secrets/db_password) && \
    echo "Connecting with password from secret..."

# Of gebruik multi-stage zonder secrets in final image
FROM alpine AS config
RUN --mount=type=secret,id=config \
    cp /run/secrets/config /tmp/config

FROM alpine AS final
COPY --from=config /tmp/config /app/config
```

```bash
# Build met secrets
echo "mysecret" | docker build --secret id=db_password,src=- .
```

## 10. BuildKit Features

### Cache Mounts

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Cache npm downloads
RUN --mount=type=cache,target=/root/.npm \
    npm install -g npm@latest

COPY package*.json ./

# Cache node_modules
RUN --mount=type=cache,target=/app/node_modules \
    --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .
RUN npm run build
```

### Bind Mounts

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Bind mount voor local files tijdens build
RUN --mount=type=bind,source=.,target=. \
    npm run test
```

### SSH Mounts

```dockerfile
FROM alpine:latest

# SSH mount voor private repositories
RUN --mount=type=ssh \
    apk add --no-cache git openssh-client && \
    git clone git@github.com:company/private-repo.git
```

## 11. Praktische Voorbeelden

### Production-ready Node.js Application

```dockerfile
# syntax=docker/dockerfile:1
FROM node:18-alpine AS base

# Installeer dumb-init voor proper signal handling
RUN apk add --no-cache dumb-init

# Maak app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs

WORKDIR /app
RUN chown nodejs:nodejs /app

# Dependencies stage
FROM base AS dependencies

# Cache npm dependencies
RUN --mount=type=cache,target=/root/.npm \
    npm config set cache /root/.npm

COPY --chown=nodejs:nodejs package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production && \
    npm cache clean --force

# Development dependencies
FROM dependencies AS dev-dependencies
RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Build stage
FROM dev-dependencies AS build
COPY --chown=nodejs:nodejs . .
RUN npm run build
RUN npm run test

# Production stage
FROM base AS production

# Copy production dependencies
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy built application
COPY --from=build --chown=nodejs:nodejs /app/dist ./dist
COPY --chown=nodejs:nodejs package*.json ./

USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD node dist/healthcheck.js

EXPOSE 3000

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### Multi-architecture Build

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM node:18-alpine AS build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

WORKDIR /app

# Platform-specific optimizations
RUN --mount=type=cache,target=/root/.npm \
    if [ "$TARGETARCH" = "arm64" ]; then \
        npm config set target_arch arm64; \
    fi

COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY . .
RUN npm run build

# Runtime
FROM --platform=$TARGETPLATFORM node:18-alpine

WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY package*.json ./

USER 1001
CMD ["node", "dist/server.js"]
```

## Conclusie

Deze geavanceerde Dockerfile instructies geven je veel meer controle over je container builds. Door deze technieken te gebruiken kun je:

- **Flexibelere builds** maken met ARG en ONBUILD
- **Betere monitoring** implementeren met HEALTHCHECK
- **Veiligere containers** bouwen met proper user management
- **Efficiëntere builds** creëren met cache mounts en multi-stage builds
- **Platform-agnostische images** ontwikkelen

Experimenteer met deze technieken in je eigen projecten en zie hoe ze je Docker workflow kunnen verbeteren!

## Nuttige Links

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [BuildKit Features](https://docs.docker.com/build/buildkit/)
- [Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Security Best Practices](https://docs.docker.com/develop/security/)