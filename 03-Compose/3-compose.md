# 3 - Van `docker run` naar Docker Compose

## Inleiding: De evolutie van een eenvoudige website

In dit hoofdstuk maken we een praktische reis van een simpele HTML-pagina naar een volledige multi-container applicatie. We beginnen met de eenvoudigste oplossing en ondervinden stap voor stap de beperkingen, waardoor we natuurlijk naar steeds geavanceerdere oplossingen toe groeien.

**Het verhaal dat we gaan vertellen:**
1. **Eenvoudige website** - Een statische HTML-pagina met hardgecodeerde data
2. **Docker run** - Snel prototypen met volumes, maar moeilijk te distribueren
3. **Dockerfile** - Distribueerbare images maken, maar statische content blijft problematisch
4. **Multi-container setup** - Meerdere services handmatig beheren wordt complexer
5. **Docker Compose** - De elegante oplossing voor al onze pijnpunten

**Waarom deze evolutie belangrijk is:**
- Je leert de beperkingen van elke stap kennen
- Je begrijpt waarom Docker Compose noodzakelijk is
- Je krijgt praktische ervaring met containerisatie concepten
- Je ontwikkelt inzicht in moderne applicatie architectuur

---

## Fase 1: De eenvoudige start - Statische website

### Het begin: Een simpele HTML-pagina

In de map `compose-files/1-fe/` vinden we onze uitgangssituatie: een eenvoudige HTML-pagina met een hardgecodeerde lijst voedsel.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=, initial-scale=1.0">
  <title>Document</title>
</head>
<body>
  <p>List of foods from API: </p>
  <ul id="list">
    <li> Apple </li>
    <li> Orange </li>
    <li> Banana </li>
    <li> Kiwi </li>
  </ul>
</body>
</html>
```

**Het probleem:** Deze pagina is volledig statisch. In de echte wereld willen we:
- Data uit databases kunnen halen
- API's die dynamische content serveren  
- Infrastructure die kan schalen
- Een deployment die professioneel is

### Stap 1: Snel prototypen met `docker run`

Voor snelle ontwikkeling kunnen we de officiele `nginx` image gebruiken en onze HTML als volume mounten:

```bash
cd compose-files/1-fe
docker run \
  --rm \
  -p 8080:80 \
  -v "$(pwd)/index.html:/usr/share/nginx/html/index.html:ro" \
  nginx:1.27-alpine
```

**Uitleg van de parameters:**
- `--rm`: Verwijder container automatisch na stoppen
- `-p 8080:80`: Publiceer nginx poort 80 naar host poort 8080
- `-v ...:ro`: Mount bestand read-only in de container
- `nginx:1.27-alpine`: Lichtgewicht nginx variant

**Voordelen van deze aanpak:**
- ✅ Onmiddellijk resultaat: website draait op http://localhost:8080
- ✅ Ontwikkelvriendelijk: wijzig HTML en refresh browser
- ✅ Geen image-build proces nodig
- ✅ Ideaal voor experimenten en snelle iteraties

**Waarom dit niet voldoende is:**
- ❌ **Niet distribueerbaar**: Content zit buiten de container
- ❌ **Ontwikkel-only**: Kan niet naar productie of klanten
- ❌ **Fragiel**: Afhankelijk van lokale bestanden
- ❌ **Niet reproduceerbaar**: Werkt alleen op deze machine

> "Je kunt deze setup niet naar een collega sturen - ze hebben de exacte bestandsstructuur nodig"

### Stap 2: Een distributeerbare image bouwen met Dockerfile

**Het probleem herkennen:**
Om onze applicatie naar productie of klanten te kunnen sturen, hebben we een self-contained image nodig. Hier komt de `Dockerfile` in beeld.

In `1-fe/Dockerfile` zien we hoe we een distribueerbare image maken:

```dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Bouw en test de image:**

```bash
# Navigeer naar de juiste directory
cd compose-files/1-fe

# Bouw de image
docker build -t fe-static:latest .

# Start de container
docker run --rm -p 8081:80 fe-static:latest
```

