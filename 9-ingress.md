# 9 - Ingress & Reverse Proxies: External Access naar Kubernetes

## Inleiding: Het External Access Probleem

**Het probleem:**
In Kubernetes draaien je applicaties in een cluster, maar hoe krijg je externe toegang tot je services?

**Basic service types limitations:**
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

**De oplossing: Ingress**
- ✅ **Eén entry point** voor alle services
- ✅ **Path-based routing**: verschillende URLs naar verschillende services
- ✅ **SSL/TLS termination**: HTTPS afhandeling
- ✅ **Cost effective**: Eén load balancer voor alles

---

## Ingress Fundamentals

### Wat is een Ingress?

**Ingress** = HTTP(S) routing regels die externe toegang tot services in een cluster regelen.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
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
              number: 3000
```

### Ingress Controller

**Belangrijk**: Ingress resource doet niets zonder een **Ingress Controller**!

Populaire Ingress Controllers:
- **NGINX Ingress Controller** (meest gebruikt)
- **Traefik** (modern, auto-discovery)
- **HAProxy Ingress**
- **Istio Gateway**
- **AWS Load Balancer Controller**

---

## Traefik als Modern Reverse Proxy

### Waarom Traefik?

**Voordelen van Traefik:**
- ✅ **Auto-discovery**: Automatische service detectie
- ✅ **Real-time updates**: Geen reload nodig
- ✅ **Built-in SSL**: Automatische cert generation
- ✅ **Dashboard**: Web UI voor monitoring
- ✅ **Cloud native**: Designed voor containers

### Traefik Installation

```bash
# Add Traefik Helm repository
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

# Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --create-namespace \
  --set dashboard.expose=true
```

### Traefik Configuration

```yaml
# traefik-values.yaml
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
```

---

## Ingress Routing Patterns

### Host-based Routing

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

### Path-based Routing

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
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 3000
      - path: /api/v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 3001
```

---

## SSL/TLS Certificate Management

### Manual Certificate Setup

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: webapp-tls
  namespace: default
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

## Best Practices

### Security
- Always use HTTPS in production
- Implement proper authentication middleware
- Use rate limiting to prevent abuse
- Keep ingress controller updated

### Performance
- Enable compression middleware
- Use caching where appropriate
- Monitor ingress metrics
- Implement proper health checks

### Maintenance
- Use GitOps for ingress configurations
- Test ingress changes in staging first
- Monitor certificate expiration
- Have backup ingress controllers

---

## Conclusie: Professional External Access

**Voor Ingress:**
```bash
# Multiple LoadBalancers needed
kubectl expose deployment frontend --type=LoadBalancer --port=80
kubectl expose deployment backend --type=LoadBalancer --port=3000
# Result: Multiple expensive load balancers
```

**Met Ingress:**
```yaml
# One ingress handles everything
apiVersion: networking.k8s.io/v1
kind: Ingress
# ... routes to multiple services
```

**Voordelen samengevat:**
- ✅ **Cost effective**: Eén load balancer voor alle services
- ✅ **SSL management**: Automatic certificate handling
- ✅ **Advanced routing**: Host and path-based routing
- ✅ **Production ready**: Rate limiting, auth, monitoring
- ✅ **Cloud native**: Integrates with DNS and cert management

Ingress + Traefik = Professional Kubernetes networking!