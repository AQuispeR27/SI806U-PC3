-- ============================================
-- SCHEMA PARA POSTGRESQL - SISTEMA CULQUI
-- ============================================

-- Eliminar tablas si existen (para reiniciar)
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS transacciones CASCADE;
DROP TABLE IF EXISTS metodos_pago CASCADE;
DROP TABLE IF EXISTS comercios CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS rate_limiting CASCADE;
DROP TABLE IF EXISTS logs_autenticacion CASCADE;
DROP TABLE IF EXISTS sesiones CASCADE;
DROP TABLE IF EXISTS rol_permisos CASCADE;
DROP TABLE IF EXISTS usuario_roles CASCADE;
DROP TABLE IF EXISTS permisos CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

-- Crear tipo ENUM personalizado para PostgreSQL
CREATE TYPE estado_usuario AS ENUM ('activo', 'inactivo', 'bloqueado');
CREATE TYPE dispositivo_tipo AS ENUM ('web', 'mobile', 'b2b');
CREATE TYPE tipo_cliente AS ENUM ('personal', 'empresa');
CREATE TYPE tipo_metodo_pago AS ENUM ('tarjeta', 'cuenta_bancaria');
CREATE TYPE estado_transaccion AS ENUM ('pendiente', 'completada', 'fallida', 'reembolsada');
CREATE TYPE tipo_transaccion AS ENUM ('pago', 'reembolso', 'transferencia');
CREATE TYPE canal_notificacion AS ENUM ('email', 'sms', 'push', 'sistema');
CREATE TYPE tipo_rate_limiting AS ENUM ('ip', 'usuario');

-- ============================================
-- TABLA: usuarios
-- ============================================
CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    estado estado_usuario DEFAULT 'activo' NOT NULL,
    verificado BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_email ON usuarios(email);
CREATE INDEX idx_estado ON usuarios(estado);

-- Trigger para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION update_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_usuarios
BEFORE UPDATE ON usuarios
FOR EACH ROW
EXECUTE FUNCTION update_fecha_actualizacion();

-- ============================================
-- TABLA: roles
-- ============================================
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLA: usuario_roles
-- ============================================
CREATE TABLE usuario_roles (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    rol_id INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
    FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE(usuario_id, rol_id)
);

CREATE INDEX idx_usuario_rol ON usuario_roles(usuario_id, rol_id);

-- ============================================
-- TABLA: permisos
-- ============================================
CREATE TABLE permisos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    recurso VARCHAR(50) NOT NULL,
    accion VARCHAR(50) NOT NULL
);

CREATE INDEX idx_recurso_accion ON permisos(recurso, accion);

-- ============================================
-- TABLA: rol_permisos
-- ============================================
CREATE TABLE rol_permisos (
    id BIGSERIAL PRIMARY KEY,
    rol_id INT NOT NULL,
    permiso_id INT NOT NULL,

    FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permiso_id) REFERENCES permisos(id) ON DELETE CASCADE,
    UNIQUE(rol_id, permiso_id)
);

CREATE INDEX idx_rol_permiso ON rol_permisos(rol_id, permiso_id);

-- ============================================
-- TABLA: sesiones
-- ============================================
CREATE TABLE sesiones (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    token VARCHAR(500) UNIQUE NOT NULL,
    refresh_token VARCHAR(500) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    dispositivo_tipo dispositivo_tipo DEFAULT 'web',
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMP NOT NULL,
    activa BOOLEAN DEFAULT TRUE,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_usuario_activa ON sesiones(usuario_id, activa);
CREATE INDEX idx_token ON sesiones(token);
CREATE INDEX idx_fecha_expiracion ON sesiones(fecha_expiracion);

-- ============================================
-- TABLA: logs_autenticacion
-- ============================================
CREATE TABLE logs_autenticacion (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT,
    evento VARCHAR(50) NOT NULL,
    resultado VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    ubicacion VARCHAR(100),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detalles JSONB,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE INDEX idx_usuario_fecha ON logs_autenticacion(usuario_id, fecha_hora);
CREATE INDEX idx_ip_fecha ON logs_autenticacion(ip_address, fecha_hora);
CREATE INDEX idx_evento ON logs_autenticacion(evento);

-- ============================================
-- TABLA: rate_limiting
-- ============================================
CREATE TABLE rate_limiting (
    id BIGSERIAL PRIMARY KEY,
    identificador VARCHAR(255) NOT NULL,
    tipo tipo_rate_limiting NOT NULL,
    intentos INT DEFAULT 0,
    ventana_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    bloqueado_hasta TIMESTAMP NULL,

    UNIQUE(identificador, tipo)
);

CREATE INDEX idx_identificador_tipo ON rate_limiting(identificador, tipo);
CREATE INDEX idx_bloqueado_hasta ON rate_limiting(bloqueado_hasta);

-- ============================================
-- TABLA: clientes
-- ============================================
CREATE TABLE clientes (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT UNIQUE NOT NULL,
    tipo_cliente tipo_cliente DEFAULT 'personal',
    documento_tipo VARCHAR(20),
    documento_numero VARCHAR(50),
    razon_social VARCHAR(255),
    direccion TEXT,
    ciudad VARCHAR(100),
    pais VARCHAR(50) DEFAULT 'Perú',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_documento ON clientes(documento_tipo, documento_numero);

-- ============================================
-- TABLA: metodos_pago
-- ============================================
CREATE TABLE metodos_pago (
    id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    tipo tipo_metodo_pago NOT NULL,
    proveedor VARCHAR(50),
    ultimos_4_digitos VARCHAR(4),
    fecha_expiracion DATE,
    es_principal BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_agregado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
);

CREATE INDEX idx_cliente_activo ON metodos_pago(cliente_id, activo);

-- ============================================
-- TABLA: transacciones
-- ============================================
CREATE TABLE transacciones (
    id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL,
    metodo_pago_id BIGINT,
    monto DECIMAL(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    estado estado_transaccion DEFAULT 'pendiente',
    tipo_transaccion tipo_transaccion DEFAULT 'pago',
    referencia VARCHAR(100) UNIQUE,
    descripcion TEXT,
    fee DECIMAL(12,2) DEFAULT 0.00,
    fecha_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_procesado TIMESTAMP NULL,

    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id) ON DELETE SET NULL
);

CREATE INDEX idx_cliente_fecha ON transacciones(cliente_id, fecha_transaccion);
CREATE INDEX idx_estado ON transacciones(estado);
CREATE INDEX idx_referencia ON transacciones(referencia);

-- ============================================
-- TABLA: comercios
-- ============================================
CREATE TABLE comercios (
    id BIGSERIAL PRIMARY KEY,
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

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_api_key ON comercios(api_key);
CREATE INDEX idx_ruc ON comercios(ruc);

-- ============================================
-- TABLA: notificaciones
-- ============================================
CREATE TABLE notificaciones (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    fecha_envio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    canal canal_notificacion DEFAULT 'sistema',

    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_usuario_leida ON notificaciones(usuario_id, leida);
CREATE INDEX idx_fecha_envio ON notificaciones(fecha_envio);

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
-- FIN DEL SCHEMA POSTGRESQL
-- ============================================
