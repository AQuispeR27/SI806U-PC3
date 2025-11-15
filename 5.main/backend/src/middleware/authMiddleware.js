const JwtService = require('../services/jwtService');

/**
 * Middleware para verificar JWT token
 */
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  // Verificar que el header exista y tenga el formato correcto
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: {
        code: 'NO_TOKEN',
        message: 'Token de autenticación no proporcionado'
      }
    });
  }

  // Extraer el token
  const token = authHeader.split(' ')[1];

  try {
    // Verificar y decodificar el token
    const decoded = JwtService.verifyToken(token);

    // Agregar información del usuario al request
    req.user = decoded;

    // Continuar con el siguiente middleware
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: {
        code: 'INVALID_TOKEN',
        message: error.message
      }
    });
  }
};

/**
 * Middleware para verificar roles específicos
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !req.user.roles) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'NO_ROLE',
          message: 'No se encontraron roles para el usuario'
        }
      });
    }

    // Verificar si el usuario tiene alguno de los roles permitidos
    const hasRole = req.user.roles.some(role => allowedRoles.includes(role));

    if (!hasRole) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'INSUFFICIENT_PERMISSIONS',
          message: 'No tiene permisos para acceder a este recurso'
        }
      });
    }

    next();
  };
};

module.exports = {
  verifyToken,
  requireRole
};
