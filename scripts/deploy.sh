#!/bin/bash

# ============================================
# Script de Deploy - Sistema Culqui
# ============================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "============================================"
echo "  🚀 Culqui Deployment Script"
echo "============================================"
echo -e "${NC}"

# Variables
ENVIRONMENT="${1:-development}"
VERSION="${VERSION:-latest}"

# Validar entorno
if [[ ! "$ENVIRONMENT" =~ ^(development|production)$ ]]; then
    echo -e "${RED}✗ Invalid environment: $ENVIRONMENT${NC}"
    echo "Usage: $0 [development|production]"
    exit 1
fi

echo -e "${GREEN}Environment: ${ENVIRONMENT}${NC}"
echo -e "${GREEN}Version: ${VERSION}${NC}"
echo ""

# ============================================
# Pre-deployment checks
# ============================================
echo -e "${YELLOW}→ Running pre-deployment checks...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found${NC}"

# Check .env file
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found, using defaults${NC}"
    cp .env.example .env
fi
echo -e "${GREEN}✓ Environment variables configured${NC}"

echo ""

# ============================================
# Backup (Production only)
# ============================================
if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${YELLOW}→ Creating database backup...${NC}"
    if [ -f scripts/backup-db.sh ]; then
        bash scripts/backup-db.sh
    else
        echo -e "${YELLOW}⚠ Backup script not found, skipping${NC}"
    fi
    echo ""
fi

# ============================================
# Pull latest images (if using registry)
# ============================================
echo -e "${YELLOW}→ Pulling latest images...${NC}"

if [ "$ENVIRONMENT" = "production" ]; then
    docker-compose -f docker-compose.prod.yml pull || echo "Using local images"
else
    docker-compose pull || echo "Using local images"
fi

echo ""

# ============================================
# Stop current containers
# ============================================
echo -e "${YELLOW}→ Stopping current containers...${NC}"

if [ "$ENVIRONMENT" = "production" ]; then
    docker-compose -f docker-compose.prod.yml down --remove-orphans
else
    docker-compose down --remove-orphans
fi

echo -e "${GREEN}✓ Containers stopped${NC}"
echo ""

# ============================================
# Start new containers
# ============================================
echo -e "${YELLOW}→ Starting new containers...${NC}"

if [ "$ENVIRONMENT" = "production" ]; then
    docker-compose -f docker-compose.prod.yml up -d
else
    docker-compose up -d
fi

echo -e "${GREEN}✓ Containers started${NC}"
echo ""

# ============================================
# Wait for services to be ready
# ============================================
echo -e "${YELLOW}→ Waiting for services to be ready...${NC}"

# Wait for backend
echo -n "  Waiting for backend..."
for i in {1..30}; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo -e " ${GREEN}OK${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

# Wait for frontend
echo -n "  Waiting for frontend..."
for i in {1..30}; do
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e " ${GREEN}OK${NC}"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""

# ============================================
# Health checks
# ============================================
echo -e "${YELLOW}→ Running health checks...${NC}"

# Backend health check
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend is healthy${NC}"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
    echo -e "${YELLOW}Showing backend logs:${NC}"
    docker logs culqui-backend --tail 50
    exit 1
fi

# Frontend health check
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Frontend is healthy${NC}"
else
    echo -e "${RED}✗ Frontend health check failed${NC}"
    echo -e "${YELLOW}Showing frontend logs:${NC}"
    docker logs culqui-frontend --tail 50
    exit 1
fi

# Database health check
if docker exec culqui-mysql mysqladmin ping -h localhost -u root -p"$DB_PASSWORD" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database is healthy${NC}"
else
    echo -e "${RED}✗ Database health check failed${NC}"
    exit 1
fi

echo ""

# ============================================
# Display status
# ============================================
echo -e "${BLUE}"
echo "============================================"
echo "  ✓ Deployment completed successfully!"
echo "============================================"
echo -e "${NC}"

echo "Services running:"
docker-compose ps

echo ""
echo "Access your application:"
echo "  🌐 Frontend: http://localhost:3000"
echo "  🔌 Backend:  http://localhost:5000"
echo "  📊 MySQL:    localhost:3306"

echo ""
echo "Useful commands:"
echo "  View logs:    docker-compose logs -f"
echo "  Stop all:     docker-compose down"
echo "  Restart:      docker-compose restart"

echo ""
echo -e "${GREEN}Deployment completed! 🎉${NC}"