**Wat gebeurt er hier:**
1. `FROM nginx:1.27-alpine`: Start met een lichtgewicht nginx basis
2. `COPY index.html ...`: Kopieer onze content IN de image
3. `EXPOSE 80`: Documenteer welke poort de service gebruikt
4. `CMD ...`: Specificeer hoe nginx moet starten

**Voordelen van deze Dockerfile aanpak:**
- ✅ **Distribueerbaar**: Alles zit in de image
- ✅ **Reproduceerbaar**: Image werkt overal waar Docker draait
- ✅ **Versioned**: Je kunt verschillende versies taggen
- ✅ **Productie-klaar**: Kan naar registry en deployment pipeline

**Nieuwe beperkingen die ontstaan:**
- ❌ **Langzame ontwikkeling**: Elke HTML-wijziging vereist rebuild
- ❌ **Statisch**: Nog steeds geen mogelijkheid voor dynamische content
- ❌ **Eenvoudig**: Echte applicaties hebben databases, API's, etc.

> "Nu kunnen we ons werk wel delen, maar het is nog steeds een statische website"

---

## Fase 2: Complexiteit neemt toe - Dynamische content

### De realiteit van moderne webapplicaties

Moderne applicaties bestaan zelden uit één container. Kijk naar de uitbreiding in `2-fe-be/`:

![Multi-Container Architecture](../images/multi-container-architecture.png)

**Frontend** (`2-fe-be/frontend/`):
- Aangepaste HTML die data ophaalt via JavaScript
- Maakt AJAX calls naar een backend API
- Nog steeds geserveerd door nginx

```html
<!-- Het verschil: dynamische lijst in plaats van hardcoded -->
<ul id="list"></ul>

<script type="text/javascript">
async function createList() {
    const url = "http://localhost:3000";
    try {
      const response = await fetch(url);
      const json = await response.json();
      
      for (let i of json) {
        ul = document.getElementById("list");
        li = document.createElement("li");
        li.innerHTML = i.color + " " + i.name;
        ul.appendChild(li);
      }
    } catch (error) {
      console.error(error.message);
    }
}
createList();
</script>
```

**Backend** (`2-fe-be/api/`):
- Node.js Express server
- Praat met MongoDB database
- Serveert API endpoints voor de frontend

```javascript
// server.js - Een echte API!
const express = require('express')
const mongoose = require('mongoose')
const cors = require('cors')

// Database connectie met retry logic
let connectWithRetry = function() {
  return mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/foodsdb')
      .then(() => console.log('Connected to MongoDB!'))
      .catch ((error) => {
        console.error('Failed to connect to mongo - retrying in 1 sec', error);
        setTimeout(connectWithRetry, 1000);
      }); 
};

// API endpoint
app.get("/", async (req, res) => {
  const foods = await Food.find();
  res.send(foods);
});
```

**Database**:
- MongoDB voor data persistentie
- Moet toegankelijk zijn voor de backend
- Data moet bewaard blijven tussen restarts

### Het handmatige container management probleem

**Stel je voor dat je dit handmatig moet beheren:**

```bash
# Stap 1: Maak een custom network 
docker network create foodapp-network

# Stap 2: Start de database
docker run -d \
  --name mongodb \
  --network foodapp-network \
  -v dbdata:/data/db \
  mongo

# Stap 3: Bouw de backend image
docker build -t foodapp-backend ./2-fe-be/api

# Stap 4: Start de backend (moet wachten op database)
docker run -d \
  --name backend \
  --network foodapp-network \
  -p 3000:3000 \
  -e PORT=3000 \
  -e MONGO_URI=mongodb://mongodb:27017/foodsdb \
  foodapp-backend

# Stap 5: Bouw de frontend image  
docker build -t foodapp-frontend ./2-fe-be/frontend

# Stap 6: Start de frontend
docker run -d \
  --name frontend \
  --network foodapp-network \
  -p 8080:80 \
  foodapp-frontend
```

### Uitleg van de handmatige parameters - Waarom zo complex?

#### Netwerk management (`--network`)

