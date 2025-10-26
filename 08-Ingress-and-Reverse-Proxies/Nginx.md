# Nginx als Reverse Proxy

## Inleiding

Nginx is een van de meest populaire webservers en reverse proxy servers ter wereld. In deze tutorial leren we hoe je Nginx kunt gebruiken als reverse proxy om verkeer door te sturen naar backend containers. We behandelen zowel HTTP als HTTPS configuraties met SSL certificaten.

## Wat is een Reverse Proxy?

Een reverse proxy is een server die zich tussen clients en backend servers plaatst. In plaats van dat clients direct verbinding maken met de backend servers, maken ze verbinding met de reverse proxy, die vervolgens de verzoeken doorstuurt naar de juiste backend server.

### Voordelen van een Reverse Proxy:
- **Load Balancing**: Verkeer verdelen over meerdere backend servers
- **SSL Termination**: Centraal beheer van SSL certificaten
- **Caching**: Statische content cachen voor betere performance
- **Beveiliging**: Backend servers zijn niet direct toegankelijk van buitenaf
- **Compressie**: Content comprimeren voor snellere overdracht

## Basis Nginx Reverse Proxy Setup

### Stap 1: Een eenvoudige webapplicatie container

Laten we beginnen met een eenvoudige webapplicatie die we willen bereiken via een reverse proxy:

```bash
# Start een simpele web container
docker run -d --name webapp1 -p 8081:80 nginx:alpine
docker run -d --name webapp2 -p 8082:80 nginx:alpine

# Voeg custom content toe aan webapp1
docker exec webapp1 sh -c 'echo "<h1>Web App 1</h1><p>Running on port 8081</p>" > /usr/share/nginx/html/index.html'

# Voeg custom content toe aan webapp2
docker exec webapp2 sh -c 'echo "<h1>Web App 2</h1><p>Running on port 8082</p>" > /usr/share/nginx/html/index.html'
```

### Stap 2: Nginx Configuratie voor Reverse Proxy

Maak een nginx configuratie bestand:

```nginx
# nginx.conf - Hoofdconfiguratie bestand (bestandsnaam kun je zelf kiezen)

# EVENTS BLOK - Verplicht hoofdblok voor worker proces configuratie
events {
    # worker_connections: Configureerbare waarde (512-4096 zijn gebruikelijke waardes)
    # Bepaalt max aantal gelijktijdige connecties per worker proces
    worker_connections 1024;
}

# HTTP BLOK - Verplicht hoofdblok voor alle HTTP gerelateerde configuratie
http {
    # UPSTREAM BLOK - Optioneel blok om groepen van backend servers te definiëren
    # "webapp1" is een zelfgekozen naam die je later kunt gebruiken in proxy_pass
    upstream webapp1 {
        # server: Verplichte directive binnen upstream blok
        # host.docker.internal: Docker's speciale hostname voor toegang tot host machine (vaste naam)
        # :8081: Configureerbare poortnummer waar je backend service draait
        server host.docker.internal:8081;
    }
    
    # Tweede upstream groep met zelfgekozen naam "webapp2"
    upstream webapp2 {
        # Andere configureerbare poort voor tweede service
        server host.docker.internal:8082;
    }
    
    # SERVER BLOK - Definieert een virtuele server (vergelijkbaar met virtual host)
    server {
        # listen: Verplichte directive - poort waarop nginx luistert
        # 80: Configureerbare poort (standaard HTTP poort, kan elke vrije poort zijn)
        listen 80;
        
        # server_name: Verplichte directive voor host-based routing
        # app1.localhost: Zelfgekozen domeinnaam waarop deze server reageert
        # Kan elk domein zijn (app1.example.com, mijnapp.nl, etc.)
        server_name app1.localhost;
        
        # LOCATION BLOK - Definieert hoe verschillende URL paths worden afgehandeld
        # "/" is een pad matcher - betekent alle requests die beginnen met /
        # Je kunt ook specifieke paden gebruiken zoals /api/, /admin/, etc.
        location / {
            # proxy_pass: Verplichte directive voor reverse proxy functionaliteit
            # http://webapp1: Verwijst naar de upstream groep "webapp1" die hierboven gedefinieerd is
            # "http://" protocol prefix is verplicht
            proxy_pass http://webapp1;
            
            # proxy_set_header: Optionele directives om headers door te geven aan backend
            # Host: Vaste header naam (HTTP standaard)
            # $host: Nginx ingebouwde variabele met de server_name waarde
            proxy_set_header Host $host;
            
            # X-Real-IP: Zelfgekozen header naam (conventie voor client IP)
            # $remote_addr: Nginx ingebouwde variabele met het echte client IP adres
            proxy_set_header X-Real-IP $remote_addr;
            
            # X-Forwarded-For: Standaard header naam voor proxy chains
            # $proxy_add_x_forwarded_for: Nginx ingebouwde variabele die IP chain bijhoudt
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            
            # X-Forwarded-Proto: Standaard header naam voor protocol info
            # $scheme: Nginx ingebouwde variabele (http of https)
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    # Tweede SERVER BLOK voor verschillende applicatie
    server {
        # Zelfde poort als eerste server - onderscheid gebeurt via server_name
        listen 80;
        
        # Andere zelfgekozen domeinnaam voor routing naar tweede applicatie
        server_name app2.localhost;
        
        # Zelfde location configuratie maar dan naar andere upstream
        location / {
            # Verwijst naar upstream groep "webapp2"
            proxy_pass http://webapp2;
            
            # Identieke header configuratie (standaard best practice)
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### Stap 3: Nginx Reverse Proxy Container Starten

```bash
# Start nginx reverse proxy container
docker run -d --name nginx-proxy \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine
```

Nu kun je:
- `http://app1.localhost` bezoeken om webapp1 te bereiken
- `http://app2.localhost` bezoeken om webapp2 te bereiken

