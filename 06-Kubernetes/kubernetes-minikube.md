# Kubernetes met Minikube: 3-Tier Pet Shelter Applicatie Deployment

## Tutorial Repository

**Clone de repository voor deze tutorial:**

```bash
git clone https://github.com/MilanVives/PetShelter-minimal.git
cd PetShelter-minimal
```

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
┌────────────────────────────────────────────────────────────────┐
│                      Jouw Machine                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Minikube                              │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │          Kubernetes Cluster (VM/Docker)            │  │  │
│  │  │                                                    │  │  │
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │  │  │
│  │  │  │ Frontend   │  │  Backend   │  │  MongoDB   │    │  │  │
│  │  │  │   Pod      │  │    Pod     │  │    Pod     │    │  │  │
│  │  │  │ (Express)  │  │ (Node.js)  │  │ (Database) │    │  │  │
│  │  │  │ Port: 3000 │  │ Port: 5000 │  │ Port:27017 │    │  │  │
│  │  │  └────────────┘  └────────────┘  └────────────┘    │  │  │
│  │  │        │               │               │           │  │  │
│  │  │        └───────────────┴───────────────┘           │  │  │
│  │  │                                                    │  │  │
│  │  │  ┌──────────────────────────────────────────┐      │  │  │
│  │  │  │    Services & Networking                 │      │  │  │
│  │  │  │  - frontend-service (NodePort:32500)     │      │  │  │
│  │  │  │  - backend-service (ClusterIP:5000)      │      │  │  │
│  │  │  │  - mongodb-service (ClusterIP:27017)     │      │  │  │
│  │  │  └──────────────────────────────────────────┘      │  │  │
│  │  │                                                    │  │  │
│  │  │  ┌──────────────────────────────────────────┐      │  │  │
│  │  │  │   ConfigMaps & Secrets                   │      │  │  │
│  │  │  │  - mongodb-secret (credentials)          │      │  │  │
│  │  │  │  - mongodb-configmap (database config)   │      │  │  │
│  │  │  └──────────────────────────────────────────┘      │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ▲                                     │
│                          │ kubectl                             │
│                          │                                     │
└────────────────────────────────────────────────────────────────┘
```

### Wat Gaan We Bouwen?

Een 3-tier Pet Shelter applicatie bestaande uit:

- **Frontend**: HTML/JavaScript interface geserveerd door Express (Port 3000)
- **Backend**: Node.js REST API met endpoints voor pets (Port 5000)
- **Database**: MongoDB voor opslag van pet gegevens (Port 27017)

**Applicatie Flow:**

```
User Browser
     │
     │ HTTP Request (port 32500)
     ▼
┌─────────────────────┐
│  frontend-service   │ (NodePort)
│  Port: 32500→3000   │
└─────────────────────┘
     │
     │ Internal routing
     ▼
┌─────────────────────┐
│ frontend-deployment │
│  (Express/HTML)     │
│  Port: 3000         │
└─────────────────────┘
     │
     │ API Calls to Backend
     ▼
┌─────────────────────┐
│  backend-service    │ (ClusterIP)
│  Port: 5000         │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  backend-deployment │
│  (Node.js API)      │
│  Port: 5000         │
└─────────────────────┘
     │
     │ MongoDB Connection
     │ (via env vars from Secret & ConfigMap)
     ▼
┌─────────────────────┐
│  mongodb-service    │ (ClusterIP)
│  Port: 27017        │
└─────────────────────┘
     │
     ▼
┌─────────────────────┐
│  mongodb-deployment │
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

De Pet Shelter applicatie heeft de volgende structuur:

```
PetShelter-minimal/
├── frontend/
│   ├── Dockerfile             # Frontend container
│   ├── package.json           # Node.js dependencies
│   ├── server.js              # Express server
│   └── public/
│       └── index.html         # Pet Shelter UI
├── backend/
│   ├── Dockerfile             # Backend container
│   ├── package.json           # Node.js dependencies
│   └── server.js              # REST API server
├── k8s/
│   ├── mongodb-secret.yaml    # MongoDB credentials (Secret)
│   ├── mongodb-configmap.yaml # MongoDB config (ConfigMap)
│   ├── mongodb-deployment.yaml # MongoDB Deployment & Service
│   ├── backend-deployment.yaml # Backend Deployment & Service
│   └── frontend-deployment.yaml # Frontend Deployment & Service
├── docker-compose.yml         # Voor lokale development
└── README.md                  # Documentatie
```

