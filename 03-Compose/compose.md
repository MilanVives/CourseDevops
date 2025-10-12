# 3 - Van `docker run` naar Docker Compose

## Inleiding: Een praktische reis door containerisatie

In dit hoofdstuk maken we een praktische reis van een eenvoudige HTML-pagina naar een volledige multi-container applicatie. We beginnen met de eenvoudigste oplossing en ondervinden stap voor stap de beperkingen, waardoor we natuurlijk naar steeds geavanceerdere oplossingen toe groeien.

**De reis die we gaan maken:**
1. **Statische website** - Een eenvoudige HTML-pagina
2. **Docker run** - Snel prototypen met volumes, maar niet distribueerbaar
3. **Dockerfile** - Distribueerbare images maken, maar statische content
4. **Handmatige orchestratie** - Meerdere containers handmatig beheren met Docker commando's
5. **Docker Compose** - Alles geautomatiseerd in één configuratiebestand

**Het probleem dat we gaan oplossen:**
- Hoe ga je van een eenvoudige website naar een productie-klare applicatie?
- Waarom zijn handmatige Docker commando's onvoldoende voor echte projecten?
- Hoe verhelpt Docker Compose de pijnpunten van multi-container deployment?

**Wat je zult leren:**
- De evolutie van containerisatie: van simpel naar complex
- Praktische ervaring met alle stappen van deze evolutie
- Waarom elke stap noodzakelijk is maar ook zijn beperkingen heeft
- Hoe Docker Compose de complexiteit wegneemt zonder functionaliteit te verliezen
- Theoretische kennis over container networking, volumes en orchestratie

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

**Het probleem:** Deze pagina is volledig statisch. In de echte wereld willen we data uit databases, API's die de frontend bedienen, en een infrastructure die schaalt.

### Stap 1: Snel prototypen met `docker run`

Voor ontwikkeling kunnen we snel starten met de officiële `nginx`-image en onze HTML als volume mounten:

```bash
cd compose-files
docker run \
  --rm \
  -p 8080:80 \
  -v "$(pwd)/1-fe/index.html:/usr/share/nginx/html/index.html:ro" \
  nginx:1.27-alpine
```

**Uitleg van de parameters:**
- `--rm`: Verwijder container automatisch na stoppen
- `-p 8080:80`: Publiceer nginx poort 80 naar host poort 8080
- `-v ...:ro`: Mount bestand read-only in de container
- `nginx:1.27-alpine`: Lichtgewicht nginx variant

**Voordelen van deze aanpak:**
- Onmiddellijk resultaat: website draait op http://localhost:8080
- Ontwikkelvriendelijk: wijzig HTML en refresh browser
- Geen image-build proces nodig
- Ideaal voor experimenten en snelle iteraties

**Waarom dit niet voldoende is:**
- **Niet distribueerbaar**: Content zit buiten de container
- **Ontwikkel-only**: Kan niet naar productie of klanten
- **Fragiel**: Afhankelijk van lokale bestanden
- **Niet reproduceerbaar**: Werkt alleen op deze machine

### Stap 2: Een distributeerbare image bouwen

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
cd compose-files

# Bouw de image
docker build -t fe-static:latest ./1-fe

# Start de container
docker run --rm -p 8081:80 fe-static:latest
```

**Wat gebeurt er hier:**
1. `FROM nginx:1.27-alpine`: Start met een lichtgewicht nginx basis
2. `COPY index.html ...`: Kopieer onze content IN de image
3. `EXPOSE 80`: Documenteer welke poort de service gebruikt
4. `CMD ...`: Specificeer hoe nginx moet starten

**Voordelen van deze aanpak:**
- ✅ **Distribueerbaar**: Alles zit in de image
- ✅ **Reproduceerbaar**: Image werkt overal waar Docker draait
- ✅ **Versioned**: Je kunt verschillende versies taggen
- ✅ **Productie-klaar**: Kan naar registry en deployment pipeline

**Nieuwe beperkingen:**
- ❌ **Langzame ontwikkeling**: Elke HTML-wijziging vereist rebuild
- ❌ **Statisch**: Geen mogelijkheid voor dynamische content
- ❌ **Eenvoudig**: Echte applicaties hebben databases, API's, etc.

### Dieper duiken in Dockerfile concepten

**Waarom deze Dockerfile zo eenvoudig is:**
De `1-fe/Dockerfile` is bewust simpel gehouden, maar in echte projecten zijn er veel meer overwegingen:

```dockerfile
# Meer geavanceerde Dockerfile voor frontend
FROM nginx:1.27-alpine

# Optioneel: installeer extra tools
RUN apk add --no-cache curl

# Kopieer content
COPY index.html /usr/share/nginx/html/index.html

# Optioneel: custom nginx configuratie
COPY nginx.conf /etc/nginx/nginx.conf

# Security: draai als non-root user
RUN addgroup -g 1001 -S nginx-group && \
    adduser -S nginx-user -u 1001 -G nginx-group

USER nginx-user

EXPOSE 80

# Health check voor container status
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

**Dockerfile best practices:**
- **Multi-stage builds**: Scheid build-tijd van runtime dependencies
- **Layer caching**: Kopieer eerst package files, dan code
- **Security**: Gebruik non-root users waar mogelijk
- **Size optimization**: Gebruik alpine variants en clean up na installaties
- **Health checks**: Voeg health checks toe voor monitoring

---

## Fase 2: Complexiteit neemt toe - Het multi-service probleem

### De realiteit van moderne webapplicaties

Moderne applicaties bestaan zelden uit één container. Kijk naar de uitbreiding in `2-fe-be/`:

**Frontend** (`2-fe-be/frontend/`):
- Aangepaste HTML die data ophaalt via JavaScript
- Maakt AJAX calls naar een backend API
- Nog steeds geserveerd door nginx

**Backend** (`2-fe-be/api/`):
- Node.js Express server
- Praat met MongoDB database
- Serveert API endpoints voor de frontend

**Database**:
- MongoDB voor data persistentie
- Moet toegankelijk zijn voor de backend
- Data moet bewaard blijven tussen restarts

### Het probleem met handmatig container management

**Stel je voor dat je dit handmatig moet beheren:**

