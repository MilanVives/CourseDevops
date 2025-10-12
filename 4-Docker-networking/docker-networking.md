# 4 - Docker Networking: Van Geïsoleerd naar Verbonden

## Inleiding: Het netwerklabyrint

Stel je voor: je hebt meerdere containers draaien, maar ze leven in hun eigen kleine wereld. Hoe laat je ze met elkaar praten? Hoe bereik je ze vanaf je host machine? En hoe zorg je ervoor dat ze veilig communiceren?

**Het scenario:**
- Container A moet data verzenden naar Container B
- Container B moet bereikbaar zijn vanaf de host
- Container C moet geïsoleerd blijven van de rest
- Alles moet veilig en performant zijn

**In dit hoofdstuk leer je:**
- Hoe Docker networking werkt onder de motorkap
- Verschillende network drivers en hun use cases
- Praktische container communicatie met netcat en curl
- Network isolatie en security
- Troubleshooting van netwerkproblemen
- Best practices voor productie omgevingen

---

## Fase 1: Docker networking fundamenten

### Het default gedrag

**Wanneer je geen netwerk specificeert:**
```bash
# Start een container zonder network configuratie
docker run -d --name web nginx:alpine

# Wat gebeurt er automatisch?
docker inspect web | grep -A 10 "NetworkSettings"
```

**Docker maakt automatisch:**
- Een bridge network (`docker0`)
- Een uniek IP adres voor de container
- NAT (Network Address Translation) voor internet toegang
- Interne DNS voor container naam resolving

### De drie pijlers van Docker networking

**1. Container Network Model (CNM):**
```
┌─────────────────┐    ┌─────────────────┐
│   Container A   │    │   Container B   │
│  172.17.0.2     │    │  172.17.0.3     │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └────────┬─────────────┘
                   │
            ┌──────▼──────┐
            │ Bridge      │
            │ docker0     │
            │ 172.17.0.1  │
            └──────┬──────┘
                   │
            ┌──────▼──────┐
            │ Host        │
            │ eth0        │
            └─────────────┘
```

**2. Network Drivers:**
- `bridge`: Default voor single-host networking
- `host`: Container gebruikt host's network stack
- `overlay`: Multi-host clustering (Swarm)
- `macvlan`: Geeft containers MAC adressen
- `none`: Geen networking

**3. Network Scopes:**
- `local`: Single Docker host
- `swarm`: Docker Swarm cluster
- `global`: Alle nodes in het cluster

---

## Fase 2: Bridge networks - De standaard

### Default bridge network

**Automatisch gedrag verkennen:**
```bash
# Lijst huidige networks
docker network ls

# Inspecteer de default bridge
docker network inspect bridge

# Start containers op default bridge
docker run -d --name container1 alpine sleep 3600
docker run -d --name container2 alpine sleep 3600

# Bekijk IP adressen
docker inspect container1 | grep IPAddress
docker inspect container2 | grep IPAddress
```

**Praktische test met netcat:**
```bash
# In container1: start een server
docker exec -it container1 sh
apk add netcat-openbsd
nc -l -p 8080

# In container2: verbind met container1
docker exec -it container2 sh
apk add netcat-openbsd
# Get container1 IP first
CONTAINER1_IP=$(docker inspect container1 | grep -m 1 '"IPAddress"' | cut -d '"' -f 4)
echo "Hello from container2" | nc $CONTAINER1_IP 8080
```

**Beperkingen van default bridge:**
- ❌ Geen automatische DNS resolution met container namen
- ❌ Alle containers kunnen met elkaar praten (geen isolatie)
- ❌ Moeilijk te beheren bij veel containers

### Custom bridge networks

**Creëer je eigen bridge network:**
```bash
# Maak custom bridge network
docker network create mybridge

# Inspecteer het nieuwe network
docker network inspect mybridge

# Start containers op custom network
docker run -d --name web1 --network mybridge nginx:alpine
docker run -d --name web2 --network mybridge nginx:alpine
```

**Voordelen van custom bridge:**
```bash
# Test DNS resolution met container namen
docker exec web1 ping web2
docker exec web2 ping web1

# Test communicatie met netcat
docker exec -d web1 sh -c "echo 'Hello from web1' | nc -l -p 8080"
docker exec web2 sh -c "nc web1 8080"
```

