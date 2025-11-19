# 7 - Helm Package Management voor Kubernetes

## Inleiding: Het Kubernetes Complexity Probleem

Naarmate je Kubernetes applicaties complexer worden, loop je tegen verschillende uitdagingen aan:

**Problemen met raw Kubernetes YAML:**
- ❌ **Repetitive code**: Veel duplicatie tussen environments
- ❌ **Hard-coded values**: Moeilijk om tussen dev/staging/prod te wisselen
- ❌ **Dependency management**: Moeilijk om gerelateerde resources te beheren
- ❌ **Version control**: Geen standaard manier om applicatie versies te beheren
- ❌ **Installation complexity**: Vele kubectl apply commando's nodig

**Helm als oplossing:**
- ✅ **Templating**: Dynamische YAML generatie
- ✅ **Package management**: Apps als herbruikbare packages
- ✅ **Dependency management**: Automatische dependency resolution
- ✅ **Release management**: Versiebeheer en rollbacks
- ✅ **Values management**: Environment-specific configuratie

---

## Wat is Helm?

**Helm** is de "package manager for Kubernetes" - vergelijkbaar met npm voor Node.js of apt voor Ubuntu.

### Belangrijke Links & Resources
- **Website**: https://helm.sh/
- **Installatie**: https://helm.sh/docs/intro/install/
- **Charts Repository**: https://artifacthub.io/
- **Documentatie**: https://helm.sh/docs/
- **Commando's**: https://helm.sh/docs/helm/helm/
- **Chart Template Guide**: https://helm.sh/docs/chart_template_guide/getting_started/
- **Chart Tips & How To**: https://helm.sh/docs/howto/charts_tips_and_tricks/

### Core concepten

1. **Package Manager**: 
   - Bundel YAML files en distribueer ze in publieke en private repositories
   - Herbruikbare packages voor veelgebruikte applicaties

2. **Templating Engine**:
   - Templates voor gelijkaardige deployments (bv. microservices)
   - Vermijd duplicatie van configuratie

3. **Release Management**:
   - **Versie 2**: Client + Server (Tiller) - volledige release history
   - **Versie 3**: Geen Tiller meer (verwijderd wegens security issues)

**Core begrippen:**
- **Chart**: Een Helm package met templates en configuratie
- **Release**: Een running instance van een chart
- **Repository**: Centrale opslag voor charts
- **Values**: Configuratie parameters voor charts

### Helm Architectuur

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Helm Client   │────│  Kubernetes     │────│  Chart Repo     │
│   (CLI Tool)    │    │   API Server    │    │  (Storage)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## Waarom Helm Charts?

### Package Manager Use Case: ElasticSearch

Om ElasticSearch toe te voegen aan je cluster heb je veel YAML files nodig:
- StatefulSet
- ConfigMap
- Secret
- Services
- K8s User + Permissions
- ...en meer

**Het probleem**: De kans is groot dat anderen dit reeds voor jou moeten doen. De inhoud van hun YAML files zal quasi identiek zijn aan die van jou.

**De oplossing**: Wat als iemand die YAML files bundelt en beschikbaar maakt in een publieke repository voor iedereen? → **Deze bundel = Helm Chart**

### Wat zijn Helm Charts?

- **Verzameling van YAML files**: Alles wat nodig is voor een applicatie gebundeld
- **Zelf aanmaken**: Je kan je eigen Helm Charts creëren
- **Delen**: Push naar Helm Repository voor hergebruik
- **Downloaden**: Gebruik bestaande charts van anderen

**Veelgebruikte applicaties via Helm Charts**:
- Databases: MongoDB, MySQL, PostgreSQL
- Monitoring: Prometheus, Grafana
- Andere complexe applicaties met standaard installaties

De volledige setup is reeds uitgewerkt in YAML files. Custom waarden kun je specificeren in een aparte file: **values.yaml**

### Populaire Charts Voorbeelden

**Prometheus op ArtifactHub**:
- URL: https://artifacthub.io/packages/helm/prometheus-community/prometheus
- Kant-en-klare monitoring oplossing

**Grafana op ArtifactHub**:
- URL: https://artifacthub.io/packages/helm/grafana/grafana
- Kant-en-klare visualisatie dashboards

---

## Helm Charts Fundamentals

### Chart Structuur

Volgens de officiële Helm documentatie heeft een chart de volgende structuur:

