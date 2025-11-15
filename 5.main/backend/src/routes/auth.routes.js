const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const { loginLimiter } = require('../middleware/rateLimiter');
const { validateRegister, validateLogin, validateRefreshToken } = require('../middleware/validator');
const { verifyToken } = require('../middleware/authMiddleware');

/**
 * POST /api/auth/register
 * Registrar nuevo usuario
 */
router.post('/register', validateRegister, AuthController.register);

/**
 * POST /api/auth/login
 * Iniciar sesión
 */
router.post('/login', loginLimiter, validateLogin, AuthController.login);

/**
 * POST /api/auth/logout
 * Cerrar sesión (requiere autenticación)
 */
router.post('/logout', verifyToken, AuthController.logout);

/**
 * POST /api/auth/refresh
 * Renovar token de acceso
 */
router.post('/refresh', validateRefreshToken, AuthController.refresh);

/**
 * GET /api/auth/me
 * Obtener datos del usuario actual (requiere autenticación)
 */
router.get('/me', verifyToken, AuthController.me);

module.exports = router;
