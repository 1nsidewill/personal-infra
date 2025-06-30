#!/bin/bash

# Personal Infrastructure Deploy Script
set -e

echo "🚀 Deploying Personal Infrastructure..."

# Create Docker network
echo "Creating Docker network..."
docker network create web 2>/dev/null || echo "Network 'web' already exists"

# Set proper permissions
echo "Setting permissions..."
chmod 600 docker/traefik/acme.json

# Create data directories
echo "Creating data directories..."
mkdir -p data/{postgres,redis,nextcloud} nas/media

# Deploy services
echo "Starting services..."
docker compose up -d

echo ""
echo "✅ Deployment completed!"
echo "🌐 Nextcloud: http://localhost"
echo "📊 Traefik Dashboard: http://localhost:8080"
echo ""

# Show running containers
echo "Running containers:"
docker compose ps 