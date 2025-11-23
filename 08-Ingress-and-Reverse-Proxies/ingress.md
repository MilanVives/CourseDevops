# 8 - Ingress & Reverse Proxies: External Access naar Kubernetes

## Inleiding: Het External Access Probleem

**Het probleem:**
In Kubernetes draaien je applicaties in een cluster, maar hoe krijg je externe toegang tot je services?

### Wat is Kubernetes Ingress?

**Literal meaning**: Ingress verwijst naar het binnenkomen. In de Kubernetes wereld betekent ingress het verkeer dat de cluster binnenkomt, en egress is het verkeer dat de cluster verlaat.

**Ingress** is een native Kubernetes resource (zoals pods, deployments, etc.) waarmee je **DNS routing configuraties** kunt onderhouden. De ingress controller doet de daadwerkelijke routing door de routing regels te lezen uit de ingress objecten opgeslagen in etcd.

### Service Types Limitations

**Voor Ingress: Wat waren de problemen?**

```yaml
# ClusterIP - alleen intern bereikbaar
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: ClusterIP  # ❌ Geen externe toegang
  ports:
  - port: 80
```

```yaml
# NodePort - elk pod heeft andere poort
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: NodePort  # ❌ Random ports, niet schaalbaar
  ports:
  - port: 80
    nodePort: 30080  # Poort op elke node
```

```yaml
# LoadBalancer - duur per service
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: LoadBalancer  # ❌ Één load balancer per service = kostbaar
  ports:
  - port: 80
```

**Zonder Kubernetes Ingress:**

Zonder ingress zou je voor elke applicatie een **Service Type LoadBalancer** moeten toevoegen aan de deployments. Hier is hoe dat eruitziet:

![Kubernetes zonder Ingress](../images/ingress/kubernetes-ingress-without-controller.png)

**Met Ingress:**

Met ingress is er een **reverse proxy layer** (Ingress controller implementatie) tussen de load balancer en de Kubernetes service endpoints.

**De oplossing: Ingress**
- ✅ **Eén entry point** voor alle services
- ✅ **Path-based routing**: verschillende URLs naar verschillende services
- ✅ **Host-based routing**: verschillende domeinen naar verschillende services
- ✅ **SSL/TLS termination**: HTTPS afhandeling op één plek
- ✅ **Cost effective**: Eén load balancer voor alles

---

## Voor Kubernetes Ingress: De Geschiedenis

### Custom Nginx/HAProxy Implementaties

Voor Kubernetes Ingress stabiel was, werd een **custom Nginx of HAProxy** Kubernetes deployment gebruikt die werd exposed als een LoadBalancer service om externe traffic naar interne cluster services te routen.

**Hoe werkte het toen?**
- Routing regels werden toegevoegd als een **ConfigMap** in de Nginx/HAProxy pods
- Bij een DNS wijziging of nieuwe route entry werd de ConfigMap geüpdatet
- Pod configs werden gereload of opnieuw deployed

**Kubernetes Ingress verbeterde dit:**
- Routing regels als **native Kubernetes ingress objects** in plaats van ConfigMaps
- In plaats van Nginx/HAProxy: **Ingress controllers** (aangepaste versies van Nginx/HAProxy) die routing regels dynamisch ophalen
- Implementaties met **Consul** en andere service discovery tools om DNS wijzigingen te updaten zonder downtime

**OpenShift Router:**
In OpenShift maakte het router concept (HAProxy implementations) het eenvoudig om service endpoints buiten de cluster te exposen. Dit is vergelijkbaar met Kubernetes ingress.

---

## Hoe Werkt Kubernetes Ingress?

### Twee Sleutelconcepten

Als beginner moet je **twee belangrijke concepten** begrijpen:

#### 1. Kubernetes Ingress Resource

**Kubernetes Ingress Resource** is verantwoordelijk voor het opslaan van DNS routing regels in de cluster.

#### 2. Kubernetes Ingress Controller  

**Kubernetes Ingress Controller** (Nginx/HAProxy etc.) is verantwoordelijk voor de routing door toegang te krijgen tot de DNS regels toegepast via ingress resources.

