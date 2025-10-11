# Les 11: Service Mesh & Microservices

## Service Mesh Introductie

### Het Microservices Communicatie Probleem

#### **Monolith vs Microservices Communication**

**Monolith (Simple):**
```
┌─────────────────────────────────┐
│         Monolithic App          │
│  ┌─────────┬─────────┬─────────┐│
│  │   UI    │   API   │   DB    ││
│  │ Layer   │ Layer   │ Layer   ││
│  └─────────┴─────────┴─────────┘│
│     Direct Function Calls       │
└─────────────────────────────────┘
```

**Microservices (Complex):**
```
┌─────────┐    ┌─────────┐    ┌─────────┐
│Frontend │───▶│Auth API │───▶│User DB  │
│Service  │    │Service  │    │Service  │
└─────────┘    └─────────┘    └─────────┘
     │              │              │
     ▼              ▼              ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│Product  │───▶│Payment  │───▶│Inventory│
│Service  │    │Service  │    │Service  │
└─────────┘    └─────────┘    └─────────┘
     │              │              │
     ▼              ▼              ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│Order    │───▶│Shipping │───▶│Notif.   │
│Service  │    │Service  │    │Service  │
└─────────┘    └─────────┘    └─────────┘
```

#### **Microservices Uitdagingen**

**1. Service Discovery**
```bash
# Hoe vindt Frontend Service de User Service?
# Hard-coded IPs werken niet in Kubernetes
curl http://192.168.1.100:3000/users  # ❌ Fragile

# Kubernetes service discovery helpt, maar...
curl http://user-service:3000/users   # ✅ Better, but limited
```

**2. Load Balancing**
```yaml
# Kubernetes Service geeft basic load balancing
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 3000
# Maar geen intelligent routing, circuit breakers, etc.
```

**3. Security & Encryption**
```bash
# Service-to-service communication vaak onveilig
curl http://user-service:3000/internal/admin  # ❌ No authentication
```

**4. Observability**
```bash
# Moeilijk te tracen door complex request flow:
Frontend → Auth → User → Payment → Order → Shipping
# Waar faalt de request? Hoe lang duurt elke stap?
```

**5. Traffic Management**
```bash
# Geen geavanceerd traffic routing:
# - Canary deployments
# - A/B testing  
# - Rate limiting
# - Circuit breaking
```

### Service Mesh Oplossing

#### **Service Mesh Architectuur**
```
┌─────────────────────────────────────────────────────────┐
│                 Control Plane                          │
│  ┌─────────────┬─────────────┬─────────────────────────┐│
│  │   Policy    │ Telemetry   │      Configuration      ││
│  │ Enforcement │ Collection  │      Management         ││
│  └─────────────┴─────────────┴─────────────────────────┘│
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  Data Plane                            │
│                                                         │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐              │
│  │┌───────┐│    │┌───────┐│    │┌───────┐│              │
│  ││Service││    ││Service││    ││Service││              │
│  ││   A   ││    ││   B   ││    ││   C   ││              │
│  │└───────┘│    │└───────┘│    │└───────┘│              │
│  │ [Proxy] │    │ [Proxy] │    │ [Proxy] │              │
│  └─────────┘    └─────────┘    └─────────┘              │
│       │              │              │                   │
│       └──────────────┼──────────────┘                   │
│            Encrypted │ mTLS Communication               │
└─────────────────────────────────────────────────────────┘
```

**Service Mesh Voordelen:**
- 🔒 **Automatische mTLS** tussen alle services
- 📊 **Gedetailleerde telemetry** voor elk request
- 🚦 **Traffic management** (routing, load balancing, retries)
- 🛡️ **Policy enforcement** (rate limiting, access control)
- 🔍 **Distributed tracing** door complete request flow
- 🏥 **Circuit breaking** en fault tolerance

---

## Istio Service Mesh

### Istio Architectuur

