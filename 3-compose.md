# 3 - Van `docker run` naar Compose

In dit hoofdstuk begeleiden we je stap voor stap door de evolutie van onze frontend (`1-fe/index.html`) en de uitbreiding richting een volledige stack in `2-fe-be/`. We beginnen klein met één container, bouwen vervolgens een distributieklare image en eindigen met meerdere services via Docker Compose.

## Stap 1: Snel starten met `docker run`
We gebruiken de officiële `nginx`-image en mounten ons HTML-bestand als volume. Zo kun je lokaal wijzigen zonder te rebuilden.

```bash
docker run \
  --rm \
  -p 8080:80 \
  -v "$(pwd)/1-fe/index.html:/usr/share/nginx/html/index.html:ro" \
  nginx:1.27-alpine
```

- `-p 8080:80` maakt de site bereikbaar op http://localhost:8080.
- `-v ...:ro` mount het bestand read-only, zodat nginx het rechtstreeks serveert.

### Waarom dit werkt
- Perfect voor lokale experimenten: wijzig de HTML en refresh je browser.
- Geen image-build nodig.

### Maar...
- Je kunt zo geen kant-en-klare image aan een klant opleveren, want de content zit buiten de container.

## Stap 2: Een distributeerbare image bouwen
Daarom staat er een `Dockerfile` in `1-fe/`:

```dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Bouw en start de image:

```bash
docker build -t fe-static:latest ./1-fe

docker run --rm -p 8081:80 fe-static:latest
```

Voordelen:
- Je krijgt een self-contained image die je naar een klant of registry kunt sturen.

Beperking:
- Bij elke wijziging in `index.html` moet je opnieuw `docker build` draaien. Dat kost tijd en je vergeet het soms.

## Theorie: Hoe werkt Docker Compose?
Docker Compose is een declaratieve laag bovenop Docker waarmee je meerdere containers als één applicatie beheert. Je beschrijft de gewenste toestand in YAML en Compose regelt de rest: bouwen, netwerken, volumes en volgorde van starten.

### Bouwstenen van een `compose.yml`
- `services`: elke service definieert één container (image) met zijn configuratie.
- `volumes`: gedeelde opslag die containers kunnen gebruiken (persistentie of gedeelde bestanden).
- `networks`: virtuele netwerken binnen het project, standaard krijgt elke service een interne hostname gelijk aan de servicenaam.

### Voorbeeld: minimale stack
```yaml
services:
  web:
    image: nginx:1.27-alpine
    ports:
      - "8080:80"
    volumes:
      - ./site:/usr/share/nginx/html:ro
  redis:
    image: redis:7-alpine
```
- Compose maakt automatisch een projectnetwerk `projectnaam_default` waarop `web` en `redis` elkaar vinden via `http://redis:6379`.
- Door `volumes` te gebruiken kun je lokale bestanden delen zonder de image te rebuilden.

### Veelgebruikte keywords binnen een service
- `image`: gebruik een bestaande image uit een registry.
- `build`: laat Compose zelf een image bouwen; `context` wijst naar de map met de Dockerfile, optioneel met `dockerfile`, `args` en `target`.
- `ports`: publiceer poorten naar de host, notatie `host:container` (bijv. `8080:80`).
- `environment`: omgevingsvariabelen voor je container (`KEY=value` of `KEY: value`).
- `volumes`: mount lokale paden of named volumes in de container.
- `depends_on`: definieer een startvolgorde tussen services (let op: dit garandeert niet dat een service “ready” is).
- `restart`: policy om containers automatisch te herstarten (`no`, `on-failure`, `always`, `unless-stopped`).
- `command` en `entrypoint`: overschrijf het standaardcommando van de image.

### Netwerken in Compose
- Standaard maakt Compose één intern bridge-netwerk. Services praten met elkaar via hun servicenaam (`backend` -> `http://mongodb:27017`).
- Je kunt meerdere netwerken definiëren, bijvoorbeeld één voor interne communicatie en één gedeeld met andere projecten.
- Een service kan meerdere netwerken krijgen, waarbij je per netwerk ook `aliases` kunt zetten.

