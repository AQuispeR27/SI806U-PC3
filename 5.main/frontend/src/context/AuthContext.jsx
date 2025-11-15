import React, { createContext, useState, useEffect } from 'react';
import AuthService from '../services/authService';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Verificar si hay sesión activa al cargar
  useEffect(() => {
    const checkAuth = async () => {
      try {
        if (AuthService.isAuthenticated()) {
          const storedUser = AuthService.getStoredUser();
          setUser(storedUser);
        }
      } catch (error) {
        console.error('Error al verificar autenticación:', error);
        setError(error.message);
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, []);

  /**
   * Login de usuario
   */
  const login = async (email, password) => {
    try {
      setLoading(true);
      setError(null);

      const response = await AuthService.login(email, password);
      setUser(response.data.usuario);

      return response;
    } catch (error) {
      setError(error.message);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  /**
   * Registro de usuario
   */
  const register = async (userData) => {
    try {
      setLoading(true);
      setError(null);

      const response = await AuthService.register(userData);

      return response;
    } catch (error) {
      setError(error.message);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  /**
   * Logout de usuario
   */
  const logout = async () => {
    try {
      setLoading(true);
      await AuthService.logout();
      setUser(null);
      setError(null);
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
      // Limpiar sesión aunque falle
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  /**
   * Actualizar usuario
   */
  const updateUser = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
  };

  const value = {
    user,
    loading,
    error,
    login,
    register,
    logout,
    updateUser,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