#### **Core Components**
```
┌─────────────────────────────────────────────────────────┐
│                  Istio Control Plane                   │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │                   istiod                            ││
│  │  ┌─────────────┬─────────────┬─────────────────────┐││
│  │  │   Pilot     │   Citadel   │      Galley         │││
│  │  │ (Traffic    │ (Security   │   (Configuration    │││
│  │  │Management)  │Management)  │   Management)       │││
│  │  └─────────────┴─────────────┴─────────────────────┘││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  Envoy Proxies                         │
│                                                         │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐              │
│  │┌───────┐│    │┌───────┐│    │┌───────┐│              │
│  ││Service││    ││Service││    ││Service││              │
│  ││   A   ││    ││   B   ││    ││   C   ││              │
│  │└───────┘│    │└───────┘│    │└───────┘│              │
│  │ Envoy   │    │ Envoy   │    │ Envoy   │              │
│  │ Sidecar │    │ Sidecar │    │ Sidecar │              │
│  └─────────┘    └─────────┘    └─────────┘              │
└─────────────────────────────────────────────────────────┘
```

### Istio Installatie

#### **Stap 1: Istio Setup**
```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio op Kubernetes cluster
istioctl install --set values.defaultRevision=default

# Verify installation
kubectl get pods -n istio-system

# Enable automatic sidecar injection voor namespace
kubectl label namespace default istio-injection=enabled
kubectl label namespace ecommerce istio-injection=enabled
```

#### **Stap 2: Deploy Istio Addons**
```bash
# Install observability tools
kubectl apply -f samples/addons/grafana.yaml
kubectl apply -f samples/addons/jaeger.yaml
kubectl apply -f samples/addons/kiali.yaml
kubectl apply -f samples/addons/prometheus.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system
```

### Istio Configuration

#### **1. Gateway - External Traffic**
```yaml
# istio-gateway.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: ecommerce-gateway
  namespace: ecommerce
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - ecommerce.example.com
    - "*"  # Allow all hosts for demo
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: ecommerce-tls-secret
    hosts:
    - ecommerce.example.com
```

#### **2. VirtualService - Traffic Routing**
```yaml
# frontend-virtualservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: frontend-vs
  namespace: ecommerce
spec:
  hosts:
  - ecommerce.example.com
  - "*"
  gateways:
  - ecommerce-gateway
  http:
  - match:
    - uri:
        prefix: /api/
    rewrite:
      uri: /
    route:
    - destination:
        host: backend
        port:
          number: 3000
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
    retries:
      attempts: 3
      perTryTimeout: 10s
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: frontend
        port:
          number: 80

---
# backend-virtualservice.yaml  
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend-vs
  namespace: ecommerce
spec:
  hosts:
  - backend
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: backend
        subset: canary
      weight: 100
  - route:
    - destination:
        host: backend
        subset: stable
      weight: 90
    - destination:
        host: backend
        subset: canary
      weight: 10
```

#### **3. DestinationRule - Load Balancing & Circuit Breaking**
```yaml
# backend-destinationrule.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: backend-dr
  namespace: ecommerce
spec:
  host: backend
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
    connectionPool:
      tcp:
        maxConnections: 10
      http:
        http1MaxPendingRequests: 10
        maxRequestsPerConnection: 2
    circuitBreaker:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
  - name: stable
    labels:
      version: stable
  - name: canary
    labels:
      version: canary
```

#### **4. ServiceEntry - External Services**
```yaml
# external-api-serviceentry.yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: external-payment-api
  namespace: ecommerce
spec:
  hosts:
  - api.stripe.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS

---
# external-api-virtualservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: external-payment-vs
  namespace: ecommerce
spec:
  hosts:
  - api.stripe.com
  http:
  - timeout: 10s
    retries:
      attempts: 3
      perTryTimeout: 5s
    route:
    - destination:
        host: api.stripe.com
```

### Security Policies

#### **1. PeerAuthentication - mTLS**
```yaml
# peer-authentication.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: ecommerce
spec:
  mtls:
    mode: STRICT  # Require mTLS for all communication

---
# Specific service mTLS
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: backend-mtls
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: backend
  mtls:
    mode: STRICT
  portLevelMtls:
    3000:
      mode: STRICT
```

#### **2. AuthorizationPolicy - Access Control**
```yaml
# authorization-policy.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: frontend-authz
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: frontend
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
  - to:
    - operation:
        methods: ["GET", "POST"]

---
# Backend access control
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: backend-authz
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: backend
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/ecommerce/sa/frontend-sa"]
  - to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
        paths: ["/api/*"]

---
# Database access - only from backend
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: database-authz
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      app: mongodb
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/ecommerce/sa/backend-sa"]
```