```yaml
networks:
  internal:
  public:
    external: true

services:
  api:
    build: ./api
    networks:
      - internal
  gateway:
    image: nginx:alpine
    networks:
      internal:
      public:
        aliases:
          - gateway.app.local
```
- Met `external: true` gebruik je een reeds bestaand Docker-netwerk (handig voor reverse proxies zoals Traefik).
- Gebruik `docker network ls` en `docker network inspect` om de verbindingen te onderzoeken.

### Handige Compose-commando’s
- `docker compose up` — bouwt (indien nodig) en start alle services; gebruik `-d` voor detached mode.
- `docker compose up --build` — forceert een rebuild, handig na codewijzigingen.
- `docker compose down` — stopt en verwijdert containers, netwerken en standaard-volumes.
- `docker compose ps` — toont de status van alle services.
- `docker compose logs [-f] [service]` — bekijk (live) logs, ideaal om fouten op te sporen.
- `docker compose exec service bash` — voer een command uit in een draaiende container.
- `docker compose config` — valideer en bekijk de samengevoegde configuratie.
- `docker compose run --rm service command` — draai een losse taak (bijv. database migratie) buiten de reguliere lifecycle.

### Best practices
- Houd je projectstructuur overzichtelijk: één map per service met daarin de Dockerfile en code.
- Voeg `.dockerignore`-bestanden toe om build-context kleiner te maken (snelheid en veiligheid).
- Bewaar gevoelige configuratie in `.env`-bestanden en verwijs in Compose met `env_file`.
- Gebruik named volumes voor data die je wilt behouden (`dbdata`, `cachedata`) en bind mounts voor lokale ontwikkelcode.
- Combineer `depends_on` met healthchecks of retries in de applicatie (zoals `connectWithRetry`) zodat services robuust starten.
- Kies duidelijke servicenames; ze worden hostnames binnen het netwerk.
- Automatiseer opruimen met `docker compose down -v` wanneer je testdata wilt verwijderen.

Met deze bouwstenen, voorbeelden en gewoontes beheer je grotere stacks zonder losse `docker run`-commando’s.

## Stap 3: Compose toepassen op `2-fe-be`
In de map `2-fe-be/` vind je de uitbreiding met een Node.js-backend (`api/`), een aangepaste frontend (`frontend/`) en een MongoDB-service. De Compose-definitie staat in `2-fe-be/compose.yml` en ziet er samengevat zo uit:

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

### Wat gebeurt er hier?
- `backend` bouwt de Node-image, luistert op poort 3000 en krijgt de database-URL via `MONGO_URI`.
- `frontend` bouwt een nginx-image met de nieuwe frontend.
- `mongodb` gebruikt de officiële `mongo`-image met een persistent volume (`dbdata`).

### Compose draaien
Navigeer naar de projectroot en start alle services:

```bash
cd /Users/milan/Dev/devops/compose

docker compose -f 2-fe-be/compose.yml up --build
```

- Gebruik `docker compose -f 2-fe-be/compose.yml logs backend` als de backend onverwachts stopt. Vaak wijst een exit code 0 op een proces dat klaar denkt te zijn; controleer of `node server.js` draait en of de database bereikbaar is.
- Stoppen doe je met `Ctrl+C` of:

```bash
docker compose -f 2-fe-be/compose.yml down
```

### Verbeterpunten om te verkennen
- Voeg een `restart: on-failure` toe zodat services automatisch herstarten als ze crashen.
- Breid `depends_on` uit met healthchecks als je zeker wilt zijn dat Mongo klaar is voordat de backend connect.
- Deel `.env`-bestanden voor gevoelige variabelen in plaats van ze in de YAML te hardcoderen.
- Voeg een gedeeld netwerk toe wanneer je services wilt koppelen aan externe reverse proxies of monitoring.

**Conclusie:** begin klein met `docker run`, lever een nette image met een Dockerfile, leer de theorie achter Docker Compose en pas die vervolgens toe op je groeiende stack. Zo begrijp je stap voor stap waarom Compose het werk vereenvoudigt zodra je meer dan één container beheert.
