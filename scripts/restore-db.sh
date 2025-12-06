#!/bin/bash

# ============================================
# Script de Restauración de Base de Datos
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Database Restore Script${NC}"
echo -e "${GREEN}============================================${NC}"

# Variables
BACKUP_DIR="./backups"
CONTAINER_NAME="culqui-mysql"
DB_NAME="${DB_NAME:-culqui_db}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-root_password}"

# Verificar que se pasó un archivo de backup
if [ -z "$1" ]; then
    echo -e "${RED}✗ Usage: $0 <backup_file.sql.gz>${NC}"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/backup_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Verificar que el archivo existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}✗ Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}→ Restoring from backup...${NC}"
echo "  File: $BACKUP_FILE"
echo "  Database: $DB_NAME"

# Confirmar
read -p "Are you sure you want to restore? This will overwrite current data (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

# Descomprimir si está comprimido
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo -e "${YELLOW}→ Decompressing backup...${NC}"
    gunzip -c "$BACKUP_FILE" > /tmp/restore_temp.sql
    RESTORE_FILE="/tmp/restore_temp.sql"
else
    RESTORE_FILE="$BACKUP_FILE"
fi

# Restaurar
echo -e "${YELLOW}→ Restoring database...${NC}"
if docker exec -i "$CONTAINER_NAME" mysql \
    -u"$DB_USER" \
    -p"$DB_PASSWORD" \
    "$DB_NAME" < "$RESTORE_FILE"; then

    echo -e "${GREEN}✓ Database restored successfully!${NC}"

    # Limpiar archivo temporal
    [ -f /tmp/restore_temp.sql ] && rm /tmp/restore_temp.sql

else
    echo -e "${RED}✗ Restore failed!${NC}"
    [ -f /tmp/restore_temp.sql ] && rm /tmp/restore_temp.sql
    exit 1
fi

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Restore completed successfully${NC}"
echo -e "${GREEN}============================================${NC}"