```bash
# Stap 1: Maak een custom network (vervanger van deprecated --link)
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

### Uitleg van de handmatige parameters

**Netwerk management (`--network`):**
```bash
docker network create foodapp-network
--network foodapp-network
```
- **Waarom nodig**: Containers kunnen standaard niet met elkaar praten
- **Custom networks**: Bieden automatische DNS resolution tussen containers
- **Vervangt `--link`**: De oudere `--link` parameter is deprecated en minder flexibel

**Oude `--link` methode (DEPRECATED):**
```bash
# OUDE MANIER - niet meer aanbevolen
docker run -d --name mongodb mongo
docker run -d --name backend --link mongodb:mongodb backend-image
```
- **Probleem met `--link`**: Alleen unidirectionele verbindingen
- **Beperkt**: Werkt alleen met containers op dezelfde host
- **Inflexibel**: Moeilijk om complexe netwerk topologieën te maken

**Volume management (`-v`):**
```bash
-v dbdata:/data/db
```
- **Named volume**: Docker beheert de data persistent
- **Alternative**: `-v /host/path:/container/path` voor bind mounts
- **Waarom named volumes**: Portabel tussen verschillende hosts

**Environment variables (`-e`):**
```bash
-e PORT=3000
-e MONGO_URI=mongodb://mongodb:27017/foodsdb
```
- **Configuratie**: Externe configuratie zonder code aanpassingen
- **Connection strings**: `mongodb://mongodb:27017` gebruikt container hostname
- **Flexibiliteit**: Verschillende omgevingen (dev/test/prod) met andere waarden

**Port mapping (`-p`):**
```bash
-p 3000:3000  # Host port 3000 -> Container port 3000
-p 8080:80    # Host port 8080 -> Container port 80
```
- **Externe toegang**: Alleen gemapte poorten zijn bereikbaar van buitenaf
- **Security**: Database heeft geen `-p` dus alleen intern bereikbaar
- **Format**: `host_port:container_port`

### Praktische problemen met handmatige orchestratie

**1. Startup volgorde problemen:**
```bash
# Backend start voor database klaar is
$ docker logs backend
MongoNetworkError: failed to connect to server [mongodb:27017]
```

**2. Cleanup complexiteit:**
```bash
# Alles handmatig stoppen en opruimen
docker stop frontend backend mongodb
docker rm frontend backend mongodb
docker network rm foodapp-network
docker volume rm dbdata  # Dit verwijdert DATA!
```

**3. Development cycle frustratie:**
```bash
# Elke code wijziging vereist:
docker stop backend
docker rm backend
docker build -t foodapp-backend ./2-fe-be/api
docker run -d --name backend --network foodapp-network -p 3000:3000 -e PORT=3000 -e MONGO_URI=mongodb://mongodb:27017/foodsdb foodapp-backend
```

**4. Environment inconsistentie:**
- Ontwikkelaar A vergeet `-e MONGO_URI` parameter
- Ontwikkelaar B gebruikt andere poort mapping
- Productie team gebruikt andere netwerk configuratie
- Niemand weet meer welke exacte commando's nodig zijn

**Problemen met deze aanpak:**
- 🔥 **Foutgevoelig**: Verkeerde volgorde = crashes
- 🔥 **Netwerk complexiteit**: Handmatig netwerk configureren
- 🔥 **Niet herhaalbaar**: Verschillende commando's voor dev/test/prod
- 🔥 **Moeilijk te onderhouden**: Updates vereisen vele stappen
- 🔥 **Geen dependency management**: Backend start voor database klaar is
- 🔥 **Command-line horror**: Lange, complexe commando's die niemand onthoudt
- 🔥 **Inconsistente omgevingen**: Elke ontwikkelaar doet het anders
- 🔥 **Documentatie nightmare**: Moeilijk om setup instructies up-to-date te houden

### De ontstaan van Docker Compose

**Docker Compose is ontstaan als antwoord op deze problemen:**

> "Stel je voor dat je één commando kunt typen en alle containers starten in de juiste volgorde, met de juiste configuratie, en elkaar kunnen vinden..."

Dit is precies wat Docker Compose doet!

---

## Theorie: Docker Compose fundamenten

### Wat is Docker Compose?

Docker Compose is een tool voor het definiëren en draaien van multi-container Docker applicaties. Met een YAML-bestand configureer je alle services van je applicatie, en met één commando start je alles op.

**Kernprincipes:**
- **Declaratief**: Je beschrijft WAT je wilt, niet HOE
- **Herhalbaar**: Dezelfde configuratie werkt overal
- **Geïsoleerd**: Elk project krijgt zijn eigen netwerk en namespace
- **Ontwikkelaar-vriendelijk**: Ontworpen voor lokale ontwikkeling

### Anatomie van een `compose.yml`

Een Docker Compose bestand heeft deze hoofdsecties:

```yaml
services:          # Definitie van alle containers
  web:
    image: nginx
    ports:
      - "80:80"
  
networks:         # Optioneel: aangepaste netwerken
  frontend:
  backend:

volumes:          # Optioneel: named volumes voor persistentie
  dbdata:
```

### Services: Het hart van Compose

Elke service definieert één container met zijn configuratie:

```yaml
services:
  backend:
    build: ./api                    # Bouw image uit Dockerfile
    image: myapp-backend:latest     # Of gebruik bestaande image
    ports:
      - "3000:3000"                # Publiceer poorten
    environment:                   # Omgevingsvariabelen
      - NODE_ENV=development
      - DB_HOST=database
    volumes:
      - ./api:/app                 # Mount code voor ontwikkeling
      - node_modules:/app/node_modules  # Cache dependencies
    depends_on:                    # Start volgorde
      - database
    restart: unless-stopped        # Herstart policy
```

**Belangrijke service-opties:**

| Optie | Doel | Voorbeeld |
|-------|------|-----------|
| `image` | Gebruik bestaande image | `nginx:alpine` |
| `build` | Bouw image van Dockerfile | `./backend` |
| `ports` | Publiceer poorten naar host | `8080:80` |
| `environment` | Omgevingsvariabelen | `DEBUG=true` |
| `volumes` | Mount bestanden/directories | `./code:/app` |
| `depends_on` | Definieer afhankelijkheden | `- database` |
| `networks` | Verbind met netwerken | `- frontend` |
| `restart` | Herstart policy | `on-failure` |

### Networking: Services vinden elkaar

**Automatische service discovery:**
- Elke service is bereikbaar via zijn servicenaam
- Compose maakt automatisch een intern netwerk
- Services kunnen met elkaar praten via `http://servicename:port`

```yaml
services:
  frontend:
    image: nginx
    # Kan praten met: http://backend:3000
    
  backend:
    build: ./api
    # Kan praten met: http://database:27017
    
  database:
    image: postgres
```

### Volumes: Persistentie en development

**Named volumes** (voor persistentie):
```yaml
services:
  database:
    image: postgres
    volumes:
      - dbdata:/var/lib/postgresql/data

volumes:
  dbdata:  # Managed door Docker
```

