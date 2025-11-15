# 5. Página Web Funcional - Login Culqui

## Descripción
Implementación funcional del sistema de login usando:
- **Backend:** Node.js + Express
- **Frontend:** React 18+
- **Base de Datos:** MySQL
- **Autenticación:** JWT (JSON Web Tokens)

---

## Estructura del Proyecto

```
5-pagina-web-login/
├── backend/                    # Servidor Node.js
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.js
│   │   │   └── jwt.js
│   │   ├── controllers/
│   │   │   └── authController.js
│   │   ├── middleware/
│   │   │   ├── authMiddleware.js
│   │   │   ├── rateLimiter.js
│   │   │   └── validator.js
│   │   ├── models/
│   │   │   ├── User.js
│   │   │   └── Session.js
│   │   ├── routes/
│   │   │   └── auth.routes.js
│   │   ├── services/
│   │   │   ├── authService.js
│   │   │   └── jwtService.js
│   │   ├── utils/
│   │   │   ├── logger.js
│   │   │   └── response.js
│   │   └── app.js
│   ├── .env
│   ├── .env.example
│   ├── package.json
│   └── README.md
│
├── frontend/                   # Aplicación React
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── components/
│   │   │   ├── auth/
│   │   │   │   ├── LoginForm.jsx
│   │   │   │   └── ProtectedRoute.jsx
│   │   │   ├── dashboard/
│   │   │   │   └── Dashboard.jsx
│   │   │   └── common/
│   │   │       ├── Header.jsx
│   │   │       └── Loader.jsx
│   │   ├── services/
│   │   │   └── authService.js
│   │   ├── context/
│   │   │   └── AuthContext.jsx
│   │   ├── hooks/
│   │   │   └── useAuth.js
│   │   ├── styles/
│   │   │   ├── Login.css
│   │   │   └── Dashboard.css
│   │   ├── App.jsx
│   │   ├── App.css
│   │   └── index.js
│   ├── .env
│   ├── .env.example
│   ├── package.json
│   └── README.md
│
└── README.md                   # Este archivo
```

---

## Instalación y Configuración

### Requisitos Previos
- Node.js >= 16.x
- MySQL >= 8.0
- npm o yarn

### 1. Configurar la Base de Datos

```bash
# Conectarse a MySQL
mysql -u root -p

# Crear base de datos
CREATE DATABASE culqui_db;

# Usar la base de datos
USE culqui_db;

# Ejecutar el schema
source ../../2-arquitectura-datos/schema.sql
```

### 2. Configurar el Backend

```bash
cd backend

# Instalar dependencias
npm install

# Copiar archivo de variables de entorno
cp .env.example .env

# Editar .env con tus credenciales
nano .env
```

**Archivo `.env`:**
```env
# Server
PORT=5000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=culqui_db

# JWT
JWT_SECRET=tu_secreto_super_seguro_aqui
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=otro_secreto_para_refresh
JWT_REFRESH_EXPIRES_IN=7d

# CORS
FRONTEND_URL=http://localhost:3000
```

```bash
# Iniciar el servidor
npm run dev
```

El backend estará corriendo en `http://localhost:5000`

### 3. Configurar el Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Copiar archivo de variables de entorno
cp .env.example .env

# Editar .env
nano .env
```

**Archivo `.env`:**
```env
REACT_APP_API_URL=http://localhost:5000/api
```

```bash
# Iniciar la aplicación
npm start
```

El frontend estará corriendo en `http://localhost:3000`

---

## Uso del Sistema

### 1. Crear un Usuario de Prueba

```sql
-- Insertar usuario de prueba
INSERT INTO usuarios (email, password_hash, nombre, apellido, estado, verificado)
VALUES (
  'test@culqui.com',
  '$2a$10$YourBcryptHashHere',  -- Password: 'test123'
  'Usuario',
  'Prueba',
  'activo',
  TRUE
);

-- Asignar rol de cliente
INSERT INTO usuario_roles (usuario_id, rol_id)
VALUES (LAST_INSERT_ID(), 4);  -- 4 = rol 'cliente'
```

**O usar la función de registro en la aplicación.**

### 2. Iniciar Sesión

1. Abrir navegador en `http://localhost:3000`
2. Ingresar credenciales:
   - Email: `test@culqui.com`
   - Password: `test123`
3. Click en "Iniciar Sesión"
4. Serás redirigido al dashboard

---

## Endpoints del Backend

### Autenticación

#### POST /api/auth/register
Registrar nuevo usuario