**Waarom custom networks nodig zijn:**
```bash
docker network create foodapp-network
--network foodapp-network
```
- **Probleem**: Containers kunnen standaard niet met elkaar praten
- **Oplossing**: Custom networks bieden automatische DNS resolution tussen containers
- **Vervangt `--link`**: De oudere `--link` parameter is deprecated

**Oude `--link` methode (DEPRECATED):**
```bash
# OUDE MANIER - niet meer aanbevolen
docker run -d --name mongodb mongo
docker run -d --name backend --link mongodb:mongodb backend-image
```

**Problemen met `--link`:**
- ❌ Alleen unidirectionele verbindingen
- ❌ Beperkt tot containers op dezelfde host  
- ❌ Inflexibel voor complexe netwerk topologieën
- ❌ Moeilijk te debuggen
- ❌ Niet geschikt voor moderne container orchestratie

#### Environment variables (`-e`)

```bash
-e PORT=3000
-e MONGO_URI=mongodb://mongodb:27017/foodsdb
```

**Waarom environment variables:**
- **Configuratie**: Externe configuratie zonder code aanpassingen
- **Connection strings**: `mongodb://mongodb:27017` gebruikt container hostname
- **Flexibiliteit**: Verschillende omgevingen (dev/test/prod) met andere waarden
- **Security**: Gevoelige data (passwords) niet in code

#### Volume management (`-v`)

```bash
-v dbdata:/data/db
```

**Named volumes vs bind mounts:**
- **Named volume**: `dbdata:/data/db` - Docker beheert de data persistent
- **Bind mount**: `/host/path:/container/path` - Direct host filesystem access
- **Waarom named volumes**: Portabel tussen verschillende hosts

#### Port mapping (`-p`)

```bash
-p 3000:3000  # Host port 3000 -> Container port 3000
-p 8080:80    # Host port 8080 -> Container port 80
```

**Security door selective exposure:**
- **Externe toegang**: Alleen gemapte poorten zijn bereikbaar van buitenaf
- **Internal services**: Database heeft geen `-p` dus alleen intern bereikbaar
- **Format**: `host_port:container_port`

### Praktische problemen met handmatige orchestratie

#### 1. Startup volgorde problemen
```bash
# Backend start voordat database klaar is
$ docker logs backend
MongoNetworkError: failed to connect to server [mongodb:27017]
```

#### 2. Cleanup complexiteit
```bash
# Alles handmatig stoppen en opruimen - foutgevoelig!
docker stop frontend backend mongodb
docker rm frontend backend mongodb
docker network rm foodapp-network
docker volume rm dbdata  # Dit verwijdert je DATA!
```

#### 3. Development cycle frustratie
```bash
# Elke code wijziging vereist:
docker stop backend
docker rm backend
docker build -t foodapp-backend ./2-fe-be/api
docker run -d --name backend --network foodapp-network \
  -p 3000:3000 \
  -e PORT=3000 \
  -e MONGO_URI=mongodb://mongodb:27017/foodsdb \
  foodapp-backend
```

#### 4. Environment inconsistentie
- Ontwikkelaar A vergeet `-e MONGO_URI` parameter → backend crash
- Ontwikkelaar B gebruikt andere poort mapping → frontend kan niet verbinden
- Productie team gebruikt andere netwerk configuratie → mysterious failures
- Niemand weet meer welke exacte commando's nodig zijn

**De kernproblemen:**
- 🔥 **Foutgevoelig**: Verkeerde volgorde = crashes
- 🔥 **Command-line horror**: Lange, complexe commando's die niemand onthoudt
- 🔥 **Inconsistente omgevingen**: Elke ontwikkelaar doet het anders
- 🔥 **Niet herhaalbaar**: Verschillende setups voor dev/test/prod
- 🔥 **Moeilijk te onderhouden**: Updates vereisen vele handmatige stappen
- 🔥 **Geen dependency management**: Services starten in verkeerde volgorde
- 🔥 **Documentatie nightmare**: Setup instructies zijn nooit up-to-date

> "We hebben een tool nodig die dit allemaal automatiseert en betrouwbaar maakt!"

---

## Fase 3: De Docker Compose oplossing

