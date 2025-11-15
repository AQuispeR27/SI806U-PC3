# Backend - Sistema de Login Culqui

API REST desarrollada con Node.js y Express para el sistema de autenticación de Culqui.

## Tecnologías

- **Node.js** >= 16.x
- **Express** 4.x
- **MySQL** 8.x
- **JWT** para autenticación
- **bcryptjs** para hashing de contraseñas
- **express-validator** para validación de inputs
- **express-rate-limit** para prevención de fuerza bruta

## Instalación

```bash
# Instalar dependencias
npm install

# Copiar variables de entorno
cp .env.example .env

# Editar .env con tus credenciales
nano .env
```

## Configuración

Edita el archivo `.env` con tus credenciales:

```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=culqui_db
JWT_SECRET=tu_secreto_jwt
FRONTEND_URL=http://localhost:3000
```

## Base de Datos

Ejecuta el schema SQL para crear las tablas:

```bash
mysql -u root -p < ../../2-arquitectura-datos/schema.sql
```

## Uso

```bash
# Desarrollo (con auto-reload)
npm run dev

# Producción
npm start

# Tests
npm test
```

## Endpoints

### Autenticación

- **POST** `/api/auth/register` - Registrar usuario
- **POST** `/api/auth/login` - Iniciar sesión
- **POST** `/api/auth/logout` - Cerrar sesión
- **POST** `/api/auth/refresh` - Renovar token
- **GET** `/api/auth/me` - Datos del usuario actual

### Health Check

- **GET** `/health` - Verificar estado del servidor

## Estructura

```
src/
├── config/          # Configuraciones (DB, JWT)
├── controllers/     # Controladores de rutas
├── middleware/      # Middlewares (auth, validación, rate limiting)
├── models/          # Modelos de datos
├── routes/          # Definición de rutas
├── services/        # Lógica de negocio
└── app.js          # Entry point
```

## Seguridad

- ✅ Contraseñas hasheadas con bcrypt
- ✅ JWT para autenticación stateless
- ✅ Rate limiting (5 intentos/15 min)
- ✅ Validación de inputs
- ✅ CORS configurado
- ✅ Variables de entorno para secretos

## Licencia

MIT