### Traffic Management

#### **1. Canary Deployment**
```yaml
# canary-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-canary
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
      version: canary
  template:
    metadata:
      labels:
        app: backend
        version: canary
    spec:
      containers:
      - name: api
        image: backend:v2.0  # New version
        ports:
        - containerPort: 3000
        env:
        - name: VERSION
          value: "v2.0-canary"

---
# Gradual traffic shift
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend-canary-vs
  namespace: ecommerce
spec:
  hosts:
  - backend
  http:
  - match:
    - headers:
        cookie:
          regex: ".*canary=true.*"
    route:
    - destination:
        host: backend
        subset: canary
  - route:
    - destination:
        host: backend
        subset: stable
      weight: 95
    - destination:
        host: backend
        subset: canary
      weight: 5  # 5% traffic to canary
```

#### **2. A/B Testing**
```yaml
# ab-testing-virtualservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: frontend-ab-test
  namespace: ecommerce
spec:
  hosts:
  - frontend
  http:
  - match:
    - headers:
        user-agent:
          regex: ".*Mobile.*"
    route:
    - destination:
        host: frontend
        subset: mobile-optimized
  - match:
    - headers:
        x-user-group:
          exact: "beta"
    route:
    - destination:
        host: frontend
        subset: beta-features
  - route:
    - destination:
        host: frontend
        subset: stable
```

---

## Linkerd - Lightweight Alternative

### Linkerd vs Istio Comparison

| Feature | Istio | Linkerd |
|---------|-------|---------|
| **Complexity** | High - Veel configuratie opties | Low - Simpele setup |
| **Resource Usage** | Higher - Envoy proxy overhead | Lower - Rust-based proxy |
| **Performance** | Good - Feature-rich | Excellent - Optimized for speed |
| **Learning Curve** | Steep - Complex concepts | Gentle - Easy to start |
| **Protocol Support** | HTTP, gRPC, TCP | HTTP, gRPC, TCP |
| **Multi-cluster** | ✅ Advanced | ✅ Basic |
| **Security** | ✅ Advanced policies | ✅ mTLS by default |

### Linkerd Installation

```bash
# Install Linkerd CLI
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin

# Pre-installation check
linkerd check --pre

# Install Linkerd control plane
linkerd install | kubectl apply -f -

# Verify installation
linkerd check

# Install viz extension for observability
linkerd viz install | kubectl apply -f -
```

### Linkerd Usage

#### **1. Inject Linkerd Proxy**
```bash
# Inject sidecar into existing deployment
kubectl get deploy backend -o yaml | linkerd inject - | kubectl apply -f -

# Or annotate namespace for automatic injection
kubectl annotate namespace ecommerce linkerd.io/inject=enabled

# Verify injection
linkerd -n ecommerce stat deploy
```

#### **2. Traffic Policies**
```yaml
# traffic-split.yaml - Canary deployment
apiVersion: split.smi-spec.io/v1alpha1
kind: TrafficSplit
metadata:
  name: backend-split
  namespace: ecommerce
spec:
  service: backend
  backends:
  - service: backend-stable
    weight: 90
  - service: backend-canary
    weight: 10

---
# service-profile.yaml - Advanced routing
apiVersion: linkerd.io/v1alpha2
kind: ServiceProfile
metadata:
  name: backend.ecommerce.svc.cluster.local
  namespace: ecommerce
spec:
  routes:
  - name: api_health
    condition:
      method: GET
      pathRegex: /health
    timeout: 5s
  - name: api_users
    condition:
      method: GET
      pathRegex: /api/users/.*
    timeout: 10s
    retryBudget:
      retryRatio: 0.2
      minRetriesPerSecond: 10
      ttl: 10s
```

#### **3. Linkerd Dashboard**
```bash
# Start dashboard
linkerd viz dashboard &

# Get metrics
linkerd -n ecommerce stat deploy
linkerd -n ecommerce routes deploy/backend
linkerd -n ecommerce top deploy/backend
```

---

## Service-to-Service Communication Patterns

### 1. Synchronous Communication

#### **HTTP/REST with Retries**
```yaml
# http-retry-pattern.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: user-service-vs
spec:
  hosts:
  - user-service
  http:
  - route:
    - destination:
        host: user-service
    retries:
      attempts: 3
      perTryTimeout: 2s
      retryOn: 5xx,gateway-error,connect-failure,refused-stream
    timeout: 10s
```