### Wat is Docker Compose?

Docker Compose is een tool voor het definiëren en draaien van multi-container Docker applicaties. Met een YAML-bestand configureer je alle services van je applicatie, en met **één commando** start je alles op.

![Docker Compose Overview](../images/docker-compose-overview.png)

**Kernprincipes:**
- **Declaratief**: Je beschrijft WAT je wilt, niet HOE
- **Herhalbaar**: Dezelfde configuratie werkt overal
- **Geïsoleerd**: Elk project krijgt zijn eigen netwerk en namespace
- **Ontwikkelaar-vriendelijk**: Ontworpen voor lokale ontwikkeling
- **Productie-capabel**: Ook geschikt voor eenvoudige productie deployments

### De magische transformatie - Van 6 commando's naar 1

**Van dit (handmatig):**
```bash
docker network create foodapp-network
docker run -d --name mongodb --network foodapp-network -v dbdata:/data/db mongo
docker build -t foodapp-backend ./2-fe-be/api
docker run -d --name backend --network foodapp-network -p 3000:3000 -e PORT=3000 -e MONGO_URI=mongodb://mongodb:27017/foodsdb foodapp-backend
docker build -t foodapp-frontend ./2-fe-be/frontend
docker run -d --name frontend --network foodapp-network -p 8080:80 foodapp-frontend
```

**Naar dit (Docker Compose):**
```bash
docker compose up
```

### Analyse van onze `compose.yml`

Bekijk het bestand `2-fe-be/compose.yml`:

```yaml
services:
  backend:
    build: ./api
    ports: 
      - 3000:3000
    environment:
      - PORT=3000
      - MONGO_URI=mongodb://mongodb:27017/foodsdb
    depends_on:
      - mongodb

  frontend:
    build: ./frontend
    ports: 
      - 8080:80

  mongodb:
    image: mongo
    volumes:
      - dbdata:/data/db

volumes:
  dbdata:
```

### Service-by-service uitleg

#### 1. Backend Service
```yaml
backend:
  build: ./api                    # Bouwt image van ./api/Dockerfile
  ports:
    - 3000:3000                  # Publiceert API naar localhost:3000
  environment:
    - PORT=3000                  # Node.js app luistert op poort 3000
    - MONGO_URI=mongodb://mongodb:27017/foodsdb  # Database connectie
  depends_on:
    - mongodb                    # Start pas na MongoDB
```

**Het mooie van service names:**
- `mongodb://mongodb:27017` → Docker Compose zorgt voor DNS resolution
- Geen IP-adressen nodig
- Automatische service discovery

#### 2. Frontend Service
```yaml
frontend:
  build: ./frontend              # Bouwt image van ./frontend/Dockerfile
  ports:
    - 8080:80                   # Publiceert website naar localhost:8080
```

**Eenvoudig en clean:**
- Geen environment variables nodig
- Geen depends_on (frontend werkt ook zonder backend)
- Standaard netwerk werkt perfect

#### 3. Database Service
```yaml
mongodb:
  image: mongo                   # Gebruikt officiële MongoDB image
  volumes:
    - dbdata:/data/db           # Persistent data opslag
```

**Security door design:**
- Geen `ports` mapping → alleen intern bereikbaar
- Automatisch onderdeel van het container netwerk
- Data blijft bewaard via named volume

#### 4. Named Volume
```yaml
volumes:
  dbdata:                       # Docker managed persistent storage
```

### Docker Compose magie onder de motorkap

#### Automatische netwerk creatie
```bash
# Compose maakt automatisch een netwerk
$ docker network ls
NETWORK ID     NAME                 DRIVER    SCOPE
a1b2c3d4e5f6   2-fe-be_default     bridge    local
```

#### Service discovery met DNS
```bash
# Test vanuit backend container
$ docker compose exec backend nslookup mongodb
Server:         127.0.0.11
Address:        127.0.0.11#53

Name:   mongodb
Address: 172.18.0.3
```