**Belangrijk te begrijpen:**
- Een ingress object vereist een ingress controller voor het routen van traffic
- **Externe traffic raakt NIET de ingress API**, maar raakt het ingress controller service endpoint dat direct is geconfigureerd met een load balancer

---

## Ingress Resource

### Wat is een Ingress Resource?

De **Kubernetes Ingress Resource** is een native kubernetes resource waar je de DNS routing regels specificeert. Dit betekent dat je externe DNS traffic mapt naar interne Kubernetes service endpoints.

### Basic Ingress Resource Voorbeeld

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: dev
spec:
  rules:
  - host: test.apps.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-service
            port:
              number: 80
```

**Wat betekent dit?**
- Alle calls naar `test.apps.example.com` moeten naar de service `hello-service` in de dev namespace gaan
- Het bevat alleen routing regels
- Je kan meerdere routing endpoints toevoegen voor path-based routing
- Je kan TLS configuratie toevoegen

**Key Points:**
- Een ingress object vereist een ingress controller voor het routen van traffic
- Externe traffic raakt NIET de ingress API, maar het ingress controller service endpoint

---

## Ingress Controller

### Wat is een Ingress Controller?

**Belangrijk**: Ingress controller is **NIET een native Kubernetes implementatie**. Dit betekent dat het niet standaard in de cluster zit.

We moeten een ingress controller opzetten voordat ingress regels werken. Er zijn verschillende open-source en enterprise ingress controllers beschikbaar.

Een ingress controller is typisch een **reverse web proxy server implementatie** in de cluster. In Kubernetes termen is het een reverse proxy server deployed als **Kubernetes deployment** exposed naar een service type LoadBalancer.

**Multiple Ingress Controllers:**
Je kan meerdere ingress controllers in een cluster hebben, elk gemapt naar meerdere load balancers. Elke ingress controller moet een unieke identifier hebben genaamd **ingress-class** toegevoegd aan de annotation.

### Populaire Ingress Controllers

- **NGINX Ingress Controller** (meest gebruikt)
  - Community versie: https://github.com/kubernetes/ingress-nginx
  - Nginx Inc versie: https://github.com/nginxinc/kubernetes-ingress
- **Traefik** (modern, auto-discovery)
- **HAProxy Ingress**
- **Contour**
- **Istio Gateway**
- **GKE Ingress Controller** (voor GKE)
- **AWS ALB Ingress Controller** (voor AKS)
- **Azure Application Gateway Ingress Controller**

**Comparison Document:**
Learnk8s heeft een geweldige vergelijking gemaakt van alle beschikbare ingress controllers:
https://docs.google.com/spreadsheets/d/191WWNpjJ2za6-nbG4ZoUMXMpUK8KlCIosvQB0f-oq3k/edit#gid=907731238

---

## Hoe Werkt een Ingress Controller?

### Nginx Ingress Controller Voorbeeld

Nginx is één van de meest gebruikte ingress controllers. Laten we kijken naar hoe het werkt:

![Nginx Controller Workflow](../images/ingress/nginx-controller-workflow.png)

**Workflow stappen:**

1. **Lua Template Configuration:**
   - Het `nginx.conf` bestand in de Nginx controller pod is een **lua template** die kan praten met de Kubernetes Ingress API
   - Het haalt real-time de laatste waarden op voor traffic routing
   - Template file: https://github.com/kubernetes/ingress-nginx/blob/main/rootfs/etc/nginx/template/nginx.tmpl

2. **API Communication:**
   - De Nginx controller praat met Kubernetes Ingress API om te checken of er routing regels zijn gecreëerd

3. **Configuration Generation:**
   - Als het ingress regels vindt, genereert de Nginx controller een routing configuratie in `/etc/nginx/conf.d` locatie in elke nginx pod

4. **Per Ingress Resource:**
   - Voor elke ingress resource die je creëert, genereert Nginx een configuratie in `/etc/nginx/conf.d`

5. **Main Configuration:**
   - Het hoofd `/etc/nginx/nginx.conf` bestand bevat alle configuraties van `etc/nginx/conf.d`

6. **Dynamic Updates:**
   - Als je het ingress object update met nieuwe configuraties, wordt de Nginx config opnieuw geüpdatet
   - Er gebeurt een **graceful reload** van de configuratie

**Verificatie:**
Als je connect naar de Nginx ingress controller pod met `kubectl exec` en het `/etc/nginx/nginx.conf` bestand checkt, zie je alle regels gespecificeerd in het ingress object toegepast in het conf bestand.

---

## Ingress & Ingress Controller Architecture

### Complete Architectuur Diagram

Hier is het architectuur diagram dat de ingress & ingress controller setup op een Kubernetes cluster uitlegt:

![Ingress Architecture](../images/ingress/ingress-architecture.png)

Het toont ingress regels die traffic routen naar twee applicaties: `payment` en `auth`.

**Architectuur componenten:**

1. **External Load Balancer:**
   - Ontvangt al het externe verkeer
   - Routeert naar de Ingress Controller

2. **Ingress Controller (Nginx/Traefik/HAProxy):**
   - Deployed als een Kubernetes Deployment
   - Exposed via LoadBalancer Service
   - Leest Ingress Resources via Kubernetes API

3. **Ingress Resources:**
   - Opgeslagen in etcd
   - Bevatten routing regels
   - Specificeren host en path-based routing

4. **Backend Services:**
   - ClusterIP Services voor interne communicatie
   - Payment Service → Payment Pods
   - Auth Service → Auth Pods

5. **Pods:**
   - Draaien de daadwerkelijke applicaties
   - Worden bereikt via Services

**Traffic Flow:**
```
External User 
  → DNS Resolution (example.com)
  → Load Balancer 
  → Ingress Controller
  → Reads Ingress Rules
  → Routes to Service (payment-service or auth-service)
  → Service routes to Pods
  → Application responds