### Applicatie Componenten

#### 1. Frontend (Express + HTML/JavaScript)

**Functionaliteiten:**

- Overzicht van alle pets in de shelter
- Formulier om nieuwe pets toe te voegen
- Maakt API calls naar de backend
- Express server op poort 3000

**Backend API calls:**

- `GET /api/pets` - Haal alle pets op
- `POST /api/pets` - Voeg nieuwe pet toe

#### 2. Backend (Node.js REST API)

**Specificaties:**

- Image: `dimilan/pet-shelter-backend:latest`
- Port: 5000
- MongoDB connectie via environment variables
- Automatische database seeding met voorbeeld pets

**API Endpoints:**

- `GET /api/pets` - Alle pets ophalen
- `POST /api/pets` - Nieuwe pet toevoegen

**Environment Variables:**

- `MONGO_USERNAME` (van Secret)
- `MONGO_PASSWORD` (van Secret)
- `MONGO_HOST` (van ConfigMap)
- `MONGO_PORT` (van ConfigMap)
- `MONGO_DB` (van ConfigMap)

#### 3. MongoDB Database

**Specificaties:**

- Image: `mongo:latest`
- Port: 27017
- Root credentials via Secret
- Database naam: `petshelter`
- Collection: `pets`

---

## Kubernetes Resources Aanmaken

### Stap 1: Clone de Repository

```bash
git clone https://github.com/MilanVives/PetShelter-minimal.git
cd PetShelter-minimal
```

De repository bevat een `k8s/` folder met alle benodigde Kubernetes configuraties.

### Stap 2: MongoDB Secret

**k8s/mongodb-secret.yaml**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
type: Opaque
data:
  username: YWRtaW4= # base64 encoded 'admin'
  password: cGFzc3dvcmQ= # base64 encoded 'password'
```

**Base64 encoding uitleg:**

```bash
# Encode
echo -n 'admin' | base64
# Output: YWRtaW4=

echo -n 'password' | base64
# Output: cGFzc3dvcmQ=

# Decode (voor verificatie)
echo 'YWRtaW4=' | base64 --decode
# Output: admin
```

**Eigen Secret maken:**

```bash
# Encode je eigen credentials
echo -n "myusername" | base64
echo -n "mypassword" | base64

# Of maak Secret imperatively
kubectl create secret generic mongodb-secret \
  --from-literal=username=admin \
  --from-literal=password=password
```

**Secret Uitleg:**

```yaml
apiVersion: v1 # API versie voor Secret
kind: Secret # Resource type
metadata:
  name: mongodb-secret # Naam van de Secret (gebruikt in Deployments)
type: Opaque # Generic key-value secret type
data: # Base64-encoded data
  username: <base64> # MongoDB username
  password: <base64> # MongoDB password
```

### Stap 3: MongoDB ConfigMap

**k8s/mongodb-configmap.yaml**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongodb-configmap
data:
  database-url: mongodb-service
  database-port: "27017"
  database-name: petshelter
```

**ConfigMap Uitleg:**

```yaml
apiVersion: v1 # API versie voor ConfigMap
kind: ConfigMap # Resource type
metadata:
  name: mongodb-configmap # Naam van de ConfigMap
data: # Plain text data (niet encrypted)
  database-url: mongodb-service # MongoDB service naam (interne DNS)
  database-port: "27017" # MongoDB poort
  database-name: petshelter # Database naam
```

**Waarom mongodb-service?**

- Kubernetes creëert automatisch DNS entries voor Services
- Pods kunnen elkaar bereiken via de Service naam
- Format: `<service-name>.<namespace>.svc.cluster.local`
- Binnen zelfde namespace: gewoon `<service-name>`

### Stap 4: MongoDB Deployment & Service

**k8s/mongodb-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  labels:
    app: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:latest
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: password
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
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
  name: mongodb-deployment # Deployment naam
  labels:
    app: mongodb # Labels voor organisatie
