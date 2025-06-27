#!/bin/bash

# Personal Infrastructure Deploy Script
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT=${1:-dev}
ENV_FILE="$PROJECT_ROOT/.env"

echo "Deploying Personal Infrastructure - Environment: $ENVIRONMENT"

cd "$PROJECT_ROOT"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    echo "Please create .env file with required environment variables"
    exit 1
fi

echo "✅ Using environment file: $ENV_FILE"

# Load and validate environment variables
echo "📋 Loading environment variables..."
source "$ENV_FILE"

# Validate critical variables
if [ -z "$NEXTCLOUD_DOMAIN" ]; then
    echo "❌ Error: NEXTCLOUD_DOMAIN not set in .env"
    exit 1
fi

if [ -z "$ACME_EMAIL" ]; then
    echo "❌ Error: ACME_EMAIL not set in .env"
    exit 1
fi

echo "✅ NEXTCLOUD_DOMAIN: $NEXTCLOUD_DOMAIN"
echo "✅ ACME_EMAIL: $ACME_EMAIL"

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
    echo "🚀 Deploying development environment..."
    echo "📋 Stopping existing containers..."
    cd docker
    docker compose --env-file "$ENV_FILE" down --remove-orphans 2>/dev/null || true
    echo "🔄 Starting development services..."
    docker compose --env-file "$ENV_FILE" up -d
    ;;
  "prod")
    echo "🚀 Deploying production environment..."
    echo "📋 Stopping existing containers..."
    cd docker
    docker compose --env-file "$ENV_FILE" \
      -f docker-compose.yml \
      -f nextcloud/docker-compose.nextcloud.yml \
      -f samba/docker-compose.samba.yml \
      down --remove-orphans 2>/dev/null || true
    echo "🔄 Starting production services..."
    docker compose --env-file "$ENV_FILE" \
      -f docker-compose.yml \
      -f nextcloud/docker-compose.nextcloud.yml \
      -f samba/docker-compose.samba.yml \
      up -d
    ;;
  "nextcloud")
    echo "🚀 Deploying Nextcloud only..."
    echo "📋 Stopping existing containers..."
    cd docker
    docker compose --env-file "$ENV_FILE" \
      -f docker-compose.yml \
      -f nextcloud/docker-compose.nextcloud.yml \
      down --remove-orphans 2>/dev/null || true
    echo "🔄 Starting Nextcloud services..."
    docker compose --env-file "$ENV_FILE" \
      -f docker-compose.yml \
      -f nextcloud/docker-compose.nextcloud.yml \
      up -d
    ;;
  "samba")
    echo "🚀 Deploying Samba only..."
    echo "📋 Stopping existing containers..."
    cd docker
    docker compose --env-file "$ENV_FILE" \
      -f docker-compose.yml \
      -f samba/docker-compose.samba.yml \
      down --remove-orphans 2>/dev/null || true
    echo "🔄 Starting Samba services..."
    docker compose --env-file "$ENV_FILE" \
      -f docker-compose.yml \
      -f samba/docker-compose.samba.yml \
      up -d
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    echo "Available options: dev, prod, nextcloud, samba"
    exit 1
    ;;
esac

echo ""
echo "🎉 Deployment completed!"
echo "📊 Traefik Dashboard: http://localhost:8080"

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 5

# Show running containers
echo ""
echo "🐳 Running containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# Validate environment variables in containers
echo ""
echo "🔍 Validating environment variables..."
if docker ps | grep -q nextcloud; then
    echo "📋 Nextcloud environment variables:"
    docker exec nextcloud env | grep "NEXTCLOUD_" | head -5 || echo "  No NEXTCLOUD_ variables found"
fi

# Show access URLs
echo ""
echo "🌐 Access URLs:"
if [ ! -z "$NEXTCLOUD_DOMAIN" ]; then
    echo "  Nextcloud: https://$NEXTCLOUD_DOMAIN"
fi
echo "  Traefik Dashboard: http://localhost:8080"

echo ""
echo "✅ All services should be available shortly!"
echo "💡 Check logs: docker logs <container_name>" 