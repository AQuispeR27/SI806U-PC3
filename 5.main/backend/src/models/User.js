const { pool } = require('../config/database');

class User {
  /**
   * Buscar usuario por email
   */
  static async findByEmail(email) {
    try {
      const [rows] = await pool.query(
        `SELECT
          id,
          email,
          password_hash,
          nombre,
          apellido,
          telefono,
          estado,
          verificado,
          fecha_creacion
        FROM usuarios
        WHERE email = ?`,
        [email]
      );
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Error al buscar usuario: ${error.message}`);
    }
  }

  /**
   * Buscar usuario por ID
   */
  static async findById(id) {
    try {
      const [rows] = await pool.query(
        `SELECT
          id,
          email,
          nombre,
          apellido,
          telefono,
          estado,
          verificado,
          fecha_creacion
        FROM usuarios
        WHERE id = ?`,
        [id]
      );
      return rows[0] || null;
    } catch (error) {
      throw new Error(`Error al buscar usuario por ID: ${error.message}`);
    }
  }

  /**
   * Crear nuevo usuario
   */
  static async create({ email, password_hash, nombre, apellido, telefono = null }) {
    try {
      const [result] = await pool.query(
        `INSERT INTO usuarios (email, password_hash, nombre, apellido, telefono, estado, verificado)
         VALUES (?, ?, ?, ?, ?, 'activo', FALSE)`,
        [email, password_hash, nombre, apellido, telefono]
      );
      return result.insertId;
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        throw new Error('El email ya está registrado');
      }
      throw new Error(`Error al crear usuario: ${error.message}`);
    }
  }

  /**
   * Obtener roles del usuario
   */
  static async getRoles(userId) {
    try {
      const [rows] = await pool.query(
        `SELECT
          r.id,
          r.nombre,
          r.descripcion
         FROM usuario_roles ur
         INNER JOIN roles r ON ur.rol_id = r.id
         WHERE ur.usuario_id = ?`,
        [userId]
      );
      return rows;
    } catch (error) {
      throw new Error(`Error al obtener roles: ${error.message}`);
    }
  }

  /**
   * Obtener permisos del usuario
   */
  static async getPermisos(userId) {
    try {
      const [rows] = await pool.query(
        `SELECT DISTINCT
          p.id,
          p.nombre,
          p.recurso,
          p.accion
         FROM usuario_roles ur
         INNER JOIN rol_permisos rp ON ur.rol_id = rp.rol_id
         INNER JOIN permisos p ON rp.permiso_id = p.id
         WHERE ur.usuario_id = ?`,
        [userId]
      );
      return rows;
    } catch (error) {
      throw new Error(`Error al obtener permisos: ${error.message}`);
    }
  }

  /**
   * Asignar rol a usuario
   */
  static async assignRole(userId, rolId) {
    try {
      await pool.query(
        `INSERT INTO usuario_roles (usuario_id, rol_id)
         VALUES (?, ?)`,
        [userId, rolId]
      );
      return true;
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        return true; // Ya tiene ese rol
      }
      throw new Error(`Error al asignar rol: ${error.message}`);
    }
  }

  /**
   * Actualizar último acceso
   */
  static async updateLastAccess(userId) {
    try {
      await pool.query(
        `UPDATE usuarios SET fecha_actualizacion = NOW() WHERE id = ?`,
        [userId]
      );
      return true;
    } catch (error) {
      throw new Error(`Error al actualizar último acceso: ${error.message}`);
    }
  }
}

module.exports = User;