spec:
  replicas: 1 # Aantal pod replicas
  selector:
    matchLabels:
      app: mongodb # Selecteer pods met dit label
  template: # Pod template
    metadata:
      labels:
        app: mongodb # Label voor pods
    spec:
      containers:
        - name: mongodb # Container naam
          image: mongo:latest # Docker image
          ports:
            - containerPort: 27017 # MongoDB poort
          env: # Environment variables
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef: # Haal waarde uit Secret
                  name: mongodb-secret
                  key: username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: password
```

**Service Uitleg:**

```yaml
apiVersion: v1 # API versie voor Service
kind: Service # Resource type
metadata:
  name: mongodb-service # Service naam (gebruikt als DNS naam)
spec:
  selector:
    app: mongodb # Route traffic naar pods met dit label
  ports:
    - protocol: TCP # Protocol
      port: 27017 # Service poort (intern bereikbaar)
      targetPort: 27017 # Container poort
```

**Service Type: ClusterIP (default)**

- Alleen bereikbaar binnen het cluster
- Heeft intern IP adres
- Perfect voor databases (geen externe toegang nodig)

### Stap 5: Backend API Deployment & Service

**k8s/backend-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  labels:
    app: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: dimilan/pet-shelter-backend:latest
          imagePullPolicy: Never
          ports:
            - containerPort: 5000
          env:
            - name: MONGO_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: username
            - name: MONGO_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: password
            - name: MONGO_HOST
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-url
            - name: MONGO_PORT
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-port
            - name: MONGO_DB
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-name
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
```

**Backend Deployment Uitleg:**

```yaml
spec:
  replicas: 1 # Aantal backend instances
  template:
    spec:
      containers:
        - name: backend
          image: dimilan/pet-shelter-backend:latest # Pre-built Docker image
          imagePullPolicy: Never # Gebruik lokale image in Minikube
          ports:
            - containerPort: 5000 # Backend API poort
          env: # Environment variables voor MongoDB connectie
            - name: MONGO_USERNAME # MongoDB username (van Secret)
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: username
            - name: MONGO_PASSWORD # MongoDB password (van Secret)
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: password
            - name: MONGO_HOST # MongoDB hostname (van ConfigMap)
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-url
            - name: MONGO_PORT # MongoDB port (van ConfigMap)
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-port
            - name: MONGO_DB # Database naam (van ConfigMap)
              valueFrom:
                configMapKeyRef:
                  name: mongodb-configmap
                  key: database-name
```

**MongoDB Connection String:**
De backend bouwt de volgende connection string:

```javascript
const mongoUrl = `mongodb://${process.env.MONGO_USERNAME}:${process.env.MONGO_PASSWORD}@${process.env.MONGO_HOST}:${process.env.MONGO_PORT}/${process.env.MONGO_DB}?authSource=admin`;
// Resulteert in: mongodb://admin:password@mongodb-service:27017/petshelter?authSource=admin
```

**Backend Service Uitleg:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP # Alleen intern bereikbaar
  selector:
    app: backend # Route naar backend pods
  ports:
    - protocol: TCP
      port: 5000 # Internal service port
      targetPort: 5000 # Container port
```

**Service Type: ClusterIP**

- Alleen bereikbaar binnen het cluster
- Frontend kan backend bereiken via `http://backend-service:5000`
- Perfect voor backend services die niet direct extern toegankelijk moeten zijn

### Stap 6: Frontend Deployment & Service

**k8s/frontend-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
  labels:
    app: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: dimilan/pet-shelter-frontend:latest
          imagePullPolicy: Never
          ports:
            - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 32500
```

**Frontend Deployment Uitleg:**

```yaml
spec:
  replicas: 1 # Aantal frontend instances
  template:
    spec:
      containers:
        - name: frontend
          image: dimilan/pet-shelter-frontend:latest # Pre-built Docker image
          imagePullPolicy: Never # Gebruik lokale image in Minikube
          ports:
            - containerPort: 3000 # Frontend server poort
```

**Frontend Service Uitleg:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort # Expose service extern via Node port
  selector:
    app: frontend # Route naar frontend pods
  ports:
    - protocol: TCP
      port: 3000 # Internal service port
      targetPort: 3000 # Container port
      nodePort: 32500 # External access port (30000-32767)
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

#### Stap 2: Clone de Repository en Build Images

```bash
# Clone de repository
git clone https://github.com/MilanVives/PetShelter-minimal.git
cd PetShelter-minimal

