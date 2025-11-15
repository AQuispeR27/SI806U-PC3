const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { testConnection } = require('./config/database');
const authRoutes = require('./routes/auth.routes');
const { apiLimiter } = require('./middleware/rateLimiter');

const app = express();
const PORT = process.env.PORT || 5000;

// ===========================================
// MIDDLEWARE
// ===========================================

// CORS - Permitir requests desde el frontend
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Parser de JSON
app.use(express.json());

// Parser de URL encoded
app.use(express.urlencoded({ extended: true }));

// Rate limiting general
app.use('/api/', apiLimiter);

// Logger simple para desarrollo
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
  });
}

// ===========================================
// RUTAS
// ===========================================

// Ruta de health check
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Servidor funcionando correctamente',
    timestamp: new Date().toISOString()
  });
});

// Rutas de autenticación
app.use('/api/auth', authRoutes);

// Ruta 404 - No encontrada
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'Ruta no encontrada'
    }
  });
});

// ===========================================
// MANEJO DE ERRORES
// ===========================================

app.use((error, req, res, next) => {
  console.error('Error:', error);

  res.status(error.status || 500).json({
    success: false,
    error: {
      code: error.code || 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Error interno del servidor'
    }
  });
});

// ===========================================
// INICIAR SERVIDOR
// ===========================================

const startServer = async () => {
  try {
    // Verificar conexión a la base de datos
    const dbConnected = await testConnection();

    if (!dbConnected) {
      console.error('❌ No se pudo conectar a la base de datos');
      process.exit(1);
    }

    // Iniciar servidor
    app.listen(PORT, () => {
      console.log('');
      console.log('===========================================');
      console.log('🚀 Servidor Culqui Backend');
      console.log('===========================================');
      console.log(`📡 Puerto: ${PORT}`);
      console.log(`🌍 Entorno: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 URL: http://localhost:${PORT}`);
      console.log(`✅ Servidor iniciado correctamente`);
      console.log('===========================================');
      console.log('');
    });
  } catch (error) {
    console.error('❌ Error al iniciar el servidor:', error);
    process.exit(1);
  }
};

// Manejar errores no capturados
process.on('unhandledRejection', (error) => {
  console.error('Unhandled Rejection:', error);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Iniciar el servidor
startServer();

module.exports = app;