**Bind mounts** (voor ontwikkeling):
```yaml
services:
  app:
    build: .
    volumes:
      - ./src:/app/src  # Live reload tijdens ontwikkeling
```

### Essentiële Compose commando's

```bash
# Start alle services
docker compose up

# Start in background
docker compose up -d

# Forceer rebuild
docker compose up --build

# Stop en verwijder alles
docker compose down

# Bekijk status
docker compose ps

# Bekijk logs
docker compose logs
docker compose logs backend

# Voer commando uit in service
docker compose exec backend bash

# Valideer configuratie
docker compose config
```

### Geavanceerde Compose concepten

**1. Environment Files (.env):**
```bash
# .env bestand
NODE_ENV=development
MONGO_URI=mongodb://mongodb:27017/foodsdb
API_PORT=3000
WEB_PORT=8080
```

```yaml
# compose.yml
services:
  backend:
    build: ./api
    ports:
      - "${API_PORT}:3000"
    env_file:
      - .env
```

**2. Override files voor verschillende omgevingen:**
```yaml
# compose.override.yml (automatisch geladen)
services:
  backend:
    volumes:
      - ./api:/app  # Live code reloading voor development
    environment:
      - DEBUG=true
```

```yaml
# compose.prod.yml (voor productie)
services:
  backend:
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
    environment:
      - NODE_ENV=production
```

**3. Multi-stage builds in compose context:**
```dockerfile
# Dockerfile met multi-stage build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

```yaml
# compose.yml met build argumenten
services:
  backend:
    build:
      context: ./api
      target: runtime  # Gebruik de runtime stage
      args:
        - NODE_ENV=development
```

**4. Healthchecks en dependency management:**
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
        condition: service_healthy  # Wacht tot MongoDB gezond is
```

**5. Networks en service isolation:**
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
      - frontend
      - backend

  mongodb:
    image: mongo
    networks:
      - backend  # Alleen toegankelijk vanuit backend network
```

**6. Volume types en gebruik:**
```yaml
volumes:
  # Named volume - beheerd door Docker
  dbdata:
    driver: local
  
  # Named volume met custom configuratie
  logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /host/logs

services:
  backend:
    volumes:
      # Named volume voor persistentie
      - dbdata:/data/db
      
      # Bind mount voor ontwikkeling
      - ./api:/app
      
      # Volume voor logs
      - logs:/var/log/app
      
      # Anonymous volume voor cache
      - /app/node_modules
```

---

## Fase 3: Praktische toepassing - De volledige stack

### Analyse van onze `2-fe-be/compose.yml`

```yaml
services:
  backend:
    build: ./api
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - MONGO_URI=mongodb://mongodb:27017/foodsdb
    depends_on:
      - mongodb

  frontend:
    build: ./frontend
    ports:
      - "8080:80"

  mongodb:
    image: mongo
    volumes:
      - dbdata:/data/db

volumes:
  dbdata:
```

### Service-by-service analyse

**1. Backend Service (`backend`):**
```yaml
backend:
  build: ./api                    # Bouwt image van ./api/Dockerfile
  ports:
    - "3000:3000"                # Publiceert API naar localhost:3000
  environment:
    - PORT=3000                  # Node.js app luistert op poort 3000
    - MONGO_URI=mongodb://mongodb:27017/foodsdb  # Database connectie
  depends_on:
    - mongodb                    # Start pas na MongoDB
```

**Backend Dockerfile analyse (`./api/Dockerfile`):**
```dockerfile
FROM node                       # Basis image met Node.js
WORKDIR /app                   # Werkdirectory in container

COPY package*.json .           # Kopieer package files eerst (layer caching)
COPY . .                       # Kopieer rest van de code

RUN npm i                      # Installeer dependencies

EXPOSE 3000                    # Documenteer poort

CMD node server.js             # Start commando
```

**Verbeteringen voor de backend Dockerfile:**
```dockerfile
# Betere versie van api/Dockerfile
FROM node:18-alpine            # Specifieke versie + alpine voor kleinere size

WORKDIR /app

# Kopieer package files eerst voor betere caching
COPY package*.json ./
RUN npm ci --only=production   # Gebruik npm ci voor reproduceerbare builds

# Kopieer source code
COPY . .

# Security: maak non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Verander eigenaarschap van app directory
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
```

**2. Frontend Service (`frontend`):**
```yaml
frontend:
  build: ./frontend              # Bouwt image van ./frontend/Dockerfile
  ports:
    - "8080:80"                 # Publiceert website naar localhost:8080
```

**Frontend Dockerfile analyse (`./frontend/Dockerfile`):**
```dockerfile
FROM nginx                     # Basis nginx image
COPY . /usr/share/nginx/html   # Kopieer alle bestanden naar nginx document root
EXPOSE 80                      # Documenteer poort
```

**Verbeteringen voor de frontend Dockerfile:**
```dockerfile
# Betere versie van frontend/Dockerfile
FROM nginx:1.27-alpine         # Specifieke versie + alpine

# Kopieer alleen de bestanden die nodig zijn
COPY index.html /usr/share/nginx/html/
COPY *.css /usr/share/nginx/html/    # Als er CSS bestanden zijn
COPY *.js /usr/share/nginx/html/     # Als er JS bestanden zijn

# Custom nginx configuratie (optioneel)
# COPY nginx.conf /etc/nginx/nginx.conf

# Security: run as non-root
RUN addgroup -g 1001 -S nginx-group && \
    adduser -S nginx-user -u 1001 -G nginx-group

# Verander eigenaarschap
RUN chown -R nginx-user:nginx-group /usr/share/nginx/html
RUN chown -R nginx-user:nginx-group /var/cache/nginx
RUN chown -R nginx-user:nginx-group /var/log/nginx

USER nginx-user

EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

**Wat doet de backend:**
- Express.js server met REST API endpoints
- Gebruikt MongoDB voor data persistentie
- Heeft retry-logica voor database connecties (connectWithRetry)
- Serveert JSON data voor de frontend

**Backend dependency analysis:**
```json
// package.json dependencies
{
  "cors": "^2.8.5",        // Cross-Origin Resource Sharing
  "express": "^4.21.1",    // Web framework
  "mongoose": "^8.7.3"     // MongoDB ODM
}
```

**Waarom deze dependencies:**
- **CORS**: Frontend en backend draaien op verschillende poorten (8080 vs 3000)
- **Express**: Lightweight web framework voor API endpoints
- **Mongoose**: Object Document Mapper voor MongoDB, met connection pooling en retry logic