**Netwerk configuratie opties:**
```bash
# Network met custom subnet
docker network create \
  --driver bridge \
  --subnet 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  --ip-range 192.168.1.128/25 \
  mynetwork

# Container met specifiek IP
docker run -d --name fixedip \
  --network mynetwork \
  --ip 192.168.1.100 \
  nginx:alpine
```

### Bridge network troubleshooting

**Network debugging tools:**
```bash
# Installeer network tools in container
docker run -it --rm --network mybridge alpine sh
apk add curl netcat-openbsd tcpdump nmap

# Test connectivity
ping web1
nslookup web1
nc -zv web1 80

# Port scanning
nmap -p 1-1000 web1
```

**Host naar container communicatie:**
```bash
# Port mapping voor externe toegang
docker run -d --name webapp \
  --network mybridge \
  -p 8080:80 \
  nginx:alpine

# Test vanaf host
curl http://localhost:8080

# Bekijk port mapping
docker port webapp
```

---

## Fase 3: Host networking - Direct toegang

### Host network driver

**Container gebruikt host's network stack:**
```bash
# Start container met host networking
docker run -d --name hostnet \
  --network host \
  nginx:alpine

# Container is nu bereikbaar op host IP
curl http://localhost:80
```

**Voordelen en nadelen:**
```bash
# Voordelen:
# ✅ Beste performance (geen NAT overhead)
# ✅ Container heeft toegang tot alle host interfaces
# ✅ Geen port mapping nodig

# Nadelen:
# ❌ Geen network isolatie
# ❌ Port conflicts tussen containers
# ❌ Security risico's
```

**Praktisch voorbeeld met netcat server:**
```bash
# Start netcat server op host network
docker run -it --rm --network host alpine sh
apk add netcat-openbsd
nc -l -p 9999

# Vanaf host (andere terminal):
echo "Hello host network" | nc localhost 9999

# Container kan nu alle host interfaces gebruiken
ip addr show
```

**Use cases voor host networking:**
- High-performance applicaties
- Network monitoring tools
- Legacy applicaties die host access nodig hebben
- Development omgevingen

---

## Fase 4: Custom networks en isolatie

### Network isolatie demonstratie

**Creëer gescheiden netwerken:**
```bash
# Frontend network
docker network create frontend

# Backend network  
docker network create backend

# Database network (geïsoleerd)
docker network create database
```

**Multi-tier applicatie setup:**
```bash
# Database (alleen op database network)
docker run -d --name db \
  --network database \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  postgres:alpine

# Backend (verbonden met database en frontend)
docker run -d --name api \
  --network backend \
  alpine sleep 3600

# Verbind backend ook met database network
docker network connect database api

# Frontend (alleen op frontend network)
docker run -d --name web \
  --network frontend \
  -p 8080:80 \
  nginx:alpine

# Verbind frontend met backend
docker network connect backend web
```

**Test isolatie:**
```bash
# Web kan api bereiken (beide op backend network)
docker exec web ping api  # ✅ Werkt

# Web kan db NIET bereiken (verschillende networks)
docker exec web ping db   # ❌ Mislukt

# API kan db bereiken (beide op database network)
docker exec api ping db   # ✅ Werkt
```

### Network security met iptables

**Docker's iptables regels bekijken:**
```bash
# Bekijk Docker's iptables regels
sudo iptables -L DOCKER
sudo iptables -L DOCKER-USER

# Custom regels toevoegen
sudo iptables -I DOCKER-USER -p tcp --dport 8080 -j DROP
sudo iptables -I DOCKER-USER -s 192.168.1.0/24 -p tcp --dport 8080 -j ACCEPT
```

**Network policies met custom rules:**
```bash
# Blokkeer alle inter-container communicatie op poort 22
sudo iptables -I DOCKER-USER -p tcp --dport 22 -j DROP

# Allow specifieke communicatie
sudo iptables -I DOCKER-USER -s 172.18.0.0/16 -d 172.19.0.0/16 -j ACCEPT
```

---

## Fase 5: Overlay networks - Multi-host networking

### Docker Swarm overlay networks

**Initialiseer Docker Swarm:**
```bash
# Op manager node
docker swarm init --advertise-addr <MANAGER-IP>

# Join commando voor worker nodes
docker swarm join-token worker
```

**Creëer overlay network:**
```bash
# Overlay network voor services
docker network create \
  --driver overlay \
  --attachable \
  myoverlay

# Deploy service op overlay network
docker service create \
  --name web \
  --network myoverlay \
  --replicas 3 \
  nginx:alpine
```