```
wordpress/
├── Chart.yaml          # YAML file met informatie over de chart
├── LICENSE             # OPTIONAL: Licentie file
├── README.md           # OPTIONAL: Human-readable README
├── values.yaml         # Default configuratie waarden voor deze chart
├── values.schema.json  # OPTIONAL: JSON Schema voor values.yaml validatie
├── charts/             # Directory met afhankelijke charts
├── crds/               # Custom Resource Definitions
├── templates/          # Directory met templates die gecombineerd met values
│   │                   # valide Kubernetes manifest files genereren
│   └── NOTES.txt       # OPTIONAL: Korte gebruiksinstructies
└── ...
```

**Vereenvoudigde versie voor beginners**:
```
mychart/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── templates/          # Kubernetes YAML templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl   # Template helpers
└── charts/            # Sub-chart dependencies
```

### Basic Chart Voorbeeld

**Chart.yaml:**
```yaml
apiVersion: v2
name: webapp
description: A Helm chart for my web application
version: 0.1.0
appVersion: "1.0"
```

**values.yaml:**
```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  host: webapp.example.com
```

**templates/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "webapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "webapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
```

---

## Templating Engine

### Probleem: Gelijkaardige Deployments

Bij microservices architectuur heb je vaak:
- Veel gelijkaardige deployments
- Enige verschillen zijn: app name en image
- Twee opties:
  1. ❌ Voor elke deployment verschillende YAML files maken (duplicatie!)
  2. ✅ Template YAML files en verschillende values.yaml files per applicatie

### Value Injection

**Hoe werkt het?**
- De **values.yaml** file bevat waarden die in de template files geïnjecteerd worden
- Deze waarden kunnen overschreven worden met:
  - Een andere values file (`-f` of `--values` flag)
  - Command line parameters (`--set` flag)

**Voorbeeld van value injection in template**:
```yaml
# In values.yaml
replicaCount: 3
image:
  repository: nginx
  tag: "1.21"

# In templates/deployment.yaml
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
      - name: app
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### Use Cases voor Templating

**1. Microservices met gelijkaardige configuraties**
- Één template
- Meerdere values files (één per microservice)

**2. CI/CD Pipeline integratie**
- Bij elke nieuwe Docker Image build → incrementele tag
- Automatisch values updaten in CI/CD
- Automatische deployment met nieuwe versie

**3. Verschillende Environments**
- Development
- Staging  
- Production
- Verschillende configuratie per environment via aparte values files

---

## Helm Commands & Workflow

### Installatie

```bash
# Installeer Helm via script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Repository Management

```bash
# Lijst huidige repositories
helm repo list
# Of kort:
helm repo ls

# Voeg een repository toe
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update repositories (vergelijkbaar met apt update)
helm repo update

# Verwijder een repository
helm repo remove bitnami

# Zoek in een specifieke repository
helm repo search bitnami

# Zoek in Artifact Hub (alle publieke charts)
helm search hub
helm search hub prometheus
```

### Chart Discovery & Installation

```bash
# Zoek charts in repositories
helm search repo nginx
helm search hub wordpress

# Installeer een chart
helm install my-nginx bitnami/nginx

# Installeer met specifieke versie
helm install my-prometheus prometheus-community/prometheus --version 15.12.0

# Installeer in een specifieke namespace
helm install my-prometheus prometheus-community/prometheus --namespace dev

# Installeer met custom values file
helm install myapp ./mychart -f values-dev.yaml

# Installeer met inline values (override)
helm install my-nginx bitnami/nginx --set replicaCount=3

# Dry-run (test zonder daadwerkelijk te installeren)
helm install mychart ./mychart --dry-run --debug
```

### Release Management

```bash
# Lijst alle releases
helm list
# Of in alle namespaces:
helm ls --all-namespaces

# Status van een release
helm status my-prometheus

# Upgrade een release
helm upgrade my-nginx bitnami/nginx --set replicaCount=3
helm upgrade my-prometheus prometheus-community/prometheus --version 15.15.0

# Rollback naar vorige versie
helm rollback my-prometheus 1
# Met namespace:
helm rollback my-prometheus 1 -n dev

# Uninstall (verwijder release)
helm uninstall my-nginx

# Uninstall maar behoud geschiedenis (voor mogelijke rollback)
helm uninstall my-prometheus --keep-history
```

### Chart Development Workflow

```bash
# Creëer een nieuwe chart (met volledige directory structuur)
helm create mychart
helm create app

# Valideer chart syntax
helm lint mychart/

# Template rendering (dry-run) - zie gegenereerde YAML
helm template mychart/ --values mychart/values.yaml

