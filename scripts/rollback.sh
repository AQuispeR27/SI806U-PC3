#!/bin/bash

# ============================================
# Script de Rollback - Sistema Culqui
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}Rollback Script${NC}"
echo -e "${YELLOW}============================================${NC}"

# Verificar argumento
if [ -z "$1" ]; then
    echo -e "${RED}✗ Usage: $0 <version_number>${NC}"
    echo ""
    echo "Available versions:"
    docker images | grep culqui-backend | awk '{print $2}' | grep -v latest
    exit 1
fi

VERSION="$1"

echo -e "${YELLOW}→ Rolling back to version: ${VERSION}${NC}"

# Confirmar
read -p "Are you sure you want to rollback to version $VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 0
fi

# Verificar que las imágenes existen
if ! docker images | grep "culqui-backend.*$VERSION" > /dev/null; then
    echo -e "${RED}✗ Backend image version $VERSION not found${NC}"
    exit 1
fi

if ! docker images | grep "culqui-frontend.*$VERSION" > /dev/null; then
    echo -e "${RED}✗ Frontend image version $VERSION not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Images found${NC}"

# Backup actual antes del rollback
echo -e "${YELLOW}→ Creating backup before rollback...${NC}"
bash scripts/backup-db.sh || echo "Backup skipped"

# Detener contenedores actuales
echo -e "${YELLOW}→ Stopping current containers...${NC}"
docker-compose -f docker-compose.prod.yml down

# Actualizar versión en .env
echo -e "${YELLOW}→ Updating version...${NC}"
sed -i "s/VERSION=.*/VERSION=$VERSION/" .env

# Iniciar con la versión antigua
echo -e "${YELLOW}→ Starting containers with version $VERSION...${NC}"
export VERSION=$VERSION
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
echo -e "${YELLOW}→ Waiting for services...${NC}"
sleep 20

# Health checks
echo -e "${YELLOW}→ Running health checks...${NC}"

if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is healthy${NC}"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
    docker logs culqui-backend --tail 50
    exit 1
fi

if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Frontend is healthy${NC}"
else
    echo -e "${RED}✗ Frontend health check failed${NC}"
    docker logs culqui-frontend --tail 50
    exit 1
fi

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✓ Rollback to version $VERSION completed!${NC}"
echo -e "${GREEN}============================================${NC}"