#### Automatische container naming
```bash
$ docker compose ps
NAME              COMMAND                  SERVICE      STATUS
2-fe-be-backend-1   "docker-entrypoint.s…"   backend      Up
2-fe-be-frontend-1  "/docker-entrypoint.…"   frontend     Up
2-fe-be-mongodb-1   "docker-entrypoint.s…"   mongodb      Up
```

### Service name resolution - Het netwerk-magic uitgelegd

#### Het probleem met IP-gebaseerde communicatie

**Voorheen (problematisch):**
```javascript
// Hardcoded IP - breekt bij restart
const mongoUri = "mongodb://172.17.0.3:27017/foodsdb";
```

**Docker Compose oplossing:**
```javascript
// Service naam - altijd werkend
const mongoUri = "mongodb://mongodb:27017/foodsdb";
```

#### Hoe service names werken

![Service Name Resolution](../images/service-name-resolution.png)

**Automatische DNS resolutie:**
1. Docker Compose maakt een intern netwerk
2. Elke service krijgt een DNS entry met zijn servicenaam
3. Containers kunnen elkaar bereiken via servicenaam
4. Docker regelt de IP resolutie automatisch

#### Praktische voorbeelden

**Backend praat met MongoDB:**
```javascript
// In server.js
mongoose.connect(process.env.MONGO_URI)
// MONGO_URI=mongodb://mongodb:27017/foodsdb
// 'mongodb' wordt automatisch geresolv'd naar IP
```

**Frontend praat met Backend:**
```javascript
// Voor browser-to-backend (vanuit browser):
const url = "http://localhost:3000";  // Via host port mapping

// Voor container-to-container (als frontend server-side was):
const url = "http://backend:3000";    // Via service naam
```

#### Testing van service names

```bash
# Start de compose stack
docker compose -f 2-fe-be/compose.yml up -d

# Test DNS resolution vanuit backend
docker compose exec backend nslookup mongodb
# Returns: Name: mongodb, Address: 172.20.0.3

# Test HTTP communicatie tussen services
docker compose exec backend curl http://frontend:80
# Haalt de HTML pagina op van de frontend service
```

### De volledige stack starten

#### Stap 1: Navigeer naar de juiste directory
```bash
cd compose-files/2-fe-be
```

#### Stap 2: Start alle services
```bash
docker compose up --build
```

**Wat gebeurt er automatisch:**
1. Docker bouwt images voor `backend` en `frontend`
2. MongoDB container start eerst (vanwege `depends_on`)
3. Backend wacht op MongoDB en probeert connectie met retry logic
4. Frontend start als laatste
5. Alle services kunnen met elkaar praten via service names
6. Data wordt bewaard in een named volume

#### Stap 3: Test de applicatie
- Open http://localhost:8080 (frontend)
- Controleer of data wordt geladen via de API
- Backend API is bereikbaar op http://localhost:3000

### Essential Compose commando's

```bash
# Start alle services in foreground (zie logs live)
docker compose up

# Start in background (detached)
docker compose up -d

# Forceer rebuild van images
docker compose up --build

# Stop en verwijder alles behalve volumes
docker compose down

# Stop en verwijder ALLES inclusief volumes (verliest data!)
docker compose down -v

# Bekijk status van alle services
docker compose ps

# Bekijk logs van alle services
docker compose logs

# Bekijk logs van specifieke service
docker compose logs backend
docker compose logs -f frontend  # Follow logs live

# Ga in een draaiende container
docker compose exec backend bash
docker compose exec mongodb mongosh

# Start alleen specifieke service
docker compose up backend

# Schaal een service (meerdere instances)
docker compose up --scale backend=3

# Valideer configuratie zonder starten
docker compose config

# Download/update images zonder starten
docker compose pull
```

---

## Fase 4: Geavanceerde concepten en best practices

### Environment files voor configuratie

#### Het probleem met hardcoded waarden
```yaml
# Niet flexibel - hardcoded waarden
services:
  backend:
    environment:
      - NODE_ENV=development
      - MONGO_URI=mongodb://mongodb:27017/foodsdb
      - API_PORT=3000
```

#### De oplossing: .env files
```bash
# .env bestand
NODE_ENV=development
MONGO_URI=mongodb://mongodb:27017/foodsdb
API_PORT=3000
WEB_PORT=8080
DB_NAME=foodsdb
```

