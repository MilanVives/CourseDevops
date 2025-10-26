#!/bin/bash

echo "=== Nginx Reverse Proxy Demo Setup ==="

# Cleanup any existing containers
echo "Cleaning up existing containers..."
docker stop webapp1 webapp2 nginx-proxy 2>/dev/null || true
docker rm webapp1 webapp2 nginx-proxy 2>/dev/null || true

# Create demo content directories
mkdir -p webapp1 webapp2 ssl

# Create content for webapp1
cat > webapp1/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Web App 1</title>
    <style>
        body { font-family: Arial; background: #e3f2fd; padding: 50px; text-align: center; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Web Application 1</h1>
        <p>Deze applicatie draait achter een Nginx reverse proxy</p>
        <p><strong>Container:</strong> webapp1</p>
        <p><strong>Bereikbaar via:</strong> app1.localhost</p>
    </div>
</body>
</html>
EOF

# Create content for webapp2
cat > webapp2/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Web App 2</title>
    <style>
        body { font-family: Arial; background: #f3e5f5; padding: 50px; text-align: center; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌟 Web Application 2</h1>
        <p>Deze applicatie draait ook achter een Nginx reverse proxy</p>
        <p><strong>Container:</strong> webapp2</p>
        <p><strong>Bereikbaar via:</strong> app2.localhost</p>
    </div>
</body>
</html>
EOF

# Start backend web applications
echo "Starting backend web applications..."
docker run -d --name webapp1 \
  -v $(pwd)/webapp1:/usr/share/nginx/html:ro \
  nginx:alpine

docker run -d --name webapp2 \
  -v $(pwd)/webapp2:/usr/share/nginx/html:ro \
  nginx:alpine

# Get container IPs
WEBAPP1_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' webapp1)
WEBAPP2_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' webapp2)

echo "webapp1 IP: $WEBAPP1_IP"
echo "webapp2 IP: $WEBAPP2_IP"

# Create nginx configuration
cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream webapp1 {
        server $WEBAPP1_IP:80;
    }
    
    upstream webapp2 {
        server $WEBAPP2_IP:80;
    }
    
    server {
        listen 80;
        server_name app1.localhost;
        
        location / {
            proxy_pass http://webapp1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    
    server {
        listen 80;
        server_name app2.localhost;
        
        location / {
            proxy_pass http://webapp2;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    
    # Default server for andere domeinen
    server {
        listen 80 default_server;
        server_name _;
        
        location / {
            return 200 'Nginx Reverse Proxy is actief!\nProbeer: http://app1.localhost of http://app2.localhost\n';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Start nginx reverse proxy
echo "Starting Nginx reverse proxy..."
docker run -d --name nginx-proxy \
  -p 80:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Test de reverse proxy:"
echo "1. http://app1.localhost - Web App 1"
echo "2. http://app2.localhost - Web App 2"
echo "3. http://localhost - Default server"
echo ""
echo "Voeg deze regels toe aan je /etc/hosts bestand (als je localhost gebruikt):"
echo "127.0.0.1 app1.localhost"
echo "127.0.0.1 app2.localhost"
echo ""
echo "Stop alles met: docker stop webapp1 webapp2 nginx-proxy && docker rm webapp1 webapp2 nginx-proxy"
EOF

chmod +x "/Users/milan/Library/CloudStorage/OneDrive-HogeschoolVIVES/Vives/General/9-Devops-General/CourseMD/08-Ingress-and-Reverse-Proxies/nginx-examples/setup-demo.sh"