const { pool } = require('../config/database');

class Session {
  /**
   * Crear nueva sesión
   */
  static async create({ usuario_id, token, refresh_token, ip_address, user_agent, dispositivo_tipo = 'web' }) {
    try {
      // Calcular fecha de expiración (1 hora desde ahora)
      const fechaExpiracion = new Date(Date.now() + 60 * 60 * 1000);

      const [result] = await pool.query(
        `INSERT INTO sesiones
         (usuario_id, token, refresh_token, ip_address, user_agent, dispositivo_tipo, fecha_expiracion)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [usuario_id, token, refresh_token, ip_address, user_agent, dispositivo_tipo, fechaExpiracion]
      );

      return result.insertId;
    } catch (error) {
      throw new Error(`Error al crear sesión: ${error.message}`);
    }
  }

  /**
   * Buscar sesión por token
   */
  static async findByToken(token) {
    try {
      const [rows] = await pool.query(
        `SELECT * FROM sesiones WHERE token = ? AND activa = TRUE`,
        [token]
      );
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Error al buscar sesión: ${error.message}`);
    }
  }

  /**
   * Desactivar sesión (logout)
   */
  static async deactivate(token) {
    try {
      await pool.query(
        `UPDATE sesiones SET activa = FALSE WHERE token = ?`,
        [token]
      );
      return true;
    } catch (error) {
      throw new Error(`Error al desactivar sesión: ${error.message}`);
    }
  }

  /**
   * Desactivar todas las sesiones de un usuario
   */
  static async deactivateAllUserSessions(userId) {
    try {
      await pool.query(
        `UPDATE sesiones SET activa = FALSE WHERE usuario_id = ?`,
        [userId]
      );
      return true;
    } catch (error) {
      throw new Error(`Error al desactivar sesiones del usuario: ${error.message}`);
    }
  }

  /**
   * Limpiar sesiones expiradas
   */
  static async cleanExpiredSessions() {
    try {
      await pool.query(
        `UPDATE sesiones SET activa = FALSE WHERE fecha_expiracion < NOW() AND activa = TRUE`
      );
      return true;
    } catch (error) {
      throw new Error(`Error al limpiar sesiones expiradas: ${error.message}`);
    }
  }

  /**
   * Obtener sesiones activas de un usuario
   */
  static async getActiveSessions(userId) {
    try {
      const [rows] = await pool.query(
        `SELECT
          id,
          ip_address,
          user_agent,
          dispositivo_tipo,
          fecha_inicio,
          fecha_expiracion
         FROM sesiones
         WHERE usuario_id = ? AND activa = TRUE
         ORDER BY fecha_inicio DESC`,
        [userId]
      );
      return rows;
    } catch (error) {
      throw new Error(`Error al obtener sesiones activas: ${error.message}`);
    }
  }
}

module.exports = Session;
