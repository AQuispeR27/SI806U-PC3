# Arquitectura Completa - Sistema de Login Culqui

Este repositorio contiene la arquitectura completa del sistema de login para Culqui, incluyendo diseño, documentación e implementación funcional.

## Estructura del Proyecto

```
PC3-SI806U/
├── 1-arquitectura-general/
│   └── ARQUITECTURA_GENERAL.md       # Flujo entrada → proceso → salida
│
├── 2-arquitectura-datos/
│   ├── ARQUITECTURA_DATOS.md         # ERD y diseño de base de datos
│   └── schema.sql                    # Script SQL para crear tablas
│
├── 3-arquitectura-servicios/
│   └── ARQUITECTURA_SERVICIOS.md     # Datos necesarios para login
│
├── 4-arquitectura-aplicaciones/
│   └── ARQUITECTURA_APLICACIONES.md  # Frontend/Backend y conexión API
│
└── 5-pagina-web-login/
    ├── backend/                      # API REST con Node.js + Express
    │   ├── src/
    │   │   ├── config/              # Configuración (DB, JWT)
    │   │   ├── controllers/         # Controladores
    │   │   ├── middleware/          # Autenticación, validación, rate limiting
    │   │   ├── models/              # Modelos de datos
    │   │   ├── routes/              # Rutas de la API
    │   │   ├── services/            # Lógica de negocio
    │   │   └── app.js              # Entry point
    │   ├── package.json
    │   └── README.md
    │
    └── frontend/                     # Aplicación React
        ├── src/
        │   ├── components/          # Componentes React
        │   │   ├── auth/           # Login, ProtectedRoute
        │   │   ├── dashboard/      # Dashboard
        │   │   └── common/         # Header, etc.
        │   ├── context/            # AuthContext
        │   ├── hooks/              # useAuth
        │   ├── services/           # authService (API calls)
        │   ├── styles/             # CSS
        │   ├── App.jsx
        │   └── index.js
        ├── package.json
        └── README.md
```

---

## Resumen de Arquitecturas

### 1️⃣ Arquitectura General
**Flujo completo:** Entrada → Proceso → Salida

- **Entrada:** Formulario web/mobile con email y password
- **Proceso:** Validación → Autenticación → Autorización → Generación JWT
- **Salida:** Token JWT + datos de usuario

📄 Ver: [`1-arquitectura-general/ARQUITECTURA_GENERAL.md`](1-arquitectura-general/ARQUITECTURA_GENERAL.md)

---

### 2️⃣ Arquitectura de Datos
**Base de datos:** MySQL con 13 tablas principales

**Tablas clave:**
- `usuarios` - Credenciales y datos básicos
- `roles` y `permisos` - Control de acceso
- `sesiones` - Tokens activos
- `logs_autenticacion` - Auditoría
- `clientes`, `comercios`, `transacciones`, etc.

📄 Ver: [`2-arquitectura-datos/ARQUITECTURA_DATOS.md`](2-arquitectura-datos/ARQUITECTURA_DATOS.md)
💾 Script SQL: [`2-arquitectura-datos/schema.sql`](2-arquitectura-datos/schema.sql)

---

### 3️⃣ Arquitectura de Servicios
**Datos necesarios para login:**

Tablas utilizadas:
1. `usuarios` → Validar credenciales
2. `usuario_roles` → Obtener roles
3. `permisos` → Obtener permisos
4. `sesiones` → Crear sesión activa
5. `logs_autenticacion` → Auditoría

📄 Ver: [`3-arquitectura-servicios/ARQUITECTURA_SERVICIOS.md`](3-arquitectura-servicios/ARQUITECTURA_SERVICIOS.md)

---

### 4️⃣ Arquitectura de Aplicaciones
**Stack tecnológico:**

**Frontend:**
- React 18+ (Web App, Portal B2B)
- React Native (Mobile App)
- Comunicación: REST API HTTPS JSON

**Backend:**
- Node.js + Express
- Autenticación: JWT
- Base de datos: MySQL
- Seguridad: bcrypt, rate limiting, CORS

📄 Ver: [`4-arquitectura-aplicaciones/ARQUITECTURA_APLICACIONES.md`](4-arquitectura-aplicaciones/ARQUITECTURA_APLICACIONES.md)

---

### 5️⃣ Implementación Funcional
**Sistema de login completo listo para usar:**

#### Backend (Node.js + Express)
✅ API REST completa
✅ Autenticación con JWT
✅ Hash de contraseñas (bcrypt)
✅ Rate limiting (5 intentos/15 min)
✅ Validación de inputs
✅ Gestión de sesiones
✅ Logs de auditoría

#### Frontend (React)
✅ Formulario de login con validación
✅ Context API para estado global
✅ Rutas protegidas
✅ Dashboard de usuario
✅ Manejo de errores
✅ Auto-logout si token expira

