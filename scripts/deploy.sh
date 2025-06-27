#!/bin/bash

# Personal Infrastructure Deploy Script
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT=${1:-dev}

echo "Deploying Personal Infrastructure - Environment: $ENVIRONMENT"

cd "$PROJECT_ROOT"

# Create necessary networks
echo "Creating Docker networks..."
docker network create web 2>/dev/null || echo "Network 'web' already exists"
docker network create backend 2>/dev/null || echo "Network 'backend' already exists"

# Set proper permissions for Traefik acme.json
echo "Setting up Traefik permissions..."
chmod 600 docker/traefik/acme.json

# Create data directories if they don't exist
echo "Creating data directories..."
mkdir -p data/{postgres,redis,qdrant}
mkdir -p nas/{media,samples}

# Deploy based on environment
case $ENVIRONMENT in
  "dev")
    echo "Deploying development environment..."
    cd docker
    docker-compose up -d
    ;;
  "prod")
    echo "Deploying production environment..."
    cd docker
    docker-compose -f docker-compose.yml up -d
    docker-compose -f nextcloud/docker-compose.nextcloud.yml up -d
    docker-compose -f samba/docker-compose.samba.yml up -d
    ;;
  "nextcloud")
    echo "Deploying Nextcloud only..."
    cd docker
    docker-compose -f nextcloud/docker-compose.nextcloud.yml up -d
    ;;
  "samba")
    echo "Deploying Samba only..."
    cd docker
    docker-compose -f samba/docker-compose.samba.yml up -d
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    echo "Available options: dev, prod, nextcloud, samba"
    exit 1
    ;;
esac

echo "Deployment completed!"
echo "Traefik Dashboard: http://localhost:8080"
echo "Services should be available shortly..."

# Show running containers
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 