**2. Frontend Service (`frontend`):**
```yaml
frontend:
  build: ./frontend              # Bouwt image van ./frontend/Dockerfile
  ports:
    - "8080:80"                 # Publiceert website naar localhost:8080
```

**Wat doet de frontend:**
- Nginx serveert aangepaste HTML/JavaScript
- JavaScript maakt AJAX calls naar `http://localhost:3000`
- Dynamisch laden van data in plaats van hardcoded lijst

**3. Database Service (`mongodb`):**
```yaml
mongodb:
  image: mongo                   # Gebruikt officiële MongoDB image
  volumes:
    - dbdata:/data/db           # Persistent data opslag
```

### Het Docker build proces uitgelegd

**Wanneer je `docker compose up --build` uitvoert:**

```bash
# Compose bouwt eerst alle images
[+] Building 45.2s (12/12) FINISHED
=> [backend internal] load build definition from Dockerfile
=> [backend internal] load .dockerignore  
=> [backend internal] load metadata for docker.io/library/node:latest
=> [backend 1/6] FROM docker.io/library/node:latest
=> [backend internal] load build context
=> [backend 2/6] WORKDIR /app
=> [backend 3/6] COPY package*.json .
=> [backend 4/6] COPY . .
=> [backend 5/6] RUN npm i
=> [backend 6/6] EXPOSE 3000
=> [backend] exporting to image
```

**Layer caching in actie:**
```dockerfile
# Slecht - elke code wijziging vereist npm install opnieuw
FROM node
WORKDIR /app
COPY . .                    # Kopieer ALLES eerst
RUN npm i                   # Elke keer opnieuw als code wijzigt
CMD node server.js

# Goed - npm install wordt gecached
FROM node  
WORKDIR /app
COPY package*.json ./       # Kopieer alleen package files
RUN npm i                   # Wordt alleen opnieuw gedaan als package.json wijzigt
COPY . .                    # Kopieer code als laatste
CMD node server.js
```

**Build context optimalisatie met .dockerignore:**
```bash
# .dockerignore (vergelijkbaar met .gitignore)
node_modules
*.log
.git
README.md
.env
coverage/
.nyc_output
```

**Multi-stage builds voor productie:**
```dockerfile
# Development stage
FROM node:18 AS development
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]

# Production build stage  
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production runtime stage
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY package*.json ./
USER node
CMD ["npm", "start"]
```

**Compose met multi-stage builds:**
```yaml
services:
  backend-dev:
    build:
      context: ./api
      target: development  # Gebruik development stage
    volumes:
      - ./api:/app
      - /app/node_modules
  
  backend-prod:
    build:
      context: ./api  
      target: production   # Gebruik production stage
```

### Het netwerk-magic uitgelegd

**Automatische service discovery in actie:**

![Docker Compose Service DNS](../images/compose-service-dns.png)

#### Het probleem met IP-gebaseerde communicatie

Voordat we Docker Compose hadden, moesten containers elkaar bereiken via IP-adressen:

```bash
# Handmatige container setup (de ouderwetse manier)
docker run -d --name mongodb mongo
docker run -d --name backend \
  -e MONGO_URI=mongodb://172.17.0.3:27017/foodsdb \
  backend-image

# Problemen:
# - IP adressen kunnen wijzigen bij restart
# - Niet leesbaar of onderhoudbaar
# - Geen load balancing
# - Foutgevoelig bij typing
```

#### De Docker Compose oplossing: Service Namen

Docker Compose lost dit op met **automatische DNS resolutie**:

```yaml
services:
  backend:
    build: ./api
    environment:
      - MONGO_URI=mongodb://mongodb:27017/foodsdb  # Servicenaam!
    
  mongodb:
    image: mongo
```

**Wat gebeurt er automatisch:**
1. Docker Compose maakt een intern netwerk
2. Elke service krijgt een DNS entry met zijn servicenaam
3. Containers kunnen elkaar bereiken via servicenaam
4. Docker regelt de IP resolutie automatisch

![Service Communicatie](../images/compose-service-communication.png)

![Service Name Resolution Detail](../images/compose-service-name-resolution.png)

### Praktische voorbeelden van service name resolution

#### 1. **Backend praat met MongoDB:**
```javascript
// In server.js: MONGO_URI=mongodb://mongodb:27017/foodsdb
mongoose.connect(process.env.MONGO_URI)
```
- `mongodb` = servicenaam wordt automatisch hostname
- Docker DNS zet `mongodb` om naar het juiste IP adres
- Compose regelt dit automatisch, geen configuratie nodig

#### 2. **Frontend praat met Backend:**

**Probleem scenario** (binnen container-to-container):
```javascript
// FOUT: Dit werkt niet tussen containers
const url = "http://localhost:3000";
fetch(url)  // localhost verwijst naar de frontend container zelf
```

**Juiste aanpak** (service namen gebruiken):
```javascript
// CORRECT: Gebruik service naam voor interne communicatie
const url = "http://backend:3000";
fetch(url)  // backend wordt automatisch geresolv'd naar IP
```

**Voor browser-to-backend** (vanuit browser):
```javascript
// In browser JavaScript: gebruik host machine IP
const url = "http://localhost:3000";  // Via port mapping
fetch(url)
```

#### 3. **Praktische test van service name resolution**

**Setup:**
```bash
# Start de compose stack
docker compose -f 2-fe-be/compose.yml up -d

# Test service resolution vanuit backend container
docker compose exec backend nslookup mongodb
# Output: Name: mongodb, Address: 172.20.0.3

# Test HTTP communicatie tussen services
docker compose exec backend curl http://frontend:80
# Haalt de HTML pagina op van de frontend service
```

#### 4. **Database connecties via service namen**

**PostgreSQL voorbeeld:**
```yaml
services:
  app:
    build: ./app
    environment:
      # Gebruik service naam in connection string
      - DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
    depends_on:
      - postgres
      
  postgres:
    image: postgres:13
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
```

**Redis cache voorbeeld:**
```yaml
services:
  webapp:
    build: ./webapp
    environment:
      # Service naam voor Redis connectie
      - REDIS_URL=redis://redis:6379
      - SESSION_STORE=redis://redis:6379/1
    depends_on:
      - redis
      
  redis:
    image: redis:alpine
    # Geen ports mapping nodig voor interne communicatie
```

#### 5. **Microservices communicatie**

