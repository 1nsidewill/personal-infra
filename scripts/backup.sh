#!/bin/bash

# Personal Infrastructure Backup Script
set -e

# Configuration
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Starting backup at $(date)"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Backing up PostgreSQL..."
docker exec postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_backup_$DATE.sql"

# Backup Qdrant data
echo "Backing up Qdrant data..."
tar -czf "$BACKUP_DIR/qdrant_backup_$DATE.tar.gz" -C "$PROJECT_ROOT/data" qdrant/

# Backup Redis (if needed)
echo "Backing up Redis..."
docker exec redis redis-cli BGSAVE
sleep 5
cp "$PROJECT_ROOT/data/redis/dump.rdb" "$BACKUP_DIR/redis_backup_$DATE.rdb"

# Backup NAS data
echo "Backing up NAS data..."
tar -czf "$BACKUP_DIR/nas_backup_$DATE.tar.gz" -C "$PROJECT_ROOT" nas/

# Backup Docker compose files
echo "Backing up Docker configurations..."
tar -czf "$BACKUP_DIR/docker_config_backup_$DATE.tar.gz" -C "$PROJECT_ROOT" docker/

# Clean up old backups (keep last 7 days)
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*backup_*" -type f -mtime +7 -delete

echo "Backup completed at $(date)"
echo "Backup files saved to: $BACKUP_DIR" 