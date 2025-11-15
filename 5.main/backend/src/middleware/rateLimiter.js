const rateLimit = require('express-rate-limit');

/**
 * Rate limiter para endpoints de login
 * Máximo 5 intentos cada 15 minutos
 */
const loginLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutos
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 5, // 5 intentos
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Demasiados intentos de login. Por favor, intente más tarde.'
    }
  },
  standardHeaders: true, // Incluir info en headers `RateLimit-*`
  legacyHeaders: false, // Deshabilitar headers `X-RateLimit-*`
  // Función para generar la clave única (por IP)
  keyGenerator: (req) => {
    return req.ip || req.connection.remoteAddress;
  },
  // Handler personalizado cuando se excede el límite
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      error: {
        code: 'TOO_MANY_REQUESTS',
        message: 'Demasiados intentos de login. Por favor, intente más tarde.',
        retryAfter: Math.ceil(req.rateLimit.resetTime / 1000)
      }
    });
  }
});

/**
 * Rate limiter general para la API
 * Máximo 100 requests cada 15 minutos
 */
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Demasiadas peticiones. Por favor, intente más tarde.'
    }
  },
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = {
  loginLimiter,
  apiLimiter
};
