const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Session = require('../models/Session');
const JwtService = require('./jwtService');
const { pool } = require('../config/database');

class AuthService {
  /**
   * Registrar nuevo usuario
   */
  static async register({ email, password, nombre, apellido, telefono }) {
    try {
      // Validar que el email no exista
      const existingUser = await User.findByEmail(email);
      if (existingUser) {
        throw new Error('El email ya está registrado');
      }

      // Hashear password
      const password_hash = await bcrypt.hash(password, 10);

      // Crear usuario
      const userId = await User.create({
        email,
        password_hash,
        nombre,
        apellido,
        telefono
      });

      // Asignar rol de cliente por defecto (rol_id = 4)
      await User.assignRole(userId, 4);

      // Obtener usuario creado
      const usuario = await User.findById(userId);

      return {
        usuario: {
          id: usuario.id,
          email: usuario.email,
          nombre: usuario.nombre,
          apellido: usuario.apellido
        }
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Login de usuario
   */
  static async login({ email, password, ipAddress, userAgent }) {
    try {
      // 1. Buscar usuario por email
      const user = await User.findByEmail(email);

      if (!user) {
        // Registrar intento fallido
        await this.logFailedAttempt(null, email, ipAddress, 'usuario_no_existe');
        throw new Error('Credenciales inválidas');
      }

      // 2. Verificar estado de la cuenta
      if (user.estado !== 'activo') {
        await this.logFailedAttempt(user.id, email, ipAddress, 'cuenta_inactiva');
        throw new Error('Cuenta inactiva o bloqueada');
      }

      // 3. Comparar password
      const isPasswordValid = await bcrypt.compare(password, user.password_hash);

      if (!isPasswordValid) {
        // Registrar intento fallido
        await this.logFailedAttempt(user.id, email, ipAddress, 'password_incorrecto');
        throw new Error('Credenciales inválidas');
      }

      // 4. Obtener roles y permisos
      const roles = await User.getRoles(user.id);
      const permisos = await User.getPermisos(user.id);

      // 5. Generar tokens
      const tokenPayload = {
        userId: user.id,
        email: user.email,
        roles: roles.map(r => r.nombre)
      };

      const token = JwtService.generateToken(tokenPayload);
      const refreshToken = JwtService.generateRefreshToken({ userId: user.id });

      // 6. Crear sesión en BD
      await Session.create({
        usuario_id: user.id,
        token,
        refresh_token: refreshToken,
        ip_address: ipAddress,
        user_agent: userAgent,
        dispositivo_tipo: 'web'
      });

      // 7. Registrar login exitoso
      await this.logSuccessfulLogin(user.id, ipAddress, userAgent);

      // 8. Actualizar último acceso
      await User.updateLastAccess(user.id);

      // 9. Retornar respuesta
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
    } catch (error) {
      throw error;
    }
  }

  /**
   * Logout de usuario
   */
  static async logout(token) {
    try {
      await Session.deactivate(token);
      return true;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Renovar token
   */
  static async refreshToken(refreshToken) {
    try {
      // Verificar refresh token
      const decoded = JwtService.verifyRefreshToken(refreshToken);

      // Buscar usuario
      const user = await User.findById(decoded.userId);
      if (!user) {
        throw new Error('Usuario no encontrado');
      }

      // Obtener roles
      const roles = await User.getRoles(user.id);

      // Generar nuevo token
      const newToken = JwtService.generateToken({
        userId: user.id,
        email: user.email,
        roles: roles.map(r => r.nombre)
      });

      return { token: newToken };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Registrar intento fallido
   */
  static async logFailedAttempt(userId, email, ipAddress, razon) {
    try {
      await pool.query(
        `INSERT INTO logs_autenticacion
         (usuario_id, evento, resultado, ip_address, detalles)
         VALUES (?, 'failed_login', 'fallido', ?, ?)`,
        [userId, ipAddress, JSON.stringify({ email, razon })]
      );
    } catch (error) {
      console.error('Error al registrar intento fallido:', error);
    }
  }

  /**
   * Registrar login exitoso
   */
  static async logSuccessfulLogin(userId, ipAddress, userAgent) {
    try {
      await pool.query(
        `INSERT INTO logs_autenticacion
         (usuario_id, evento, resultado, ip_address, user_agent, detalles)
         VALUES (?, 'login', 'exito', ?, ?, ?)`,
        [userId, ipAddress, userAgent, JSON.stringify({ dispositivo: 'web' })]
      );
    } catch (error) {
      console.error('Error al registrar login exitoso:', error);
    }
  }
}

module.exports = AuthService;
