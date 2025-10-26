#!/bin/bash

echo "=== SSL Certificate Generation for Nginx Demo ==="

# Create ssl directory if it doesn't exist
mkdir -p ssl

# Generate private key
echo "Generating private key..."
openssl genrsa -out ssl/nginx.key 2048

# Generate certificate signing request
echo "Generating certificate signing request..."
openssl req -new -key ssl/nginx.key -out ssl/nginx.csr -subj "/C=BE/ST=WestVlaanderen/L=Kortrijk/O=VIVES/CN=*.localhost"

# Generate self-signed certificate
echo "Generating self-signed certificate..."
openssl x509 -req -days 365 -in ssl/nginx.csr -signkey ssl/nginx.key -out ssl/nginx.crt

# Set proper permissions
chmod 600 ssl/nginx.key
chmod 644 ssl/nginx.crt

echo ""
echo "SSL certificates generated successfully!"
echo "- Private key: ssl/nginx.key"
echo "- Certificate: ssl/nginx.crt"
echo ""
echo "Note: This is a self-signed certificate for development only."
echo "Browsers will show a security warning which you can safely ignore for testing."