# Controleer of chart correct gerenderd wordt
helm template myapp ./myapp-chart

# Install met debug output
helm install mychart ./mychart --dry-run --debug

# Package chart (creëert .tgz file)
helm package mychart/

# Creëer index file voor je chart repository
helm repo index mychart/
# Dit maakt een index.yaml info file voor je helm chart
# Voer dit commando uit BUITEN de chart directory
```

---

## Templating & Values Management

### Template Functions

**String Manipulation**:
```yaml
# Quotes toevoegen
name: {{ .Values.name | quote }}

# Uppercase
env: {{ .Values.environment | upper }}

# Lowercase
region: {{ .Values.region | lower }}
```

**Conditionals**:
```yaml
# If statement
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name }}
# ... ingress configuratie
{{- end }}

# If-else
{{- if .Values.production }}
replicas: 5
{{- else }}
replicas: 1
{{- end }}
```

**Loops**:
```yaml
# Loop door een lijst
{{- range .Values.environments }}
- name: {{ . }}
{{- end }}

# Loop met index
{{- range $index, $env := .Values.environments }}
- name: {{ $env }}
  index: {{ $index }}
{{- end }}
```

**Default Values**:
```yaml
# Gebruik default als waarde niet bestaat
replicas: {{ .Values.replicaCount | default 1 }}
tag: {{ .Values.image.tag | default "latest" }}
```

### Environment-Specific Values

**values.yaml (defaults)**:
```yaml
replicaCount: 1
image:
  repository: myapp
  tag: "latest"
ingress:
  enabled: false
resources:
  limits:
    memory: "128Mi"
```

**values-dev.yaml**:
```yaml
replicaCount: 1
image:
  tag: "dev"
ingress:
  enabled: false
resources:
  limits:
    memory: "256Mi"
```

**values-staging.yaml**:
```yaml
replicaCount: 2
image:
  tag: "staging-1.2.0"
ingress:
  enabled: true
  host: staging.myapp.com
resources:
  limits:
    memory: "512Mi"
```

**values-prod.yaml**:
```yaml
replicaCount: 5
image:
  tag: "1.2.0"
ingress:
  enabled: true
  host: myapp.company.com
resources:
  limits:
    memory: "1Gi"
  requests:
    memory: "512Mi"
```

**Deployment commando's**:
```bash
# Deploy naar verschillende environments
helm install myapp-dev ./mychart -f values-dev.yaml
helm install myapp-staging ./mychart -f values-staging.yaml
helm install myapp-prod ./mychart -f values-prod.yaml

# Of met namespace
helm install myapp ./mychart -f values-prod.yaml -n production
```

---

## Complete Three-Tier Application Example

### Chart Structure for Web App

```
webapp-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── database/
│       ├── statefulset.yaml
│       ├── service.yaml
│       └── pvc.yaml
└── charts/
```

### Chart.yaml

```yaml
apiVersion: v2
name: webapp
description: A Helm chart for a complete web application
version: 0.1.0
appVersion: "1.0"
keywords:
  - webapp
  - microservices
maintainers:
  - name: Your Name
    email: your.email@example.com
```

### Values.yaml (Complete Example)

```yaml
# Frontend Configuration
frontend:
  replicaCount: 3
  image:
    repository: mycompany/frontend
    tag: "1.0.0"
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 80
  ingress:
    enabled: true
    host: webapp.example.com
    annotations:
      kubernetes.io/ingress.class: nginx

# Backend Configuration  
backend:
  replicaCount: 3
  image:
    repository: mycompany/backend
    tag: "1.0.0"
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 8080
  env:
    DATABASE_HOST: mongodb
    DATABASE_PORT: "27017"

# Database Configuration
database:
  image:
    repository: mongo
    tag: "5.0"
  persistence:
    enabled: true
    size: 10Gi
    storageClass: standard
  service:
    port: 27017
```

### Frontend Template

**templates/frontend/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}-frontend
  labels:
    app: {{ include "webapp.name" . }}-frontend
    chart: {{ include "webapp.chart" . }}
spec:
  replicas: {{ .Values.frontend.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "webapp.name" . }}-frontend
  template:
    metadata:
      labels:
        app: {{ include "webapp.name" . }}-frontend
    spec:
      containers:
      - name: frontend
        image: "{{ .Values.frontend.image.repository }}:{{ .Values.frontend.image.tag }}"
        imagePullPolicy: {{ .Values.frontend.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        env:
        - name: API_URL
          value: "http://{{ include "webapp.fullname" . }}-backend:{{ .Values.backend.service.port }}"
        resources:
          {{- toYaml .Values.frontend.resources | nindent 10 }}
```