# Point Docker CLI naar Minikube's Docker daemon
eval $(minikube docker-env)

# Build backend image
cd backend
docker build -t dimilan/pet-shelter-backend:latest .

# Build frontend image
cd ../frontend
docker build -t dimilan/pet-shelter-frontend:latest .

# Ga terug naar root directory
cd ..

# Verifieer images
docker images | grep pet-shelter
```

#### Stap 3: Deploy in de Juiste Volgorde

**Belangrijke volgorde:**

1. Secret (credentials)
2. ConfigMap (configuratie)
3. MongoDB (database eerst)
4. Backend (API laag)
5. Frontend (UI laatst)

```bash
# 1. Maak Secret aan
kubectl apply -f k8s/mongodb-secret.yaml

# Verifieer Secret
kubectl get secret
kubectl describe secret mongodb-secret

# 2. Maak ConfigMap aan
kubectl apply -f k8s/mongodb-configmap.yaml

# Verifieer ConfigMap
kubectl get configmap
kubectl describe configmap mongodb-configmap

# 3. Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml

# Wacht tot MongoDB pod ready is
kubectl get pods -w
# Druk Ctrl+C als mongodb pod STATUS = Running en READY = 1/1

# Verifieer MongoDB deployment
kubectl get deployment mongodb-deployment
kubectl get service mongodb-service
kubectl get pods -l app=mongodbdb

# 4. Deploy Backend
kubectl apply -f k8s/backend-deployment.yaml

# Wacht tot backend pod ready is
kubectl get pods -w
# Druk Ctrl+C als backend pod STATUS = Running en READY = 1/1

# Verifieer backend deployment
kubectl get deployment backend-deployment
kubectl get service backend-service
kubectl get pods -l app=backend

# Check backend logs voor database seeding
kubectl logs -l app=backend

# 5. Deploy Frontend
kubectl apply -f k8s/frontend-deployment.yaml

# Wacht tot frontend pod ready is
kubectl get pods -w
# Druk Ctrl+C als frontend pod STATUS = Running en READY = 1/1

# Verifieer frontend deployment
kubectl get deployment frontend-deployment
kubectl get service frontend-service
kubectl get pods -l app=frontend
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
pod/mongodb-deployment-7d8f9b6c5-xyz12    1/1     Running   0          7m
pod/backend-deployment-6c9d8e7f5-abc34    1/1     Running   0          4m
pod/frontend-deployment-8a1b2c3d4-def56   1/1     Running   0          2m

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/kubernetes         ClusterIP   10.96.0.1       <none>        443/TCP          30m
service/mongodb-service    ClusterIP   10.96.100.20    <none>        27017/TCP        7m
service/backend-service    ClusterIP   10.96.100.30    <none>        5000/TCP         4m
service/frontend-service   NodePort    10.96.100.40    <none>        3000:32500/TCP   2m

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mongodb-deployment   1/1     1            1           7m
deployment.apps/backend-deployment   1/1     1            1           4m
deployment.apps/frontend-deployment  1/1     1            1           2m

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/mongodb-deployment-7d8f9b6c5  1         1         1       7m
replicaset.apps/backend-deployment-6c9d8e7f5  1         1         1       4m
replicaset.apps/frontend-deployment-8a1b2c3d4 1         1         1       2m
```

### Deployment met Een Command

```bash
# Deploy alles in één keer (let op de volgorde!)
kubectl apply -f k8s/mongodb-secret.yaml && \
kubectl apply -f k8s/mongodb-configmap.yaml && \
kubectl apply -f k8s/mongodb-deployment.yaml && \
sleep 30 && \
kubectl apply -f k8s/backend-deployment.yaml && \
sleep 20 && \
kubectl apply -f k8s/frontend-deployment.yaml

# Of gebruik de hele k8s directory
kubectl apply -f k8s/
```

````

---

## Toegang tot Services

### Methode 1: Minikube Service Command (Aanbevolen voor Beginners)

Dit is de makkelijkste manier om toegang te krijgen tot de NodePort service.

```bash
# Open frontend in browser
minikube service frontend-service

