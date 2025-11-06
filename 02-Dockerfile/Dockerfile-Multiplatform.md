# Multi-platform Docker Images

## Introduction

When building Docker images on macOS (ARM64/Apple Silicon) or other ARM architectures, you may encounter issues running images on different platforms. Multi-platform builds solve this by creating images that work across different CPU architectures (amd64, arm64, etc.).

## Why Multi-platform?

- **ARM Macs (M1/M2/M3)**: Need arm64 images locally but amd64 for cloud deployment
- **Cloud servers**: Most cloud providers use amd64 (x86_64) architecture
- **Team compatibility**: Different team members may use different architectures
- **CI/CD pipelines**: Often run on amd64 architecture

## Setup

Enable Docker BuildKit (required for multi-platform builds):

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Create and use a new builder instance (supports multi-platform)
docker buildx create --name multiplatform-builder --use

# Verify builder supports multiple platforms
docker buildx inspect --bootstrap
```

## Example 1: Static HTML/JS Website

### Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY app.js /usr/share/nginx/html/

EXPOSE 80
```

### Build Commands

```bash
# Build for current platform only
docker buildx build -t mywebsite:latest .

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t mywebsite:latest \
  .

# Build and push to registry (required for multi-platform)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myusername/mywebsite:latest \
  --push \
  .

# Build and load locally (single platform only)
docker buildx build \
  --platform linux/arm64 \
  -t mywebsite:latest \
  --load \
  .
```

## Example 2: Node.js API

### Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
```

### Build Commands

```bash
# Build for both amd64 and arm64
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myapi:latest \
  .

# Build with specific tag and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myusername/myapi:1.0.0 \
  -t myusername/myapi:latest \
  --push \
  .

# Build for amd64 only (for cloud deployment)
docker buildx build \
  --platform linux/amd64 \
  -t myapi:amd64 \
  --load \
  .
```

## Example 3: Java Spring Boot API

### Dockerfile

```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app
COPY pom.xml .
COPY src ./src

# Build with Maven wrapper
COPY mvnw .
COPY .mvn .mvn
RUN ./mvnw clean package -DskipTests

# Production stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Alternative with Gradle

```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle
COPY src ./src

RUN ./gradlew build -x test

# Production stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Build Commands

```bash
# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myusername/springboot-api:latest \
  --push \
  .

# Build with specific Java options
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg JAVA_OPTS="-Xmx512m -Xms256m" \
  -t myusername/springboot-api:latest \
  --push \
  .

# Build for production with version tag
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myusername/springboot-api:1.0.0 \
  -t myusername/springboot-api:latest \
  --push \
  .
```

## Multi-stage Build Example (Node.js)

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist

EXPOSE 3000
CMD ["node", "dist/server.js"]
```

```bash
# Build multi-platform with multi-stage
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myusername/myapi:latest \
  --push \
  .
```

## Common Commands Cheat Sheet

```bash
# List available builders
docker buildx ls

# Create new builder
docker buildx create --name mybuilder --use

# Remove builder
docker buildx rm mybuilder

# Inspect current builder
docker buildx inspect

# Build for Mac (ARM) and Linux (AMD)
docker buildx build --platform linux/amd64,linux/arm64 -t myapp .

# Build and save to local Docker (single platform)
docker buildx build --platform linux/arm64 -t myapp --load .

# Build and push to registry (multiple platforms)
docker buildx build --platform linux/amd64,linux/arm64 -t user/myapp --push .
```

## Key Points

- **`--platform`**: Specify target architectures (linux/amd64, linux/arm64, linux/arm/v7)
- **`--push`**: Required when building for multiple platforms (images stored in registry)
- **`--load`**: Load image to local Docker (works with single platform only)
- **BuildKit**: Must be enabled for multi-platform builds
- **Base images**: Ensure your base images support target platforms

## Troubleshooting

**Error: "multiple platforms feature is currently not supported for docker driver"**
```bash
# Solution: Create a buildx builder
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
```

**Error: "failed to solve: failed to push"**
```bash
# Solution: Login to Docker Hub first
docker login
```

**Local testing on different platform**
```bash
# Build for amd64 on ARM Mac
docker buildx build --platform linux/amd64 -t myapp:amd64 --load .

# Run it (uses emulation, slower)
docker run --platform linux/amd64 myapp:amd64
```