**Multi-service API setup:**
```yaml
services:
  api-gateway:
    build: ./gateway
    ports:
      - "8080:80"
    environment:
      # Interne service URLs
      - USER_SERVICE_URL=http://user-service:3000
      - ORDER_SERVICE_URL=http://order-service:3001
      - PAYMENT_SERVICE_URL=http://payment-service:3002
      
  user-service:
    build: ./services/users
    environment:
      - DB_HOST=user-db
      
  order-service:
    build: ./services/orders
    environment:
      - DB_HOST=order-db
      - USER_SERVICE=http://user-service:3000
      
  payment-service:
    build: ./services/payments
    environment:
      - ORDER_SERVICE=http://order-service:3001
      
  user-db:
    image: postgres:13
    
  order-db:
    image: postgres:13
```

**In API Gateway code:**
```javascript
// gateway/server.js
const userServiceUrl = process.env.USER_SERVICE_URL;
const orderServiceUrl = process.env.ORDER_SERVICE_URL;

app.get('/users/:id', async (req, res) => {
  // Service naam wordt automatisch resolved
  const response = await fetch(`${userServiceUrl}/users/${req.params.id}`);
  const user = await response.json();
  res.json(user);
});
```

#### 6. **Development vs Production service names**

**Development (docker-compose.yml):**
```yaml
services:
  app:
    build: ./app
    environment:
      - API_URL=http://api:3000        # Interne service naam
      - DB_HOST=database               # Interne service naam
      
  api:
    build: ./api
    
  database:
    image: postgres:13
```

**Production deployment overwegingen:**
```yaml
# Voor productie kun je service discovery tools gebruiken
services:
  app:
    build: ./app
    environment:
      # Productie kan externe service discovery gebruiken
      - API_URL=http://api.production.company.com
      - DB_HOST=prod-database.amazonaws.com
```

#### 7. **Service name debugging**

**Veelvoorkomende problemen en oplossingen:**

```bash
# Problem: Service not found
docker compose exec app curl http://wrong-service-name:3000
# curl: (6) Could not resolve host: wrong-service-name

# Solution: Check service names in compose.yml
docker compose config --services
# Lists all service names

# Problem: Connection refused
docker compose exec app curl http://api:3000
# curl: (7) Failed to connect to api port 3000: Connection refused

# Debug steps:
# 1. Check if service is running
docker compose ps

# 2. Check if service is listening on correct port
docker compose exec api netstat -tuln

# 3. Check if service is healthy
docker compose exec api curl http://localhost:3000/health
```

**Network troubleshooting:**
```bash
# Test DNS resolution
docker compose exec app nslookup api
# Should return IP address of api service

# Test network connectivity
docker compose exec app ping api
# Should get response from api container

# Check service logs
docker compose logs api
# Look for startup errors or connection issues
```

#### 8. **Service aliases voor flexibiliteit**

Soms wil je meerdere namen voor dezelfde service:

```yaml
services:
  primary-database:
    image: postgres:13
    networks:
      default:
        aliases:
          - db
          - database
          - postgres
          - primary-db
          
  app:
    build: ./app
    environment:
      # Alle aliases werken:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      # Of: DATABASE_URL=postgresql://user:pass@database:5432/mydb
      # Of: DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
```

#### 9. **Environment-specific service resolution**

**Development override:**
```yaml
# docker-compose.override.yml (automatisch geladen in development)
services:
  app:
    environment:
      - API_URL=http://api:3000          # Local service
      - DEBUG=true
      
  mock-service:
    image: mockserver/mockserver
    networks:
      default:
        aliases:
          - external-api                 # Mock external API
```

**Production configuration:**
```yaml
# docker-compose.prod.yml
services:
  app:
    environment:
      - API_URL=https://api.production.com  # External production API
      - DEBUG=false
```

#### 10. **Load balancing met service names**

Wanneer je meerdere instances van een service hebt:

```yaml
services:
  nginx:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
      
  app:
    build: ./app
    # Geen ports mapping - alleen intern bereikbaar
    
# Start meerdere app instances
```

**Nginx configuratie:**
```nginx
# nginx.conf
upstream app_servers {
    server app_1:3000;
    server app_2:3000;
    server app_3:3000;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://app_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Start met schaling:**
```bash
# Start 3 instances van app service
docker compose up --scale app=3 -d

# Nginx zal automatisch load balancen tussen app_1, app_2, app_3
```

### Geavanceerde service name features

#### Service aliases voor flexibiliteit

```yaml
services:
  web:
    build: ./frontend
    networks:
      default:
        aliases:
          - frontend
          - webapp
          - ui
          
  api:
    build: ./backend
    networks:
      default:
        aliases:
          - backend
          - server
          - rest-api
```

**Nu werken alle deze namen:**
```bash
# Allemaal wijzen naar dezelfde container
curl http://web:80
curl http://frontend:80
curl http://webapp:80
curl http://ui:80

# API bereiken
curl http://api:3000
curl http://backend:3000
curl http://server:3000
curl http://rest-api:3000
```

#### Multi-network service discovery

```yaml
networks:
  frontend:
  backend:
  
services:
  nginx:
    image: nginx
    networks:
      - frontend
      
  app:
    build: ./app
    networks:
      - frontend  # Kan praten met nginx
      - backend   # Kan praten met database
      
  database:
    image: postgres
    networks:
      - backend   # Alleen bereikbaar vanuit backend network
```

**Network scope van service namen:**
- Service namen werken alleen binnen hetzelfde netwerk
- `app` kan `nginx` EN `database` bereiken
- `nginx` kan NIET rechtstreeks met `database` praten

### Hands-on testing van service names

#### DNS resolution testen

```bash
# Start de compose stack
docker compose -f 2-fe-be/compose.yml up -d

# Ga in backend container
docker compose -f 2-fe-be/compose.yml exec backend bash

# Test DNS resolution
nslookup mongodb
# Output:
# Server:         127.0.0.11
# Address:        127.0.0.11#53
# Name:   mongodb
# Address: 172.18.0.3

# Test connectivity met ping
ping mongodb
# PING mongodb (172.18.0.3) 56(84) bytes of data.
# 64 bytes from 2-fe-be_mongodb_1.2-fe-be_default (172.18.0.3): icmp_seq=1 ttl=64

# Test HTTP connectiviteit
curl http://frontend:80
# Haalt HTML op van frontend service
```

#### Service discovery debugging

```bash
# Bekijk alle services in het netwerk
docker compose ps

# Inspecteer netwerk configuratie
docker network ls
docker network inspect 2-fe-be_default

# Check DNS servers in container
docker compose exec backend cat /etc/resolv.conf
# nameserver 127.0.0.11  <- Docker's embedded DNS server