# Dit opent automatisch je browser op het juiste adres
````

**Wat gebeurt er?**

- Minikube bepaalt het juiste IP en poort
- Opent automatisch de browser
- Werkt ook als `minikube ip` niet toegankelijk is

**Alleen URL krijgen (zonder browser te openen):**

```bash
minikube service frontend-service --url

# Output: http://192.168.49.2:32500
```

### Methode 2: Minikube IP + NodePort

```bash
# Haal Minikube IP op
minikube ip

# Open in browser: http://<MINIKUBE-IP>:32500
# Bijvoorbeeld: http://192.168.49.2:32500

# Of met curl
curl http://$(minikube ip):32500
```

### Methode 3: Port Forwarding

Port forwarding stuurt traffic van je localhost naar een pod of service.

```bash
# Forward naar frontend service
kubectl port-forward service/frontend-service 8080:3000

# Open browser op: http://localhost:8080
```

**Forward naar specifieke pod:**

```bash
# Haal pod naam op
POD_NAME=$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')

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
# frontend-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: petshelter.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 3000
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 5000
```

**Apply Ingress:**

```bash
kubectl apply -f frontend-ingress.yaml

# Voeg toe aan /etc/hosts
echo "$(minikube ip) petshelter.local" | sudo tee -a /etc/hosts

# Open browser: http://petshelter.local
```

### De Applicatie Gebruiken

Zodra je de Pet Shelter applicatie hebt geopend:

1. **Bekijk Pet Lijst**

   - Je ziet alle pets in de shelter
   - De backend seeded automatisch enkele voorbeeld pets bij eerste start

2. **Voeg Nieuwe Pet Toe**

   - Vul het formulier in:
     - Naam (bijv. "Max")
     - Soort (bijv. "Dog")
     - Leeftijd (bijv. "3")
   - Klik "Add Pet"

3. **Data wordt opgeslagen in MongoDB**

   - Nieuwe pets worden opgeslagen in de database
   - Refresh pagina om alle pets te zien (inclusief nieuwe)

4. **Test de Backend API**

   ```bash
   # Port forward naar backend
   kubectl port-forward service/backend-service 5000:5000

   # In andere terminal, test API
   curl http://localhost:5000/api/pets

   # Output: JSON array met alle pets
   ```

5. **Bekijk Backend Logs**

   ```bash
   # Bekijk logs van backend pod
   kubectl logs -l app=backend

   # Je zou moeten zien:
   # "Connecting to MongoDB..."
   # "Server running on port 5000"
   # "Connected to MongoDB"
   # "Database seeded with initial pets"
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
kubectl get pods -l app=frontend
kubectl get pods -l app=backend
kubectl get pods -l app=mongodbdb

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
kubectl describe svc frontend-service
kubectl describe svc backend-service

# Service endpoints (welke pods worden geraakt)
kubectl get endpoints frontend-service
kubectl get endpoints backend-service
```

#### Deployments Inspecteren

```bash
# Alle deployments
kubectl get deployments

# Deployment details
kubectl describe deployment frontend-deployment
kubectl describe deployment backend-deployment

# Deployment rollout status
kubectl rollout status deployment/frontend-deployment

# Deployment geschiedenis
kubectl rollout history deployment/backend-deployment
```

### Logs Bekijken

```bash
# Logs van een pod
kubectl logs <pod-name>

# Logs van backend/frontend via label
kubectl logs -l app=backend
kubectl logs -l app=frontend

# Logs live volgen (zoals tail -f)
kubectl logs -f <pod-name>

# Logs van vorige container (na crash)
kubectl logs <pod-name> --previous

# Logs van alle pods met label
kubectl logs -l app=backend --all-containers=true

# Laatste 50 regels
kubectl logs <pod-name> --tail=50

# Logs met timestamps
kubectl logs <pod-name> --timestamps
```

**Praktische voorbeelden:**

```bash
# WebApp logs
POD=$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD

# MongoDB logs
POD=$(kubectl get pods -l app=mongodb -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD

# Follow frontend logs
kubectl logs -f -l app=frontend
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
# Shell in frontend pod
POD=$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /bin/sh

# In de pod:
# ls /app
# cat /app/server.js
# env | grep MONGO
# exit

# Shell in MongoDB pod
POD=$(kubectl get pods -l app=mongodb -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- /bin/bash

# In de pod (MongoDB CLI):
# mongosh -u admin -p password
# show dbs
# use petshelter
# db.pets.find()
# exit
```