**templates/frontend/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "webapp.fullname" . }}-frontend
  labels:
    app: {{ include "webapp.name" . }}-frontend
spec:
  type: {{ .Values.frontend.service.type }}
  ports:
    - port: {{ .Values.frontend.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: {{ include "webapp.name" . }}-frontend
```

**templates/frontend/ingress.yaml:**
```yaml
{{- if .Values.frontend.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "webapp.fullname" . }}-frontend
  annotations:
    {{- toYaml .Values.frontend.ingress.annotations | nindent 4 }}
spec:
  rules:
  - host: {{ .Values.frontend.ingress.host }}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ include "webapp.fullname" . }}-frontend
            port:
              number: {{ .Values.frontend.service.port }}
{{- end }}
```

### Backend Template

**templates/backend/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}-backend
  labels:
    app: {{ include "webapp.name" . }}-backend
spec:
  replicas: {{ .Values.backend.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "webapp.name" . }}-backend
  template:
    metadata:
      labels:
        app: {{ include "webapp.name" . }}-backend
    spec:
      containers:
      - name: backend
        image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
        imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.backend.service.port }}
        env:
        - name: DATABASE_HOST
          value: {{ .Values.backend.env.DATABASE_HOST | quote }}
        - name: DATABASE_PORT
          value: {{ .Values.backend.env.DATABASE_PORT | quote }}
```

---

## Advanced Helm Features

### Helper Templates (_helpers.tpl)

