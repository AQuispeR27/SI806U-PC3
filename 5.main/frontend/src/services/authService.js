const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

/**
 * Servicio de autenticación para comunicarse con el backend
 */
class AuthService {
  /**
   * Registrar nuevo usuario
   */
  static async register(userData) {
    try {
      const response = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error?.message || 'Error al registrar usuario');
      }

      return data;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Iniciar sesión
   */
  static async login(email, password) {
    try {
      const response = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error?.message || 'Error al iniciar sesión');
      }

      // Almacenar tokens en localStorage
      if (data.data.token) {
        localStorage.setItem('token', data.data.token);
        localStorage.setItem('refreshToken', data.data.refreshToken);
        localStorage.setItem('user', JSON.stringify(data.data.usuario));
      }

      return data;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Cerrar sesión
   */
  static async logout() {
    try {
      const token = localStorage.getItem('token');

      if (token) {
        await fetch(`${API_URL}/auth/logout`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
        });
      }

      // Limpiar localStorage
      localStorage.removeItem('token');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('user');

      return true;
    } catch (error) {
      // Limpiar localStorage incluso si falla la petición
      localStorage.removeItem('token');
      localStorage.removeItem('refreshToken');
      localStorage.removeItem('user');
      throw error;
    }
  }

  /**
   * Renovar token
   */
  static async refreshToken() {
    try {
      const refreshToken = localStorage.getItem('refreshToken');

      if (!refreshToken) {
        throw new Error('No hay refresh token');
      }

      const response = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ refreshToken }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error?.message || 'Error al renovar token');
      }

      localStorage.setItem('token', data.data.token);

      return data.data.token;
    } catch (error) {
      // Si falla, hacer logout
      this.logout();
      throw error;
    }
  }

  /**
   * Obtener datos del usuario actual
   */
  static async getCurrentUser() {
    try {
      const token = localStorage.getItem('token');

      if (!token) {
        return null;
      }

      const response = await fetch(`${API_URL}/auth/me`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      const data = await response.json();

      if (!response.ok) {
        // Si el token expiró, intentar renovar
        if (response.status === 401) {
          await this.refreshToken();
          return this.getCurrentUser(); // Reintentar
        }
        throw new Error(data.error?.message || 'Error al obtener usuario');
      }

      return data.data;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Verificar si hay sesión activa
   */
  static isAuthenticated() {
    const token = localStorage.getItem('token');
    return !!token;
  }

  /**
   * Obtener token almacenado
   */
  static getToken() {
    return localStorage.getItem('token');
  }

  /**
   * Obtener usuario almacenado
   */
  static getStoredUser() {
    const userJson = localStorage.getItem('user');
    return userJson ? JSON.parse(userJson) : null;
  }
}

export default AuthService;