**Cross-host container communicatie:**
```bash
# Start containers op verschillende hosts
# Host 1:
docker run -d --name container1 \
  --network myoverlay \
  alpine sleep 3600

# Host 2:
docker run -d --name container2 \
  --network myoverlay \
  alpine sleep 3600

# Test communicatie tussen hosts
docker exec container1 ping container2
```

### Overlay network debugging

**Network traffic analysis:**
```bash
# Bekijk overlay network details
docker network inspect myoverlay

# Tcpdump op overlay interface
sudo tcpdump -i docker_gwbridge

# VXLAN traffic monitoring
sudo tcpdump -i any port 4789
```

---

## Fase 6: Macvlan networks - Container als physical device

### Macvlan setup

**Creëer macvlan network:**
```bash
# Bepaal parent interface
ip link show

# Creëer macvlan network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan-net

# Start container met eigen MAC adres
docker run -d --name macvlan-container \
  --network macvlan-net \
  --ip=192.168.1.100 \
  alpine sleep 3600
```

**Container is nu bereikbaar vanaf netwerk:**
```bash
# Vanaf andere machine op netwerk
ping 192.168.1.100
ssh user@192.168.1.100  # Als SSH server draait in container
```

**Use cases voor macvlan:**
- Legacy applicaties die MAC adres nodig hebben
- Network appliances simulatie
- DHCP servers in containers
- Monitoring tools die directe network toegang nodig hebben

---

## Fase 7: Praktische communicatie voorbeelden

### HTTP communicatie tussen containers

**Setup web server en client:**
```bash
# Netwerk aanmaken
docker network create webnet

# Simple HTTP server met Python
docker run -d --name webserver \
  --network webnet \
  python:alpine \
  python -c "
import http.server
import socketserver

PORT = 8080
Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(('', PORT), Handler) as httpd:
    print(f'Server running on port {PORT}')
    httpd.serve_forever()
"

# HTTP client voor testing
docker run -it --rm \
  --network webnet \
  alpine sh

# In client container:
apk add curl
curl http://webserver:8080
```

### Database communicatie

**PostgreSQL server en client:**
```bash
# Database server
docker run -d --name postgres \
  --network webnet \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=testuser \
  -e POSTGRES_PASSWORD=testpass \
  postgres:alpine

# Wacht tot database klaar is
docker logs postgres

# Database client
docker run -it --rm \
  --network webnet \
  postgres:alpine \
  psql -h postgres -U testuser -d testdb

# SQL commands:
# CREATE TABLE test (id INT, name VARCHAR(50));
# INSERT INTO test VALUES (1, 'Docker Network Test');
# SELECT * FROM test;
```

### Real-time communicatie met netcat

**Chat applicatie met netcat:**
```bash
# Chat server
docker run -it --name chatserver \
  --network webnet \
  alpine sh

# In server:
apk add netcat-openbsd
nc -l -p 9999

# Chat client
docker run -it --name chatclient \
  --network webnet \
  alpine sh

# In client:
apk add netcat-openbsd
nc chatserver 9999

# Nu kun je berichten heen en weer sturen!
```

### Load balancing met multiple containers

**Setup met nginx load balancer:**
```bash
# Backend servers
docker run -d --name backend1 \
  --network webnet \
  -e SERVER_ID=1 \
  nginx:alpine

docker run -d --name backend2 \
  --network webnet \
  -e SERVER_ID=2 \
  nginx:alpine

# Nginx load balancer configuratie
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend1:80;
        server backend2:80;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }
}
EOF

# Load balancer
docker run -d --name loadbalancer \
  --network webnet \
  -p 8080:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine
```

---

## Fase 8: Network performance en monitoring

### Performance testing

**Bandwidth testing tussen containers:**
```bash
# Iperf server
docker run -d --name iperf-server \
  --network webnet \
  alpine sh -c "
apk add iperf3
iperf3 -s
"

# Iperf client
docker run -it --rm \
  --network webnet \
  alpine sh -c "
apk add iperf3
iperf3 -c iperf-server -t 30
"
```

**Latency testing:**
```bash
# Ping statistieken
docker exec chatclient ping -c 100 chatserver

# Hping voor advanced testing
docker run -it --rm \
  --network webnet \
  --cap-add NET_RAW \
  alpine sh -c "
apk add hping3
hping3 -S -p 80 -c 10 webserver
"
```