### Database Connectie Testen

```bash
# Test MongoDB connectie vanuit frontend pod
POD=$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec $POD -- env | grep -E 'MONGO'

# Test DNS resolution
kubectl exec $POD -- nslookup mongodb-service

# Test MongoDB poort (vereist nc)
kubectl exec $POD -- nc -zv mongodb-service 27017
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
frontend-deployment-xyz               0/1     Pending   0          2m
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
frontend-deployment-xyz               0/1     CrashLoopBackOff   5          5m
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
kubectl get pods -l app=mongodb

# Als MongoDB niet running is, debug MongoDB eerst
kubectl logs -l app=mongodb

# Check environment variables in frontend
POD=$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- env | grep -E 'MONGO'

# Check of Secret bestaat
kubectl get secret mongo-secret
kubectl describe secret mongo-secret

# Check of ConfigMap bestaat
kubectl get configmap mongo-config
kubectl describe configmap mongo-config

# Herstart deployment
kubectl rollout restart deployment/frontend-deployment
```

#### 3. Cannot Connect to MongoDB

**Symptomen:**

- Webapp crashes met MongoDB connection error
- Logs tonen: "MongoError: connect ECONNREFUSED"

**Diagnose:**

```bash
# Check MongoDB pod status
kubectl get pods -l app=mongodb

# Check MongoDB service
kubectl get svc mongodb-service
kubectl describe svc mongodb-service

# Check endpoints
kubectl get endpoints mongodb-service
```

**Oplossing:**

```bash
# Verify MongoDB is running
kubectl logs -l app=mongodb

# Test DNS from frontend pod
POD=$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- nslookup mongodb-service

# Check if MongoDB port is accessible
kubectl exec $POD -- nc -zv mongodb-service 27017

# If service has no endpoints, check selector
kubectl get svc mongodb-service -o yaml | grep -A 5 selector
kubectl get pods -l app=mongodb --show-labels

# Recreate MongoDB if needed
kubectl delete -f mongo.yaml
kubectl apply -f mongo.yaml
```

#### 4. Service Not Accessible via Browser

**Symptomen:**

- Cannot access frontend via `http://<minikube-ip>:32500`
- Browser shows "Connection refused" of "Timeout"

**Diagnose:**

```bash
# Check minikube is running
minikube status

# Check service exists
kubectl get svc frontend-service

# Check if pods are running
kubectl get pods -l app=frontend
```

**Oplossingen:**

**Oplossing 1: Gebruik minikube service command**

```bash
# Easiest solution
minikube service frontend-service

# Dit opent automatisch de browser
```

**Oplossing 2: Port forward**

```bash
# Als minikube service niet werkt
kubectl port-forward svc/frontend-service 8080:3000

# Open browser: http://localhost:8080
```

**Oplossing 3: Check networking**

```bash
# Get minikube IP
minikube ip

# Verify nodePort
kubectl get svc frontend-service -o yaml | grep nodePort

# Test met curl
curl http://$(minikube ip):32500

# Check firewall rules (macOS)
sudo pfctl -s all | grep 30100

# Check docker network (if using docker driver)
docker ps | grep minikube
docker exec minikube curl localhost:32500
```

#### 5. Image Pull Errors

**Symptomen:**

```bash
$ kubectl get pods
NAME                                 READY   STATUS         RESTARTS   AGE
frontend-deployment-xyz               0/1     ImagePullErr   0          2m
```

**Diagnose:**

```bash
kubectl describe pod <pod-name>
# Look for: Failed to pull image "dimilan/pet-shelter-frontend:v1.0"
```

**Mogelijke oorzaken:**

- Image bestaat niet
- Verkeerde image naam
- Docker Hub rate limit
- Geen internet connectie

**Oplossing:**