```yaml
# compose.yml met environment variabelen
services:
  backend:
    build: ./api
    ports:
      - "${API_PORT}:3000"
    environment:
      - NODE_ENV=${NODE_ENV}
      - MONGO_URI=${MONGO_URI}
    env_file:
      - .env
```

### Override files voor verschillende omgevingen

#### Development configuratie (compose.override.yml)
```yaml
# Automatisch geladen in development
services:
  backend:
    volumes:
      - ./api:/app              # Live code reloading
      - /app/node_modules       # Prevent overwriting node_modules
    environment:
      - DEBUG=true
      - NODE_ENV=development
```

#### Production configuratie (compose.prod.yml)
```yaml
# Voor productie: docker compose -f compose.yml -f compose.prod.yml up
services:
  backend:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.50'
    environment:
      - NODE_ENV=production
      - DEBUG=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Healthchecks en dependency management

#### Probleem: Services starten te snel
```yaml
# Basis depends_on wacht alleen tot container start, niet tot service ready is
depends_on:
  - mongodb  # MongoDB container is gestart, maar database nog niet klaar
```

#### Oplossing: Healthchecks
```yaml
services:
  mongodb:
    image: mongo
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s

  backend:
    build: ./api
    depends_on:
      mongodb:
        condition: service_healthy  # Wacht tot MongoDB echt klaar is
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Advanced networking en security

#### Multiple networks voor service isolation
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # Geen externe toegang

services:
  frontend:
    build: ./frontend
    networks:
      - frontend
      
  backend:
    build: ./api
    networks:
      - frontend  # Kan praten met frontend
      - backend   # Kan praten met database
      
  mongodb:
    image: mongo
    networks:
      - backend   # Alleen toegankelijk vanuit backend network
```

**Security voordelen:**
- Database is niet bereikbaar vanuit frontend
- Externe netwerk toegang gecontroleerd
- Services geïsoleerd per functie

### Debugging en troubleshooting

#### Veelvoorkomende problemen

**1. Port conflicts:**
```bash
# Error: port already in use
ERROR: Ports are not available: exposing port 8080

# Oplossing: Verander poort mapping
services:
  frontend:
    ports:
      - "8081:80"  # Gebruik andere host poort
```

**2. Service connectivity issues:**
```bash
# Debug stappen:
# 1. Check of services draaien
docker compose ps

# 2. Check service logs
docker compose logs backend

# 3. Test DNS resolution
docker compose exec backend nslookup mongodb

# 4. Test network connectivity
docker compose exec backend ping mongodb

# 5. Test HTTP connectivity
docker compose exec backend curl http://frontend:80
```

**3. Volume permission problems:**
```bash
# Check volume ownership in container
docker compose exec mongodb ls -la /data/db

# Fix permissions if needed
docker compose exec mongodb chown -R mongodb:mongodb /data/db
```

### Best practices samengevat

#### Compose file organisatie
```yaml
# Volledige productie-ready compose.yml
services:
  backend:
    build: 
      context: ./api
      dockerfile: Dockerfile
    image: foodapp-backend:${VERSION:-latest}
    container_name: foodapp-backend
    restart: unless-stopped
    ports:
      - "${API_PORT:-3000}:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - MONGO_URI=mongodb://mongodb:27017/${DB_NAME:-foodsdb}
    env_file:
      - .env
    volumes:
      - api_logs:/var/log/app
    networks:
      - backend
    depends_on:
      mongodb:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.50'

networks:
  backend:
    driver: bridge
    name: foodapp-backend

volumes:
  dbdata:
    driver: local
    name: foodapp-mongodb-data
  api_logs:
    driver: local
```

#### Dockerfile optimalisaties

**Backend Dockerfile verbeteringen:**
```dockerfile
# Betere versie van api/Dockerfile
FROM node:18-alpine

WORKDIR /app

# Kopieer package files eerst voor betere caching
COPY package*.json ./
RUN npm ci --only=production

# Kopieer source code
COPY . .

# Security: maak non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

