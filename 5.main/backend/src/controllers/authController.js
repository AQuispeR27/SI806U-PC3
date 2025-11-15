const AuthService = require('../services/authService');

class AuthController {
  /**
   * POST /api/auth/register
   * Registrar nuevo usuario
   */
  static async register(req, res) {
    try {
      const { email, password, nombre, apellido, telefono } = req.body;

      const result = await AuthService.register({
        email,
        password,
        nombre,
        apellido,
        telefono
      });

      return res.status(201).json({
        success: true,
        data: result,
        message: 'Usuario registrado exitosamente'
      });
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: {
          message: error.message
        }
      });
    }
  }

  /**
   * POST /api/auth/login
   * Iniciar sesión
   */
  static async login(req, res) {
    try {
      const { email, password } = req.body;
      const ipAddress = req.ip || req.connection.remoteAddress;
      const userAgent = req.headers['user-agent'];

      const result = await AuthService.login({
        email,
        password,
        ipAddress,
        userAgent
      });

      return res.status(200).json({
        success: true,
        data: result,
        message: 'Login exitoso'
      });
    } catch (error) {
      const statusCode = error.message === 'Credenciales inválidas' ? 401 : 400;
      return res.status(statusCode).json({
        success: false,
        error: {
          message: error.message
        }
      });
    }
  }

  /**
   * POST /api/auth/logout
   * Cerrar sesión
   */
  static async logout(req, res) {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader) {
        return res.status(400).json({
          success: false,
          error: { message: 'Token no proporcionado' }
        });
      }

      const token = authHeader.split(' ')[1];
      await AuthService.logout(token);

      return res.status(200).json({
        success: true,
        message: 'Logout exitoso'
      });
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.message }
      });
    }
  }

  /**
   * POST /api/auth/refresh
   * Renovar token
   */
  static async refresh(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          error: { message: 'Refresh token no proporcionado' }
        });
      }

      const result = await AuthService.refreshToken(refreshToken);

      return res.status(200).json({
        success: true,
        data: result,
        message: 'Token renovado exitosamente'
      });
    } catch (error) {
      return res.status(401).json({
        success: false,
        error: { message: error.message }
      });
    }
  }

  /**
   * GET /api/auth/me
   * Obtener datos del usuario actual
   */
  static async me(req, res) {
    try {
      // El middleware authMiddleware ya agregó req.user
      const User = require('../models/User');
      const usuario = await User.findById(req.user.userId);

      if (!usuario) {
        return res.status(404).json({
          success: false,
          error: { message: 'Usuario no encontrado' }
        });
      }

      const roles = await User.getRoles(usuario.id);

      return res.status(200).json({
        success: true,
        data: {
          id: usuario.id,
          nombre: usuario.nombre,
          apellido: usuario.apellido,
          email: usuario.email,
          telefono: usuario.telefono,
          roles: roles.map(r => r.nombre)
        }
      });
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: { message: error.message }
      });
    }
  }
}

module.exports = AuthController;