```

---

## Ingress Routing Patterns

### Host-based Routing

Route naar verschillende services gebaseerd op hostname:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  rules:
  - host: webapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
```

**Use case:**
- `webapp.example.com` → frontend applicatie
- `api.example.com` → backend API
- Verschillende domeinen voor verschillende services

### Path-based Routing

Route naar verschillende services gebaseerd op URL path:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 5000
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 3000
```

**Use case:**
- `myapp.example.com/` → frontend
- `myapp.example.com/api` → backend API
- `myapp.example.com/admin` → admin interface

### PathType Options

**Prefix:**
```yaml
pathType: Prefix
path: /api
# Matches: /api, /api/, /api/v1, /api/users, etc.
```

**Exact:**
```yaml
pathType: Exact
path: /api
# Matches only: /api
# Does NOT match: /api/, /api/v1
```

**ImplementationSpecific:**
```yaml
pathType: ImplementationSpecific
# Depends on IngressClass implementation
```

---

## SSL/TLS Configuration

### TLS Termination met Ingress

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: webapp-tls
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # Base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi... # Base64 encoded private key
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress-tls
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: webapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

### Cert-Manager voor Automatische Certificates

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
```

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: admin@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Ingress met automatische certificate:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: webapp-tls-auto  # Automatically created by cert-manager
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

---

## NGINX Ingress Controller Setup

### Installation Methods

#### Method 1: Using kubectl (Manifest-based)

```bash
# Apply the NGINX Ingress Controller manifests
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml

# Verify installation
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

#### Method 2: Using Helm

```bash
# Add the NGINX Ingress Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress Controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Verify installation
helm list -n ingress-nginx
kubectl get pods -n ingress-nginx -w
```

#### For Minikube

```bash
# Enable ingress addon (easiest for local development)
minikube addons enable ingress

# Verify
kubectl get pods -n ingress-nginx
```

### Verify Installation

```bash
# Check if ingress controller is running
kubectl get pods -n ingress-nginx

# Expected output:
# NAME                                        READY   STATUS    RESTARTS   AGE
# ingress-nginx-controller-xxxxx              1/1     Running   0          2m

# Check service
kubectl get svc -n ingress-nginx

