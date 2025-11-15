# 4. Arquitectura de Aplicaciones - Sistema Culqui

## Visión General

![Arquitectura-Aplicaciones](Pregunta_4.png)

## FRONTEND

### 1. Web App (Aplicación Web)
**Tecnología:** React 18+
**Descripción:** Interfaz web para clientes finales.

#### Componentes Principales:
```
src/
├── components/
│   ├── auth/
│   │   ├── LoginForm.jsx       ← Formulario de login
│   │   ├── RegisterForm.jsx
│   │   └── ForgotPassword.jsx
│   ├── dashboard/
│   │   ├── Dashboard.jsx
│   │   └── UserProfile.jsx
│   └── common/
│       ├── Header.jsx
│       └── Footer.jsx
├── services/
│   ├── authService.js          ← Comunicación con Backend
│   └── apiClient.js
├── store/                      ← Redux/Context
│   ├── authSlice.js
│   └── store.js
├── utils/
│   ├── validators.js
│   └── tokenManager.js
└── App.jsx
```

#### Función en el Login:
1. **Renderizar formulario** de login con campos email/password
2. **Validar inputs** en el cliente (formato de email, longitud de password)
3. **Enviar credenciales** al backend via REST API
4. **Recibir y almacenar** JWT token
5. **Redirigir** al dashboard después del login exitoso
6. **Gestionar estado** de autenticación (logueado/no logueado)

#### Conexión con Backend:
**Método:** REST API
**Protocolo:** HTTPS
**Formato:** JSON

**Ejemplo de código:**
```javascript
// authService.js
const API_URL = 'https://api.culqui.com';

export const login = async (email, password) => {
  const response = await fetch(`${API_URL}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password })
  });

  if (!response.ok) {
    throw new Error('Login failed');
  }

  const data = await response.json();
  // Almacenar token
  localStorage.setItem('token', data.token);
  return data;
};
```

---

### 2. Portal B2B (Comercios)
**Tecnología:** React 18+
**Descripción:** Interfaz especializada para usuarios tipo comercio.

#### Diferencias con Web App:
- Dashboard más complejo (analytics, transacciones, API keys)
- Funcionalidades de reportes avanzados
- Gestión de webhooks
- Mismo sistema de autenticación

#### Función en el Login:
- **Idéntica a Web App** pero con redirección a dashboard B2B
- Valida que el usuario tenga rol `comercio`
- Si usuario es `cliente` y intenta acceder, redirige a Web App

#### Conexión con Backend:
**Igual que Web App:** REST API HTTPS JSON

---

### 3. Smartphone App (iOS/Android)
**Tecnología:** React Native
**Descripción:** Aplicación móvil nativa para clientes.

#### Componentes Principales:
```
src/
├── screens/
│   ├── LoginScreen.jsx
│   ├── DashboardScreen.jsx
│   └── ProfileScreen.jsx
├── services/
│   ├── authService.js
│   └── secureStorage.js    ← Almacenamiento seguro de tokens
├── navigation/
│   ├── AuthNavigator.jsx
│   └── AppNavigator.jsx
└── App.jsx
```

#### Función en el Login:
1. Renderizar formulario nativo
2. Validar inputs
3. **Enviar credenciales** al backend (misma API)
4. **Almacenar token** en almacenamiento seguro (Keychain/Keystore)
5. Activar notificaciones push después del login

#### Conexión con Backend:
**Método:** REST API
**Protocolo:** HTTPS
**Formato:** JSON
**Diferencia:** Usa `SecureStorage` para tokens en vez de `localStorage`

```javascript
// authService.js (React Native)
import * as SecureStore from 'expo-secure-store';