# Test service resolution van buitenaf
docker run --rm --network 2-fe-be_default alpine nslookup backend
```

### Veelgemaakte fouten en oplossingen

#### 1. **Service naam typfouten**
```yaml
# FOUT: Typo in service naam
services:
  databse:  # Fout gespeld!
    image: postgres
  
  app:
    environment:
      - DB_HOST=database  # Verwijst naar non-existente service
```

**Oplossing:**
```bash
# Debug met nslookup
docker compose exec app nslookup database
# nslookup: can't resolve 'database': Name or service not known

# Check beschikbare services
docker compose ps
```

#### 2. **Wrong network context**
```yaml
services:
  web:
    networks:
      - frontend
  
  api:
    networks:
      - backend  # Andere network!
```

```bash
# web kan api NIET bereiken
docker compose exec web ping api
# ping: api: Name or service not known
```

**Oplossing**: Zorg dat services op hetzelfde netwerk zitten.

#### 3. **Port confusion**
```javascript
// FOUT: Verkeerde poort
fetch('http://backend:80')  // Backend luistert op 3000, niet 80

// CORRECT: Juiste interne poort
fetch('http://backend:3000')  // Backend container port
```

#### 4. **Browser vs container context**
```javascript
// In browser JavaScript (FOUT):
fetch('http://backend:3000')  // Browser kent service naam niet

// In browser JavaScript (CORRECT):
fetch('http://localhost:3000')  // Via host port mapping

// In container JavaScript (CORRECT):
fetch('http://backend:3000')  // Service naam werkt
```

### Load balancing met service namen

#### Meerdere instances van een service

```yaml
services:
  web:
    build: ./frontend
    
  app:
    build: ./backend
    scale: 3  # Drie instances van backend
    
  database:
    image: postgres
```

```bash
# Start met schaling
docker compose up --scale app=3

# Service naam verdeelt load automatisch
curl http://app:3000  # Kan naar app_1, app_2, of app_3 gaan
```

**Automatische load balancing:**
- Docker DNS round-robin tussen instances
- Service naam blijft hetzelfde
- Transparant voor andere services

### Advanced service discovery patterns

#### Health check gebaseerde discovery

```yaml
services:
  app:
    build: ./app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    
  proxy:
    image: nginx
    depends_on:
      app:
        condition: service_healthy  # Wacht tot app gezond is
```

#### Service discovery met external networks

```yaml
# Gedeeld netwerk tussen projecten
networks:
  shared:
    external: true
    name: company-network

services:
  api:
    networks:
      - shared
    # Nu bereikbaar als 'api' vanuit andere projecten op hetzelfde netwerk
```

### Best practices voor service naming

#### 1. **Duidelijke, beschrijvende namen**
```yaml
services:
  user-service:        # ✅ Duidelijk
    build: ./users
    
  payment-gateway:     # ✅ Specifiek
    build: ./payments
    
  cache:              # ✅ Functioneel
    image: redis
    
  # Vermijd:
  app1:               # ❌ Niet beschrijvend
  container2:         # ❌ Te generiek
```

#### 2. **Consistente naming conventions**
```yaml
services:
  # Microservices pattern
  user-service:
  order-service:
  payment-service:
  
  # Database naming
  user-db:
  order-db:
  
  # Infrastructure
  redis-cache:
  nginx-proxy:
```

#### 3. **Environment-specific configurations**
```yaml
# compose.yml (base)
services:
  database:
    image: postgres
    
# compose.override.yml (development)
services:
  database:
    networks:
      default:
        aliases:
          - db
          - postgres
          - dev-db

# compose.prod.yml (production)  
services:
  database:
    networks:
      default:
        aliases:
          - db
          - postgres
          - prod-db
```

### Troubleshooting service discovery

#### Common debugging commands

```bash
# 1. Check service is running
docker compose ps

# 2. Test DNS resolution
docker compose exec service_name nslookup target_service

# 3. Test network connectivity  
docker compose exec service_name ping target_service

# 4. Check network configuration
docker network inspect project_default

# 5. Test HTTP connectivity
docker compose exec service_name curl http://target_service:port

# 6. Check service logs
docker compose logs target_service

# 7. Inspect service configuration
docker compose config
```

#### Advanced network debugging

```bash
# Show all containers in network
docker network inspect project_default | jq '.[0].Containers'

# DNS debug in container
docker compose exec app sh
> dig backend
> nslookup backend  
> getent hosts backend

# Network routing table
docker compose exec app ip route show

# Active connections
docker compose exec app netstat -tuln
```

### Data persistence

**Named volume `dbdata`:**
- MongoDB data blijft bewaard tussen restarts
- `docker compose down` verwijdert NIET de data
- `docker compose down -v` verwijdert WEL de data

### De stack starten

**Stap 1: Navigeer naar de juiste directory**
```bash
cd compose-files
```

**Stap 2: Start alle services**
```bash
docker compose -f 2-fe-be/compose.yml up --build
```

**Wat gebeurt er:**
1. Docker bouwt images voor `backend` en `frontend`
2. MongoDB container start eerst
3. Backend wacht op MongoDB en probeert connectie
4. Frontend start als laatste
5. Alle services kunnen met elkaar praten

**Stap 3: Test de applicatie**
- Open http://localhost:8080 (frontend)
- Controleer of data wordt geladen via de API
- Backend API is bereikbaar op http://localhost:3000

### Debugging en monitoring

**Bekijk logs van alle services:**
```bash
docker compose -f 2-fe-be/compose.yml logs
```

**Bekijk logs van specifieke service:**
```bash
docker compose -f 2-fe-be/compose.yml logs backend
docker compose -f 2-fe-be/compose.yml logs -f frontend  # Live volgen
```

**Controleer status:**
```bash
docker compose -f 2-fe-be/compose.yml ps
```

**Ga in een draaiende container:**
```bash
docker compose -f 2-fe-be/compose.yml exec backend bash
docker compose -f 2-fe-be/compose.yml exec mongodb mongosh
```

### Stoppen en opruimen

**Graceful stop:**
```bash
docker compose -f 2-fe-be/compose.yml down
```

**Stop en verwijder volumes (VERLIEST DATA!):**
```bash
docker compose -f 2-fe-be/compose.yml down -v
```

### Container networking deep dive

**Wat gebeurt er onder de motorkap:**

1. **Network creation:**
```bash
# Compose maakt automatisch een network
$ docker network ls
NETWORK ID     NAME                 DRIVER    SCOPE
a1b2c3d4e5f6   2-fe-be_default     bridge    local
```

2. **Container discovery:**
```bash
# Ga in backend container en test connectiviteit
$ docker compose exec backend bash
root@backend:/app# ping mongodb
PING mongodb (172.18.0.3) 56(84) bytes of data.
64 bytes from 2-fe-be_mongodb_1.2-fe-be_default (172.18.0.3): icmp_seq=1 ttl=64 time=0.045 ms

