const { body, validationResult } = require('express-validator');

/**
 * Middleware para manejar errores de validación
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Error de validación en los datos enviados',
        details: errors.array()
      }
    });
  }

  next();
};

/**
 * Validaciones para el registro de usuario
 */
const validateRegister = [
  body('email')
    .isEmail()
    .withMessage('Debe proporcionar un email válido')
    .normalizeEmail(),

  body('password')
    .isLength({ min: 8 })
    .withMessage('La contraseña debe tener al menos 8 caracteres')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('La contraseña debe contener al menos una mayúscula, una minúscula y un número'),

  body('nombre')
    .trim()
    .notEmpty()
    .withMessage('El nombre es obligatorio')
    .isLength({ min: 2, max: 100 })
    .withMessage('El nombre debe tener entre 2 y 100 caracteres'),

  body('apellido')
    .trim()
    .notEmpty()
    .withMessage('El apellido es obligatorio')
    .isLength({ min: 2, max: 100 })
    .withMessage('El apellido debe tener entre 2 y 100 caracteres'),

  body('telefono')
    .optional()
    .matches(/^[0-9]{9,15}$/)
    .withMessage('El teléfono debe contener entre 9 y 15 dígitos'),

  handleValidationErrors
];

/**
 * Validaciones para el login
 */
const validateLogin = [
  body('email')
    .isEmail()
    .withMessage('Debe proporcionar un email válido')
    .normalizeEmail(),

  body('password')
    .notEmpty()
    .withMessage('La contraseña es obligatoria'),

  handleValidationErrors
];

/**
 * Validaciones para refresh token
 */
const validateRefreshToken = [
  body('refreshToken')
    .notEmpty()
    .withMessage('El refresh token es obligatorio'),

  handleValidationErrors
];

module.exports = {
  validateRegister,
  validateLogin,
  validateRefreshToken
};
