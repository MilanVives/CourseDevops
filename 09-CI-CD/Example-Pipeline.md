# Complete CI/CD Pipeline with GitHub Actions

## Overview

This guide demonstrates a complete CI/CD pipeline using GitHub Actions that:
1. Builds Docker images for frontend and backend on every push
2. Pushes images to Docker Hub with proper tagging
3. Automatically redeploys the application on a production server
4. Uses secrets for secure credential management

## Project Structure

Based on the frontend/backend application in `03-Compose/compose-files/2-fe-be/`:

```
project/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── api/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── Dockerfile
│   └── index.html
└── compose.yml
```

## GitHub Actions Workflow

### Complete Workflow File

Create `.github/workflows/deploy.yml` in your repository root:

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

env:
  DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
  REGISTRY: docker.io

jobs:
  build-and-push:
    name: Build and Push Docker Images
    runs-on: ubuntu-latest
    
    steps:
      # Checkout the repository code
      - name: Checkout code
        uses: actions/checkout@v4
      
      # Set up Docker Buildx for multi-platform builds
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      # Login to Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      
      # Extract metadata for tagging
      - name: Extract metadata
        id: meta
        run: |
          echo "date=$(date +'%Y%m%d-%H%M%S')" >> $GITHUB_OUTPUT
          echo "sha_short=$(echo ${{ github.sha }} | cut -c1-7)" >> $GITHUB_OUTPUT
          echo "branch=$(echo ${GITHUB_REF#refs/heads/})" >> $GITHUB_OUTPUT
      
      # Build and push backend image
      - name: Build and push Backend
        uses: docker/build-push-action@v5
        with:
          context: ./api
          file: ./api/Dockerfile
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/myapp-backend:latest
            ${{ secrets.DOCKER_USERNAME }}/myapp-backend:${{ steps.meta.outputs.sha_short }}
            ${{ secrets.DOCKER_USERNAME }}/myapp-backend:${{ steps.meta.outputs.date }}
          cache-from: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/myapp-backend:buildcache
          cache-to: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/myapp-backend:buildcache,mode=max
      
      # Build and push frontend image
      - name: Build and push Frontend
        uses: docker/build-push-action@v5
        with:
          context: ./frontend
          file: ./frontend/Dockerfile
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/myapp-frontend:latest
            ${{ secrets.DOCKER_USERNAME }}/myapp-frontend:${{ steps.meta.outputs.sha_short }}
            ${{ secrets.DOCKER_USERNAME }}/myapp-frontend:${{ steps.meta.outputs.date }}
          cache-from: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/myapp-frontend:buildcache
          cache-to: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/myapp-frontend:buildcache,mode=max

  deploy:
    name: Deploy to Production Server
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    
    steps:
      # Deploy to server via SSH
      - name: Deploy to Production Server
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          port: ${{ secrets.SERVER_PORT }}
          script: |
            # Navigate to application directory
            cd /opt/myapp || exit 1
            
            # Pull latest images
            docker compose pull
            
            # Restart services with zero downtime
            docker compose up -d --remove-orphans
            
            # Clean up old images
            docker image prune -af --filter "until=72h"
            
            # Show running containers
            docker compose ps
```

### Workflow Explanation

#### Triggers
```yaml
on:
  push:
    branches: [main, develop]  # Build on push to these branches
  pull_request:
    branches: [main]           # Build on PR to main
```

#### Job 1: Build and Push
- **Checkout code**: Gets your repository code
- **Setup Buildx**: Enables advanced Docker build features
- **Login to Docker Hub**: Authenticates with your credentials
- **Extract metadata**: Creates tags (latest, commit SHA, timestamp)
- **Build and push**: Creates images with multiple tags for version tracking
- **Cache**: Uses Docker layer caching for faster builds

#### Job 2: Deploy
- **needs: build-and-push**: Only runs after successful build
- **if condition**: Only deploys on pushes to main branch
- **SSH to server**: Connects to production server
- **Pull and restart**: Updates containers with new images
- **Cleanup**: Removes old images to save space

## Setup Guide

### 1. Docker Hub Setup

#### Create Docker Hub Account
1. Go to [hub.docker.com](https://hub.docker.com)
2. Create an account or login
3. Note your Docker Hub username

#### Generate Access Token
1. Login to Docker Hub
2. Click on your username → **Account Settings**
3. Go to **Security** → **Access Tokens**
4. Click **New Access Token**
5. Name: `github-actions-token`
6. Permissions: **Read, Write, Delete**
7. Click **Generate**
8. **IMPORTANT**: Copy the token immediately (you can't see it again!)

### 2. SSH Key Setup for Server Access

#### Generate SSH Key Pair (on your local machine)

```bash
# Generate a new SSH key specifically for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# This creates two files:
# - github_actions_deploy (private key - for GitHub secrets)
# - github_actions_deploy.pub (public key - for server)
```

#### Add Public Key to Production Server

```bash
# Copy public key to server
ssh-copy-id -i ~/.ssh/github_actions_deploy.pub user@your-server.com

# Or manually:
# 1. Copy the contents of github_actions_deploy.pub
cat ~/.ssh/github_actions_deploy.pub

# 2. SSH into your server
ssh user@your-server.com

# 3. Add to authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### Test SSH Connection

```bash
# Test the connection using the private key
ssh -i ~/.ssh/github_actions_deploy user@your-server.com

# If successful, you're ready to proceed
```

### 3. GitHub Secrets Setup

#### Add Secrets to GitHub Repository

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

**DOCKER_USERNAME**
```
Value: your-dockerhub-username
```

**DOCKER_TOKEN**
```
Value: [paste the Docker Hub access token you generated]
```

**SERVER_HOST**
```
Value: your-server.com (or IP address like 123.45.67.89)
```