## Docker Compose Setup

Een meer praktische setup met Docker Compose:

```yaml
# docker-compose.yml
version: '3.8'

services:
  nginx-proxy:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - webapp1
      - webapp2
    networks:
      - app-network

  webapp1:
    image: nginx:alpine
    volumes:
      - ./webapp1:/usr/share/nginx/html:ro
    networks:
      - app-network

  webapp2:
    image: nginx:alpine
    volumes:
      - ./webapp2:/usr/share/nginx/html:ro
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

Bijbehorende nginx configuratie voor Docker Compose:

```nginx
# nginx.conf voor Docker Compose
events {
    worker_connections 1024;
}

http {
    upstream webapp1 {
        server webapp1:80;
    }
    
    upstream webapp2 {
        server webapp2:80;
    }
    
    server {
        listen 80;
        server_name app1.localhost;
        
        location / {
            proxy_pass http://webapp1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    server {
        listen 80;
        server_name app2.localhost;
        
        location / {
            proxy_pass http://webapp2;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

## SSL Certificaten met Nginx

### Zelf-ondertekende Certificaten voor Ontwikkeling

Voor ontwikkeling kun je zelf-ondertekende certificaten gebruiken:

```bash
# Maak SSL directory
mkdir ssl

# Genereer private key
openssl genrsa -out ssl/nginx.key 2048

# Genereer certificate signing request
openssl req -new -key ssl/nginx.key -out ssl/nginx.csr -subj "/C=BE/ST=WestVlaanderen/L=Kortrijk/O=VIVES/CN=*.localhost"

# Genereer zelf-ondertekend certificaat
openssl x509 -req -days 365 -in ssl/nginx.csr -signkey ssl/nginx.key -out ssl/nginx.crt
```

### Nginx Configuratie met SSL

```nginx
# nginx-ssl.conf
events {
    worker_connections 1024;
}

http {
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name app1.localhost app2.localhost;
        return 301 https://$server_name$request_uri;
    }
    
    upstream webapp1 {
        server webapp1:80;
    }
    
    upstream webapp2 {
        server webapp2:80;
    }
    
    # HTTPS server voor app1
    server {
        listen 443 ssl;
        server_name app1.localhost;
        
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        # SSL configuratie
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        
        location / {
            proxy_pass http://webapp1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    # HTTPS server voor app2
    server {
        listen 443 ssl;
        server_name app2.localhost;
        
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        
        location / {
            proxy_pass http://webapp2;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

## Let's Encrypt met Certbot

Voor productie omgevingen kun je gratis SSL certificaten krijgen van Let's Encrypt:

### Handmatige Setup

```bash
# Installeer certbot
sudo apt update
sudo apt install certbot

# Verkrijg certificaat (vervang domain.com met je echte domein)
sudo certbot certonly --standalone -d app1.domain.com -d app2.domain.com

# Certificaten worden opgeslagen in /etc/letsencrypt/live/
```

### Nginx Configuratie met Let's Encrypt

```nginx
# nginx-letsencrypt.conf
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name app1.domain.com app2.domain.com;
        
        # Let's Encrypt challenge location
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        # Redirect everything else to HTTPS
        location / {
            return 301 https://$server_name$request_uri;
        }
    }
    
    upstream webapp1 {
        server webapp1:80;
    }
    
    upstream webapp2 {
        server webapp2:80;
    }
    
    server {
        listen 443 ssl;
        server_name app1.domain.com;
        
        ssl_certificate /etc/letsencrypt/live/app1.domain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/app1.domain.com/privkey.pem;
        
        location / {
            proxy_pass http://webapp1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    server {
        listen 443 ssl;
        server_name app2.domain.com;
        
        ssl_certificate /etc/letsencrypt/live/app2.domain.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/app2.domain.com/privkey.pem;
        
        location / {
            proxy_pass http://webapp2;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

## Load Balancing

Nginx kan ook load balancing doen tussen meerdere backend servers:

```nginx
# nginx-loadbalancer.conf
events {
    worker_connections 1024;
}

http {
    # Load balancing configuratie
    upstream webapp_cluster {
        # Verschillende load balancing methodes:
        # Round-robin (default)
        server webapp1:80;
        server webapp2:80;
        server webapp3:80;
        
        # Weighted round-robin
        # server webapp1:80 weight=3;
        # server webapp2:80 weight=2;
        # server webapp3:80 weight=1;
        
        # Least connections
        # least_conn;
        
        # IP hash (sticky sessions)
        # ip_hash;
    }
    
    server {
        listen 80;
        server_name app.localhost;
        
        location / {
            proxy_pass http://webapp_cluster;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

## Geavanceerde Configuratie

### Caching

```nginx
http {
    # Cache zone definitie
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=10g 
                     inactive=60m use_temp_path=off;
    
    server {
        listen 80;
        server_name app.localhost;
        
        location / {
            proxy_cache my_cache;
            proxy_cache_valid 200 1h;
            proxy_cache_valid 404 1m;
            proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
            
            proxy_pass http://webapp1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Cache headers
            add_header X-Cache-Status $upstream_cache_status;
        }
        
        # Static files - langere cache
        location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
            proxy_cache my_cache;
            proxy_cache_valid 200 24h;
            proxy_pass http://webapp1;
        }
    }
}
```

### Rate Limiting

```nginx
http {
    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    
    server {
        listen 80;
        server_name app.localhost;
        
        # Login endpoint - max 5 requests per minuut
        location /login {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://webapp1;
        }
        
        # API endpoint - max 10 requests per seconde
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://webapp1;
        }
        
        location / {
            proxy_pass http://webapp1;
        }
    }
}
```

## Docker Compose Complete Voorbeeld

Hier is een complete Docker Compose setup met Nginx reverse proxy, SSL en meerdere services:

```yaml
# docker-compose.yml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/cache:/var/cache/nginx
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - frontend
      - api
      - admin
    networks:
      - app-network

  frontend:
    image: nginx:alpine
    container_name: frontend-app
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
    networks:
      - app-network

  api:
    image: node:alpine
    container_name: api-server
    working_dir: /app
    volumes:
      - ./api:/app
    command: npm start
    environment:
      - NODE_ENV=production
    networks:
      - app-network

  admin:
    image: nginx:alpine
    container_name: admin-panel
    volumes:
      - ./admin:/usr/share/nginx/html:ro
    networks:
      - app-network

  db:
    image: postgres:13
    container_name: database
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: dbpass
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  db_data:

networks:
  app-network:
    driver: bridge
```

## Monitoring en Logging

### Nginx Status Module

```nginx
server {
    listen 8080;
    server_name localhost;
    
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 172.16.0.0/12; # Docker networks
        deny all;
    }
}
```

### Structured Logging

```nginx
http {
    log_format json_combined escape=json
        '{'
            '"time_local":"$time_local",'
            '"remote_addr":"$remote_addr",'
            '"remote_user":"$remote_user",'
            '"request":"$request",'
            '"status": "$status",'
            '"body_bytes_sent":"$body_bytes_sent",'
            '"request_time":"$request_time",'
            '"http_referrer":"$http_referer",'
            '"http_user_agent":"$http_user_agent",'
            '"upstream_addr":"$upstream_addr",'
            '"upstream_response_time":"$upstream_response_time"'
        '}';
    
    access_log /var/log/nginx/access.log json_combined;
}
```

## Best Practices

### 1. Security Headers

```nginx
server {
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Hide nginx version
    server_tokens off;
}
```

### 2. Timeout Configuratie

```nginx
http {
    # Client timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout 15;
    send_timeout 10;
    
    # Proxy timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
```

### 3. Buffer Sizes

```nginx
http {
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;
}
```

## Troubleshooting

### Veelvoorkomende Problemen

1. **502 Bad Gateway**
   - Check of backend service draait
   - Controleer netwerkconnectiviteit
   - Verify upstream configuratie

2. **SSL Certificaat Fouten**
   - Controleer certificaat pad
   - Verify certificaat validiteit
   - Check private key permissions

3. **Performance Issues**
   - Monitor cache hit ratio
   - Check upstream response times
   - Analyze nginx access logs

### Debug Logging

```nginx
# Enable debug logging
error_log /var/log/nginx/error.log debug;

# Voor specifieke locaties
location /api/ {
    error_log /var/log/nginx/api_debug.log debug;
    proxy_pass http://api_backend;
}
```

## Conclusie

Nginx is een krachtige en flexibele reverse proxy server die essentieel is voor moderne web architecturen. Door de juiste configuratie kun je:

- Meerdere services achter één eindpunt plaatsen
- SSL certificaten centraal beheren
- Load balancing implementeren
- Caching en performance optimalisatie toepassen
- Security headers en rate limiting configureren

Met Docker en Docker Compose wordt het beheer van Nginx reverse proxy setups nog eenvoudiger en reproduceerbaar.