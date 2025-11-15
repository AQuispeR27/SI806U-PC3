-- ============================================
-- SCHEMA DE BASE DE DATOS - SISTEMA CULQUI
-- ============================================

-- Eliminar tablas si existen (para reiniciar)
DROP TABLE IF EXISTS notificaciones;
DROP TABLE IF EXISTS transacciones;
DROP TABLE IF EXISTS metodos_pago;
DROP TABLE IF EXISTS comercios;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS rate_limiting;
DROP TABLE IF EXISTS logs_autenticacion;
DROP TABLE IF EXISTS sesiones;
DROP TABLE IF EXISTS rol_permisos;
DROP TABLE IF EXISTS usuario_roles;
DROP TABLE IF EXISTS permisos;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS usuarios;

-- ============================================
-- TABLA: usuarios
-- ============================================
CREATE TABLE usuarios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    estado ENUM('activo', 'inactivo', 'bloqueado') DEFAULT 'activo' NOT NULL,
    verificado BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_email (email),
    INDEX idx_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: roles
-- ============================================
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: usuario_roles
-- ============================================
CREATE TABLE usuario_roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    rol_id INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE INDEX idx_usuario_rol (usuario_id, rol_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: permisos
-- ============================================
CREATE TABLE permisos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    recurso VARCHAR(50) NOT NULL,
    accion VARCHAR(50) NOT NULL,

    INDEX idx_recurso_accion (recurso, accion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: rol_permisos
-- ============================================
CREATE TABLE rol_permisos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rol_id INT NOT NULL,
    permiso_id INT NOT NULL,

    FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permiso_id) REFERENCES permisos(id) ON DELETE CASCADE,
    UNIQUE INDEX idx_rol_permiso (rol_id, permiso_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: sesiones
-- ============================================
CREATE TABLE sesiones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    token VARCHAR(500) UNIQUE NOT NULL,
    refresh_token VARCHAR(500) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    dispositivo_tipo ENUM('web', 'mobile', 'b2b') DEFAULT 'web',
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NOT NULL,
    activa BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario_activa (usuario_id, activa),
    INDEX idx_token (token(255)),
    INDEX idx_fecha_expiracion (fecha_expiracion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: logs_autenticacion
-- ============================================
CREATE TABLE logs_autenticacion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT,
    evento VARCHAR(50) NOT NULL,
    resultado VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    ubicacion VARCHAR(100),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detalles JSON,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_usuario_fecha (usuario_id, fecha_hora),
    INDEX idx_ip_fecha (ip_address, fecha_hora),
    INDEX idx_evento (evento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: rate_limiting
-- ============================================
CREATE TABLE rate_limiting (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    identificador VARCHAR(255) NOT NULL,
    tipo ENUM('ip', 'usuario') NOT NULL,
    intentos INT DEFAULT 0,
    ventana_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    bloqueado_hasta TIMESTAMP NULL,

    UNIQUE INDEX idx_identificador_tipo (identificador, tipo),
    INDEX idx_bloqueado_hasta (bloqueado_hasta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: clientes
-- ============================================
CREATE TABLE clientes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT UNIQUE NOT NULL,
    tipo_cliente ENUM('personal', 'empresa') DEFAULT 'personal',
    documento_tipo VARCHAR(20),
    documento_numero VARCHAR(50),
    razon_social VARCHAR(255),
    direccion TEXT,
    ciudad VARCHAR(100),
    pais VARCHAR(50) DEFAULT 'Perú',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_documento (documento_tipo, documento_numero)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: metodos_pago
-- ============================================
CREATE TABLE metodos_pago (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    tipo ENUM('tarjeta', 'cuenta_bancaria') NOT NULL,
    proveedor VARCHAR(50),
    ultimos_4_digitos VARCHAR(4),
    fecha_expiracion DATE,
    es_principal BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    INDEX idx_cliente_activo (cliente_id, activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: transacciones
-- ============================================
CREATE TABLE transacciones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    metodo_pago_id BIGINT,
    monto DECIMAL(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    estado ENUM('pendiente', 'completada', 'fallida', 'reembolsada') DEFAULT 'pendiente',
    tipo_transaccion ENUM('pago', 'reembolso', 'transferencia') DEFAULT 'pago',
    referencia VARCHAR(100) UNIQUE,
    descripcion TEXT,
    fee DECIMAL(12,2) DEFAULT 0.00,
    fecha_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_procesado TIMESTAMP NULL,

    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id) ON DELETE SET NULL,
    INDEX idx_cliente_fecha (cliente_id, fecha_transaccion),
    INDEX idx_estado (estado),
    INDEX idx_referencia (referencia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: comercios
-- ============================================
CREATE TABLE comercios (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT UNIQUE NOT NULL,
    nombre_comercial VARCHAR(255) NOT NULL,
    ruc VARCHAR(11) UNIQUE NOT NULL,
    razon_social VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    url_webhook VARCHAR(255),
    api_key VARCHAR(255) UNIQUE NOT NULL,
    api_secret VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_api_key (api_key),
    INDEX idx_ruc (ruc)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- TABLA: notificaciones
-- ============================================
CREATE TABLE notificaciones (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    canal ENUM('email', 'sms', 'push', 'sistema') DEFAULT 'sistema',

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    INDEX idx_usuario_leida (usuario_id, leida),
    INDEX idx_fecha_envio (fecha_envio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar roles por defecto
INSERT INTO roles (nombre, descripcion) VALUES
('super_admin', 'Administrador total del sistema'),
('admin', 'Administrador con permisos limitados'),
('comercio', 'Usuario tipo comercio'),
('cliente', 'Cliente final'),
('soporte', 'Personal de soporte técnico');

-- Insertar permisos por defecto
INSERT INTO permisos (nombre, descripcion, recurso, accion) VALUES
-- Permisos de usuarios
('usuarios:crear', 'Crear nuevos usuarios', 'usuarios', 'crear'),
('usuarios:leer', 'Ver usuarios', 'usuarios', 'leer'),
('usuarios:actualizar', 'Actualizar usuarios', 'usuarios', 'actualizar'),
('usuarios:eliminar', 'Eliminar usuarios', 'usuarios', 'eliminar'),

-- Permisos de transacciones
('transacciones:crear', 'Crear transacciones', 'transacciones', 'crear'),
('transacciones:leer', 'Ver transacciones', 'transacciones', 'leer'),
('transacciones:actualizar', 'Actualizar transacciones', 'transacciones', 'actualizar'),
('transacciones:reembolsar', 'Reembolsar transacciones', 'transacciones', 'reembolsar'),

-- Permisos de comercios
('comercios:crear', 'Crear comercios', 'comercios', 'crear'),
('comercios:leer', 'Ver comercios', 'comercios', 'leer'),
('comercios:actualizar', 'Actualizar comercios', 'comercios', 'actualizar'),
('comercios:gestionar_api', 'Gestionar API keys', 'comercios', 'gestionar_api'),

-- Permisos de reportes
('reportes:generar', 'Generar reportes', 'reportes', 'generar'),
('reportes:exportar', 'Exportar reportes', 'reportes', 'exportar'),

-- Permisos de dashboard
('dashboard:ver', 'Ver dashboard', 'dashboard', 'ver');

-- Asignar permisos a rol super_admin (todos los permisos)
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT 1, id FROM permisos;

-- Asignar permisos a rol cliente (permisos básicos)
INSERT INTO rol_permisos (rol_id, permiso_id)
SELECT 4, id FROM permisos WHERE nombre IN (
    'transacciones:crear',
    'transacciones:leer',
    'dashboard:ver'
);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger para limpiar sesiones expiradas automáticamente
DELIMITER //
CREATE TRIGGER cleanup_expired_sessions
BEFORE INSERT ON sesiones
FOR EACH ROW
BEGIN
    DELETE FROM sesiones
    WHERE fecha_expiracion < NOW()
    AND activa = TRUE;
END//
DELIMITER ;

-- ============================================
-- FIN DEL SCHEMA
-- ============================================
