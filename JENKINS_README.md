# 🚀 Guía Completa del Pipeline CI/CD Jenkins - Sistema Culqui

Esta guía te ayudará a configurar y ejecutar el pipeline de Jenkins para el sistema de login de Culqui.

---

## 📋 Tabla de Contenidos

1. [Descripción del Pipeline](#descripción-del-pipeline)
2. [Requisitos Previos](#requisitos-previos)
3. [Instalación de Jenkins](#instalación-de-jenkins)
4. [Configuración Inicial](#configuración-inicial)
5. [Credenciales Necesarias](#credenciales-necesarias)
6. [Crear el Job en Jenkins](#crear-el-job-en-jenkins)
7. [Estructura del Pipeline](#estructura-del-pipeline)
8. [Variables de Entorno](#variables-de-entorno)
9. [Stages del Pipeline](#stages-del-pipeline)
10. [Ejecución del Pipeline](#ejecución-del-pipeline)
11. [Monitoreo y Logs](#monitoreo-y-logs)
12. [Troubleshooting](#troubleshooting)
13. [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 Descripción del Pipeline

El pipeline de CI/CD implementado en este proyecto automatiza completamente el proceso de:

- ✅ **Checkout** del código desde Git
- ✅ **Instalación** de dependencias (Backend y Frontend)
- ✅ **Análisis** de calidad de código (Linting)
- ✅ **Ejecución** de tests unitarios
- ✅ **Escaneo** de seguridad (NPM Audit)
- ✅ **Build** de imágenes Docker
- ✅ **Testing** de las imágenes
- ✅ **Escaneo** de vulnerabilidades en imágenes (Trivy)
- ✅ **Push** a Docker Registry
- ✅ **Deploy** automático a entornos
- ✅ **Smoke Tests** post-deployment

---

## 📦 Requisitos Previos

### Software Necesario

| Software | Versión Mínima | Propósito |
|----------|---------------|-----------|
| **Jenkins** | 2.387+ | Servidor CI/CD |
| **Docker** | 20.10+ | Containerización |
| **Docker Compose** | 2.0+ | Orquestación local |
| **Git** | 2.30+ | Control de versiones |
| **Node.js** | 16.x+ | Runtime (opcional) |

### Hardware Recomendado

- **CPU:** 2+ cores
- **RAM:** 4GB mínimo (8GB recomendado)
- **Disk:** 20GB espacio libre
- **Network:** Conexión a Internet estable

---

## 🔧 Instalación de Jenkins

### Opción 1: Instalación en Ubuntu/Debian

```bash
# 1. Actualizar sistema
sudo apt update

# 2. Instalar Java
sudo apt install openjdk-11-jdk -y

# 3. Agregar repositorio de Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 4. Instalar Jenkins
sudo apt update
sudo apt install jenkins -y

# 5. Iniciar Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# 6. Verificar estado
sudo systemctl status jenkins

# 7. Obtener password inicial
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Opción 2: Instalación con Docker (Recomendado)

```bash
# Crear volumen para persistencia
docker volume create jenkins-data

# Ejecutar Jenkins en Docker
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --restart unless-stopped \
  jenkins/jenkins:lts-jdk11

# Ver logs y obtener password inicial
docker logs jenkins
```

### Opción 3: Instalación con Docker Compose

Crear archivo `jenkins-docker-compose.yml`:

```yaml
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts-jdk11
    container_name: jenkins-culqui
    restart: unless-stopped
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins-data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - ./jenkins-scripts:/usr/local/bin/scripts
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
      - DOCKER_HOST=unix:///var/run/docker.sock

volumes:
  jenkins-data:
    name: jenkins-culqui-data
```

Ejecutar:

```bash
docker-compose -f jenkins-docker-compose.yml up -d
```

---

## ⚙️ Configuración Inicial

### 1. Acceder a Jenkins

1. Abrir navegador en `http://localhost:8080`
2. Ingresar password inicial (ver logs de instalación)
3. Seleccionar "Install suggested plugins"
4. Crear usuario administrador
5. Configurar URL de Jenkins

### 2. Instalar Plugins Necesarios

Ir a: **Manage Jenkins → Manage Plugins → Available**

Instalar los siguientes plugins:

- ✅ **Docker Pipeline** - Para trabajar con Docker
- ✅ **Docker** - Integración con Docker
- ✅ **Git** - Integración con Git
- ✅ **Pipeline** - Soporte para Jenkinsfile
- ✅ **Credentials Binding** - Gestión de credenciales
- ✅ **Blue Ocean** (Opcional) - UI moderna
- ✅ **Slack Notification** (Opcional) - Notificaciones
- ✅ **Email Extension** (Opcional) - Emails

### 3. Configurar Docker en Jenkins

Si Jenkins está en Docker, necesitas instalar Docker dentro del contenedor:

```bash
# Entrar al contenedor de Jenkins
docker exec -it -u root jenkins bash

# Instalar Docker CLI
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce-cli

# Dar permisos al usuario jenkins
usermod -aG docker jenkins

# Reiniciar Jenkins
exit
docker restart jenkins
```

### 4. Configurar Git

```bash
# Dentro del contenedor de Jenkins
apt-get install -y git
```

---

## 🔑 Credenciales Necesarias

Ir a: **Manage Jenkins → Manage Credentials → System → Global credentials**

### Crear las siguientes credenciales:

#### 1. Docker Registry Credentials

- **Kind:** Username with password
- **ID:** `docker-credentials-id`
- **Username:** Tu usuario de Docker Hub
- **Password:** Tu password/token de Docker Hub
- **Description:** Docker Registry Credentials

#### 2. Docker Registry URL

- **Kind:** Secret text
- **ID:** `docker-registry-url`
- **Secret:** `docker.io` (o tu registry privado)
- **Description:** Docker Registry URL

#### 3. Database Credentials

Crear credenciales individuales tipo "Secret text":

| ID | Valor | Descripción |
|----|-------|-------------|
| `db-host` | `mysql` | Database Host |
| `db-user` | `culqui_user` | Database User |
| `db-password` | `tu_password` | Database Password |
| `db-name` | `culqui_db` | Database Name |

#### 4. JWT Secrets

| ID | Valor | Descripción |
|----|-------|-------------|
| `jwt-secret` | `tu_jwt_secret` | JWT Secret Key |
| `jwt-refresh-secret` | `tu_refresh_secret` | JWT Refresh Secret |

#### 5. GitHub/GitLab Credentials (si aplica)

- **Kind:** SSH Username with private key
- **ID:** `git-ssh-key`
- **Username:** `git`
- **Private Key:** Tu llave SSH privada
- **Description:** Git SSH Key

---

## 📁 Crear el Job en Jenkins

### Método 1: Pipeline desde SCM (Recomendado)

1. **Crear nuevo Job:**
   - Clic en "New Item"
   - Nombre: `culqui-login-pipeline`
   - Tipo: "Pipeline"
   - Clic "OK"

2. **Configurar el Job:**

   **General:**
   - ✅ GitHub project (opcional): URL de tu repo
   - ✅ Discard old builds: Keep 10 builds

   **Build Triggers:**
   - ✅ Poll SCM: `H/5 * * * *` (cada 5 minutos)
   - O configurar webhook de GitHub

   **Pipeline:**
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/tu-usuario/PC3-SI806U.git`
   - Credentials: Seleccionar credenciales de Git
   - Branch: `*/main` o `*/claude/culqui-login-architecture-*`
   - Script Path: `Jenkinsfile`

3. **Guardar**

### Método 2: Pipeline Script Directo

1. Crear nuevo Job tipo "Pipeline"
2. En "Pipeline":
   - Definition: **Pipeline script**
   - Copiar y pegar el contenido del `Jenkinsfile`
3. Guardar

---

## 🏗️ Estructura del Pipeline

```
Pipeline CI/CD Culqui
│
├── 1. Checkout
│   └── Obtener código desde Git
│
├── 2. Install Dependencies (Parallel)
│   ├── Backend Dependencies
│   └── Frontend Dependencies
│
├── 3. Code Quality (Parallel)
│   ├── Backend Lint
│   └── Frontend Lint
│
├── 4. Run Tests (Parallel)
│   ├── Backend Tests
│   └── Frontend Tests
│
├── 5. Security Scan
│   └── NPM Audit
│
├── 6. Build Docker Images (Parallel)
│   ├── Build Backend Image
│   └── Build Frontend Image
│
├── 7. Test Docker Images
│   ├── Test Backend Container
│   └── Test Frontend Container
│
├── 8. Image Security Scan
│   └── Trivy Vulnerability Scan
│
├── 9. Push to Registry (main/develop only)
│   ├── Push Backend Image
│   └── Push Frontend Image
│
├── 10. Deploy (main/develop only)
│   ├── Production (main)
│   └── Development (develop)
│
└── 11. Smoke Tests
    ├── Backend Health Check
    ├── Frontend Health Check
    └── API Endpoint Test
```

---

## 🌍 Variables de Entorno

El pipeline utiliza las siguientes variables:

### Configuradas Automáticamente

```groovy
VERSION = "${env.BUILD_NUMBER}"
GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
ENVIRONMENT = "${env.BRANCH_NAME == 'main' ? 'production' : 'development'}"
BACKEND_IMAGE = "culqui-backend"
FRONTEND_IMAGE = "culqui-frontend"
```

### Desde Credenciales de Jenkins

```groovy
DOCKER_REGISTRY = credentials('docker-registry-url')
DOCKER_CREDENTIALS = credentials('docker-credentials-id')
DB_HOST = credentials('db-host')
DB_USER = credentials('db-user')
DB_PASSWORD = credentials('db-password')
DB_NAME = credentials('db-name')
JWT_SECRET = credentials('jwt-secret')
```

### Para Modificar Variables

1. Ir a: **Job → Configure → Pipeline**
2. Editar sección `environment {}` en el Jenkinsfile
3. O agregar en: **Manage Jenkins → Configure System → Global properties → Environment variables**

---

## 📊 Stages del Pipeline

### Stage 1: Checkout

**Propósito:** Obtener el código fuente desde el repositorio Git.

**Qué hace:**
- Clona el repositorio
- Checkout de la rama correspondiente
- Muestra información del commit

**Salida esperada:**
```
Branch: main
Build: 42
Commit: a1b2c3d
```

---

### Stage 2: Install Dependencies

**Propósito:** Instalar dependencias de Node.js para backend y frontend.

**Qué hace:**
- `npm ci` en backend (instalación limpia)
- `npm ci` en frontend (instalación limpia)
- Se ejecuta en **paralelo** para mayor velocidad

**Duración estimada:** 1-3 minutos

---

### Stage 3: Code Quality (Linting)

**Propósito:** Verificar calidad del código.

**Qué hace:**
- Ejecutar linters (ESLint, etc.)
- Verificar estándares de código

**Nota:** Actualmente marcado como opcional (skipped)

Para habilitarlo, descomentar:
```groovy
sh 'npm run lint'
```

---

### Stage 4: Run Tests

**Propósito:** Ejecutar tests unitarios y de integración.

**Qué hace:**
- Tests de backend con Jest
- Tests de frontend con React Testing Library

**Nota:** Actualmente marcado como opcional (skipped)

Para habilitarlo:
```groovy
sh 'npm test'
```

---

### Stage 5: Security Scan

**Propósito:** Detectar vulnerabilidades en dependencias.

**Qué hace:**
- Ejecuta `npm audit` en backend
- Ejecuta `npm audit` en frontend
- Alerta sobre vulnerabilidades HIGH/CRITICAL

**Salida esperada:**
```
found 0 vulnerabilities
```

---

### Stage 6: Build Docker Images

**Propósito:** Construir imágenes Docker de backend y frontend.

**Qué hace:**
- Build de `culqui-backend:${VERSION}`
- Build de `culqui-frontend:${VERSION}`
- Tagea con: `latest`, `${VERSION}`, `${GIT_COMMIT_SHORT}`

**Duración estimada:** 3-5 minutos

**Salida esperada:**
```
Successfully built abc123def456
Successfully tagged culqui-backend:42
Successfully tagged culqui-backend:latest
```

---

### Stage 7: Test Docker Images

**Propósito:** Verificar que las imágenes funcionan correctamente.

**Qué hace:**
- Inicia contenedor de backend
- Ejecuta health check en `/health`
- Inicia contenedor de frontend
- Ejecuta health check en `/health`
- Detiene y limpia contenedores

**Duración estimada:** 30 segundos

---

### Stage 8: Image Security Scan

**Propósito:** Escanear vulnerabilidades en imágenes Docker.

**Qué hace:**
- Usa **Trivy** para escanear imágenes
- Detecta vulnerabilidades HIGH/CRITICAL
- Reporta CVEs encontrados

**Salida esperada:**
```
Total: 0 (HIGH: 0, CRITICAL: 0)
```

---

### Stage 9: Push to Registry

**Propósito:** Subir imágenes a Docker Registry.

**Condición:** Solo en ramas `main` o `develop`

**Qué hace:**
- Login a Docker Registry
- Push de `culqui-backend:${VERSION}`
- Push de `culqui-frontend:${VERSION}`
- Push de tags `latest`

**Duración estimada:** 2-4 minutos

---

### Stage 10: Deploy

**Propósito:** Desplegar la aplicación al entorno correspondiente.

**Condición:** Solo en ramas `main` o `develop`

**Qué hace:**

**Para rama `main` (Producción):**
```bash
# Backup de BD
./scripts/backup-db.sh

# Deploy con docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Health check
curl http://localhost/health
```

**Para rama `develop` (Desarrollo):**
```bash
docker-compose up -d
curl http://localhost:3000/health
```

**Duración estimada:** 1-2 minutos

---

### Stage 11: Smoke Tests

**Propósito:** Verificar que el deployment fue exitoso.

**Qué hace:**
- Test de health check backend
- Test de health check frontend
- Test de endpoint de login

**Salida esperada:**
```
✓ Backend health OK
✓ Frontend health OK
✓ Login endpoint responding
```

---

## ▶️ Ejecución del Pipeline

### Ejecución Manual

1. Ir a Jenkins Dashboard
2. Seleccionar job `culqui-login-pipeline`
3. Clic en "Build Now"
4. Ver progreso en "Build History"

### Ejecución Automática

El pipeline se ejecuta automáticamente:

- **Poll SCM:** Cada 5 minutos revisa cambios en Git
- **Webhook:** Al hacer push a GitHub/GitLab (recomendado)

#### Configurar Webhook en GitHub:

1. Ir a: **Settings → Webhooks → Add webhook**
2. Payload URL: `http://tu-jenkins-server:8080/github-webhook/`
3. Content type: `application/json`
4. Events: "Just the push event"
5. Active: ✅
6. Add webhook

### Ejecución por Rama

- **main** → Deploy a Producción
- **develop** → Deploy a Desarrollo
- **Otras** → Solo Build y Test (sin deploy)

---

## 📈 Monitoreo y Logs

### Ver Logs del Build

1. Dashboard → Job → Build #X
2. Clic en "Console Output"
3. Ver logs en tiempo real

### Blue Ocean (UI Moderna)

1. Instalar plugin "Blue Ocean"
2. Clic en "Open Blue Ocean"
3. Ver pipeline visual

### Verificar Estado de Contenedores

```bash
# Ver contenedores corriendo
docker ps

# Ver logs del backend
docker logs culqui-backend

# Ver logs del frontend
docker logs culqui-frontend

# Ver logs de MySQL
docker logs culqui-mysql
```

### Health Checks

```bash
# Backend
curl http://localhost:5000/health

# Frontend
curl http://localhost:3000/health

# Desde Jenkins
curl http://localhost/health
```

---

## 🔧 Troubleshooting

### Problema 1: "Permission denied" al ejecutar Docker

**Error:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solución:**
```bash
# Agregar usuario jenkins al grupo docker
sudo usermod -aG docker jenkins

# Reiniciar Jenkins
sudo systemctl restart jenkins

# O si está en Docker
docker restart jenkins
```

---

### Problema 2: "Cannot connect to Docker daemon"

**Error:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solución:**
```bash
# Verificar que Docker esté corriendo
sudo systemctl status docker

# Verificar socket
ls -la /var/run/docker.sock

# Montar socket en Jenkins (si está en Docker)
docker run ... -v /var/run/docker.sock:/var/run/docker.sock ...
```

---

### Problema 3: "Credentials not found"

**Error:**
```
Credentials 'docker-credentials-id' could not be found
```

**Solución:**
1. Ir a: **Manage Jenkins → Manage Credentials**
2. Verificar que existan las credenciales con el ID correcto
3. Crear credenciales faltantes

---

### Problema 4: "Port already in use"

**Error:**
```
Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Solución:**
```bash
# Ver qué está usando el puerto
sudo lsof -i :3000

# Detener contenedor que usa el puerto
docker stop <container-id>

# O cambiar puerto en docker-compose.yml
ports:
  - "3001:3000"  # Cambiar 3001 por un puerto libre
```

---

### Problema 5: Build falla en "npm ci"

**Error:**
```
npm ERR! cipm can only install packages when your package.json and package-lock.json are in sync
```

**Solución:**
```bash
# Eliminar package-lock.json y node_modules
rm -rf node_modules package-lock.json

# Regenerar
npm install

# Commit cambios
git add package-lock.json
git commit -m "Update package-lock.json"
```

---

### Problema 6: "Trivy not found"

**Error:**
```
docker: Error response from daemon: pull access denied for aquasec/trivy
```

**Solución:**
```bash
# Pull manual de Trivy
docker pull aquasec/trivy

# O deshabilitar stage temporalmente comentando en Jenkinsfile
```

---

## ✅ Mejores Prácticas

### 1. Branches y Estrategia Git

```
main (production)
  ↑
develop (staging)
  ↑
feature/* (development)
```

- `main` → Deploy automático a producción
- `develop` → Deploy automático a staging
- `feature/*` → Solo build y test

### 2. Versioning

Usar tags semánticos:
```bash
git tag v1.0.0
git push origin v1.0.0
```

El pipeline puede usar tags:
```groovy
VERSION = "${env.TAG_NAME ?: env.BUILD_NUMBER}"
```

### 3. Rollback

En caso de fallo, hacer rollback:
```bash
# Ver versiones disponibles
docker images | grep culqui

# Rollback a versión anterior
export VERSION=41  # Versión anterior
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Backups

Automatizar backups de BD antes de deploy:
```bash
#!/bin/bash
# scripts/backup-db.sh

DATE=$(date +%Y%m%d_%H%M%S)
docker exec culqui-mysql mysqldump -u root -p$DB_PASSWORD culqui_db > backup_$DATE.sql
```

### 5. Notificaciones

Configurar notificaciones en `post` section:

```groovy
post {
    success {
        slackSend(color: 'good', message: "Build #${BUILD_NUMBER} SUCCESS")
    }
    failure {
        slackSend(color: 'danger', message: "Build #${BUILD_NUMBER} FAILED")
    }
}
```

### 6. Secrets Management

**NUNCA** commitear secrets en Git:
- Usar Jenkins Credentials
- Usar archivos `.env` (no commiteados)
- Usar HashiCorp Vault (avanzado)

### 7. Optimización de Builds

```groovy
// Cachear node_modules
stage('Install Dependencies') {
    when {
        changeset "**/package.json"
    }
    ...
}
```

---

## 📚 Recursos Adicionales

- **Jenkins Docs:** https://www.jenkins.io/doc/
- **Docker Docs:** https://docs.docker.com/
- **Jenkinsfile Syntax:** https://www.jenkins.io/doc/book/pipeline/syntax/
- **Blue Ocean:** https://www.jenkins.io/doc/book/blueocean/
- **Trivy:** https://aquasecurity.github.io/trivy/

---

## 🎓 Resumen Rápido

### Para ejecutar el pipeline por primera vez:

```bash
# 1. Instalar Jenkins
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# 2. Acceder a http://localhost:8080

# 3. Instalar plugins: Docker, Git, Pipeline

# 4. Configurar credenciales

# 5. Crear nuevo Job tipo Pipeline desde SCM

# 6. ¡Build Now!
```

### Verificar el deployment:

```bash
# Backend
curl http://localhost:5000/health

# Frontend
curl http://localhost:3000/health

# Ver logs
docker logs culqui-backend
docker logs culqui-frontend
```

---

¿Tienes preguntas? Consulta el troubleshooting o revisa los logs del pipeline.
