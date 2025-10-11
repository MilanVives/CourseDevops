# Les 6: Kubernetes Cloud Deployment - Easy Start

## Introductie: Waarom Kubernetes?

### Het Container Orchestratie Probleem

Na het leren van Docker en Docker Compose stuit je al snel op beperkingen:

#### **Docker Compose Beperkingen:**
```yaml
# docker-compose.yml werkt lokaal, maar...
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "80:80"
    replicas: 3  # ❌ Dit werkt niet in Compose!
```

**Problemen die optreden:**
- ❌ **Geen automatische failover** - als container crasht, start deze niet automatisch
- ❌ **Geen load balancing** tussen meerdere instances van dezelfde service
- ❌ **Geen auto-scaling** - kan niet automatisch opschalen bij hoge load
- ❌ **Één machine beperking** - Compose werkt alleen op één host
- ❌ **Geen rolling updates** - downtime bij deployments
- ❌ **Geen health checks** met automatische herstel

### Kubernetes als Oplossing

Kubernetes lost deze problemen op door:
- ✅ **Automatische healing** - crashed containers worden herstart
- ✅ **Load balancing** - verkeer wordt verdeeld over healthy instances
- ✅ **Auto-scaling** - meer pods bij hoge load
- ✅ **Multi-node** - werkt over meerdere machines/servers
- ✅ **Rolling updates** - zero-downtime deployments
- ✅ **Health monitoring** - unhealthy pods worden vervangen

---

## Van Docker Compose naar Kubernetes

### Praktisch Voorbeeld: Nginx Deployment

#### **Docker Compose (lokaal):**
```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    environment:
      - ENV=production
```

#### **Kubernetes (cloud-ready):**
```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3  # 3 instances voor high availability
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: ENV
          value: "production"
---
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer  # External access via cloud load balancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
```

**Voordelen van Kubernetes versie:**
- 🔄 **3 replicas** - high availability
- 🌐 **LoadBalancer service** - automatische load balancing
- 🔧 **Self-healing** - crashed pods worden automatisch vervangen
- 📈 **Scalable** - kan eenvoudig opgeschaald worden

---

## Linode Kubernetes Engine (LKE) - Quick Start

### Waarom Linode?

- 💰 **Kosteneffectief** - goedkoper dan AWS/GCP voor leren
- 🚀 **Eenvoudig** - simpele interface en setup
- ⚡ **Snel** - cluster binnen 5 minuten operationeel
- 🎓 **Perfect voor leren** - geen complexe billing of credits

### Stap 1: LKE Cluster Aanmaken

```bash
# Via Linode CLI (optioneel)
curl -H "Authorization: Bearer $LINODE_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{
      "label": "my-k8s-cluster",
      "region": "eu-west",
      "k8s_version": "1.28",
      "node_pools": [
        {
          "type": "g6-standard-2",
          "count": 2
        }
      ]
    }' \
    https://api.linode.com/v4/lke/clusters
```

**Of via Linode Dashboard:**
1. Ga naar Kubernetes tab
2. Create Cluster
3. Kies regio (Amsterdam/Frankfurt)
4. Selecteer node type: `g6-standard-2` (2 CPU, 4GB RAM)
5. Aantal nodes: 2
6. Create Cluster

### Stap 2: kubectl Configureren

```bash
# Download kubeconfig van Linode dashboard
# Of via CLI:
curl -H "Authorization: Bearer $LINODE_TOKEN" \
    https://api.linode.com/v4/lke/clusters/$CLUSTER_ID/kubeconfig | \
    base64 -d > ~/.kube/config

# Test connectie
kubectl get nodes
# NAME                         STATUS   ROLES    AGE   VERSION
# lke-cluster-pool-12345-abc   Ready    <none>   5m    v1.28.0
# lke-cluster-pool-12345-def   Ready    <none>   5m    v1.28.0
```

### Stap 3: Eerste Deployment

```bash
# Maak deployment
kubectl create deployment nginx --image=nginx:latest

# Scale naar 3 replicas
kubectl scale deployment nginx --replicas=3

# Expose via LoadBalancer
kubectl expose deployment nginx --type=LoadBalancer --port=80

# Check status
kubectl get deployments
kubectl get pods
kubectl get services
```

**Output:**
```
NAME    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
nginx   LoadBalancer   10.2.34.56     139.162.1.2      80:30123/TCP   2m
```

### Stap 4: Toegang Tot Applicatie

```bash
# Get external IP
EXTERNAL_IP=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Application available at: http://$EXTERNAL_IP"

# Test
curl http://$EXTERNAL_IP
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
```

---

## Praktische Oefening: WordPress op Kubernetes

### Doel
Deploy een WordPress website met MySQL database op LKE cluster.

### Stap 1: MySQL Database

```yaml
# mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword123"
        - name: MYSQL_DATABASE
          value: "wordpress"
        - name: MYSQL_USER
          value: "wpuser"
        - name: MYSQL_PASSWORD
          value: "wppassword123"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  clusterIP: None  # Headless service voor interne toegang
```