# Expected output:
# NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
# ingress-nginx-controller             LoadBalancer   10.96.xxx.xxx   <pending>     80:xxxxx/TCP,443:xxxxx/TCP
```

---

## Praktisch Voorbeeld: Complete Setup

### Scenario: PetShelter Applicatie met Ingress

Laten we een complete ingress setup maken voor de PetShelter applicatie.

**Stap 1: Deploy de applicatie**

```yaml
# mongodb-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
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
        image: mongo:7
        ports:
        - containerPort: 27017
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
```

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
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
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 5000
    targetPort: 5000
```

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
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
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 3000
    targetPort: 3000
```

**Stap 2: Creëer Ingress Resource**

```yaml
# petshelter-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: petshelter-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx  # Of "traefik" als je Traefik gebruikt
  rules:
  - host: petshelter.local
    http:
      paths:
      # Frontend routes
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000
      # API routes
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 5000
```

**Stap 3: Apply de configuratie**

```bash
# Deploy alles
kubectl apply -f mongodb-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl apply -f petshelter-ingress.yaml

# Verify
kubectl get pods
kubectl get svc
kubectl get ingress
```

**Stap 4: Test de ingress**

```bash
# Voor Minikube: Add to /etc/hosts
echo "$(minikube ip) petshelter.local" | sudo tee -a /etc/hosts

# Test
curl http://petshelter.local/
curl http://petshelter.local/api/pets

# Of open in browser
minikube service ingress-nginx-controller -n ingress-nginx
```

### Met TLS/HTTPS

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: petshelter-tls
type: kubernetes.io/tls
stringData:
  tls.crt: |
    -----BEGIN CERTIFICATE-----
    # Your certificate here
    -----END CERTIFICATE-----
  tls.key: |
    -----BEGIN PRIVATE KEY-----
    # Your private key here
    -----END PRIVATE KEY-----
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: petshelter-ingress-tls
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - petshelter.example.com
    secretName: petshelter-tls
  rules:
  - host: petshelter.example.com
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

---

## Traefik als Alternatief

### Waarom Traefik?

**Voordelen van Traefik:**
- ✅ **Auto-discovery**: Automatische service detectie
- ✅ **Real-time updates**: Geen reload nodig bij config changes
- ✅ **Built-in SSL**: Automatische certificaat generatie met Let's Encrypt
- ✅ **Dashboard**: Web UI voor monitoring en debugging
- ✅ **Cloud native**: Speciaal designed voor containers en Kubernetes
- ✅ **Modern**: HTTP/2, gRPC, WebSocket support out-of-the-box

### Traefik Installation

```bash
# Add Traefik Helm repository
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

# Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --create-namespace \
  --set dashboard.enabled=true \
  --set dashboard.domain=traefik.localhost
```

### Traefik Configuration

**traefik-values.yaml:**
```yaml
deployment:
  replicas: 2

service:
  type: LoadBalancer

ports:
  web:
    port: 80
    expose: true
  websecure:
    port: 443
    expose: true
  traefik:
    port: 9000
    expose: true

# Enable dashboard
api:
  dashboard: true
  insecure: true

# Automatic SSL certificates
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /data/acme.json
      httpChallenge:
        entryPoint: web

# Additional config
additionalArguments:
  - "--providers.kubernetesingress.ingressclass=traefik"
  - "--log.level=INFO"

# Resources
resources:
  requests:
    cpu: "100m"
    memory: "50Mi"
  limits:
    cpu: "300m"
    memory: "150Mi"
```

**Install met custom values:**
```bash
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --create-namespace \
  -f traefik-values.yaml
```

### Access Traefik Dashboard

```bash
# Port-forward to access dashboard
kubectl port-forward -n traefik-system $(kubectl get pods -n traefik-system | grep traefik | awk '{print $1}') 9000:9000

# Open in browser: http://localhost:9000/dashboard/
```

---

## Advanced Ingress Features
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # base64 encoded cert
  tls.key: LS0tLS1CRUdJTi... # base64 encoded key
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: webapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

### Automatic SSL with cert-manager

**Install cert-manager:**
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

**ClusterIssuer setup:**
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
```

**Automatic certificate Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: webapp-tls-auto  # Will be auto-generated
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

---

## Load Balancing Strategieën

