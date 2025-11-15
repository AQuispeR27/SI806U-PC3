const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');

class JwtService {
  /**
   * Generar token de acceso
   */
  static generateToken(payload) {
    return jwt.sign(payload, jwtConfig.secret, {
      expiresIn: jwtConfig.expiresIn
    });
  }

  /**
   * Generar refresh token
   */
  static generateRefreshToken(payload) {
    return jwt.sign(payload, jwtConfig.refreshSecret, {
      expiresIn: jwtConfig.refreshExpiresIn
    });
  }

  /**
   * Verificar token de acceso
   */
  static verifyToken(token) {
    try {
      return jwt.verify(token, jwtConfig.secret);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Token expirado');
      }
      if (error.name === 'JsonWebTokenError') {
        throw new Error('Token inválido');
      }
      throw error;
    }
  }

  /**
   * Verificar refresh token
   */
  static verifyRefreshToken(token) {
    try {
      return jwt.verify(token, jwtConfig.refreshSecret);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Refresh token expirado');
      }
      if (error.name === 'JsonWebTokenError') {
        throw new Error('Refresh token inválido');
      }
      throw error;
    }
  }

  /**
   * Decodificar token sin verificar
   */
  static decodeToken(token) {
    return jwt.decode(token);
  }
}

module.exports = JwtService;