### Network monitoring

**Traffic monitoring met tcpdump:**
```bash
# Monitor bridge traffic
sudo tcpdump -i docker0

# Monitor specifiek network
BRIDGE=$(docker network inspect webnet | jq -r '.[0].Options."com.docker.network.bridge.name"')
sudo tcpdump -i $BRIDGE

# Container network namespace monitoring
PID=$(docker inspect chatserver | jq -r '.[0].State.Pid')
sudo nsenter -t $PID -n tcpdump -i eth0
```

**Network statistieken:**
```bash
# Container network stats
docker exec chatserver cat /proc/net/dev

# Detailed network info
docker exec chatserver ss -tuln
docker exec chatserver netstat -i
```

---

## Fase 9: DNS en service discovery

### Container DNS resolution

**Automatische DNS in custom networks:**
```bash
# Custom network met DNS
docker network create \
  --dns 8.8.8.8 \
  --dns 1.1.1.1 \
  dnsnet

# Container met custom DNS
docker run -it --rm \
  --network dnsnet \
  --dns 9.9.9.9 \
  alpine sh

# Test DNS resolution
nslookup google.com
dig github.com
```

**Container als DNS server:**
```bash
# Dnsmasq DNS server
docker run -d --name dns-server \
  --network dnsnet \
  --cap-add NET_ADMIN \
  alpine sh -c "
apk add dnsmasq
echo 'address=/myapp.local/192.168.1.100' > /etc/dnsmasq.conf
dnsmasq --no-daemon
"

# Test custom DNS
docker run -it --rm \
  --network dnsnet \
  --dns $(docker inspect dns-server | jq -r '.[0].NetworkSettings.Networks.dnsnet.IPAddress') \
  alpine sh

# Test custom domain
nslookup myapp.local
```

### Service aliases

**Multiple aliases voor een container:**
```bash
# Container met aliases
docker run -d --name webserver \
  --network webnet \
  --network-alias web \
  --network-alias api \
  --network-alias frontend \
  nginx:alpine

# Test alle aliases
docker run -it --rm --network webnet alpine sh
ping web
ping api  
ping frontend
# Alle wijzen naar dezelfde container!
```

---

## Fase 10: Network security en firewalling

### Container firewalls

**Iptables regels voor containers:**
```bash
# Blokkeer uitgaande connecties naar specifieke IP's
sudo iptables -I DOCKER-USER -s 172.17.0.0/16 -d 10.0.0.0/8 -j DROP

# Rate limiting
sudo iptables -I DOCKER-USER -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Allow alleen specifieke poorten
sudo iptables -I DOCKER-USER -p tcp -m multiport --dports 80,443,22 -j ACCEPT
sudo iptables -A DOCKER-USER -j DROP
```

**Network namespaces isolatie:**
```bash
# Container in eigen network namespace
docker run -d --name isolated \
  --network none \
  alpine sleep 3600

# Handmatig network interface toevoegen
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth1 netns $(docker inspect isolated | jq -r '.[0].State.Pid')
sudo ip addr add 192.168.100.1/24 dev veth0
sudo ip link set veth0 up

# In container namespace:
sudo nsenter -t $(docker inspect isolated | jq -r '.[0].State.Pid') -n sh
ip addr add 192.168.100.2/24 dev veth1
ip link set veth1 up
ip route add default via 192.168.100.1
```

### Network encryption

**TLS/SSL tussen containers:**
```bash
# Generate certificates
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=webserver"

# HTTPS server
docker run -d --name https-server \
  --network webnet \
  -v $(pwd)/cert.pem:/cert.pem:ro \
  -v $(pwd)/key.pem:/key.pem:ro \
  python:alpine \
  python -c "
import http.server
import ssl
import socketserver

PORT = 8443
Handler = http.server.SimpleHTTPRequestHandler

with socketserver.TCPServer(('', PORT), Handler) as httpd:
    httpd.socket = ssl.wrap_socket(httpd.socket,
                                   certfile='/cert.pem',
                                   keyfile='/key.pem',
                                   server_side=True)
    print(f'HTTPS Server running on port {PORT}')
    httpd.serve_forever()
"

# HTTPS client
docker run -it --rm \
  --network webnet \
  alpine sh -c "
apk add curl
curl -k https://https-server:8443
"
```

