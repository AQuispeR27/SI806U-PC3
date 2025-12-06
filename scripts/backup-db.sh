#!/bin/bash

# ============================================
# Script de Backup de Base de Datos
# ============================================

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Database Backup Script${NC}"
echo -e "${GREEN}============================================${NC}"

# Variables
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
CONTAINER_NAME="culqui-mysql"
DB_NAME="${DB_NAME:-culqui_db}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-root_password}"

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Nombre del archivo de backup
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_${DATE}.sql"

echo -e "${YELLOW}→ Creating backup...${NC}"
echo "  Database: $DB_NAME"
echo "  File: $BACKUP_FILE"

# Realizar backup
if docker exec "$CONTAINER_NAME" mysqldump \
    -u"$DB_USER" \
    -p"$DB_PASSWORD" \
    "$DB_NAME" > "$BACKUP_FILE"; then

    echo -e "${GREEN}✓ Backup created successfully!${NC}"

    # Comprimir backup
    gzip "$BACKUP_FILE"
    echo -e "${GREEN}✓ Backup compressed: ${BACKUP_FILE}.gz${NC}"

    # Mostrar tamaño
    SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    echo "  Size: $SIZE"

    # Limpiar backups antiguos (mantener solo los últimos 7)
    echo -e "${YELLOW}→ Cleaning old backups (keeping last 7)...${NC}"
    ls -t "$BACKUP_DIR"/backup_*.sql.gz | tail -n +8 | xargs -r rm
    echo -e "${GREEN}✓ Old backups cleaned${NC}"

else
    echo -e "${RED}✗ Backup failed!${NC}"
    exit 1
fi

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Backup completed successfully${NC}"
echo -e "${GREEN}============================================${NC}"