### Traefik Load Balancing

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  annotations:
    traefik.ingress.kubernetes.io/service.loadbalancer.method: wrr
    traefik.ingress.kubernetes.io/service.loadbalancer.healthcheck.path: /health
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
```

### Advanced Load Balancing

**Weighted Round Robin:**
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: weighted-webapp
spec:
  weighted:
    services:
    - name: webapp-v1
      port: 80
      weight: 70  # 70% traffic to v1
    - name: webapp-v2
      port: 80
      weight: 30  # 30% traffic to v2 (canary)
```

---

## Complete Three-Tier Setup

### Application Services

```yaml
# Frontend Service
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80

---
# Backend Service
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000

---
# Database Service (internal only)
apiVersion: v1
kind: Service
metadata:
  name: database-service
spec:
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP  # Internal only!
```

### Comprehensive Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/router.middlewares: default-auth@kubernetescrd
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: webapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      # Frontend routes
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      
      # API routes
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 3000
      
      # Health check endpoint
      - path: /health
        pathType: Exact
        backend:
          service:
            name: backend-service
            port:
              number: 3000
```

---

## Advanced Ingress Features

### Middleware Configuration

```yaml
# Basic Auth Middleware
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
spec:
  basicAuth:
    secret: authsecret

---
# Rate Limiting Middleware
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
spec:
  rateLimit:
    burst: 100
    average: 50

---
# CORS Middleware
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: cors-header
spec:
  headers:
    accessControlAllowMethods:
      - GET
      - POST
      - PUT
    accessControlAllowOriginList:
      - https://myapp.example.com
    accessControlMaxAge: 100
```

---

## External DNS Integration

### Automatic DNS Management

```bash
# Install external-dns
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install external-dns bitnami/external-dns \
  --set provider=cloudflare \
  --set cloudflare.apiToken=your-api-token \
  --set domainFilters[0]=example.com
```

**Ingress with auto-DNS:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.example.com
    external-dns.alpha.kubernetes.io/ttl: "120"
spec:
  rules:
  - host: myapp.example.com
    # ... rest of config
```

---

## Monitoring & Troubleshooting

### Ingress Debugging

```bash
# Check ingress status
kubectl get ingress

# Describe ingress for events
kubectl describe ingress webapp-ingress

# Check ingress controller logs
kubectl logs -n traefik-system deployment/traefik

# Test ingress connectivity
curl -H "Host: myapp.example.com" http://CLUSTER_IP

# Check certificate status
kubectl get certificate
kubectl describe certificate webapp-tls
```

### Common Issues & Solutions

**1. Ingress not working:**
```bash
# Check if ingress controller is running
kubectl get pods -n traefik-system

# Verify service endpoints
kubectl get endpoints webapp-service
```

**2. SSL certificate issues:**
```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate challenges
kubectl get challenges
kubectl describe challenge webapp-tls-auto-123
```

---

## Kubernetes Ingress FAQs

### Is Ingress a load balancer?

**Nee.** Ingress is NIET een load balancer. 

- **Ingress** is een Kubernetes resource object dat routing regels, custom headers, en TLS configuraties bevat
- De **Ingress Controller** fungeert als de daadwerkelijke load balancer en reverse proxy
- De Ingress Controller leest de Ingress regels en routeert het verkeer

### Why do I need an ingress controller?

De ingress controller is verantwoordelijk voor de **daadwerkelijke routing** van externe traffic naar Kubernetes service endpoints. 

**Zonder een ingress controller:**
- Routing regels toegevoegd aan ingress objects zullen NIET werken
- Het is alsof je een routekaart hebt (ingress) maar geen chauffeur (controller)

**Met een ingress controller:**
- De controller leest de ingress objects uit de Kubernetes API
- Configureert een reverse proxy (Nginx/Traefik/HAProxy)
- Routeert traffic volgens de regels in de ingress objects

### What is the difference between ingress and Nginx?

- **Ingress** = Een Kubernetes object (resource definition)
- **Nginx** = Software die gebruikt wordt als een ingress controller (reverse proxy implementatie)

**Analogie:**
- Ingress = Receptenboek (instructies)
- Nginx = De kok die het recept uitvoert

### Can we route traffic to multiple paths using ingress?

**Ja!** Met een enkele ingress definitie kun je meerdere path-based routing configuraties toevoegen.