---

## Fase 11: Troubleshooting en debugging

### Common networking issues

**1. Container kan andere container niet bereiken:**
```bash
# Check if containers are on same network
docker inspect container1 | jq '.[0].NetworkSettings.Networks'
docker inspect container2 | jq '.[0].NetworkSettings.Networks'

# Test connectivity
docker exec container1 ping container2
docker exec container1 nc -zv container2 80

# Check DNS resolution
docker exec container1 nslookup container2
docker exec container1 dig container2
```

**2. Port mapping werkt niet:**
```bash
# Check port mappings
docker port container-name

# Check if service luistert op juiste interface
docker exec container-name netstat -tlnp

# Test van buitenaf
curl -v http://localhost:mapped-port
telnet localhost mapped-port
```

**3. Network performance problemen:**
```bash
# Check network stats
docker exec container-name cat /proc/net/dev

# Test bandwidth
docker exec container1 sh -c "yes | head -c 100M" | docker exec -i container2 sh -c "cat > /dev/null"

# Check for packet loss
docker exec container1 ping -c 1000 container2 | grep "packet loss"
```

### Advanced debugging tools

**Network namespace debugging:**
```bash
# List network namespaces
sudo ip netns list

# Enter container's network namespace
PID=$(docker inspect container-name | jq -r '.[0].State.Pid')
sudo nsenter -t $PID -n bash

# In namespace:
ip addr show
ip route show
ss -tuln
```

**Packet capture:**
```bash
# Capture on container interface
PID=$(docker inspect container-name | jq -r '.[0].State.Pid')
sudo nsenter -t $PID -n tcpdump -i eth0 -w capture.pcap

# Capture on bridge
sudo tcpdump -i docker0 -w bridge-capture.pcap

# Analyze with tshark
tshark -r capture.pcap -T fields -e ip.src -e ip.dst -e tcp.port
```

**Network connectivity matrix:**
```bash
#!/bin/bash
# Test connectivity between all containers

CONTAINERS=$(docker ps --format "{{.Names}}")

echo "Container Connectivity Matrix:"
echo "============================="

for container1 in $CONTAINERS; do
    echo -n "$container1: "
    for container2 in $CONTAINERS; do
        if [ "$container1" != "$container2" ]; then
            if docker exec $container1 ping -c 1 -W 1 $container2 >/dev/null 2>&1; then
                echo -n "✅ $container2 "
            else
                echo -n "❌ $container2 "
            fi
        fi
    done
    echo
done
```

---

## Fase 12: Production best practices

### Network design patterns

**1. Three-tier architecture:**
```bash
# DMZ network for load balancers
docker network create dmz

# Application network for app servers
docker network create app-tier

# Database network for data layer
docker network create db-tier

# Load balancer (public access)
docker run -d --name lb \
  --network dmz \
  -p 80:80 -p 443:443 \
  nginx:alpine

# App servers (internal only)
docker run -d --name app1 --network app-tier myapp:latest
docker run -d --name app2 --network app-tier myapp:latest

# Database (most restricted)
docker run -d --name db --network db-tier postgres:alpine

# Connect tiers
docker network connect app-tier lb
docker network connect db-tier app1
docker network connect db-tier app2
```

**2. Zero-trust networking:**
```bash
# Default deny network
docker network create \
  --internal \
  --subnet 10.0.0.0/24 \
  zero-trust

# Explicit allow rules via reverse proxy
docker run -d --name proxy \
  --network zero-trust \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine
```

### Network monitoring in production

**Centralized logging:**
```bash
# Log aggregator
docker run -d --name logstash \
  --network monitoring \
  -p 5000:5000 \
  elastic/logstash:latest

# Application with structured logging
docker run -d --name app \
  --network app-tier \
  --log-driver json-file \
  --log-opt max-size=100m \
  --log-opt max-file=3 \
  myapp:latest
```

**Health checking:**
```bash
# Health check service
docker run -d --name healthcheck \
  --network monitoring \
  alpine sh -c "
while true; do
  for container in app1 app2 db; do
    if nc -z \$container 80; then
      echo \"\$(date): \$container - OK\"
    else
      echo \"\$(date): \$container - FAIL\"
    fi
  done
  sleep 30
done
"
```

### Network backup and disaster recovery

