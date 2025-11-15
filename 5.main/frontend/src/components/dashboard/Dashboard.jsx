import React from 'react';
import { useNavigate } from 'react-router-dom';
import useAuth from '../../hooks/useAuth';
import Header from '../common/Header';
import '../../styles/Dashboard.css';

const Dashboard = () => {
  const { user } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="dashboard-container">
      <Header />

      <main className="dashboard-main">
        <div className="dashboard-welcome">
          <h1>Bienvenido, {user?.nombre}!</h1>
          <p>Has iniciado sesión exitosamente en Culqui</p>
        </div>

        <div className="dashboard-grid">
          <div className="dashboard-card">
            <h2>Información de Usuario</h2>
            <div className="user-info">
              <p><strong>Nombre:</strong> {user?.nombre} {user?.apellido}</p>
              <p><strong>Email:</strong> {user?.email}</p>
              <p><strong>Roles:</strong> {user?.roles?.join(', ')}</p>
            </div>
          </div>

          <div className="dashboard-card">
            <h2>Permisos</h2>
            <div className="permissions-list">
              {user?.permisos && user.permisos.length > 0 ? (
                <ul>
                  {user.permisos.map((permiso, index) => (
                    <li key={index}>{permiso}</li>
                  ))}
                </ul>
              ) : (
                <p>No hay permisos asignados</p>
              )}
            </div>
          </div>

          <div className="dashboard-card">
            <h2>Acciones Rápidas</h2>
            <div className="quick-actions">
              <button className="action-btn">Ver Transacciones</button>
              <button className="action-btn">Configuración</button>
              <button className="action-btn">Soporte</button>
            </div>
          </div>

          <div className="dashboard-card">
            <h2>Estadísticas</h2>
            <div className="stats">
              <div className="stat-item">
                <span className="stat-value">0</span>
                <span className="stat-label">Transacciones</span>
              </div>
              <div className="stat-item">
                <span className="stat-value">$0.00</span>
                <span className="stat-label">Balance</span>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Dashboard;