### Stap 2: WordPress Applicatie

```yaml
# wordpress-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:latest
        env:
        - name: WORDPRESS_DB_HOST
          value: "mysql:3306"
        - name: WORDPRESS_DB_NAME
          value: "wordpress"
        - name: WORDPRESS_DB_USER
          value: "wpuser"
        - name: WORDPRESS_DB_PASSWORD
          value: "wppassword123"
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: wordpress
```

### Stap 3: Deployment

```bash
# Deploy MySQL
kubectl apply -f mysql-deployment.yaml

# Wacht tot MySQL ready is
kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

# Deploy WordPress
kubectl apply -f wordpress-deployment.yaml

# Check status
kubectl get all

# Get WordPress URL
kubectl get svc wordpress
```

### Stap 4: WordPress Setup

1. Ga naar externe IP van WordPress LoadBalancer
2. Volg WordPress setup wizard
3. Maak admin account aan
4. Test website functionaliteit

---

## High Availability Demonstratie

### Kubernetes Self-Healing

```bash
# Bekijk running pods
kubectl get pods

# Verwijder een WordPress pod (simuleer crash)
POD_NAME=$(kubectl get pods -l app=wordpress -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Kubernetes start automatisch nieuwe pod
kubectl get pods --watch
```

**Observatie:**
- 🔄 Oude pod verdwijnt (Terminating)
- 🚀 Nieuwe pod wordt automatisch gestart
- 🌐 LoadBalancer blijft traffic routeren naar healthy pods
- ⚡ Geen downtime voor gebruikers

### Load Balancing Test

```bash
# Installeer hey load tester
go install github.com/rakyll/hey@latest

# Of gebruik ab (Apache Bench)
sudo apt-get install apache2-utils

# Test load balancing
WORDPRESS_IP=$(kubectl get svc wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Stuur 1000 requests
hey -n 1000 -c 10 http://$WORDPRESS_IP

# Bekijk logs van beide WordPress pods
kubectl logs -l app=wordpress --tail=50
```

---

## Monitoring en Troubleshooting

### Basis Monitoring Commando's

```bash
# Cluster status
kubectl cluster-info
kubectl get nodes

# Resource overzicht
kubectl get all --all-namespaces

# Pod details en events
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Logs
kubectl logs <pod-name>
kubectl logs -l app=wordpress --tail=100

# Resource gebruik
kubectl top nodes
kubectl top pods
```

### Troubleshooting Checklist

#### **Pod start niet:**
```bash
# Check pod status en events
kubectl describe pod <pod-name>

# Check image bestaat
kubectl get pod <pod-name> -o yaml | grep image

# Check resource limits
kubectl describe node
```

#### **Service niet bereikbaar:**
```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Check service selector
kubectl get svc <service-name> -o yaml

# Test connectivity vanuit pod
kubectl exec -it <pod-name> -- curl <service-name>
```

#### **LoadBalancer krijgt geen External IP:**
```bash
# Check cloud controller
kubectl get pods -n kube-system | grep cloud

# Check service events
kubectl describe svc <service-name>

# Linode specific: check NodeBalancer in dashboard
```

---

## Kubernetes Dashboard (Optioneel)

### Dashboard Installatie

```bash
# Installeer dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Maak admin service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# Get access token
kubectl -n kubernetes-dashboard create token admin-user

# Start proxy
kubectl proxy

# Open dashboard
open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## Cleanup

### Resources Opruimen

```bash
# Verwijder deployments
kubectl delete deployment wordpress mysql

# Verwijder services
kubectl delete service wordpress mysql

# Check alles is weg
kubectl get all

# Cluster verwijderen (via Linode dashboard of CLI)
curl -H "Authorization: Bearer $LINODE_TOKEN" \
    -X DELETE \
    https://api.linode.com/v4/lke/clusters/$CLUSTER_ID
```

---

## Samenvatting

### Wat je hebt geleerd:

✅ **Kubernetes voordelen** vs Docker Compose beperkingen  
✅ **Managed Kubernetes** setup met Linode (LKE)  
✅ **Basic deployments** en services  
✅ **LoadBalancer** voor externe toegang  
✅ **Multi-tier applicatie** deployment (WordPress + MySQL)  
✅ **High availability** en self-healing  
✅ **Basic monitoring** en troubleshooting  
✅ **Resource cleanup** procedures  

### Volgende Stap:

In **Les 7** duiken we diep in Kubernetes theorie en concepten:
- Pods, Services, Deployments in detail
- ConfigMaps en Secrets
- Namespaces en labels
- Complex drie-tier applicatie deployment

### Handige Resources:

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Linode Kubernetes Engine Guide](https://www.linode.com/docs/guides/deploy-and-manage-a-cluster-with-linode-kubernetes-engine-a-tutorial/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)