**Network configuration backup:**
```bash
#!/bin/bash
# Backup all Docker networks

BACKUP_DIR="/backup/docker-networks/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Export network configurations
docker network ls --format "{{.Name}}" | while read network; do
    if [ "$network" != "bridge" ] && [ "$network" != "host" ] && [ "$network" != "none" ]; then
        docker network inspect "$network" > "$BACKUP_DIR/$network.json"
    fi
done

# Export container network connections
docker ps --format "{{.Names}}" | while read container; do
    docker inspect "$container" | jq '.[0].NetworkSettings' > "$BACKUP_DIR/$container-networks.json"
done
```

**Network restore script:**
```bash
#!/bin/bash
# Restore Docker networks from backup

BACKUP_DIR="/backup/docker-networks/$1"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Recreate networks
for config_file in "$BACKUP_DIR"/*.json; do
    if [[ "$config_file" != *"-networks.json" ]]; then
        network_name=$(basename "$config_file" .json)
        
        # Extract network configuration
        subnet=$(jq -r '.[0].IPAM.Config[0].Subnet' "$config_file")
        gateway=$(jq -r '.[0].IPAM.Config[0].Gateway' "$config_file")
        driver=$(jq -r '.[0].Driver' "$config_file")
        
        # Recreate network
        docker network create \
            --driver "$driver" \
            --subnet "$subnet" \
            --gateway "$gateway" \
            "$network_name"
    fi
done
```

---

## Conclusie: Netwerk mastery bereikt

### De reis die we hebben afgelegd

**Van simpel naar complex:**
1. **Default bridge**: Automatisch networking begrip
2. **Custom bridges**: Gecontroleerde communicatie
3. **Host networking**: Performance en directe toegang
4. **Overlay networks**: Multi-host clustering
5. **Macvlan**: Container als network device
6. **Security**: Isolatie en firewalling
7. **Monitoring**: Troubleshooting en performance
8. **Production**: Enterprise-ready networking

### Wat je nu kunt

**Praktische vaardigheden:**
- ✅ **Network types kiezen** voor specifieke use cases
- ✅ **Container communicatie** opzetten en debuggen
- ✅ **Security implementeren** met network isolatie
- ✅ **Performance optimaliseren** voor production workloads
- ✅ **Troubleshooting** van complexe network issues

**Advanced concepten:**
- ✅ **Multi-tier architectures** ontwerpen
- ✅ **Zero-trust networking** implementeren  
- ✅ **Service discovery** en DNS configureren
- ✅ **Network monitoring** en logging opzetten
- ✅ **Disaster recovery** planning voor networks

### Network decision matrix

**Wanneer welk network type te gebruiken:**

| Use Case | Network Type | Reden |
|----------|-------------|-------|
| Development | Custom Bridge | DNS resolution + isolatie |
| High Performance | Host | Minimale overhead |
| Multi-host | Overlay | Swarm clustering |
| Legacy Integration | Macvlan | Physical network access |
| Maximum Security | None + manual | Complete controle |
| Load Balancing | Custom Bridge | Service discovery |
| Microservices | Multiple Custom | Service isolatie |

### Production checklist

**Network security:**
- ✅ Custom networks voor isolatie
- ✅ Least privilege principle
- ✅ Regular security scanning
- ✅ Network monitoring en alerting
- ✅ Backup en recovery procedures

**Performance:**
- ✅ Network type optimaal voor use case
- ✅ Resource limits geconfigureerd
- ✅ Monitoring van bandwidth en latency
- ✅ Load balancing geïmplementeerd

**Reliability:**
- ✅ Health checks voor alle services
- ✅ Automatic restart policies
- ✅ Network redundancy
- ✅ Disaster recovery getest

### De volgende stap

Met deze networking kennis kun je:
- 🏗️ **Enterprise architectures** bouwen met Docker
- 🔒 **Security-first** netwerk designs maken
- 🚀 **High-performance** communicatie implementeren
- 🔧 **Complex issues** debuggen en oplossen
- 📊 **Production-ready** monitoring opzetten

**Je bent nu klaar voor:**
- Kubernetes networking (CNI, Services, Ingress)
- Service mesh architectures (Istio, Linkerd)
- Cloud-native networking patterns
- Container security hardening
- DevOps network automation

Docker networking is geen mysterie meer - het is je krachtige tool voor moderne, gedistribueerde applicaties! 🌐🚀