**Voorbeeld:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-path-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 4000
      - path: /docs
        pathType: Prefix
        backend:
          service:
            name: documentation-service
            port:
              number: 5000
```

### Does ingress support TLS configuration?

**Ja!** Je kan TLS configuraties hebben in je ingress object definitie.

**Hoe het werkt:**
1. TLS certificaat wordt toegevoegd als een Kubernetes Secret
2. De Secret wordt gerefereerd in het ingress object
3. De ingress controller handelt de TLS termination af

**Voorbeeld:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: webapp-tls
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: webapp-tls  # Reference to the secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
```

### Wat is het verschil tussen IngressClass en ingress controller?

**IngressClass** = Een Kubernetes resource dat een specifieke ingress controller implementatie definieert

**Gebruik:**
- Als je meerdere ingress controllers hebt (bijvoorbeeld: Nginx EN Traefik)
- Je moet specificeren welke controller een ingress resource moet verwerken

**Voorbeeld:**
```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
spec:
  ingressClassName: nginx  # Uses nginx controller
  rules:
  - host: myapp.example.com
    # ...
```

### Can I use ingress without a cloud load balancer?

**Ja!** Er zijn verschillende opties:

1. **NodePort**: Ingress controller exposed via NodePort
   ```yaml
   service:
     type: NodePort
   ```

2. **HostNetwork**: Ingress controller gebruikt host network
   ```yaml
   hostNetwork: true
   ```

3. **MetalLB**: Software load balancer voor bare metal
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.0/config/manifests/metallb-native.yaml
   ```

4. **Minikube**: Built-in ingress support
   ```bash
   minikube addons enable ingress
   ```

---

## Monitoring & Troubleshooting

### Ingress Debugging

```bash
# Check ingress status
kubectl get ingress

# Describe ingress voor events en details
kubectl describe ingress webapp-ingress

# Check ingress controller logs (Nginx)
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check ingress controller logs (Traefik)
kubectl logs -n traefik-system deployment/traefik

# Test ingress connectivity
curl -H "Host: myapp.example.com" http://CLUSTER_IP

# Check certificate status
kubectl get certificate
kubectl describe certificate webapp-tls
```

### Common Issues & Solutions

**1. Ingress not working:**
```bash
# Check if ingress controller is running
kubectl get pods -n ingress-nginx
# Expected: Controller pod moet Running zijn

# Verify service endpoints
kubectl get endpoints webapp-service
# Expected: Endpoints moeten IP adressen hebben

# Check if service selector matches pod labels
kubectl get pods --show-labels
kubectl get svc webapp-service -o yaml | grep selector
```

**2. SSL certificate issues:**
```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate challenges
kubectl get challenges
kubectl describe challenge webapp-tls-auto-123

# Check certificate ready status
kubectl get certificate webapp-tls
# Expected: READY = True
```

**3. 404 Not Found errors:**
```bash
# Check if path matches exactly
kubectl get ingress webapp-ingress -o yaml

# Verify backend service exists
kubectl get svc

# Test service directly
kubectl port-forward svc/webapp-service 8080:80
curl localhost:8080

# Check ingress controller configuration
kubectl exec -it -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | grep -A 20 webapp
```

**4. Backend unhealthy:**
```bash
# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Check service endpoint
kubectl describe svc webapp-service
# Expected: Endpoints moet pod IPs bevatten

# Test pod directly
kubectl port-forward <pod-name> 8080:80
curl localhost:8080
```

---

## Best Practices

### Security
- ✅ Always use HTTPS in production (TLS/SSL)
- ✅ Implement proper authentication middleware
- ✅ Use rate limiting to prevent DDoS abuse
- ✅ Keep ingress controller updated (security patches)
- ✅ Use network policies voor toegangscontrole
- ✅ Scan certificates voor expiration
- ✅ Gebruik secrets voor gevoelige data (niet hardcoded)

### Performance
- ✅ Enable gzip compression middleware
- ✅ Use caching waar appropriate
- ✅ Monitor ingress metrics (Prometheus/Grafana)
- ✅ Implement proper health checks
- ✅ Configure connection pooling
- ✅ Set appropriate timeouts
- ✅ Use HTTP/2 waar mogelijk

### Maintenance
- ✅ Use GitOps voor ingress configurations (ArgoCD/Flux)
- ✅ Test ingress changes in staging VOOR production
- ✅ Monitor certificate expiration dates
- ✅ Have backup ingress controllers (high availability)
- ✅ Document custom annotations
- ✅ Version control alle manifests
- ✅ Implement proper logging en monitoring

### Production Checklist

```yaml
# Production-ready ingress example
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-ingress
  annotations:
    # TLS/SSL
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Security
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://app.example.com"
    
    # Performance
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    
    # Monitoring
    nginx.ingress.kubernetes.io/enable-access-log: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