export const login = async (email, password) => {
  const response = await fetch(`${API_URL}/api/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password,
      deviceInfo: {
        type: 'mobile',
        platform: Platform.OS  // 'ios' o 'android'
      }
    })
  });

  const data = await response.json();

  // Almacenar token de forma segura
  await SecureStore.setItemAsync('token', data.token);
  return data;
};
```

---

## BACKEND

### Arquitectura en Capas

```
┌─────────────────────────────────────────┐
│        API Layer (Routes)               │  ← Recibe HTTP requests
├─────────────────────────────────────────┤
│        Controller Layer                 │  ← Maneja lógica de requests
├─────────────────────────────────────────┤
│        Service Layer                    │  ← Lógica de negocio
├─────────────────────────────────────────┤
│        Data Access Layer (DAL)          │  ← Interacción con BD
├─────────────────────────────────────────┤
│        Database (MySQL)                 │  ← Almacenamiento
└─────────────────────────────────────────┘
```

---

### Estructura del Proyecto Backend

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js         ← Configuración de MySQL
│   │   ├── jwt.js              ← Configuración de JWT
│   │   └── env.js              ← Variables de entorno
│   │
│   ├── routes/
│   │   ├── auth.routes.js      ← Rutas de autenticación
│   │   ├── user.routes.js
│   │   └── transaction.routes.js
│   │
│   ├── controllers/
│   │   ├── authController.js   ← Lógica del login
│   │   ├── userController.js
│   │   └── transactionController.js
│   │
│   ├── services/
│   │   ├── authService.js      ← Lógica de negocio de auth
│   │   ├── userService.js
│   │   └── jwtService.js       ← Generación de tokens
│   │
│   ├── models/
│   │   ├── User.js             ← Modelo de datos
│   │   ├── Session.js
│   │   └── Role.js
│   │
│   ├── middleware/
│   │   ├── authMiddleware.js   ← Validación de JWT
│   │   ├── rateLimiter.js      ← Control de intentos
│   │   ├── validator.js        ← Validación de inputs
│   │   └── errorHandler.js
│   │
│   ├── utils/
│   │   ├── bcrypt.js           ← Hash de passwords
│   │   ├── logger.js           ← Logs del sistema
│   │   └── response.js         ← Formato de respuestas
│   │
│   └── app.js                  ← Entry point
│
├── tests/
├── package.json
└── .env
```

---

### Función del Backend en el Login

#### 1. API Layer (Routes)
**Archivo:** `src/routes/auth.routes.js`

```javascript
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const rateLimiter = require('../middleware/rateLimiter');
const validator = require('../middleware/validator');

// POST /api/auth/login
router.post(
  '/login',
  rateLimiter.loginLimiter,           // Limitar intentos
  validator.validateLoginInput,        // Validar formato
  authController.login                 // Procesar login
);

// POST /api/auth/logout
router.post('/logout', authController.logout);

// POST /api/auth/refresh
router.post('/refresh', authController.refreshToken);

module.exports = router;
```

---

#### 2. Controller Layer
**Archivo:** `src/controllers/authController.js`

```javascript
const authService = require('../services/authService');
const { successResponse, errorResponse } = require('../utils/response');

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const ipAddress = req.ip;
    const userAgent = req.headers['user-agent'];

    // Llamar al servicio de autenticación
    const result = await authService.login({
      email,
      password,
      ipAddress,
      userAgent
    });

    return successResponse(res, result, 'Login exitoso');
  } catch (error) {
    return errorResponse(res, error.message, error.statusCode || 500);
  }
};

exports.logout = async (req, res) => {
  try {
    const { userId } = req.user;  // Del JWT decodificado
    const token = req.headers.authorization.split(' ')[1];

    await authService.logout(userId, token);

    return successResponse(res, null, 'Logout exitoso');
  } catch (error) {
    return errorResponse(res, error.message, 500);
  }
};
```

---

#### 3. Service Layer (Lógica de Negocio)
**Archivo:** `src/services/authService.js`

```javascript
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Session = require('../models/Session');
const jwtService = require('./jwtService');
const { AppError } = require('../utils/errors');

exports.login = async ({ email, password, ipAddress, userAgent }) => {
  // 1. Buscar usuario por email
  const user = await User.findByEmail(email);

  if (!user) {
    throw new AppError('Credenciales inválidas', 401);
  }

  // 2. Verificar estado de la cuenta
  if (user.estado !== 'activo') {
    throw new AppError('Cuenta inactiva o bloqueada', 403);
  }

  // 3. Comparar password
  const isPasswordValid = await bcrypt.compare(password, user.password_hash);

  if (!isPasswordValid) {
    // Registrar intento fallido
    await logFailedAttempt(email, ipAddress);
    throw new AppError('Credenciales inválidas', 401);
  }

  // 4. Obtener roles y permisos
  const roles = await User.getRoles(user.id);
  const permisos = await User.getPermisos(user.id);

  // 5. Generar JWT
  const token = jwtService.generateToken({
    userId: user.id,
    email: user.email,
    roles: roles.map(r => r.nombre),
    permisos: permisos.map(p => p.nombre)
  });

  const refreshToken = jwtService.generateRefreshToken({
    userId: user.id
  });

  // 6. Crear sesión en BD
  await Session.create({
    usuario_id: user.id,
    token,
    refresh_token: refreshToken,
    ip_address: ipAddress,
    user_agent: userAgent,
    dispositivo_tipo: 'web'
  });

  // 7. Registrar log de autenticación
  await logSuccessfulLogin(user.id, ipAddress, userAgent);

  // 8. Retornar respuesta
  return {
    token,
    refreshToken,
    usuario: {
      id: user.id,
      nombre: user.nombre,
      apellido: user.apellido,
      email: user.email,
      roles: roles.map(r => r.nombre),
      permisos: permisos.map(p => p.nombre)
    }
  };
};

exports.logout = async (userId, token) => {
  // Marcar sesión como inactiva
  await Session.deactivate(token);

  // Registrar logout en logs
  await logLogout(userId);
};
```

---

#### 4. Model Layer (Data Access)
**Archivo:** `src/models/User.js`

```javascript
const db = require('../config/database');