# DNS resolution werkt automatisch
root@backend:/app# nslookup mongodb
Server:         127.0.0.11
Address:        127.0.0.11#53

Name:   mongodb
Address: 172.18.0.3
```

3. **Port exposure vs publishing:**
```yaml
services:
  mongodb:
    image: mongo
    expose:
      - "27017"        # Alleen binnen Docker netwerk bereikbaar
    # ports:           # GEEN publishing naar host
    #   - "27017:27017"
  
  backend:
    build: ./api
    ports:
      - "3000:3000"    # Gepubliceerd naar host (localhost:3000)
```

**Security implications:**
- **Internal services**: Database alleen bereikbaar binnen Docker netwerk
- **Published services**: Frontend en backend bereikbaar van buitenaf
- **Network isolation**: Optioneel gescheiden netwerken voor extra security

### Troubleshooting en debugging

**Veelvoorkomende problemen en oplossingen:**

**1. Database connection errors:**
```bash
# Check of MongoDB draait
$ docker compose ps
NAME              COMMAND                  SERVICE      STATUS
2-fe-be-mongodb-1   "docker-entrypoint.s…"   mongodb      Up (healthy)

# Check backend logs  
$ docker compose logs backend
backend-1  | Failed to connect to mongo on startup - retrying in 1 sec

# Oplossing: Wacht tot healthcheck slaagt
```

**2. Port conflicts:**
```bash
# Error: port already in use
ERROR: for frontend  Cannot start service frontend: 
Ports are not available: exposing port 8080: listen tcp 0.0.0.0:8080: bind: address already in use

# Oplossing: Verander poort mapping
services:
  frontend:
    ports:
      - "8081:80"  # Gebruik andere host poort
```

**3. Build context problemen:**
```bash
# Error: COPY failed
COPY failed: file not found in build context

# Oplossing: Check build context in compose file
services:
  backend:
    build:
      context: ./api        # Relatief tot compose.yml locatie
      dockerfile: Dockerfile
```

**4. Volume permission issues:**
```bash
# Error: permission denied
mongodb-1  | {"t":{"$date":"2024-01-01T10:00:00.000Z"},"s":"E","c":"STORAGE","id":20568,"ctx":"initandlisten","msg":"Error setting up listener: SocketException: Permission denied"}

# Oplossing: Check volume ownership
$ docker compose exec mongodb bash
root@mongodb:/# ls -la /data/db
drwxr-xr-x 2 mongodb mongodb 4096 Jan  1 10:00 .
```

### Performance optimalisatie

**Development optimalisaties:**
```yaml
services:
  backend:
    build: ./api
    volumes:
      - ./api:/app              # Live reloading
      - /app/node_modules       # Prevent overwriting node_modules
    environment:
      - NODE_ENV=development
      - CHOKIDAR_USEPOLLING=true  # Voor file watching op sommige systemen
```

**Production optimalisaties:**
```yaml
services:
  backend:
    build:
      context: ./api
      target: production
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.50'
        reservations:
          memory: 256M
          cpus: '0.25'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

---

## Fase 4: Inzichten en best practices

### Wat hebben we geleerd?

**Van simpel naar complex:**
1. **Eenvoudige HTML**: Statisch, maar niet distribueerbaar
2. **Docker image**: Distribueerbaar, maar alleen static content
3. **Multi-container**: Echte applicatie met database en API
4. **Docker Compose**: Alles gemanaged als één geheel

**De kracht van Compose:**
- ✅ Één commando voor hele stack
- ✅ Consistente omgeving (dev = prod)
- ✅ Automatisch netwerk en service discovery
- ✅ Declaratieve configuratie
- ✅ Eenvoudig te delen met team

### Productie-overwegingen

**Wat ontbreekt voor productie:**
- **Healthchecks**: Controleer of services echt klaar zijn
- **Restart policies**: Automatisch herstarten bij crashes
- **Resource limits**: Memory en CPU begrenzingen
- **Secrets management**: Veilige configuratie
- **Monitoring**: Logs, metrics, alerting
- **Backup strategie**: Database backups
- **Load balancing**: Meerdere instances van services

**Uitgebreide compose.yml voor productie:**
```yaml
services:
  backend:
    build: ./api
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    environment:
      - NODE_ENV=production
    env_file:
      - .env.production
    depends_on:
      mongodb:
        condition: service_healthy

  mongodb:
    image: mongo
    restart: unless-stopped
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - dbdata:/data/db
      - ./mongo-init:/docker-entrypoint-initdb.d:ro
```

### Best practices samengevat

### Best practices samengevat

**Compose file organisatie:**
```yaml
# compose.yml - Complete schema met commentaar
version: '3.8'  # Optioneel - moderne Compose detecteert automatisch

services:
  backend:
    build: 
      context: ./api
      dockerfile: Dockerfile
      args:
        - NODE_ENV=${NODE_ENV:-development}
    image: foodapp-backend:${VERSION:-latest}
    container_name: foodapp-backend  # Custom naam in plaats van gegenereerde
    restart: unless-stopped
    ports:
      - "${API_PORT:-3000}:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-development}
      - MONGO_URI=mongodb://mongodb:27017/${DB_NAME:-foodsdb}
    env_file:
      - .env                    # Laad environment variabelen
    volumes:
      - ./api:/app             # Development: live reloading
      - api_node_modules:/app/node_modules  # Cache node_modules
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
      start_period: 60s
    deploy:                     # Swarm mode / resource limits
      resources:
        limits:
          memory: 512M
          cpus: '0.50'
    labels:                     # Metadata voor tooling
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.localhost`)"

  frontend:
    build: ./frontend
    image: foodapp-frontend:${VERSION:-latest}
    container_name: foodapp-frontend
    restart: unless-stopped
    ports:
      - "${WEB_PORT:-8080}:80"
    networks:
      - frontend
    depends_on:
      - backend
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.web.rule=Host(`localhost`)"

  mongodb:
    image: mongo:${MONGO_VERSION:-7}
    container_name: foodapp-mongodb
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_ROOT_USER:-admin}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD:-admin123}
      - MONGO_INITDB_DATABASE=${DB_NAME:-foodsdb}
    volumes:
      - mongodb_data:/data/db
      - ./mongo-init:/docker-entrypoint-initdb.d:ro
    networks:
      - backend
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 40s
    # ports:                    # Alleen voor development debugging
    #   - "27017:27017"