#### **gRPC with Load Balancing**
```yaml
# grpc-service.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: grpc-service-dr
spec:
  host: grpc-service
  trafficPolicy:
    loadBalancer:
      consistentHash:
        httpHeaderName: "user-id"  # Session affinity
    portLevelSettings:
    - port:
        number: 9000
      connectionPool:
        http:
          h2MaxRequests: 100
          maxRequestsPerConnection: 10
```

### 2. Circuit Breaker Pattern

#### **Implementation with Istio**
```yaml
# circuit-breaker.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: payment-service-cb
spec:
  host: payment-service
  trafficPolicy:
    outlierDetection:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 50
    connectionPool:
      tcp:
        maxConnections: 10
      http:
        http1MaxPendingRequests: 10
        maxRequestsPerConnection: 2
        consecutiveGatewayErrors: 5
        interval: 30s
        baseEjectionTime: 30s
```

---

## Monitoring en Observability

### Distributed Tracing

#### **Jaeger Integration**
```yaml
# jaeger-tracing.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: jaeger-config
data:
  sampling_strategies.json: |
    {
      "service_strategies": [
        {
          "service": "frontend",
          "type": "probabilistic",
          "param": 1.0
        },
        {
          "service": "backend",
          "type": "probabilistic", 
          "param": 0.8
        }
      ],
      "default_strategy": {
        "type": "probabilistic",
        "param": 0.1
      }
    }
```

#### **Application Instrumentation**
```javascript
// Node.js application with tracing
const opentelemetry = require('@opentelemetry/api');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

// Initialize tracing
const jaegerExporter = new JaegerExporter({
  endpoint: 'http://jaeger-collector:14268/api/traces',
});

const sdk = new NodeSDK({
  traceExporter: jaegerExporter,
  serviceName: 'backend-service',
});

sdk.start();

// Express middleware for trace context
app.use((req, res, next) => {
  const span = opentelemetry.trace.getActiveSpan();
  span?.setAttributes({
    'http.method': req.method,
    'http.url': req.url,
    'user.id': req.headers['x-user-id']
  });
  next();
});
```

### Dashboard Visualization

#### **Kiali Service Map**
```bash
# Access Kiali dashboard
kubectl port-forward svc/kiali 20001:20001 -n istio-system

# Kiali shows:
# - Service topology
# - Traffic flow between services
# - Error rates and response times
# - Security policies visualization
```

#### **Grafana Dashboards**
```bash
# Access Grafana
kubectl port-forward svc/grafana 3000:3000 -n istio-system

# Pre-built dashboards:
# - Istio Service Dashboard
# - Istio Workload Dashboard  
# - Istio Performance Dashboard
# - Istio Control Plane Dashboard
```

---

## Samenvatting

### Service Mesh Voordelen:

✅ **Automatische mTLS** - Zero-trust security by default  
✅ **Traffic Management** - Canary, A/B testing, circuit breaking  
✅ **Observability** - Distributed tracing, metrics, logging  
✅ **Policy Enforcement** - Rate limiting, access control  
✅ **Service Discovery** - Advanced routing en load balancing  
✅ **Fault Tolerance** - Retries, timeouts, circuit breakers  

### Tool Keuze Richtlijnen:

**Gebruik Istio wanneer:**
- Complex traffic management nodig
- Advanced security policies vereist
- Multi-cluster setup
- Team heeft expertise met complexe tools

**Gebruik Linkerd wanneer:**
- Eenvoudige service mesh nodig
- Performance is kritiek
- Kleine tot middelgrote deployments
- Focus op observability en security basics

### Volgende Stappen:

In **Les 12** behandelen we **GitOps en Advanced CI/CD**:
- ArgoCD voor declarative deployments
- Flux voor continuous delivery
- GitOps workflow patterns
- Multi-environment deployment strategieën

### Best Practices:

- 🔒 Start met security-first mindset (Zero Trust)
- 📊 Implement comprehensive observability van begin af aan
- 🚦 Use traffic management voor safe deployments
- 🧪 Test chaos engineering scenarios regelmatig
- 📈 Monitor business metrics alongside technical metrics