# 8 - Helm Package Management voor Kubernetes

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

**Core concepten:**
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

## Helm Charts Fundamentals

### Chart Structuur

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

## Helm Commands & Workflow

### Installation & Basic Commands

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Chart Repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search Charts
helm search repo nginx
helm search hub wordpress

# Install Chart
helm install my-nginx bitnami/nginx

# List Releases
helm list

# Upgrade Release
helm upgrade my-nginx bitnami/nginx --set replicaCount=3

# Rollback Release
helm rollback my-nginx 1

# Uninstall Release
helm uninstall my-nginx
```

### Chart Development Workflow

```bash
# Create new chart
helm create mychart

# Validate chart
helm lint mychart/

# Template rendering (dry-run)
helm template mychart/ --values mychart/values.yaml

# Install with debug
helm install mychart ./mychart --dry-run --debug

# Package chart
helm package mychart/
```

---

## Templating & Values Management

### Template Functions

```yaml
# String manipulation
name: {{ .Values.name | quote }}
env: {{ .Values.environment | upper }}

# Conditionals
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
# ... ingress config
{{- end }}

# Loops
{{- range .Values.environments }}
- name: {{ . }}
{{- end }}

# Default values
replicas: {{ .Values.replicaCount | default 1 }}
```

### Environment-Specific Values

**values-dev.yaml:**
```yaml
replicaCount: 1
image:
  tag: "dev"
ingress:
  enabled: false
```

**values-prod.yaml:**
```yaml
replicaCount: 5
image:
  tag: "1.0.0"
ingress:
  enabled: true
  host: myapp.company.com
```

```bash
# Deploy to different environments
helm install myapp-dev ./mychart -f values-dev.yaml
helm install myapp-prod ./mychart -f values-prod.yaml
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

### Frontend Template

**templates/frontend/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}-frontend
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
        ports:
        - containerPort: 80
        env:
        - name: API_URL
          value: "http://{{ include "webapp.fullname" . }}-backend:{{ .Values.backend.service.port }}"
```

---

## Advanced Helm Features

### Hooks & Tests

**templates/tests/test-connection.yaml:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "webapp.fullname" . }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
  - name: wget
    image: busybox
    command: ['wget']
    args: ['{{ include "webapp.fullname" . }}-frontend:80']
```

```bash
# Run tests
helm test my-webapp
```

---

## Conclusie: Van Complex naar Simple

**Met Helm:**
```bash
# One simple command
helm install myapp ./webapp-chart

# Easy upgrades
helm upgrade myapp ./webapp-chart --set frontend.replicaCount=5

# Simple rollbacks
helm rollback myapp 1
```

**Voordelen samengevat:**
- ✅ **Package management**: Apps als herbruikbare units
- ✅ **Template engine**: DRY principle voor Kubernetes YAML
- ✅ **Release management**: Versiebeheer en rollbacks
- ✅ **Environment management**: Easy deployment naar multiple environments
- ✅ **Dependency resolution**: Automatic handling van sub-charts

Helm transforms Kubernetes deployment van complex naar simple!