---

## Volgende Stappen

### Advanced Topics

1. **Gateway API**: De opvolger van Ingress
   - Meer expressieve routing
   - Role-oriented design
   - Portable across implementations
   - Reference: https://kubernetes.io/docs/concepts/services-networking/gateway/

2. **Service Mesh** (Istio, Linkerd):
   - Advanced traffic management
   - Mutual TLS
   - Observability
   - Circuit breaking

3. **API Gateway** (Kong, Tyk):
   - API management
   - Authentication/Authorization
   - Rate limiting
   - Analytics

### Resources

- 📚 [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- 📚 [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- 📚 [Traefik Documentation](https://doc.traefik.io/traefik/)
- 📚 [Cert-Manager](https://cert-manager.io/docs/)
- 📚 [Ingress Controller Comparison](https://docs.google.com/spreadsheets/d/191WWNpjJ2za6-nbG4ZoUMXMpUK8KlCIosvQB0f-oq3k/edit#gid=907731238)
- 📚 [DevOpsCube Ingress Setup Guide](https://devopscube.com/setup-ingress-kubernetes-nginx-controller/)
- 📚 [Kubernetes Gateway API Tutorial](https://devopscube.com/kubernetes-gateway-api/)

---

## Conclusie: Professional External Access

### Voor Ingress

```bash
# Multiple LoadBalancers needed = $$$ kostbaar
kubectl expose deployment frontend --type=LoadBalancer --port=80
kubectl expose deployment backend --type=LoadBalancer --port=3000
kubectl expose deployment api-v1 --type=LoadBalancer --port=8080
kubectl expose deployment api-v2 --type=LoadBalancer --port=8081
# Result: 4 load balancers = 4x de kosten!
```

### Met Ingress

```yaml
# Eén ingress handles everything = Cost effective!
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: unified-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /           → frontend
      - path: /api/v1     → backend
      - path: /api/v2     → api-v2
  # Eén load balancer voor alles!
```

### Voordelen Samengevat

**Cost & Efficiency:**
- ✅ **Cost effective**: Eén load balancer voor alle services (bespaar $$$)
- ✅ **Simplified management**: Eén entry point
- ✅ **Resource efficiency**: Minder overhead

**Functionality:**
- ✅ **SSL/TLS management**: Automatische certificate handling (Let's Encrypt)
- ✅ **Advanced routing**: Host-based en path-based routing
- ✅ **Flexible configuration**: Annotations voor fine-tuning

**Production Ready:**
- ✅ **Rate limiting**: DDoS protection
- ✅ **Authentication**: Middleware support
- ✅ **Monitoring**: Metrics en logging
- ✅ **Health checks**: Automatic failover

**Cloud Native:**
- ✅ **DNS integration**: Automatic DNS updates (External DNS)
- ✅ **Certificate automation**: Cert-manager integration
- ✅ **GitOps friendly**: Declarative configuration

**Ingress + Controller = Professional Kubernetes Networking! 🚀**

**Key Takeaways:**
1. Ingress is een resource object (regels), Ingress Controller is de implementatie (routing)
2. Altijd HTTPS gebruiken in productie (TLS/cert-manager)
3. Eén load balancer kan alle services bedienen (cost savings!)
4. Kies de juiste ingress controller voor je use case (Nginx, Traefik, HAProxy)
5. Monitor en test ingress configuraties voordat je naar productie gaat



Ingress + Traefik = Professional Kubernetes networking!