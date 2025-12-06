# 🐳 Guía de Docker - Sistema de Login Culqui

Guía completa para ejecutar el sistema de login de Culqui usando Docker y Docker Compose.

---

## 📋 Contenido

1. [Requisitos](#requisitos)
2. [Estructura de Docker](#estructura-de-docker)
3. [Configuración Rápida](#configuración-rápida)
4. [Desarrollo con Docker](#desarrollo-con-docker)
5. [Producción con Docker](#producción-con-docker)
6. [Scripts Útiles](#scripts-útiles)
7. [Comandos Comunes](#comandos-comunes)
8. [Troubleshooting](#troubleshooting)

---

## ✅ Requisitos

- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- **RAM:** 4GB mínimo
- **Disk:** 5GB espacio libre

### Instalar Docker

#### Ubuntu/Debian
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### macOS
```bash
brew install --cask docker
```

#### Windows
Descargar Docker Desktop desde: https://www.docker.com/products/docker-desktop

---

## 🏗️ Estructura de Docker

```
PC3-SI806U/
├── docker-compose.yml              # Desarrollo
├── docker-compose.prod.yml         # Producción
├── .env.example                    # Variables de entorno
│
├── 5-pagina-web-login/
│   ├── backend/
│   │   ├── Dockerfile             # Imagen del backend
│   │   └── .dockerignore
│   │
│   └── frontend/
│       ├── Dockerfile             # Imagen del frontend
│       ├── nginx.conf             # Configuración NGINX
│       └── .dockerignore
│
└── scripts/
    ├── backup-db.sh               # Backup de BD
    ├── restore-db.sh              # Restaurar BD
    ├── deploy.sh                  # Script de deployment
    └── rollback.sh                # Rollback a versión anterior
```

---

## ⚡ Configuración Rápida

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/PC3-SI806U.git
cd PC3-SI806U
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
nano .env  # Editar con tus valores
```

### 3. Iniciar todos los servicios

```bash
docker-compose up -d
```

### 4. Verificar que todo esté corriendo

```bash
docker-compose ps
```

Deberías ver:
```
NAME                IMAGE                  STATUS
culqui-backend      culqui-backend:latest  Up 30 seconds (healthy)
culqui-frontend     culqui-frontend:latest Up 30 seconds (healthy)
culqui-mysql        mysql:8.0              Up 45 seconds (healthy)
```

### 5. Acceder a la aplicación

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:5000
- **MySQL:** localhost:3306

---

## 🛠️ Desarrollo con Docker

### Iniciar servicios en modo desarrollo

```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f backend
```

### Rebuild después de cambios

```bash
# Rebuild todos los servicios
docker-compose up -d --build

# Rebuild solo backend
docker-compose up -d --build backend

# Rebuild solo frontend
docker-compose up -d --build frontend
```

### Ejecutar comandos dentro de contenedores

```bash
# Backend - Ejecutar npm install
docker-compose exec backend npm install

# Backend - Acceder a shell
docker-compose exec backend sh

# MySQL - Acceder a consola
docker-compose exec mysql mysql -u root -p
```

### Hot Reload (opcional)

Para habilitar hot reload en desarrollo, modificar `docker-compose.yml`:

```yaml
backend:
  volumes:
    - ./5-pagina-web-login/backend/src:/app/src:ro
  command: npm run dev  # Usar nodemon
```

---

## 🚀 Producción con Docker

### Deployment de producción

```bash
# Usar script de deployment
./scripts/deploy.sh production

# O manualmente
docker-compose -f docker-compose.prod.yml up -d
```

### Variables de entorno para producción

Editar `.env`:

```env
NODE_ENV=production
DB_PASSWORD=strong_password_here
JWT_SECRET=very_secure_secret_key
FRONTEND_URL=https://culqui.com
VERSION=1.0.0
```

### Build de imágenes para producción

```bash
# Build backend
cd 5-pagina-web-login/backend
docker build -t culqui-backend:1.0.0 .

# Build frontend
cd ../frontend
docker build \
  --build-arg REACT_APP_API_URL=https://api.culqui.com/api \
  -t culqui-frontend:1.0.0 .
```

### Push a Docker Registry

```bash
# Login a Docker Hub
docker login

# Tag images
docker tag culqui-backend:1.0.0 tu-usuario/culqui-backend:1.0.0
docker tag culqui-frontend:1.0.0 tu-usuario/culqui-frontend:1.0.0

# Push
docker push tu-usuario/culqui-backend:1.0.0
docker push tu-usuario/culqui-frontend:1.0.0
```

---

## 🔧 Scripts Útiles

### Backup de Base de Datos

```bash
./scripts/backup-db.sh
```

Crea un backup comprimido en `./backups/`

### Restaurar Base de Datos

```bash
./scripts/restore-db.sh backups/backup_culqui_db_20240115_143022.sql.gz
```

### Deploy

```bash
# Desarrollo
./scripts/deploy.sh development

# Producción
./scripts/deploy.sh production
```

### Rollback

```bash
# Ver versiones disponibles
docker images | grep culqui

# Rollback a versión específica
./scripts/rollback.sh 42
```

---

## 📝 Comandos Comunes

### Gestión de contenedores

```bash
# Ver contenedores corriendo
docker-compose ps

# Detener todos los servicios
docker-compose down

# Detener y eliminar volúmenes (⚠️ borra datos)
docker-compose down -v

# Reiniciar un servicio
docker-compose restart backend

# Ver logs
docker-compose logs -f backend
```

### Gestión de imágenes

```bash
# Listar imágenes
docker images

# Eliminar imágenes no usadas
docker image prune -a

# Ver espacio usado por Docker
docker system df
```

### Gestión de volúmenes

```bash
# Listar volúmenes
docker volume ls

# Ver detalles de un volumen
docker volume inspect culqui-mysql-data

# Backup de volumen
docker run --rm \
  -v culqui-mysql-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/mysql-data-backup.tar.gz /data
```

### Health Checks

```bash
# Backend
curl http://localhost:5000/health

# Frontend
curl http://localhost:3000/health

# MySQL
docker-compose exec mysql mysqladmin ping -h localhost -u root -p
```

---

## 🐛 Troubleshooting

### Problema: Puerto ya en uso

```bash
# Ver qué está usando el puerto
sudo lsof -i :3000

# Matar proceso
kill -9 <PID>

# O cambiar puerto en docker-compose.yml
ports:
  - "3001:3000"
```

### Problema: Contenedor no inicia

```bash
# Ver logs
docker-compose logs backend

# Ver logs completos
docker-compose logs --no-log-prefix backend

# Inspeccionar contenedor
docker inspect culqui-backend
```

### Problema: Base de datos no conecta

```bash
# Verificar que MySQL esté healthy
docker-compose ps

# Ver logs de MySQL
docker-compose logs mysql

# Probar conexión manual
docker-compose exec mysql mysql -u root -p
```

### Problema: "Cannot connect to Docker daemon"

```bash
# Iniciar Docker
sudo systemctl start docker

# Verificar estado
sudo systemctl status docker

# Agregar usuario a grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Problema: Build falla por falta de espacio

```bash
# Limpiar todo lo no usado
docker system prune -a --volumes

# Ver espacio
docker system df
```

### Problema: Cambios en código no se reflejan

```bash
# Rebuild forzado
docker-compose build --no-cache backend

# Reiniciar con rebuild
docker-compose up -d --build --force-recreate
```

---

## 📊 Monitoreo

### Ver recursos usados

```bash
# Stats en tiempo real
docker stats

# Stats de servicios específicos
docker stats culqui-backend culqui-frontend culqui-mysql
```

### Logs

```bash
# Todos los servicios
docker-compose logs -f

# Solo errores
docker-compose logs -f | grep -i error

# Últimas 100 líneas
docker-compose logs --tail=100

# Desde hace 10 minutos
docker-compose logs --since 10m
```

---

## 🔒 Seguridad

### Buenas prácticas

1. **No commitear .env** al repositorio
2. **Usar secrets** para producción
3. **Actualizar imágenes** regularmente
4. **Escanear vulnerabilidades:**

```bash
# Instalar Trivy
docker pull aquasec/trivy

# Escanear imagen
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image culqui-backend:latest
```

5. **Usar usuario no-root** en contenedores (ya implementado)

---

## 📚 Recursos

- **Docker Docs:** https://docs.docker.com/
- **Docker Compose Docs:** https://docs.docker.com/compose/
- **Best Practices:** https://docs.docker.com/develop/dev-best-practices/

---

## 🎓 Resumen Rápido

```bash
# 1. Configurar
cp .env.example .env
nano .env

# 2. Iniciar
docker-compose up -d

# 3. Ver logs
docker-compose logs -f

# 4. Verificar
curl http://localhost:5000/health
curl http://localhost:3000/health

# 5. Detener
docker-compose down
```

¡Listo! Tu aplicación Culqui está corriendo en Docker. 🎉