📄 Ver: [`5-pagina-web-login/README.md`](5-pagina-web-login/README.md)

---

## Instalación Rápida

### 1. Configurar Base de Datos

```bash
# Conectarse a MySQL
mysql -u root -p

# Crear base de datos
CREATE DATABASE culqui_db;
USE culqui_db;

# Ejecutar schema
source 2-arquitectura-datos/schema.sql
```

### 2. Iniciar Backend

```bash
cd 5-pagina-web-login/backend

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env
nano .env  # Editar con tus credenciales

# Iniciar servidor
npm run dev
```

Backend corriendo en: `http://localhost:5000`

### 3. Iniciar Frontend

```bash
cd 5-pagina-web-login/frontend

# Instalar dependencias
npm install

# Configurar variables de entorno
cp .env.example .env
nano .env  # REACT_APP_API_URL=http://localhost:5000/api

# Iniciar aplicación
npm start
```

Frontend corriendo en: `http://localhost:3000`

---

## Endpoints de la API

### Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/auth/register` | Registrar usuario |
| POST | `/api/auth/login` | Iniciar sesión |
| POST | `/api/auth/logout` | Cerrar sesión |
| POST | `/api/auth/refresh` | Renovar token |
| GET | `/api/auth/me` | Datos del usuario actual |

### Health Check

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Estado del servidor |

---

## Seguridad Implementada

✅ **Contraseñas hasheadas** con bcrypt (10 rounds)
✅ **JWT** para autenticación stateless
✅ **HTTPS** ready para producción
✅ **CORS** configurado y restrictivo
✅ **Rate Limiting** (5 intentos cada 15 minutos)
✅ **Validación de inputs** con express-validator
✅ **Prevención de SQL Injection** con prepared statements
✅ **Prevención de XSS** con sanitización
✅ **Logs de auditoría** de todos los intentos de login

---

## Características Principales

### Backend
- Arquitectura en capas (Routes → Controllers → Services → Models)
- Middleware de autenticación JWT
- Rate limiting por IP y usuario
- Validación robusta de datos
- Gestión de sesiones en base de datos
- Sistema de refresh tokens
- Logs detallados de autenticación

### Frontend
- Single Page Application (SPA) con React
- Context API para gestión de estado
- Rutas protegidas con React Router
- Formularios con validación en tiempo real
- Manejo de errores user-friendly
- Diseño responsivo
- Auto-logout en caso de token expirado

---

## Tecnologías Utilizadas

### Backend
- Node.js >= 16.x
- Express 4.x
- MySQL 8.x
- JWT (jsonwebtoken)
- bcryptjs
- express-validator
- express-rate-limit
- cors
- dotenv

### Frontend
- React 18.x
- React Router 6.x
- Context API
- CSS3

---

## Diagrama de Flujo de Login

```
Usuario ingresa credenciales
        ↓
Frontend valida formato
        ↓
POST /api/auth/login
        ↓
Backend verifica rate limiting
        ↓
Backend valida credenciales en BD
        ↓
Backend compara password (bcrypt)
        ↓
Backend obtiene roles y permisos
        ↓
Backend genera JWT token
        ↓
Backend crea sesión en BD
        ↓
Backend registra log de auditoría
        ↓
Respuesta con token + datos usuario
        ↓
Frontend almacena token
        ↓
Redirección a Dashboard
```

---

## Próximos Pasos

### Para empezar a codificar:

1. ✅ Revisa la documentación de arquitectura (carpetas 1-4)
2. ✅ Configura la base de datos con el schema.sql
3. ✅ Instala dependencias del backend y frontend
4. ✅ Configura variables de entorno (.env)
5. ✅ Inicia ambos servidores
6. ✅ Prueba el login con usuarios de prueba

### Mejoras futuras:

- [ ] Autenticación de dos factores (2FA)
- [ ] OAuth (Google, Facebook)
- [ ] Recuperación de contraseña por email
- [ ] Verificación de email al registrarse
- [ ] Notificaciones de login desde nuevos dispositivos
- [ ] Historial de sesiones activas
- [ ] Captcha en login

---

## Documentación Completa

Cada carpeta contiene documentación detallada:

1. **Arquitectura General:** Flujo completo del sistema
2. **Arquitectura de Datos:** ERD, tablas, relaciones
3. **Arquitectura de Servicios:** Datos específicos para login
4. **Arquitectura de Aplicaciones:** Frontend/Backend, API REST
5. **Implementación:** Código funcional listo para usar

---

## Licencia

MIT

## Autor

Sistema Culqui - 2024

---

## Contacto

Para preguntas sobre la arquitectura, revisa los documentos individuales en cada carpeta.