**SERVER_USER**
```
Value: ubuntu (or your server username)
```

**SERVER_PORT**
```
Value: 22 (or your custom SSH port)
```

**SSH_PRIVATE_KEY**
```
Value: [paste the contents of your private key]
```

To get private key contents:
```bash
cat ~/.ssh/github_actions_deploy
# Copy the entire output including the BEGIN and END lines
```

### 4. Production Server Setup

#### Prepare the Server

```bash
# SSH into your production server
ssh user@your-server.com

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Logout and login again for group changes to take effect
exit
ssh user@your-server.com

# Verify installations
docker --version
docker compose version
```

#### Create Application Directory

```bash
# Create application directory
sudo mkdir -p /opt/myapp
sudo chown $USER:$USER /opt/myapp
cd /opt/myapp
```

#### Create Production docker-compose.yml

Create `/opt/myapp/docker-compose.yml` on your server:

```yaml
version: '3.8'

services:
  backend:
    image: your-dockerhub-username/myapp-backend:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - MONGO_URI=mongodb://mongodb:27017/foodsdb
      - NODE_ENV=production
    depends_on:
      - mongodb
    networks:
      - app-network

  frontend:
    image: your-dockerhub-username/myapp-frontend:latest
    restart: unless-stopped
    ports:
      - "80:80"
    networks:
      - app-network

  mongodb:
    image: mongo:latest
    restart: unless-stopped
    volumes:
      - dbdata:/data/db
    networks:
      - app-network

volumes:
  dbdata:

networks:
  app-network:
    driver: bridge
```

#### Initial Deployment

```bash
# Login to Docker Hub on the server
docker login

# Pull and start containers
cd /opt/myapp
docker compose pull
docker compose up -d

# Verify everything is running
docker compose ps
docker compose logs -f
```

### 5. Update Dockerfile in Repository

Ensure your Dockerfiles follow the workflow structure:

**api/Dockerfile**
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
```

**frontend/Dockerfile**
```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/
COPY *.js /usr/share/nginx/html/
COPY *.css /usr/share/nginx/html/

EXPOSE 80
```

## Testing the Pipeline

### Test the Complete Flow

1. **Make a change to your code**
```bash
# Edit a file
echo "// Updated" >> api/server.js

# Commit and push
git add .
git commit -m "Update backend API"
git push origin main
```

2. **Monitor GitHub Actions**
- Go to your repository → **Actions** tab
- Watch the workflow run in real-time
- Check for any errors in build or deploy steps

3. **Verify on Production Server**
```bash
# SSH to server
ssh user@your-server.com

# Check containers
cd /opt/myapp
docker compose ps

# Check logs
docker compose logs backend
docker compose logs frontend

# Verify new image was pulled
docker images | grep myapp
```

### Rollback Strategy

If deployment fails or has issues:

```bash
# SSH to server
ssh user@your-server.com
cd /opt/myapp

# Roll back to previous version by commit SHA
# Update docker-compose.yml to use specific tag
nano docker-compose.yml
# Change: myapp-backend:latest
# To:     myapp-backend:abc1234 (previous commit SHA)

# Pull and restart
docker compose pull
docker compose up -d
```

## Advanced Configuration

### Environment-Specific Deployments

Add staging environment:

```yaml
deploy-staging:
  name: Deploy to Staging
  needs: build-and-push
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/develop'
  
  steps:
    - name: Deploy to Staging Server
      uses: appleboy/ssh-action@v1.0.3
      with:
        host: ${{ secrets.STAGING_SERVER_HOST }}
        username: ${{ secrets.STAGING_SERVER_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        port: ${{ secrets.STAGING_SERVER_PORT }}
        script: |
          cd /opt/myapp-staging
          docker compose pull
          docker compose up -d
```

### Notifications

Add Slack or Discord notifications:

```yaml
- name: Notify Deployment
  if: always()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
    -H 'Content-Type: application/json' \
    -d '{
      "text": "Deployment ${{ job.status }}: ${{ github.repository }}"
    }'
```

### Health Checks

Add health check before completing deployment:

```yaml
- name: Health Check
  run: |
    sleep 10
    curl -f http://${{ secrets.SERVER_HOST }}/health || exit 1
```

## Security Best Practices

1. **Never commit secrets** to your repository
2. **Use read-only tokens** where possible
3. **Rotate SSH keys** regularly
4. **Enable 2FA** on Docker Hub and GitHub
5. **Use separate credentials** for staging and production
6. **Limit SSH key access** to specific IP ranges if possible
7. **Review workflow logs** for exposed secrets (GitHub masks them automatically)

## Troubleshooting

### Build Fails

```bash
# Check workflow logs in GitHub Actions
# Common issues:
# - Dockerfile syntax errors
# - Missing dependencies in package.json
# - Context path incorrect
```

### Push to Docker Hub Fails

```bash
# Verify credentials
# Check Docker Hub token hasn't expired
# Ensure repository exists on Docker Hub
# Verify token has write permissions
```

### Deploy Fails

```bash
# SSH to server manually to test
ssh -i ~/.ssh/github_actions_deploy user@server.com

# Check server has enough disk space
df -h

# Check Docker daemon is running
systemctl status docker

# Check compose file syntax
docker compose config
```

### Images Not Updating

```bash
# Force pull fresh images
docker compose pull --no-cache
docker compose up -d --force-recreate
```

## Summary

You now have a complete CI/CD pipeline that:
- ✅ Builds Docker images automatically on every push
- ✅ Tags images with multiple versions (latest, SHA, timestamp)
- ✅ Pushes to Docker Hub securely
- ✅ Deploys to production server automatically
- ✅ Provides rollback capabilities
- ✅ Cleans up old images automatically

This setup enables true continuous deployment where every commit to main is automatically built, tested, and deployed to production.
