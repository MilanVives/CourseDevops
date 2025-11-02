# Kubernetes met Minikube: 2-Tier Applicatie Deployment

## Inhoudsopgave

1. [Introductie tot Minikube](#introductie-tot-minikube)
2. [Installatie & Setup](#installatie--setup)
3. [De Applicatie Architectuur](#de-applicatie-architectuur)
4. [Kubernetes Resources Aanmaken](#kubernetes-resources-aanmaken)
5. [Deployen naar Minikube](#deployen-naar-minikube)
6. [Toegang tot Services](#toegang-tot-services)
7. [Monitoring en Debugging](#monitoring-en-debugging)
8. [Troubleshooting](#troubleshooting)

---

## Introductie tot Minikube

### Wat is Minikube?

Minikube is een tool die een single-node Kubernetes cluster lokaal op je machine draait. Het is perfect voor:

- 🎓 Kubernetes leren
- 💻 Lokale ontwikkeling
- 🧪 Applicaties testen
- 🔬 Experimenteren met Kubernetes features

### Architectuur Overzicht

```
┌────────────────────────────────────────────────────────────┐
│                      Jouw Machine                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    Minikube                          │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │          Kubernetes Cluster (VM/Docker)        │  │  │
│  │  │                                                │  │  │
│  │  │  ┌──────────────────┐  ┌──────────────────┐    │  │  │
│  │  │  │   Web App Pod    │  │  MongoDB Pod     │    │  │  │
│  │  │  │   (Node.js)      │  │  (Database)      │    │  │  │
│  │  │  │   Port: 3000     │  │  Port: 27017     │    │  │  │
│  │  │  └──────────────────┘  └──────────────────┘    │  │  │
│  │  │          │                      │              │  │  │
│  │  │          └──────────────────────┘              │  │  │
│  │  │                                                │  │  │
│  │  │  ┌──────────────────────────────────────┐      │  │  │
│  │  │  │    Services & Networking             │      │  │  │
│  │  │  │  - webapp-service (NodePort:30100)   │      │  │  │
│  │  │  │  - mongo-service (ClusterIP:27017)   │      │  │  │
│  │  │  └──────────────────────────────────────┘      │  │  │
│  │  │                                                │  │  │
│  │  │  ┌──────────────────────────────────────┐      │  │  │
│  │  │  │   ConfigMaps & Secrets               │      │  │  │
│  │  │  │  - mongo-secret (credentials)        │      │  │  │
│  │  │  │  - mongo-config (database URL)       │      │  │  │
│  │  │  └──────────────────────────────────────┘      │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
│                          ▲                                 │
│                          │ kubectl                         │
│                          │                                 │
└────────────────────────────────────────────────────────────┘
```

### Wat Gaan We Bouwen?

Een 2-tier applicatie bestaande uit:

- **Web Application**: Node.js/Express applicatie met user profile pagina
- **Database**: MongoDB voor data opslag

**Applicatie Flow:**

```
User Browser
     │
     │ HTTP Request (port 30100)
     ▼
┌─────────────────────┐
│  webapp-service     │ (NodePort)
│  Port: 30100→3000   │
└─────────────────────┘
     │
     │ Internal routing
     ▼
┌─────────────────────┐
│  webapp-deployment  │
│  (Node.js App)      │
│  Port: 3000         │
└─────────────────────┘
     │
     │ MongoDB Connection
     │ (via env vars from Secret & ConfigMap)
     ▼
┌─────────────────────┐
│  mongo-service      │ (ClusterIP)
│  Port: 27017        │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  mongo-deployment   │
│  (MongoDB)          │
│  Port: 27017        │
└─────────────────────┘
```

---

## Installatie & Setup

### Vereisten

- **Besturingssysteem**: macOS, Linux, of Windows
- **RAM**: Minimum 2GB vrij (4GB aanbevolen)
- **CPU**: 2 cores of meer
- **Schijfruimte**: 20GB vrij
- **Docker** of een andere container runtime (optioneel, maar aanbevolen)

### Minikube Installeren

#### macOS

```bash
# Via Homebrew (aanbevolen)
brew install minikube

# Of directe download
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

#### Linux

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### Windows

```powershell
# Via Chocolatey
choco install minikube

# Of download de installer:
# https://minikube.sigs.k8s.io/docs/start/
```

### kubectl Installeren

```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Windows
choco install kubernetes-cli
```

### Installatie Verifiëren

```bash
minikube version
kubectl version --client
```

### Minikube Starten

```bash
# Start met standaard instellingen
minikube start

# Start met Docker driver (aanbevolen)
minikube start --driver=docker

# Start met specifieke resources
minikube start --cpus=4 --memory=4096 --driver=docker

# Start met specifieke Kubernetes versie
minikube start --kubernetes-version=v1.28.0

# Voor macOS met HyperKit (legacy)
minikube start --driver=hyperkit
```

**Verwachte Output:**

```
😄  minikube v1.32.0 on Darwin 14.0
✨  Using the docker driver based on existing profile
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4096MB) ...
🐳  Preparing Kubernetes v1.28.0 on Docker 24.0.7 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

### Cluster Status Controleren

```bash
# Minikube status
minikube status

# Cluster informatie
kubectl cluster-info

# Nodes bekijken
kubectl get nodes

# Minikube IP address ophalen
minikube ip
```

**Verwachte Output:**

```bash
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

---

## De Applicatie Architectuur

### Project Structuur

De demo applicatie heeft de volgende structuur:

```
minikube-demo/
├── nodedemoapp/
│   └── app/
│       ├── server.js          # Node.js Express server
│       ├── index.html         # Frontend HTML
│       ├── package.json       # Node.js dependencies
│       └── images/            # Profile afbeeldingen
│           └── profile-1.jpg
├── k8s-demo/
│   ├── README.md              # Kubernetes documentatie
│   ├── mongo-secret.yaml      # MongoDB credentials (Secret)
│   ├── mongo-config.yaml      # MongoDB URL (ConfigMap)
│   ├── mongo.yaml             # MongoDB Deployment & Service
│   └── webapp.yaml            # WebApp Deployment & Service
└── helm/
    └── nodedemochart/         # Helm chart (optioneel)
```

### Applicatie Componenten

#### 1. Web Application (Node.js + Express)

**Functionaliteiten:**

- User profile pagina met naam, email en interesses
- Mogelijkheid om profile te bewerken
- Opslag van data in MongoDB
- Express server op poort 3000

**Dependencies (package.json):**

```json
{
  "name": "developing-with-docker",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "body-parser": "^1.19.0",
    "express": "^4.17.1",
    "mongodb": "^3.3.3"
  }
}
```

**Key Features van server.js:**

- MongoDB connectie via environment variables:
  - `USER_NAME` (van Secret)
  - `USER_PWD` (van Secret)
  - `DB_URL` (van ConfigMap)
- REST API endpoints:
  - `GET /` - Serve HTML pagina
  - `GET /get-profile` - Haal user profile op
  - `POST /update-profile` - Update user profile
  - `GET /profile-picture` - Serve profiel foto

#### 2. MongoDB Database

**Specificaties:**

- Image: `mongo:5.0`
- Port: 27017
- Root credentials via Secret
- Database naam: `my-db`
- Collection: `users`

---

## Kubernetes Resources Aanmaken

### Stap 1: Secret voor MongoDB Credentials

Secrets worden gebruikt om gevoelige informatie zoals wachtwoorden veilig op te slaan.

**mongo-secret.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
type: Opaque
data:
  mongo-user: bW9uZ291c2Vy
  mongo-password: bW9uZ29wYXNzd29yZA==
```

**Belangrijk:** De waarden in `data` zijn **base64 encoded**.

**Credentials decoderen:**

```bash
# Decode username
echo "bW9uZ291c2Vy" | base64 --decode
# Output: mongouser

# Decode password
echo "bW9uZ29wYXNzd29yZA==" | base64 --decode
# Output: mongopassword
```

**Eigen Secret maken:**

```bash
# Encode je eigen credentials
echo -n "myusername" | base64
echo -n "mypassword" | base64

# Of maak Secret imperatively
kubectl create secret generic mongo-secret \
  --from-literal=mongo-user=mongouser \
  --from-literal=mongo-password=mongopassword
```

**Secret Uitleg:**

```yaml
apiVersion: v1 # API versie voor Secret
kind: Secret # Resource type
metadata:
  name: mongo-secret # Naam van de Secret (gebruikt in Deployments)
type: Opaque # Generic key-value secret type
data: # Base64-encoded data
  mongo-user: <base64> # MongoDB username
  mongo-password: <base64> # MongoDB password
```

### Stap 2: ConfigMap voor MongoDB URL

ConfigMaps worden gebruikt voor niet-gevoelige configuratie data.

**mongo-config.yaml:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-config
data:
  mongo-url: mongo-service
```

**ConfigMap Uitleg:**

```yaml
apiVersion: v1 # API versie voor ConfigMap
kind: ConfigMap # Resource type
metadata:
  name: mongo-config # Naam van de ConfigMap
data: # Plain text data (niet encrypted)
  mongo-url: mongo-service # MongoDB service naam (interne DNS)
```

**Waarom mongo-service?**

- Kubernetes creëert automatisch DNS entries voor Services
- Pods kunnen elkaar bereiken via de Service naam
- Format: `<service-name>.<namespace>.svc.cluster.local`
- Binnen zelfde namespace: gewoon `<service-name>`

### Stap 3: MongoDB Deployment en Service

**mongo.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-deployment
  labels:
    app: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongodb
          image: mongo:5.0
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-user
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-password
---
apiVersion: v1
kind: Service
metadata:
  name: mongo-service
spec:
  selector:
    app: mongo
  ports:
    - protocol: TCP
      port: 27017
      targetPort: 27017
```

**Deployment Uitleg:**

```yaml
apiVersion: apps/v1 # API versie voor Deployment
kind: Deployment # Resource type
metadata:
  name: mongo-deployment # Deployment naam
  labels:
    app: mongo # Labels voor organisatie
spec:
  replicas: 1 # Aantal pod replicas
  selector:
    matchLabels:
      app: mongo # Selecteer pods met dit label
  template: # Pod template
    metadata:
      labels:
        app: mongo # Label voor pods
    spec:
      containers:
        - name: mongodb # Container naam
          image: mongo:5.0 # Docker image
          ports:
            - containerPort: 27017 # MongoDB poort
          env: # Environment variables
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef: # Haal waarde uit Secret
                  name: mongo-secret
                  key: mongo-user
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-password
```

**Service Uitleg:**

```yaml
apiVersion: v1 # API versie voor Service
kind: Service # Resource type
metadata:
  name: mongo-service # Service naam (gebruikt als DNS naam)
spec:
  selector:
    app: mongo # Route traffic naar pods met dit label
  ports:
    - protocol: TCP # Protocol
      port: 27017 # Service poort (intern bereikbaar)
      targetPort: 27017 # Container poort
```

**Service Type: ClusterIP (default)**

- Alleen bereikbaar binnen het cluster
- Heeft intern IP adres
- Perfect voor databases (geen externe toegang nodig)

### Stap 4: WebApp Deployment en Service

**webapp.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  labels:
    app: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
        - name: webapp
          image: dimilan/k8s-demo-app:v1.0
          ports:
            - containerPort: 3000
          env:
            - name: USER_NAME
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-user
            - name: USER_PWD
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-password
            - name: DB_URL
              valueFrom:
                configMapKeyRef:
                  name: mongo-config
                  key: mongo-url
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30100
```

**WebApp Deployment Uitleg:**

```yaml
spec:
  replicas: 1 # Aantal webapp instances
  template:
    spec:
      containers:
        - name: webapp
          image: dimilan/k8s-demo-app:v1.0 # Pre-built Docker image
          ports:
            - containerPort: 3000 # Node.js app poort
          env: # Environment variables voor MongoDB connectie
            - name: USER_NAME # MongoDB username (van Secret)
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-user
            - name: USER_PWD # MongoDB password (van Secret)
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-password
            - name: DB_URL # MongoDB URL (van ConfigMap)
              valueFrom:
                configMapKeyRef:
                  name: mongo-config
                  key: mongo-url
```

**MongoDB Connection String:**
De webapp bouwt de volgende connection string:

```javascript
let mongoUrlK8s = `mongodb://${process.env.USER_NAME}:${process.env.USER_PWD}@${process.env.DB_URL}`;
// Resulteert in: mongodb://mongouser:mongopassword@mongo-service
```

**WebApp Service Uitleg:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: NodePort # Expose service extern via Node port
  selector:
    app: webapp # Route naar webapp pods
  ports:
    - protocol: TCP
      port: 3000 # Internal service port
      targetPort: 3000 # Container port
      nodePort: 30100 # External access port (30000-32767)
```

**Service Type: NodePort**

- Expose service extern via een vaste poort op elke Node
- Port range: 30000-32767
- Toegankelijk via `<NodeIP>:<NodePort>`
- Perfect voor development en testing

**Verschil tussen Port Types:**
| Type | Beschrijving | Gebruikt Voor |
|------|--------------|---------------|
| `port` | Service poort binnen cluster | Inter-pod communicatie |
| `targetPort` | Container poort | Pod/container poort |
| `nodePort` | Externe toegang poort | Browser/externe toegang |

---

## Deployen naar Minikube

### Volledige Deployment Workflow

#### Stap 1: Zorg dat Minikube draait

```bash
# Start Minikube als het nog niet draait
minikube start

# Controleer status
minikube status

# Check nodes
kubectl get nodes
```

#### Stap 2: Clone de Repository

```bash
# Clone de demo repository
git clone https://github.com/MilanVives/minikube-demo.git
cd minikube-demo/k8s-demo
```

#### Stap 3: Deploy in de Juiste Volgorde

**Belangrijke volgorde:**

1. Secret (credentials)
2. ConfigMap (configuratie)
3. MongoDB (database eerst)
4. WebApp (applicatie laatst)

```bash
# 1. Maak Secret aan
kubectl apply -f mongo-secret.yaml

# Verifieer Secret
kubectl get secret
kubectl describe secret mongo-secret

# 2. Maak ConfigMap aan
kubectl apply -f mongo-config.yaml

# Verifieer ConfigMap
kubectl get configmap
kubectl describe configmap mongo-config

# 3. Deploy MongoDB
kubectl apply -f mongo.yaml

# Wacht tot MongoDB pod ready is
kubectl get pods -w
# Druk Ctrl+C als mongo pod STATUS = Running en READY = 1/1

# Verifieer MongoDB deployment
kubectl get deployment mongo-deployment
kubectl get service mongo-service
kubectl get pods -l app=mongo

# 4. Deploy WebApp
kubectl apply -f webapp.yaml

# Wacht tot WebApp pod ready is
kubectl get pods -w
# Druk Ctrl+C als webapp pod STATUS = Running en READY = 1/1

# Verifieer WebApp deployment
kubectl get deployment webapp-deployment
kubectl get service webapp-service
kubectl get pods -l app=webapp
```

#### Stap 4: Verifieer Volledige Deployment

```bash
# Bekijk alle resources
kubectl get all

# Bekijk pods met details
kubectl get pods -o wide

# Bekijk services
kubectl get svc

# Bekijk secrets en configmaps
kubectl get secret,configmap
```

**Verwachte Output:**

```bash
$ kubectl get all

NAME                                      READY   STATUS    RESTARTS   AGE
pod/mongo-deployment-7d8f9b6c5-xyz12     1/1     Running   0          5m
pod/webapp-deployment-6c9d8e7f5-abc34    1/1     Running   0          2m

NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP          30m
service/mongo-service    ClusterIP   10.96.100.20    <none>        27017/TCP        5m
service/webapp-service   NodePort    10.96.100.30    <none>        3000:30100/TCP   2m

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mongo-deployment    1/1     1            1           5m
deployment.apps/webapp-deployment   1/1     1            1           2m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/mongo-deployment-7d8f9b6c5   1         1         1       5m
replicaset.apps/webapp-deployment-6c9d8e7f5  1         1         1       2m
```

### Deployment met Een Command

```bash
# Deploy alles in één keer (let op de volgorde!)
kubectl apply -f mongo-secret.yaml && \
kubectl apply -f mongo-config.yaml && \
kubectl apply -f mongo.yaml && \
sleep 30 && \
kubectl apply -f webapp.yaml

# Of gebruik een directory
kubectl apply -f .
```

---

## Toegang tot Services

### Methode 1: Minikube Service Command (Aanbevolen voor Beginners)

Dit is de makkelijkste manier om toegang te krijgen tot de NodePort service.

```bash
# Open webapp in browser
minikube service webapp-service

# Dit opent automatisch je browser op het juiste adres
```

**Wat gebeurt er?**

- Minikube bepaalt het juiste IP en poort
- Opent automatisch de browser
- Werkt ook als `minikube ip` niet toegankelijk is

**Alleen URL krijgen (zonder browser te openen):**

```bash
minikube service webapp-service --url

# Output: http://192.168.49.2:30100
```

### Methode 2: Minikube IP + NodePort

```bash
# Haal Minikube IP op
minikube ip

# Open in browser: http://<MINIKUBE-IP>:30100
# Bijvoorbeeld: http://192.168.49.2:30100

# Of met curl
curl http://$(minikube ip):30100
```

### Methode 3: Port Forwarding

Port forwarding stuurt traffic van je localhost naar een pod of service.

```bash
# Forward naar service
kubectl port-forward service/webapp-service 8080:3000

# Open browser op: http://localhost:8080
```

**Forward naar specifieke pod:**

```bash
# Haal pod naam op
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Forward naar pod
kubectl port-forward $POD_NAME 8080:3000
```

**Voordelen van Port Forwarding:**

- ✅ Werkt altijd (ongeacht networking setup)
- ✅ Geen speciale configuratie nodig
- ✅ Goed voor debugging specifieke pods

**Nadelen:**

- ❌ Moet terminal open blijven
- ❌ Alleen voor development
- ❌ Geen load balancing over meerdere pods

### Methode 4: Minikube Tunnel (voor LoadBalancer Services)

Voor services van type LoadBalancer (niet gebruikt in deze demo, maar goed om te weten).

```bash
# Start tunnel (vereist sudo password)
minikube tunnel

# In andere terminal:
kubectl get svc

# Service krijgt EXTERNAL-IP
```

### Methode 5: Ingress Controller (Geavanceerd)

Voor productie-achtige setups met meerdere services.

```bash
# Enable Ingress addon
minikube addons enable ingress

# Verifieer Ingress controller
kubectl get pods -n ingress-nginx
```

**Maak Ingress resource:**

```yaml
# webapp-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: webapp.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: webapp-service
                port:
                  number: 3000
```

**Apply Ingress:**

```bash
kubectl apply -f webapp-ingress.yaml

# Voeg toe aan /etc/hosts
echo "$(minikube ip) webapp.local" | sudo tee -a /etc/hosts

# Open browser: http://webapp.local
```

### De Applicatie Gebruiken

Zodra je de webapp hebt geopend:

1. **Bekijk User Profile**

   - Standaard data: Anna Smith
   - Email: anna.smith@example.com
   - Interests: coding

2. **Edit Profile**

   - Klik op "Edit Profile"
   - Wijzig naam, email, of interests
   - Klik "Update Profile"

3. **Data wordt opgeslagen in MongoDB**

   - Profile updates worden opgeslagen
   - Refresh pagina om persistente data te zien

4. **Test de Database Connectie**

   ```bash
   # Bekijk logs van webapp pod
   kubectl logs -l app=webapp

   # Je zou moeten zien: "app listening on port 3000!"
   ```

---

## Monitoring en Debugging

### Basis kubectl Commands

#### Pods Inspecteren

```bash
# Alle pods
kubectl get pods

# Pods met extra info
kubectl get pods -o wide

# Pods van specifieke app
kubectl get pods -l app=webapp
kubectl get pods -l app=mongo

# Pods in real-time volgen
kubectl get pods -w

# Pod details
kubectl describe pod <pod-name>

# Pod YAML
kubectl get pod <pod-name> -o yaml
```

#### Services Inspecteren

```bash
# Alle services
kubectl get svc

# Service details
kubectl describe svc webapp-service

# Service endpoints (welke pods worden geraakt)
kubectl get endpoints webapp-service
```

#### Deployments Inspecteren

```bash
# Alle deployments
kubectl get deployments

# Deployment details
kubectl describe deployment webapp-deployment

# Deployment rollout status
kubectl rollout status deployment/webapp-deployment

# Deployment geschiedenis
kubectl rollout history deployment/webapp-deployment
```

### Logs Bekijken

```bash
# Logs van een pod
kubectl logs <pod-name>

# Logs live volgen (zoals tail -f)
kubectl logs -f <pod-name>

# Logs van vorige container (na crash)
kubectl logs <pod-name> --previous

# Logs van alle pods met label
kubectl logs -l app=webapp --all-containers=true

# Laatste 50 regels
kubectl logs <pod-name> --tail=50

# Logs met timestamps
kubectl logs <pod-name> --timestamps
```

**Praktische voorbeelden:**

```bash
# WebApp logs
POD=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD

# MongoDB logs
POD=$(kubectl get pods -l app=mongo -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD

# Follow webapp logs
kubectl logs -f -l app=webapp
```

### In Pods Executen

```bash
# Open shell in pod
kubectl exec -it <pod-name> -- /bin/sh
# of
kubectl exec -it <pod-name> -- /bin/bash

# Enkel command uitvoeren
kubectl exec <pod-name> -- ls /app
kubectl exec <pod-name> -- env

# In container van multi-container pod
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh
```

**Praktische voorbeelden:**

```bash
# Shell in webapp pod
POD=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /bin/sh

# In de pod:
# ls /app
# cat /app/server.js
# env | grep MONGO
# exit

# Shell in MongoDB pod
POD=$(kubectl get pods -l app=mongo -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /bin/bash

# In de pod (MongoDB CLI):
# mongosh -u mongouser -p mongopassword
# show dbs
# use my-db
# db.users.find()
# exit
```

### Database Connectie Testen

```bash
# Test MongoDB connectie vanuit webapp pod
POD=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec $POD -- env | grep -E 'USER_NAME|USER_PWD|DB_URL'

# Test DNS resolution
kubectl exec $POD -- nslookup mongo-service

# Test MongoDB poort (vereist nc)
kubectl exec $POD -- nc -zv mongo-service 27017
```

### Events Bekijken

Events tonen wat er gebeurt in het cluster:

```bash
# Alle events
kubectl get events

# Events gesorteerd op tijd
kubectl get events --sort-by='.lastTimestamp'

# Events voor specifieke resource
kubectl describe pod <pod-name> | grep -A 10 Events:

# Events live volgen
kubectl get events -w
```

### Resource Usage

Enable metrics-server voor resource monitoring:

```bash
# Enable metrics server addon
minikube addons enable metrics-server

# Wacht even tot metrics beschikbaar zijn (30-60 seconden)
sleep 60

# Node resources
kubectl top nodes

# Pod resources
kubectl top pods

# Pod resources met sorting
kubectl top pods --sort-by=memory
kubectl top pods --sort-by=cpu
```

### Troubleshooting Commands Samenvatting

```bash
# Complete health check
kubectl get all
kubectl get events --sort-by='.lastTimestamp'
kubectl top pods 2>/dev/null || echo "Metrics not available yet"

# Pod debugging
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/sh

# Service debugging
kubectl get svc
kubectl get endpoints
kubectl describe svc <service-name>

# Secret & ConfigMap debugging
kubectl get secret mongo-secret -o yaml
kubectl get configmap mongo-config -o yaml
```

---

## Troubleshooting

### Veelvoorkomende Problemen en Oplossingen

#### 1. Pod blijft in Pending Status

**Symptomen:**

```bash
$ kubectl get pods
NAME                                 READY   STATUS    RESTARTS   AGE
webapp-deployment-xyz               0/1     Pending   0          2m
```

**Diagnose:**

```bash
kubectl describe pod <pod-name>
```

**Mogelijke oorzaken:**

- Onvoldoende resources (CPU/memory)
- Image pull errors
- Persistent volume problemen

**Oplossingen:**

```bash
# Check node resources
kubectl describe nodes

# Verhoog Minikube resources
minikube stop
minikube start --cpus=4 --memory=4096

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

#### 2. CrashLoopBackOff

**Symptomen:**

```bash
$ kubectl get pods
NAME                                 READY   STATUS             RESTARTS   AGE
webapp-deployment-xyz               0/1     CrashLoopBackOff   5          5m
```

**Diagnose:**

```bash
# Check current logs
kubectl logs <pod-name>

# Check previous container logs
kubectl logs <pod-name> --previous

# Describe pod
kubectl describe pod <pod-name>
```

**Mogelijke oorzaken voor WebApp:**

- Kan niet connecteren met MongoDB
- Verkeerde environment variables
- MongoDB nog niet ready

**Oplossing:**

```bash
# Check MongoDB eerst
kubectl get pods -l app=mongo

# Als MongoDB niet running is, debug MongoDB eerst
kubectl logs -l app=mongo

# Check environment variables in webapp
POD=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- env | grep -E 'USER_NAME|USER_PWD|DB_URL'

# Check of Secret bestaat
kubectl get secret mongo-secret
kubectl describe secret mongo-secret

# Check of ConfigMap bestaat
kubectl get configmap mongo-config
kubectl describe configmap mongo-config

# Herstart deployment
kubectl rollout restart deployment/webapp-deployment
```

#### 3. Cannot Connect to MongoDB

**Symptomen:**

- Webapp crashes met MongoDB connection error
- Logs tonen: "MongoError: connect ECONNREFUSED"

**Diagnose:**

```bash
# Check MongoDB pod status
kubectl get pods -l app=mongo

# Check MongoDB service
kubectl get svc mongo-service
kubectl describe svc mongo-service

# Check endpoints
kubectl get endpoints mongo-service
```

**Oplossing:**

```bash
# Verify MongoDB is running
kubectl logs -l app=mongo

# Test DNS from webapp pod
POD=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- nslookup mongo-service

# Check if MongoDB port is accessible
kubectl exec $POD -- nc -zv mongo-service 27017

# If service has no endpoints, check selector
kubectl get svc mongo-service -o yaml | grep -A 5 selector
kubectl get pods -l app=mongo --show-labels

# Recreate MongoDB if needed
kubectl delete -f mongo.yaml
kubectl apply -f mongo.yaml
```

#### 4. Service Not Accessible via Browser

**Symptomen:**

- Cannot access webapp via `http://<minikube-ip>:30100`
- Browser shows "Connection refused" of "Timeout"

**Diagnose:**

```bash
# Check minikube is running
minikube status

# Check service exists
kubectl get svc webapp-service

# Check if pods are running
kubectl get pods -l app=webapp
```

**Oplossingen:**

**Oplossing 1: Gebruik minikube service command**

```bash
# Easiest solution
minikube service webapp-service

# Dit opent automatisch de browser
```

**Oplossing 2: Port forward**

```bash
# Als minikube service niet werkt
kubectl port-forward svc/webapp-service 8080:3000

# Open browser: http://localhost:8080
```

**Oplossing 3: Check networking**

```bash
# Get minikube IP
minikube ip

# Verify nodePort
kubectl get svc webapp-service -o yaml | grep nodePort

# Test met curl
curl http://$(minikube ip):30100

# Check firewall rules (macOS)
sudo pfctl -s all | grep 30100

# Check docker network (if using docker driver)
docker ps | grep minikube
docker exec minikube curl localhost:30100
```

#### 5. Image Pull Errors

**Symptomen:**

```bash
$ kubectl get pods
NAME                                 READY   STATUS         RESTARTS   AGE
webapp-deployment-xyz               0/1     ImagePullErr   0          2m
```

**Diagnose:**

```bash
kubectl describe pod <pod-name>
# Look for: Failed to pull image "dimilan/k8s-demo-app:v1.0"
```

**Mogelijke oorzaken:**

- Image bestaat niet
- Verkeerde image naam
- Docker Hub rate limit
- Geen internet connectie

**Oplossing:**

```bash
# Verify image exists on Docker Hub
# https://hub.docker.com/r/dimilan/k8s-demo-app

# Pull image manually naar minikube
minikube ssh
docker pull dimilan/k8s-demo-app:v1.0
exit

# Of bouw image lokaal
eval $(minikube docker-env)
cd nodedemoapp/app
docker build -t k8s-demo-app:local .

# Update webapp.yaml om lokale image te gebruiken
# image: k8s-demo-app:local
# imagePullPolicy: Never
```

#### 6. Wrong Secrets Decoded

**Symptomen:**

- MongoDB authentication errors
- Logs: "Authentication failed"

**Diagnose:**

```bash
# Check secret values
kubectl get secret mongo-secret -o yaml

# Decode values
kubectl get secret mongo-secret -o jsonpath='{.data.mongo-user}' | base64 --decode
kubectl get secret mongo-secret -o jsonpath='{.data.mongo-password}' | base64 --decode
```

**Oplossing:**

```bash
# Recreate secret met correcte values
kubectl delete secret mongo-secret

# Maak nieuwe secret
kubectl create secret generic mongo-secret \
  --from-literal=mongo-user=mongouser \
  --from-literal=mongo-password=mongopassword

# Herstart deployments
kubectl rollout restart deployment/mongo-deployment
kubectl rollout restart deployment/webapp-deployment
```

#### 7. Persistent Data Loss

**Symptomen:**

- User profile data verdwijnt na MongoDB pod restart

**Diagnose:**

```bash
# Check if MongoDB has persistent volume
kubectl get pvc
# Geen PVC gevonden? Data is niet persistent!
```

**Oplossing (Optioneel - Voor Production):**

```yaml
# Voeg PVC toe aan mongo.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
# Update Deployment om PVC te gebruiken
spec:
  template:
    spec:
      containers:
        - name: mongodb
          volumeMounts:
            - name: mongo-storage
              mountPath: /data/db
      volumes:
        - name: mongo-storage
          persistentVolumeClaim:
            claimName: mongo-pvc
```

### Debug Checklist

Print deze checklist voor snelle troubleshooting:

```bash
# 1. Check Cluster
□ minikube status
□ kubectl cluster-info
□ kubectl get nodes

# 2. Check Resources
□ kubectl get all
□ kubectl get pods -o wide
□ kubectl get svc
□ kubectl get secret,configmap

# 3. Check Specific Pod
□ kubectl describe pod <pod-name>
□ kubectl logs <pod-name>
□ kubectl logs <pod-name> --previous

# 4. Check Service
□ kubectl describe svc <service-name>
□ kubectl get endpoints <service-name>

# 5. Check Connectivity
□ kubectl exec <pod> -- env | grep MONGO
□ kubectl exec <pod> -- nslookup mongo-service
□ kubectl exec <pod> -- nc -zv mongo-service 27017

# 6. Check Events
□ kubectl get events --sort-by='.lastTimestamp'

# 7. Access Application
□ minikube service webapp-service
□ kubectl port-forward svc/webapp-service 8080:3000
```

### Useful Debug One-Liners

```bash
# Get webapp pod name
kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}'

# Get MongoDB pod name
kubectl get pods -l app=mongo -o jsonpath='{.items[0].metadata.name}'

# Check all pod statuses
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready

# Get service URLs
minikube service list

# Watch all resources
watch kubectl get all

# Get logs from all webapp pods
kubectl logs -l app=webapp --all-containers=true -f

# Quick health check
kubectl get pods && kubectl get svc && echo "---" && kubectl top pods 2>/dev/null || echo "Metrics not ready"
```

---

## Cluster Management

### Deployment Scaling

```bash
# Scale webapp
kubectl scale deployment webapp-deployment --replicas=3

# Verify scaling
kubectl get pods -l app=webapp

# Check multiple pods load balancing
for i in {1..10}; do curl http://$(minikube ip):30100; done
```

### Rolling Updates

```bash
# Update image
kubectl set image deployment/webapp-deployment webapp=dimilan/k8s-demo-app:v2.0

# Check rollout status
kubectl rollout status deployment/webapp-deployment

# Check rollout history
kubectl rollout history deployment/webapp-deployment

# Rollback bij problemen
kubectl rollout undo deployment/webapp-deployment

# Rollback naar specifieke revisie
kubectl rollout undo deployment/webapp-deployment --to-revision=1
```

### Resource Updates

```bash
# Update resource via YAML edit
kubectl edit deployment webapp-deployment

# Of update YAML file en apply
kubectl apply -f webapp.yaml

# Restart deployment (zonder image change)
kubectl rollout restart deployment/webapp-deployment
```

### Cleanup

```bash
# Delete specific resources
kubectl delete -f webapp.yaml
kubectl delete -f mongo.yaml
kubectl delete -f mongo-config.yaml
kubectl delete -f mongo-secret.yaml

# Delete by name
kubectl delete deployment webapp-deployment
kubectl delete service webapp-service

# Delete alles in namespace
kubectl delete all --all

# Stop minikube
minikube stop

# Delete minikube cluster
minikube delete

# Delete and start fresh
minikube delete && minikube start
```

---

## Advanced Topics (Optioneel)

### Minikube Addons

```bash
# Lijst van addons
minikube addons list

# Enable nuttige addons
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress

# Kubernetes Dashboard
minikube dashboard

# Disable addon
minikube addons disable dashboard
```

### Namespaces

```bash
# Maak namespace
kubectl create namespace development

# Deploy naar specifieke namespace
kubectl apply -f mongo-secret.yaml -n development
kubectl apply -f mongo-config.yaml -n development
kubectl apply -f mongo.yaml -n development
kubectl apply -f webapp.yaml -n development

# Alle resources in namespace
kubectl get all -n development

# Delete namespace (verwijdert alles erin)
kubectl delete namespace development
```

### Labels en Selectors

```bash
# Resources met labels
kubectl get pods --show-labels

# Filter op label
kubectl get pods -l app=webapp
kubectl get pods -l app=mongo

# Meerdere labels
kubectl get pods -l 'app in (webapp,mongo)'

# Label toevoegen
kubectl label pods <pod-name> environment=dev

# Label verwijderen
kubectl label pods <pod-name> environment-
```

### Health Checks Toevoegen (Production Ready)

Update `webapp.yaml` met health checks:

```yaml
spec:
  template:
    spec:
      containers:
        - name: webapp
          image: dimilan/k8s-demo-app:v1.0
          ports:
            - containerPort: 3000
          # Liveness probe: restart pod als deze faalt
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          # Readiness probe: route geen traffic als deze faalt
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
```

Apply updates:

```bash
kubectl apply -f webapp.yaml
kubectl rollout status deployment/webapp-deployment
```

---

## Best Practices

### 1. Secret Management

✅ **DO:**

- Gebruik Secrets voor gevoelige data
- Gebruik RBAC om toegang te beperken
- Overweeg externe secret management (Vault, Sealed Secrets)

❌ **DON'T:**

- Commit secrets naar Git
- Gebruik plain text passwords in ConfigMaps
- Deel secrets tussen environments

### 2. Resource Limits

```yaml
# Altijd resource limits definiëren
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### 3. Labels en Annotations

```yaml
# Gebruik consistente labels
metadata:
  labels:
    app: webapp
    version: v1.0
    environment: development
    tier: frontend
```

### 4. Health Checks

- Implementeer altijd liveness en readiness probes
- Use appropriate initialDelaySeconds
- Test probes failures

### 5. Service Types

| Type         | Gebruik Voor                        |
| ------------ | ----------------------------------- |
| ClusterIP    | Internal services (databases)       |
| NodePort     | Development/testing external access |
| LoadBalancer | Production external access (cloud)  |
| Ingress      | Multiple services, HTTP routing     |

### 6. Deployment Strategie

```yaml
# Use rolling updates voor zero downtime
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

---

## Handige Commando's Samenvatting

### Minikube Commands

```bash
minikube start                    # Start cluster
minikube stop                     # Stop cluster
minikube delete                   # Delete cluster
minikube status                   # Check status
minikube ip                       # Get IP
minikube service <name>           # Open service
minikube service <name> --url     # Get service URL
minikube dashboard                # Open dashboard
minikube ssh                      # SSH into node
minikube logs                     # View logs
minikube addons list              # List addons
```

### kubectl Commands

```bash
# Get Resources
kubectl get <resource>            # List resources
kubectl get all                   # All resources
kubectl get pods -o wide          # Pods with details
kubectl get pods -w               # Watch pods
kubectl get pods --show-labels    # Show labels

# Describe Resources
kubectl describe <resource> <name>

# Logs
kubectl logs <pod>                # View logs
kubectl logs -f <pod>             # Follow logs
kubectl logs <pod> --previous     # Previous container

# Execute in Pod
kubectl exec <pod> -- <command>   # Run command
kubectl exec -it <pod> -- sh      # Interactive shell

# Apply/Delete
kubectl apply -f <file>           # Create/update
kubectl delete -f <file>          # Delete
kubectl delete <resource> <name>  # Delete by name

# Deployment Management
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout restart deployment/<name>

# Port Forward
kubectl port-forward <pod> 8080:3000
kubectl port-forward svc/<name> 8080:3000
```

### Resource Types (Short Names)

```bash
pods (po)
services (svc)
deployments (deploy)
replicasets (rs)
configmaps (cm)
secrets
namespaces (ns)
events (ev)
```

---

## Volgende Stappen

Na het voltooien van deze tutorial kun je:

1. **Helm Charts** - Package manager voor Kubernetes

   ```bash
   cd helm/nodedemochart
   helm install webapp .
   ```

2. **CI/CD** - Automatiseer deployment met GitHub Actions of GitLab CI

3. **Monitoring** - Voeg Prometheus en Grafana toe

   ```bash
   minikube addons enable metrics-server
   ```

4. **Service Mesh** - Istio of Linkerd voor advanced networking

5. **Production Deployment** - Deploy naar cloud (AKS, EKS, GKE)

---

## Resources

### Officiële Documentatie

- 📚 [Kubernetes Documentation](https://kubernetes.io/docs/)
- 📚 [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- 📚 [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Images

- 🐳 [MongoDB op Docker Hub](https://hub.docker.com/_/mongo)
- 🐳 [WebApp Image](https://hub.docker.com/r/dimilan/k8s-demo-app)

### Repository

- 💻 [minikube-demo GitHub](https://github.com/MilanVives/minikube-demo)

---

## Conclusie

Je hebt nu geleerd hoe je:

- ✅ Minikube installeert en configureert
- ✅ Een 2-tier applicatie deploy naar Kubernetes
- ✅ Secrets en ConfigMaps gebruikt
- ✅ Deployments en Services configureert
- ✅ Services toegankelijk maakt via verschillende methoden
- ✅ Applicaties monitort en debugt
- ✅ Veelvoorkomende problemen oplost

**Belangrijkste Concepten:**

- **Pods**: Kleinste deployable units
- **Deployments**: Manage pod replicas en updates
- **Services**: Stable network endpoints voor pods
- **Secrets**: Veilige opslag van credentials
- **ConfigMaps**: Configuratie data

**Praktische Skills:**

- kubectl commando's gebruiken
- Logs en events analyseren
- In pods executen voor debugging
- Services exposen via NodePort
- Rolling updates en rollbacks

**Veel success met Kubernetes! 🚀**