class User {
  static async findByEmail(email) {
    const [rows] = await db.query(
      `SELECT * FROM usuarios WHERE email = ? AND estado = 'activo'`,
      [email]
    );
    return rows[0];
  }

  static async getRoles(userId) {
    const [rows] = await db.query(
      `SELECT r.id, r.nombre, r.descripcion
       FROM usuario_roles ur
       INNER JOIN roles r ON ur.rol_id = r.id
       WHERE ur.usuario_id = ?`,
      [userId]
    );
    return rows;
  }

  static async getPermisos(userId) {
    const [rows] = await db.query(
      `SELECT DISTINCT p.id, p.nombre, p.recurso, p.accion
       FROM usuario_roles ur
       INNER JOIN rol_permisos rp ON ur.rol_id = rp.rol_id
       INNER JOIN permisos p ON rp.permiso_id = p.id
       WHERE ur.usuario_id = ?`,
      [userId]
    );
    return rows;
  }
}

module.exports = User;
```

---

### Middleware Importantes

#### 1. Rate Limiter
**Archivo:** `src/middleware/rateLimiter.js`

```javascript
const rateLimit = require('express-rate-limit');

exports.loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutos
  max: 5,                     // 5 intentos
  message: 'Demasiados intentos de login, intente más tarde',
  standardHeaders: true,
  legacyHeaders: false,
});
```

#### 2. Auth Middleware (Validar JWT)
**Archivo:** `src/middleware/authMiddleware.js`

```javascript
const jwtService = require('../services/jwtService');

exports.verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwtService.verifyToken(token);
    req.user = decoded;  // Agregar info del usuario al request
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Token inválido o expirado' });
  }
};
```

---

## Conexión Frontend ↔ Backend

### Protocolo: REST API

**Base URL:** `https://api.culqui.com`

### Endpoints de Autenticación

| Método | Endpoint | Descripción | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/api/auth/login` | Iniciar sesión | `{ email, password }` | `{ token, refreshToken, usuario }` |
| POST | `/api/auth/logout` | Cerrar sesión | - | `{ message }` |
| POST | `/api/auth/refresh` | Renovar token | `{ refreshToken }` | `{ token }` |
| POST | `/api/auth/register` | Registrar usuario | `{ email, password, nombre, apellido }` | `{ usuario }` |
| POST | `/api/auth/forgot-password` | Recuperar contraseña | `{ email }` | `{ message }` |

---

### Formato de Comunicación

#### Request (Login)
```http
POST https://api.culqui.com/api/auth/login
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "MiPassword123!"
}
```

#### Response Success (HTTP 200)
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "refresh_token_hash...",
    "usuario": {
      "id": 123,
      "nombre": "Juan",
      "apellido": "Pérez",
      "email": "usuario@ejemplo.com",
      "roles": ["cliente"],
      "permisos": ["transacciones:crear", "transacciones:leer"]
    }
  },
  "message": "Login exitoso"
}
```

#### Response Error (HTTP 401)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Usuario o contraseña incorrectos"
  }
}
```

---

### Autenticación en Requests Posteriores

Una vez logueado, todas las requests deben incluir el token:

```http
GET https://api.culqui.com/api/users/profile
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Seguridad

### 1. HTTPS Obligatorio
- Todas las comunicaciones deben ser por HTTPS
- Certificado SSL/TLS válido

### 2. CORS (Cross-Origin Resource Sharing)
```javascript
// Backend
const cors = require('cors');

app.use(cors({
  origin: [
    'https://app.culqui.com',        // Web App
    'https://b2b.culqui.com',        // Portal B2B
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### 3. Input Validation
- Validar todos los inputs en el backend
- Sanitizar para prevenir SQL Injection y XSS

### 4. Password Security
- Hash con bcrypt (salt rounds >= 10)
- No enviar passwords en logs

---

## Escalabilidad

### 1. Load Balancer
```
                  ┌─► Backend Server 1
Internet ─► LB ───┼─► Backend Server 2
                  └─► Backend Server 3
```

### 2. Database Replication
```
Master DB (Write) ─┬─► Slave DB 1 (Read)
                   └─► Slave DB 2 (Read)
```

### 3. Caching Layer
- **Redis:** Sesiones activas
- **CDN:** Assets estáticos del frontend

---

## Resumen de Conexión

| Frontend | Backend API | Base de Datos |
|----------|-------------|---------------|
| Web App (React) | → REST/HTTPS | → MySQL |
| Portal B2B (React) | → REST/HTTPS | → MySQL |
| Mobile App (RN) | → REST/HTTPS | → MySQL |

**Flujo completo:**
1. Usuario ingresa credenciales en **Frontend**
2. Frontend envía POST request a **Backend API** (HTTPS/JSON)
3. Backend valida credenciales en **Base de Datos**
4. Backend genera JWT y lo retorna al **Frontend**
5. Frontend almacena token y redirige al dashboard
6. Futuras requests incluyen token en header `Authorization`