**templates/_helpers.tpl:**
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "webapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "webapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "webapp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "webapp.labels" -}}
helm.sh/chart: {{ include "webapp.chart" . }}
{{ include "webapp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "webapp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "webapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Hooks & Tests

**templates/tests/test-connection.yaml:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "webapp.fullname" . }}-test-connection"
  labels:
    {{- include "webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  containers:
  - name: wget
    image: busybox
    command: ['wget']
    args: ['{{ include "webapp.fullname" . }}-frontend:{{ .Values.frontend.service.port }}']
```

**Run tests:**
```bash
# Run tests voor een release
helm test my-webapp

# Run tests met logs
helm test my-webapp --logs
```

### Pre-install en Post-install Hooks

**templates/hooks/pre-install-job.yaml:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "webapp.fullname" . }}-pre-install
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pre-install
        image: busybox
        command: ['sh', '-c', 'echo Pre-install hook executing...']
```

**Beschikbare hooks:**
- `pre-install`: Voor installatie
- `post-install`: Na installatie
- `pre-delete`: Voor verwijdering
- `post-delete`: Na verwijdering
- `pre-upgrade`: Voor upgrade
- `post-upgrade`: Na upgrade
- `pre-rollback`: Voor rollback
- `post-rollback`: Na rollback
- `test`: Test hook (via `helm test`)

---

## Release Management & History

### Helm V2 vs V3

**Helm V2** (Legacy):
- **Client + Server architectuur**: 
  - Helm Client (CLI)
  - Tiller (Server component in cluster)
- **Release Management**: Volledige historiek bijgehouden door Tiller
- **Rollback**: Eenvoudig naar elke vorige versie
- **Security Issues**: Tiller had te veel permissies → security risico
- **Status**: **Deprecated** - gebruik niet meer!

**Helm V3** (Current):
- **Client-only**: Geen Tiller meer
- **Direct naar K8s API**: Helm praat rechtstreeks met Kubernetes
- **Release info**: Opgeslagen als Kubernetes Secrets
- **Beperkte historiek**: Minder uitgebreide history dan V2
- **Security**: Veel veiliger zonder Tiller
- **Status**: **Huidige productie versie**

### Release History

```bash
# Bekijk release geschiedenis
helm history my-webapp

# Voorbeeld output:
# REVISION  UPDATED                   STATUS      CHART          APP VERSION  DESCRIPTION
# 1         Mon Jan 1 12:00:00 2024   superseded  webapp-0.1.0   1.0          Install complete
# 2         Mon Jan 2 14:30:00 2024   superseded  webapp-0.1.1   1.1          Upgrade complete
# 3         Mon Jan 3 10:15:00 2024   deployed    webapp-0.2.0   2.0          Upgrade complete

# Rollback naar specifieke revisie
helm rollback my-webapp 2

# Rollback naar vorige versie
helm rollback my-webapp
```

---

## Praktische Labs & Oefeningen

### Lab 1: MongoDB en NodeJS Helm Chart

**Opdracht**:
1. Converteer je bestaande MongoDB en NodeJS Kubernetes deployment naar een Helm Chart
2. **Stap 1**: Start simpel
   - Drop gewoon de YAML files in de `templates/` directory
   - Test de setup met `helm template` commando
   - Installeer met `helm install`

3. **Stap 2**: Maak het dynamisch
   - Vervang custom/hard-coded waarden in de template files door placeholders
   - Maak een `values.yaml` file met deze waarden
   - Test opnieuw met `helm template` en `helm install`

**Voorbeeld structuur**:
```
mongodb-nodejs-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── mongodb-deployment.yaml
    ├── mongodb-service.yaml
    ├── mongodb-secret.yaml
    ├── nodejs-deployment.yaml
    ├── nodejs-service.yaml
    └── nodejs-configmap.yaml
```

**Values.yaml voorbeeld**:
```yaml
mongodb:
  image: mongo:5.0
  port: 27017
  username: admin
  database: myapp
  
nodejs:
  image: myapp/nodejs:1.0
  port: 3000
  replicas: 2
```

### Lab 2: Prometheus installeren met Helm

**Opdracht**:
Zoek de officiële Prometheus Chart op via https://artifacthub.io/ en run die in je Minikube Cluster

**Stappen**:
```bash
# 1. Zoek de Prometheus chart
helm search hub prometheus

# 2. Voeg de Prometheus repository toe
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 3. Bekijk beschikbare versies
helm search repo prometheus-community/prometheus --versions

# 4. Installeer Prometheus
helm install my-prometheus prometheus-community/kube-prometheus-stack

# 5. Bekijk de status
helm status my-prometheus
helm list

# 6. Port-forward om Prometheus UI te benaderen
kubectl port-forward svc/my-prometheus-kube-prometheus-prometheus 9090:9090

# 7. Bekijk Grafana (default credentials: admin/prom-operator)
kubectl port-forward svc/my-prometheus-grafana 3000:80
```

**Extra**: Customize de installatie
```bash
# Download default values
helm show values prometheus-community/kube-prometheus-stack > prometheus-values.yaml

# Edit prometheus-values.yaml naar wens

# Installeer met custom values
helm install my-prometheus prometheus-community/kube-prometheus-stack -f prometheus-values.yaml
```

**Inspiratie**: https://www.youtube.com/watch?v=bwUECsVDbMA

---

## Best Practices

### Chart Development

1. **Gebruik semantic versioning** voor chart versies (0.1.0, 1.0.0, etc.)
2. **Documenteer je values**: Voeg comments toe in values.yaml
3. **Gebruik _helpers.tpl**: Voor herbruikbare template snippets
4. **Test altijd eerst**: Gebruik `--dry-run` en `helm lint`
5. **Beperk hard-coded waarden**: Alles wat kan variëren → values.yaml

### Security

1. **Secrets management**: Gebruik Kubernetes Secrets, NIET plain text in values
2. **RBAC**: Definieer minimale permissies in je charts
3. **Image tags**: Gebruik specifieke versie tags, NIET `latest`
4. **Scan images**: Check voor vulnerabilities

### Production Ready

```yaml
# values-production.yaml voorbeeld
replicaCount: 3

image:
  repository: myapp/production
  tag: "2.1.5"  # Specifieke versie, NIET latest!
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: app.company.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.company.com

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

---

## Samenvatting & Commando Referentie

### Quick Reference: Belangrijkste Commando's

```bash
```bash
# REPOSITORY MANAGEMENT
helm repo add <name> <url>        # Voeg repository toe
helm repo list                     # Toon alle repositories
helm repo update                   # Update alle repositories
helm repo remove <name>            # Verwijder repository

# CHART DISCOVERY
helm search repo <keyword>         # Zoek in toegevoegde repos
helm search hub <keyword>          # Zoek in Artifact Hub

# CHART DEVELOPMENT  
helm create <name>                 # Creëer nieuwe chart
helm lint <chart>                  # Valideer chart
helm template <name> <chart>       # Render templates (dry-run)
helm package <chart>               # Package chart naar .tgz
helm repo index <dir>              # Creëer index.yaml

# INSTALLATION
helm install <name> <chart>                    # Installeer chart
helm install <name> <chart> -f values.yaml     # Met custom values
helm install <name> <chart> --set key=value    # Met inline values
helm install <name> <chart> -n <namespace>     # In namespace
helm install <name> <chart> --dry-run --debug  # Test installatie

# RELEASE MANAGEMENT
helm list                          # Toon alle releases
helm ls --all-namespaces          # In alle namespaces
helm status <name>                # Release status
helm get values <name>            # Toon gebruikte values
helm history <name>               # Toon release history

# UPGRADES & ROLLBACKS
helm upgrade <name> <chart>                  # Upgrade release
helm upgrade <name> <chart> -f values.yaml   # Met nieuwe values
helm rollback <name> <revision>              # Rollback naar revisie
helm rollback <name>                         # Rollback naar vorige

# DELETION
helm uninstall <name>              # Verwijder release
helm uninstall <name> --keep-history  # Behoud history

# TESTING
helm test <name>                   # Run chart tests
```

### Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    HELM WORKFLOW                             │
└─────────────────────────────────────────────────────────────┘

1. DEVELOPMENT                2. REPOSITORY              3. DEPLOYMENT
   ┌──────────┐                 ┌──────────┐               ┌──────────┐
   │  Create  │                 │   Add    │               │ Install  │
   │  Chart   │────────────────>│   Repo   │──────────────>│  Chart   │
   │          │                 │          │               │          │
   └──────────┘                 └──────────┘               └──────────┘
        │                             │                          │
        v                             v                          v
   ┌──────────┐                 ┌──────────┐               ┌──────────┐
   │   Lint   │                 │  Search  │               │  Monitor │
   │  & Test  │                 │  Charts  │               │  Status  │
   └──────────┘                 └──────────┘               └──────────┘
        │                             │                          │
        v                             v                          v
   ┌──────────┐                 ┌──────────┐               ┌──────────┐
   │ Template │                 │  Update  │               │ Upgrade/ │
   │  Review  │                 │   Repo   │               │ Rollback │
   └──────────┘                 └──────────┘               └──────────┘
```

---

## Conclusie: Van Complex naar Simple

### Voor Helm
```bash
# Vele commando's nodig...
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f ingress.yaml
kubectl apply -f pvc.yaml
# ... en nog veel meer

# Bij updates: elk file apart aanpassen en opnieuw applyen
# Bij problemen: manueel alles terugdraaien
# Tussen environments: veel duplicatie en copy-paste
```

### Met Helm
```bash
# Één simpel commando voor alles
helm install myapp ./webapp-chart

# Easy upgrades met nieuwe configuratie
helm upgrade myapp ./webapp-chart --set frontend.replicaCount=5

# Simple rollbacks als er iets fout gaat
helm rollback myapp 1

# Verschillende environments met dezelfde chart
helm install dev-app ./chart -f values-dev.yaml
helm install prod-app ./chart -f values-prod.yaml
```

### Voordelen Samengevat

**Helm brengt je:**
- ✅ **Package Management**: Apps als herbruikbare, versiebeheerde units
- ✅ **Templating Engine**: DRY principle voor Kubernetes YAML (Don't Repeat Yourself)
- ✅ **Release Management**: Versiebeheer en makkelijke rollbacks
- ✅ **Environment Management**: Eenvoudig deployment naar meerdere environments
- ✅ **Dependency Resolution**: Automatische handling van sub-charts en dependencies
- ✅ **Community Charts**: Hergebruik van battle-tested configurations
- ✅ **CI/CD Integration**: Perfect voor geautomatiseerde deployments

**Helm transforms Kubernetes deployment van complex naar simple!** 🚀

---

## Nuttige Resources

### Officiële Documentatie
- **Helm Docs**: https://helm.sh/docs/
- **Chart Best Practices**: https://helm.sh/docs/chart_best_practices/
- **Template Functions**: https://helm.sh/docs/chart_template_guide/function_list/

### Chart Repositories
- **Artifact Hub**: https://artifacthub.io/ (centrale hub voor alle publieke charts)
- **Bitnami Charts**: https://charts.bitnami.com/
- **Prometheus Community**: https://prometheus-community.github.io/helm-charts/

### Tutorials & Guides
- **Getting Started**: https://helm.sh/docs/intro/quickstart/
- **Chart Template Guide**: https://helm.sh/docs/chart_template_guide/getting_started/
- **Tips & Tricks**: https://helm.sh/docs/howto/charts_tips_and_tricks/

### Video Resources
- **KubeCon 2019 Helm Deep Dive**: https://devops-monk.com/images/helm_pdf.pdf
- **Helm Tutorial by TechWorld**: https://www.youtube.com/watch?v=bwUECsVDbMA

---

**Happy Helming! ⎈**