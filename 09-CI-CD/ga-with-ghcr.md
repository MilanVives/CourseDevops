# Container Image Automatisch Pushen naar GitHub Container Registry (GHCR)

## Inhoudsopgave

1. [Introductie](#introductie)
2. [GitHub Personal Access Token (PAT) Aanmaken](#stap-1-github-personal-access-token-pat-aanmaken)
3. [Docker Login naar GHCR](#stap-2-docker-login-naar-ghcr)
4. [Container Image Bouwen](#stap-3-container-image-bouwen)
5. [Handmatig Pushen naar GHCR](#stap-4-handmatig-pushen-naar-ghcr)
6. [GitHub Actions Setup](#stap-5-build--push-automatiseren-met-github-actions)
7. [Verificatie](#verificatie)

---

## Introductie

In deze tutorial leren we hoe je een container image automatisch kunt deployen naar **GitHub Container Registry (GHCR)** met **GitHub Actions**.

### Wat is GitHub Container Registry?

**GitHub Container Registry (ghcr.io)** is de container registry van GitHub, vergelijkbaar met Docker Hub maar met een aantal voordelen:

- ✅ **Private by default**: Alle images zijn standaard private
- ✅ **Geïntegreerd**: Direct gekoppeld aan je GitHub repositories
- ✅ **Gratis**: Voor publieke en private repositories
- ✅ **Unified billing**: Facturatie via je GitHub account

### Waar vind je je Packages?

Onder het tabblad **Packages** op je GitHub Profiel kan je al je gepubliceerde container images zien:

**URL**: `https://github.com/USERNAME?tab=packages` (vervang USERNAME door je GitHub gebruikersnaam)

![GitHub Packages](../images/packages.png)

---

## Stap 1: GitHub Personal Access Token (PAT) Aanmaken

Om in te loggen op GHCR heb je een **Personal Access Token (PAT)** nodig van GitHub.

### 1.1 Navigeer naar Settings

Klik rechtsboven op je **GitHub gebruikersnaam** → **Settings** in de dropdown

![GitHub Settings](../images/settings.png)

### 1.2 Developer Settings

In het menu links, scroll helemaal naar beneden en klik op **Developer settings**

![Developer Settings](../images/devsettings.png)

### 1.3 Personal Access Token Genereren

1. Klik links op **Personal Access Tokens** → **Tokens (classic)**
2. Klik rechts op **Generate new token** → **Generate new token (classic)**

![Personal Access Token](../images/pat.png)

### 1.4 Token Configureren

Configureer je token als volgt:

**Note**: Geef je token een beschrijvende naam (bijvoorbeeld: `GHCR_ACCESS_TOKEN`)

**Expiration**: Kies een expiration date
- ⚠️ **Belangrijk**: Na deze datum werkt je token niet meer
- **Aanbeveling**: Kies een langere periode voor productie (90 dagen of meer)

**Select scopes**: Selecteer de volgende permissies:
- ✅ `write:packages` - Upload packages naar GitHub Package Registry
- ✅ `read:packages` - Download packages van GitHub Package Registry
- ✅ `delete:packages` - Delete packages van GitHub Package Registry (optioneel)

![PAT Permissions](../images/patperm.png)

### 1.5 Token Opslaan

1. Klik onderaan op **Generate token**
2. **⚠️ BELANGRIJK**: Kopieer de token **onmiddellijk** en sla deze op in een password manager
3. Eenmaal weggeklikt kan je de token **niet meer** zien

```
Voorbeeld token: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

## Stap 2: Docker Login naar GHCR

Nu gaan we inloggen op GHCR via de terminal:


### 2.1 Login Commando

**Methode 1: Via command line (minder veilig)**

```bash
docker login ghcr.io --username YOUR_GITHUB_USERNAME --password YOUR_PAT_TOKEN
```

**Voorbeeld:**
```bash
docker login ghcr.io --username MilanVives --password ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Output:**
```bash
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your credentials are stored unencrypted in '/Users/milan/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
```

**Methode 2: Via stdin (veiliger)** ✅ **Aanbevolen**

```bash
echo "YOUR_PAT_TOKEN" | docker login ghcr.io --username YOUR_GITHUB_USERNAME --password-stdin
```

### 2.2 Naamconventies voor GHCR Images

**Belangrijk**: Images voor GHCR moeten een specifieke naamgeving volgen:

**Format:**
```
ghcr.io/GITHUB_USERNAME/IMAGE_NAME:TAG
```

**Regels:**
- ✅ Prefix met `ghcr.io`
- ✅ Gevolgd door je GitHub username (lowercase!)
- ✅ Image naam (lowercase!)
- ✅ Optionele tag (default: `latest`)

**Voorbeelden:**
```bash
ghcr.io/milanvives/containerizedapp:latest
ghcr.io/milanvives/myapp:v1.0.0
ghcr.io/milanvives/backend:develop
```

⚠️ **Let op**: De volledige naam moet in **lowercase** zijn!

---

## Stap 3: Container Image Bouwen

Nu maken we een eenvoudige containerized applicatie om te testen.

### 3.1 Project Structuur

Maak een nieuwe directory aan voor je project:

```bash
mkdir containerizedapp
cd containerizedapp
```

### 3.2 Maak `script.sh`

Maak een eenvoudig bash script:

```bash
#!/bin/bash

echo "=== Hello from GHCR Container ==="
echo "Container is running successfully!"
echo "Built with GitHub Actions ✓"
```

**Maak het executable:**
```bash
chmod +x script.sh
```

### 3.3 Maak `Dockerfile`

```dockerfile
# Use Alpine Linux as base image (lightweight)
FROM alpine:latest

# Install bash
RUN apk add --no-cache bash

# Set working directory
WORKDIR /app

# Copy script
COPY script.sh .

# Make script executable
RUN chmod +x script.sh

# Run script on container start
ENTRYPOINT ["./script.sh"]
```

### 3.4 Build de Container Image

**Commando:**
```bash
docker build -t ghcr.io/YOUR_GITHUB_USERNAME/containerizedapp:latest .
```

**Voorbeeld:**
```bash
docker build -t ghcr.io/milanvives/containerizedapp:latest .
```

**Output:**
```bash
[+] Building 3.8s (11/11) FINISHED                         docker:desktop-linux
 => [internal] load build definition from Dockerfile                       0.0s
 => => transferring dockerfile: 160B                                       0.0s
 => [internal] load metadata for docker.io/library/alpine:latest           1.8s
 => [auth] library/alpine:pull token for registry-1.docker.io              0.0s
 => [internal] load .dockerignore                                          0.0s
 => => transferring context: 2B                                            0.0s
 => [1/5] FROM docker.io/library/alpine:latest@sha256:4b7ce07...           0.0s
 => [internal] load build context                                          0.0s
 => => transferring context: 85B                                           0.0s
 => [2/5] RUN apk add --no-cache bash                                      1.7s
 => [3/5] WORKDIR /app                                                     0.0s
 => [4/5] COPY script.sh .                                                 0.0s
 => [5/5] RUN chmod +x script.sh                                           0.1s
 => exporting to image                                                     0.0s
 => => exporting layers                                                    0.0s
 => => writing image sha256:f1ff4ce6dbbaab6df8550393274466b68156e1...      0.0s
 => => naming to ghcr.io/milanvives/containerizedapp:latest                0.0s
```

### 3.5 Test de Image Lokaal (Optioneel)

```bash
docker run --rm ghcr.io/milanvives/containerizedapp:latest
```

**Expected output:**
```bash
=== Hello from GHCR Container ===
Container is running successfully!
Built with GitHub Actions ✓
```

---

## Stap 4: Handmatig Pushen naar GHCR

### 4.1 Push de Image

**Commando:**
```bash
docker push ghcr.io/YOUR_GITHUB_USERNAME/containerizedapp:latest
```

**Voorbeeld:**
```bash
docker push ghcr.io/milanvives/containerizedapp:latest
```

**Output:**
```bash
The push refers to repository [ghcr.io/milanvives/containerizedapp]
0d9b595fd133: Pushed
5cecc193ecd1: Pushed
7abcdc4e5fd7: Pushed
a43bfea15c65: Pushed
0e64f2360a44: Pushed
latest: digest: sha256:0d7be30482f3c21c324935453d236520b23f2ef074177ed0529a4b11402a8449 size: 1358
```

### 4.2 Verificatie

Check je packages online:

**URL**: `https://github.com/YOUR_USERNAME?tab=packages`

**Voorbeeld**: https://github.com/MilanVives?tab=packages

![Gepushte Package](../images/package.png)

---

## Stap 5: Build & Push Automatiseren met GitHub Actions

Nu gaan we het build en push process automatiseren met GitHub Actions.


### 5.1 GitHub Repository Aanmaken

Maak een nieuwe repository aan op GitHub en push je code:

**Stap 1: Initialiseer Git Repository**

```bash
git init
git branch -M main
```

**Stap 2: Voeg Remote Repository Toe**

```bash
git remote add origin git@github.com:YOUR_USERNAME/containerizedapp.git
```

**Voorbeeld:**
```bash
git remote add origin git@github.com:MilanVives/containerizedapp.git
```

**Stap 3: Add, Commit, Push**

```bash
git add .
git commit -m "Initial commit: Add Dockerfile and script.sh"
git push -u origin main
```

**Output:**
```bash
Enumerating objects: 4, done.
Counting objects: 100% (4/4), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (4/4), 404 bytes | 404.00 KiB/s, done.
Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:MilanVives/containerizedapp.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

### 5.2 Directory Structuur voor GitHub Actions

Maak de benodigde directories aan:

```bash
mkdir -p .github/workflows
```

**Resulterende structuur:**
```
containerizedapp/
├── .github/
│   └── workflows/
│       └── publish-image.yml    # GitHub Actions workflow
├── Dockerfile
└── script.sh
```

### 5.3 GitHub Secret Configureren

We moeten de PAT token als secret toevoegen aan de repository.

**Stap 1: Navigeer naar Repository Settings**

Ga naar je repository op GitHub:
- Klik op **Settings** (rechtsboven)
- Klik links op **Secrets and variables** → **Actions**
- Klik op **New repository secret**

![Repository Secret](../images/secret.png)

**Stap 2: Secret Aanmaken**

- **Name**: `GH_PAT` (gebruik hoofdletters!)
- **Secret**: Plak je Personal Access Token (van stap 1.5)
- Klik op **Add secret**

**⚠️ Belangrijk**: 
- De naam moet EXACT `GH_PAT` zijn (hoofdletters)
- Je kunt de secret na het opslaan niet meer zien, alleen vervangen

### 5.4 GitHub Actions Workflow Maken

Maak een nieuw bestand aan: `.github/workflows/publish-image.yml`

**Volledige workflow:**

```yaml
name: Build and Push to GHCR

# Trigger: Bij elke push naar main branch
on:
  push:
    branches:
      - main
  # Optioneel: Handmatige trigger
  workflow_dispatch:

# Environment variables
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    # Permissies nodig voor GHCR
    permissions:
      contents: read
      packages: write

    steps:
      # Stap 1: Checkout code
      - name: Checkout repository
        uses: actions/checkout@v4

      # Stap 2: Login naar GHCR
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GH_PAT }}

      # Stap 3: Extract metadata (tags, labels)
      - name: Extract metadata for Docker
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            # Tag met branch naam
            type=ref,event=branch
            # Tag met commit SHA
            type=sha,prefix={{branch}}-
            # Tag 'latest' alleen voor main branch
            type=raw,value=latest,enable={{is_default_branch}}

      # Stap 4: Set up Docker Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Stap 5: Build en Push image
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          # Cache layers voor snellere builds
          cache-from: type=gha
          cache-to: type=gha,mode=max

      # Stap 6: Output image details
      - name: Image digest
        run: echo "Image pushed with digest ${{ steps.build.outputs.digest }}"
```

### 5.5 Uitleg van de Workflow

**Triggers:**
```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:
```
- Automatisch bij elke push naar `main` branch
- Handmatig via GitHub UI (`workflow_dispatch`)

**Permissions:**
```yaml
permissions:
  contents: read    # Lees repository inhoud
  packages: write   # Schrijf naar GHCR
```

**Environment Variables:**
```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}  # Automatisch: username/repo-name
```

**Metadata Tags:**
- `latest` - Voor main branch
- `main-abc1234` - Branch naam + SHA
- `main` - Branch naam

**Docker Buildx:**
- Multi-platform builds mogelijk
- Build caching (snellere builds)

### 5.6 Workflow Committen en Pushen

```bash
git add .github/workflows/publish-image.yml
git commit -m "Add GitHub Actions workflow for GHCR"
git push origin main
```

**Na de push:**
1. GitHub Actions start automatisch
2. Je kan de voortgang zien onder: **Actions** tab in je repository
3. Bij succes wordt de image naar GHCR gepusht

![Action Succeeded](../images/action.png)

---

## Verificatie

### 6.1 Check GitHub Actions Status

**Stap 1: Ga naar Actions Tab**

In je repository: Klik op **Actions** (bovenaan)

**Verwachte Output:**
- ✅ Groene check mark = Success
- ❌ Rode X = Failed

**Stap 2: Bekijk Logs (bij problemen)**

Klik op de workflow run → Klik op de job → Bekijk de logs

### 6.2 Verificeer Package op GHCR

**URL**: `https://github.com/YOUR_USERNAME?tab=packages`

Je zou nu je nieuwe package moeten zien met:
- Package naam
- Versie/Tags (latest, main-sha, etc.)
- Laatste update tijd

![Nieuwe Package Versie](../images/packagev2.png)

### 6.3 Pull en Test de Image

Test of de image correct werkt:

```bash
# Pull de image van GHCR
docker pull ghcr.io/YOUR_USERNAME/containerizedapp:latest

# Run de container
docker run --rm ghcr.io/YOUR_USERNAME/containerizedapp:latest
```

**Expected Output:**
```bash
=== Hello from GHCR Container ===
Container is running successfully!
Built with GitHub Actions ✓
```

---

## Troubleshooting

### Probleem 1: Permission Denied bij GHCR

**Error:**
```
Error: denied: permission_denied: write_package
```

**Oplossing:**
1. Check of `GH_PAT` secret correct is aangemaakt
2. Verify PAT heeft `write:packages` permissie
3. Check `permissions` in workflow file:
   ```yaml
   permissions:
     contents: read
     packages: write
   ```

### Probleem 2: Image Naam Incorrect

**Error:**
```
invalid reference format: repository name must be lowercase
```

**Oplossing:**
- GHCR vereist lowercase image namen
- Check of username en repository naam lowercase zijn
- Gebruik: `ghcr.io/milanvives/myapp` (lowercase)
- **Niet**: `ghcr.io/MilanVives/MyApp`

### Probleem 3: Workflow Triggered Niet

**Mogelijk redenen:**
1. Workflow file niet in `.github/workflows/` directory
2. YAML syntax errors
3. Branch naam komt niet overeen met trigger

**Verificatie:**
```bash
# Check YAML syntax
yamllint .github/workflows/publish-image.yml

# Check file locatie
ls -la .github/workflows/
```

### Probleem 4: PAT Expired

**Error:**
```
Error: Bad credentials
```

**Oplossing:**
1. Genereer nieuwe PAT (stap 1)
2. Update `GH_PAT` secret in repository settings

---

## Advanced: Package Visibility Aanpassen

### Public vs Private Packages

**Default**: GHCR packages zijn **private**

**Publiek maken:**
1. Ga naar je package: `https://github.com/users/USERNAME/packages/container/PACKAGE_NAME`
2. Klik op **Package settings** (rechtsboven)
3. Scroll naar beneden naar **Danger Zone**
4. Klik op **Change visibility** → **Public**

**⚠️ Waarschuwing**: Publieke packages kunnen door iedereen gepulled worden!

---

## Best Practices

### 1. Security

✅ **DO:**
- Gebruik PAT met minimale permissies (`read:packages`, `write:packages`)
- Sla PAT op in GitHub Secrets (NOOIT in code!)
- Gebruik expiration dates voor tokens
- Rotate tokens regelmatig

❌ **DON'T:**
- Commit PAT in code
- Gebruik PAT met `repo` of `admin` rechten als niet nodig
- Deel PAT met anderen

### 2. Tagging Strategy

**Semantic Versioning:**
```yaml
tags: |
  type=semver,pattern={{version}}
  type=semver,pattern={{major}}.{{minor}}
  type=semver,pattern={{major}}
  type=sha
```

**Branch-based:**
```yaml
tags: |
  type=ref,event=branch
  type=ref,event=pr
  type=sha,prefix={{branch}}-
```

### 3. Multi-stage Builds

**Optimaliseer je Dockerfile:**
```dockerfile
# Build stage
FROM alpine:latest AS builder
RUN apk add --no-cache bash
WORKDIR /app
COPY script.sh .
RUN chmod +x script.sh

# Runtime stage (smaller final image)
FROM alpine:latest
RUN apk add --no-cache bash
WORKDIR /app
COPY --from=builder /app/script.sh .
ENTRYPOINT ["./script.sh"]
```

### 4. Caching

**GitHub Actions Cache:**
```yaml
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Voordelen:**
- Snellere builds
- Minder data transfer
- Kostenbesparend

---

## Volgende Stappen

### 1. Multi-Architecture Builds

Build voor verschillende platformen:

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3

- name: Build multi-arch
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64
    push: true
```

### 2. Automated Testing

Voeg tests toe voor build:

```yaml
- name: Run tests
  run: |
    docker build -t test-image .
    docker run --rm test-image ./run-tests.sh
```

### 3. Deploy naar Kubernetes

Gebruik GHCR image in Kubernetes:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: ghcr.io/username/containerizedapp:latest
        imagePullPolicy: Always
      imagePullSecrets:
      - name: ghcr-secret
```

---

## Conclusie

Je hebt nu geleerd:

✅ GitHub Personal Access Token (PAT) aanmaken  
✅ Docker login naar GHCR  
✅ Container images bouwen en taggen voor GHCR  
✅ Handmatig images pushen naar GHCR  
✅ GitHub Actions workflow maken voor automatische builds  
✅ Troubleshooting common issues  
✅ Best practices voor security en efficiency  

**Voordelen van GHCR + GitHub Actions:**
- 🚀 Automatische builds bij elke code wijziging
- 🔒 Veilige credential management via Secrets
- 📦 Private packages by default
- 💰 Gratis voor publieke repositories
- 🔄 Geïntegreerd met je development workflow

**Happy containerizing! 🐳**