```bash
# Verify image exists on Docker Hub
# https://hub.docker.com/r/dimilan/pet-shelter-frontend

# Pull image manually naar minikube
minikube ssh
docker pull dimilan/pet-shelter-frontend:v1.0
exit

# Of bouw image lokaal
eval $(minikube docker-env)
cd nodedemoapp/app
docker build -t pet-shelter-frontend:local .

# Update frontend-deployment.yaml om lokale image te gebruiken
# image: pet-shelter-frontend:local
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
  --from-literal=mongo-user=admin \
  --from-literal=mongo-password=password

# Herstart deployments
kubectl rollout restart deployment/mongodb-deployment
kubectl rollout restart deployment/frontend-deployment
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
□ kubectl exec <pod> -- nslookup mongodb-service
□ kubectl exec <pod> -- nc -zv mongodb-service 27017

# 6. Check Events
□ kubectl get events --sort-by='.lastTimestamp'

# 7. Access Application
□ minikube service frontend-service
□ kubectl port-forward svc/frontend-service 8080:3000
```

### Useful Debug One-Liners

```bash
# Get frontend pod name
kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}'

# Get MongoDB pod name
kubectl get pods -l app=mongodb -o jsonpath='{.items[0].metadata.name}'

# Check all pod statuses
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready

# Get service URLs
minikube service list

# Watch all resources
watch kubectl get all

# Get logs from all frontend pods
kubectl logs -l app=frontend --all-containers=true -f

# Quick health check
kubectl get pods && kubectl get svc && echo "---" && kubectl top pods 2>/dev/null || echo "Metrics not ready"
```

---

## Cluster Management

### Deployment Scaling

```bash
# Scale frontend
kubectl scale deployment frontend-deployment --replicas=3

# Verify scaling
kubectl get pods -l app=frontend

# Check multiple pods load balancing
for i in {1..10}; do curl http://$(minikube ip):32500; done
```

### Rolling Updates

```bash
# Update image
kubectl set image deployment/frontend-deployment webapp=dimilan/pet-shelter-frontend:v2.0

# Check rollout status
kubectl rollout status deployment/frontend-deployment

# Check rollout history
kubectl rollout history deployment/frontend-deployment

# Rollback bij problemen
kubectl rollout undo deployment/frontend-deployment

# Rollback naar specifieke revisie
kubectl rollout undo deployment/frontend-deployment --to-revision=1
```

### Resource Updates

```bash
# Update resource via YAML edit
kubectl edit deployment frontend-deployment

# Of update YAML file en apply
kubectl apply -f frontend-deployment.yaml

# Restart deployment (zonder image change)
kubectl rollout restart deployment/frontend-deployment
```

### Cleanup

```bash
# Delete specific resources
kubectl delete -f frontend-deployment.yaml
kubectl delete -f mongo.yaml
kubectl delete -f mongo-config.yaml
kubectl delete -f mongo-secret.yaml

# Delete by name
kubectl delete deployment frontend-deployment
kubectl delete service frontend-service

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
kubectl apply -f frontend-deployment.yaml -n development

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
kubectl get pods -l app=frontend
kubectl get pods -l app=mongodb

# Meerdere labels
kubectl get pods -l 'app in (webapp,mongo)'

# Label toevoegen
kubectl label pods <pod-name> environment=dev

# Label verwijderen
kubectl label pods <pod-name> environment-
```

### Health Checks Toevoegen (Production Ready)

Update frontend deployment met health checks:

```yaml
spec:
  template:
    spec:
      containers:
        - name: frontend
          image: dimilan/pet-shelter-frontend:v1.0
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
kubectl apply -f frontend-deployment.yaml
kubectl rollout status deployment/frontend-deployment
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
- 🐳 [Pet Shelter Backend](https://hub.docker.com/r/dimilan/pet-shelter-backend)
- 🐳 [Pet Shelter Frontend](https://hub.docker.com/r/dimilan/pet-shelter-frontend)

### Repository

- 💻 [PetShelter-minimal GitHub](https://github.com/MilanVives/PetShelter-minimal)

---

## Conclusie

Je hebt nu geleerd hoe je:

- ✅ Minikube installeert en configureert
- ✅ Een 3-tier Pet Shelter applicatie deploy naar Kubernetes
- ✅ Docker images bouwt in Minikube's Docker daemon
- ✅ Secrets en ConfigMaps gebruikt voor configuratie
- ✅ Deployments en Services configureert voor frontend, backend en database
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