**Request:**
```json
{
  "email": "nuevo@culqui.com",
  "password": "MiPassword123!",
  "nombre": "Juan",
  "apellido": "Pérez"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "usuario": {
      "id": 1,
      "email": "nuevo@culqui.com",
      "nombre": "Juan",
      "apellido": "Pérez"
    }
  },
  "message": "Usuario registrado exitosamente"
}
```

#### POST /api/auth/login
Iniciar sesión

**Request:**
```json
{
  "email": "test@culqui.com",
  "password": "test123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_hash...",
    "usuario": {
      "id": 1,
      "nombre": "Usuario",
      "apellido": "Prueba",
      "email": "test@culqui.com",
      "roles": ["cliente"],
      "permisos": ["transacciones:crear", "transacciones:leer"]
    }
  },
  "message": "Login exitoso"
}
```

#### POST /api/auth/logout
Cerrar sesión

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "message": "Logout exitoso"
}
```

#### POST /api/auth/refresh
Renovar token

**Request:**
```json
{
  "refreshToken": "refresh_token_hash..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "nuevo_token_jwt..."
  }
}
```

#### GET /api/auth/me
Obtener datos del usuario actual

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "nombre": "Usuario",
    "apellido": "Prueba",
    "email": "test@culqui.com",
    "roles": ["cliente"]
  }
}
```

---

## Funcionalidades Implementadas

### Backend
- ✅ Registro de usuarios con validación
- ✅ Login con email y password
- ✅ Hash de contraseñas con bcrypt
- ✅ Generación de JWT tokens
- ✅ Refresh tokens
- ✅ Middleware de autenticación
- ✅ Rate limiting (5 intentos por 15 minutos)
- ✅ Validación de inputs
- ✅ Logs de autenticación
- ✅ Gestión de sesiones en BD
- ✅ CORS configurado
- ✅ Variables de entorno

### Frontend
- ✅ Formulario de login con validación
- ✅ Formulario de registro
- ✅ Gestión de estado con Context API
- ✅ Almacenamiento de token en localStorage
- ✅ Rutas protegidas
- ✅ Auto-logout si token expira
- ✅ Redirección automática
- ✅ Manejo de errores
- ✅ Loading states
- ✅ Dashboard básico
- ✅ Header con logout

---

## Seguridad Implementada

1. **Contraseñas:** Hasheadas con bcrypt (10 rounds)
2. **JWT:** Tokens firmados con secreto
3. **HTTPS Ready:** Configurado para producción
4. **CORS:** Restringido a frontend específico
5. **Rate Limiting:** Prevención de fuerza bruta
6. **Input Validation:** Validación de todos los inputs
7. **SQL Injection:** Prevenido con prepared statements
8. **XSS:** Sanitización de inputs

---

## Testing

### Backend
```bash
cd backend

# Ejecutar tests
npm test

# Tests con cobertura
npm run test:coverage
```

### Frontend
```bash
cd frontend

# Ejecutar tests
npm test

# Tests E2E
npm run test:e2e
```

---

## Despliegue

### Backend (Producción)

```bash
# Compilar
npm run build

# Iniciar en producción
npm start
```

**Recomendaciones:**
- Usar PM2 para gestión de procesos
- Configurar NGINX como reverse proxy
- Habilitar HTTPS con Let's Encrypt

### Frontend (Producción)

```bash
# Compilar para producción
npm run build

# Los archivos estarán en /build
```

**Recomendaciones:**
- Servir desde CDN (Vercel, Netlify, CloudFront)
- Configurar variable de entorno `REACT_APP_API_URL` al backend de producción

---

## Solución de Problemas

### Error: "Cannot connect to MySQL"
```bash
# Verificar que MySQL esté corriendo
sudo systemctl status mysql

# Verificar credenciales en .env
```

### Error: "CORS policy"
```bash
# Verificar que FRONTEND_URL en backend/.env coincida con la URL del frontend
```

### Error: "Token inválido"
```bash
# Limpiar localStorage del navegador
localStorage.clear()

# O hacer logout y login de nuevo
```

---

## Mejoras Futuras

- [ ] Autenticación de dos factores (2FA)
- [ ] OAuth (Google, Facebook)
- [ ] Recuperación de contraseña por email
- [ ] Verificación de email
- [ ] Notificaciones de login desde nuevos dispositivos
- [ ] Historial de sesiones activas
- [ ] Bloqueo automático después de X intentos fallidos
- [ ] Captcha en login

---

## Licencia
MIT

## Autor
Sistema Culqui - 2024