# Health check endpoint (moet je in server.js implementeren)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
```

#### Development vs Production patterns

**Development:**
- Gebruik bind mounts voor live reloading
- Publiceer alle poorten voor debugging
- Gebruik descriptive container names
- Enable debug logging

**Production:**
- Named volumes voor persistentie
- Restart policies voor betrouwbaarheid
- Resource limits voor stabiliteit
- Healthchecks voor monitoring
- Geen development tools in images

---

## Conclusie: De transformatie naar moderne deployment

### De evolutie samengevat

**De reis die we hebben afgelegd:**

1. **Statische HTML**: Simpel maar niet dynamisch
2. **Docker run met volumes**: Snel prototypen maar niet distribueerbaar
3. **Dockerfile**: Distribueerbare images maar handmatige orchestratie
4. **Multi-container handmatig**: Complexe setup met vele pijnpunten
5. **Docker Compose**: Elegante, declaratieve oplossing

### Waarom Docker Compose zo revolutionair is

Docker Compose heeft de manier waarop we ontwikkelen en deployen fundamenteel veranderd:

**Van complexiteit naar simpliciteit:**
- **Was**: 6+ complexe docker commando's
- **Nu**: `docker compose up`

**Van inconsistentie naar betrouwbaarheid:**
- **Was**: "Works on my machine" problemen
- **Nu**: Identieke omgeving voor alle ontwikkelaars

**Van handmatige naar geautomatiseerde setup:**
- **Was**: Handmatige netwerk configuratie, volume management, service orchestratie
- **Nu**: Declaratieve configuratie die alles automatisch regelt

**Van foutgevoelig naar robust:**
- **Was**: Vergeten parameters, verkeerde startup volgorde, lost containers
- **Nu**: Dependency management, automatic restarts, service discovery

### De volgende stap in je Docker journey

Docker Compose is perfect voor:
- ✅ Lokale ontwikkeling
- ✅ Testing environments
- ✅ Kleine productie deployments
- ✅ Proof of concepts
- ✅ Leren van container orchestratie concepten

Voor grote, gedistribueerde systemen kijk je naar:
- **Kubernetes**: Enterprise container orchestratie
- **Docker Swarm**: Docker-native clustering
- **Cloud container services**: ECS, GKE, AKS

Maar de concepten die je hier hebt geleerd - service discovery, networking, volumes, health checks - vormen de basis voor alles wat daarna komt.

### Het belangrijkste inzicht

Je bent begonnen met een simpele HTML pagina en eindigt met een volledige, professionele applicatie stack. Docker Compose heeft dit mogelijk gemaakt zonder de complexiteit te verbergen - je begrijpt nog steeds wat er onder de motorkap gebeurt, maar je hoeft het niet meer handmatig te beheren.

**Dit is de kracht van goede abstractions: ze versimpelingen complexiteit zonder functionaliteit weg te nemen.**

---

## Hands-on Oefeningen

### Oefening 1: Basis setup
1. Navigeer naar `compose-files/2-fe-be/`
2. Start de stack: `docker compose up --build`
3. Test de applicatie op http://localhost:8080
4. Bekijk de logs: `docker compose logs`
5. Stop de stack: `docker compose down`

### Oefening 2: Service debugging
1. Start de stack in detached mode: `docker compose up -d`
2. Test service connectivity:
   ```bash
   docker compose exec backend nslookup mongodb
   docker compose exec backend curl http://frontend:80
   ```
3. Bekijk de MongoDB data:
   ```bash
   docker compose exec mongodb mongosh
   > use foodsdb
   > db.foods.find()
   ```

### Oefening 3: Environment configuratie
1. Maak een `.env` bestand met custom poorten
2. Pas de compose.yml aan om environment variables te gebruiken
3. Test met verschillende configuraties

### Oefening 4: Productie configuratie
1. Maak een `compose.prod.yml` met healthchecks
2. Start met: `docker compose -f compose.yml -f compose.prod.yml up`
3. Test de healthcheck status: `docker compose ps`

Deze oefeningen geven je praktische ervaring met alle concepten die we hebben besproken!