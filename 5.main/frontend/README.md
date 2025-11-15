# Frontend - Sistema de Login Culqui

Aplicación web desarrollada con React para el sistema de autenticación de Culqui.

## Tecnologías

- **React** 18.x
- **React Router** 6.x
- **Context API** para gestión de estado
- **CSS3** para estilos

## Instalación

```bash
# Instalar dependencias
npm install

# Copiar variables de entorno
cp .env.example .env

# Editar .env
nano .env
```

## Configuración

Edita el archivo `.env`:

```env
REACT_APP_API_URL=http://localhost:5000/api
```

## Uso

```bash
# Desarrollo
npm start

# Build para producción
npm run build

# Tests
npm test
```

La aplicación estará disponible en `http://localhost:3000`

## Estructura

```
src/
├── components/
│   ├── auth/           # Componentes de autenticación
│   ├── dashboard/      # Dashboard principal
│   └── common/         # Componentes reutilizables
├── context/            # Context API (AuthContext)
├── hooks/              # Hooks personalizados
├── services/           # Servicios para API
├── styles/             # Archivos CSS
├── App.jsx            # Componente principal
└── index.js           # Entry point
```

## Funcionalidades

- ✅ Login con email y contraseña
- ✅ Validación de formularios
- ✅ Gestión de tokens JWT
- ✅ Rutas protegidas
- ✅ Dashboard de usuario
- ✅ Logout
- ✅ Manejo de errores
- ✅ Estados de carga

## Componentes Principales

### LoginForm
Formulario de inicio de sesión con validación.

### Dashboard
Panel principal después del login.

### ProtectedRoute
HOC para proteger rutas que requieren autenticación.

### Header
Barra de navegación con logout.

## Flujo de Autenticación

1. Usuario ingresa credenciales en LoginForm
2. AuthContext llama a authService.login()
3. Se almacena token en localStorage
4. Usuario es redirigido a Dashboard
5. ProtectedRoute verifica autenticación en cada ruta

## Licencia

MIT