networks:
  frontend:
    driver: bridge
    name: foodapp-frontend      # Custom network naam
  backend:
    driver: bridge
    name: foodapp-backend
    internal: false             # Set to true voor extra security

volumes:
  mongodb_data:
    driver: local
    name: foodapp-mongodb-data  # Custom volume naam
  api_node_modules:
    driver: local
    name: foodapp-api-modules

# Optioneel: externe resources
# networks:
#   external_network:
#     external: true
#     name: traefik-network

# volumes:
#   external_volume:
#     external: true
#     name: shared-data
```

**Environment file structuur (.env):**
```bash
# .env - Development defaults
NODE_ENV=development
VERSION=latest

# Ports
API_PORT=3000
WEB_PORT=8080

# Database
MONGO_VERSION=7
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=admin123
DB_NAME=foodsdb

# Optioneel: External services
# REDIS_URL=redis://redis:6379
# ELASTICSEARCH_URL=http://elasticsearch:9200
```

**Environment file per omgeving:**
```bash
# .env.production
NODE_ENV=production
VERSION=1.2.3

API_PORT=3000
WEB_PORT=80

MONGO_VERSION=7-focal
MONGO_ROOT_USER=produser
MONGO_ROOT_PASSWORD=secure_password_123
DB_NAME=foodsdb_prod
```

**Ontwikkeling:**
- Gebruik bind mounts voor live code reloading
- Publiceer poorten voor debugging
- Gebruik descriptive service names
- Voeg healthchecks toe voor betrouwbaarheid

**Productie:**
- Named volumes voor persistentie
- Restart policies voor betrouwbaarheid
- Resource limits voor stabiliteit
- Environment files voor configuratie
- Geen dev tools in production images

**Algemeen:**
- Houd compose.yml simpel en leesbaar
- Documenteer complexe configuraties
- Gebruik versie controle voor compose files
- Test compose configuratie regelmatig

---

## Conclusie: De evolutie naar moderne deployment

**De reis die we hebben afgelegd:**

1. **`docker run`**: Snel prototypen, maar handmatig en foutgevoelig
2. **Dockerfile**: Reproduceerbare images, maar nog steeds handmatig orchestreren
3. **Docker Compose**: Declaratieve multi-service deployment

**Waarom Docker Compose zo belangrijk is:**

Docker Compose heeft de manier waarop we ontwikkelen en deployen fundamenteel veranderd. Het lost de kernproblemen op van moderne applicatie ontwikkeling:

- **Complexiteit**: Van meerdere terminalscommando's naar één `docker compose up`
- **Consistentie**: Dezelfde omgeving voor alle ontwikkelaars
- **Reproducibility**: Works on my machine → works everywhere
- **Collaboration**: Hele team kan stack starten met één commando

**De volgende stap:**
Docker Compose is perfect voor ontwikkeling en kleine productie omgevingen. Voor grote, gedistribueerde systemen kijk je naar orchestration platforms zoals Kubernetes, maar de concepten die je hier leert vormen de basis voor alles wat daarna komt.

**Het belangrijkste inzicht:**
Je bent begonnen met een simpele HTML pagina en eindigt met een volledige, professionele applicatie stack. Docker Compose heeft dit mogelijk gemaakt zonder de complexiteit te verbergen - je begrijpt nog steeds wat er onder de motorkap gebeurt, maar je hoeft het niet meer handmatig te beheren.

---

## Appendix: Geavanceerde concepten

### Docker Compose in CI/CD pipelines

**GitHub Actions voorbeeld:**
```yaml
# .github/workflows/test.yml
name: Test Application

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Start services
        run: |
          docker compose -f 2-fe-be/compose.yml up -d --build
          
      - name: Wait for services
        run: |
          timeout 60 bash -c 'until curl -f http://localhost:3000/health; do sleep 2; done'
          
      - name: Run tests
        run: |
          docker compose -f 2-fe-be/compose.yml exec -T backend npm test
          
      - name: Cleanup
        if: always()
        run: |
          docker compose -f 2-fe-be/compose.yml down -v
```

### Docker Compose alternatieven en vergelijkingen

**1. Kubernetes (voor productie):**
```yaml
# kubernetes deployment.yml equivalent
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
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
        image: foodapp-backend:1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: MONGO_URI
          value: "mongodb://mongodb-service:27017/foodsdb"
```

**2. Docker Swarm (Compose compatible):**
```yaml
# Dezelfde compose.yml werkt met Swarm
services:
  backend:
    image: foodapp-backend:1.0.0
    deploy:
      replicas: 3
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

**3. Podman Compose (alternatief voor Docker):**
```bash
# Werkt met dezelfde compose.yml
podman-compose -f 2-fe-be/compose.yml up -d
```

### Monitoring en observability

**Uitgebreide compose met monitoring:**
```yaml
services:
  # Applicatie services...
  backend:
    build: ./api
    # ... rest van configuratie
    
  frontend:
    build: ./frontend
    # ... rest van configuratie
    
  mongodb:
    image: mongo
    # ... rest van configuratie

  # Monitoring services
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana:/etc/grafana/provisioning

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  prometheus_data:
  grafana_data:
  redis_data:
```

### Veelgemaakte fouten en solutions

**1. Volume permissions:**
```bash
# Probleem: Permission denied in container
# Oplossing: Zorg voor juiste ownership
RUN chown -R 1001:1001 /app
USER 1001
```

**2. Network connectivity:**
```bash
# Probleem: Services kunnen elkaar niet vinden
# Debug: Check network en DNS
docker compose exec backend nslookup mongodb
docker network inspect $(docker compose ps -q | head -1 | xargs docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}')
```

**3. Environment variable scope:**
```yaml
# Probleem: Environment variabelen niet beschikbaar
# Oplossing: Gebruik juiste syntax
environment:
  - NODE_ENV=production          # String format
  # OF
  NODE_ENV: production           # YAML format
  # OF  
env_file:
  - .env                         # From file
```

**4. Build context confusion:**
```yaml
# Probleem: Dockerfile kan bestanden niet vinden
# Oplossing: Juiste context instellen
services:
  app:
    build:
      context: ./backend          # Basis directory voor build
      dockerfile: Docker/Dockerfile  # Relatief tot context
```

Deze uitgebreide documentatie geeft je nu een complete basis voor het begrijpen en toepassen van Docker Compose, van de eenvoudigste use cases tot enterprise-level deployments.