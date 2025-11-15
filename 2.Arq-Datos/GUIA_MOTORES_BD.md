# Guía de Motores de Base de Datos - Sistema Culqui

Esta guía te ayudará a elegir y configurar el motor de base de datos adecuado para tu proyecto.

---

## 🎯 Motor Actual: MySQL

El proyecto está configurado por defecto para **MySQL 8.0+**

**Archivos relevantes:**
- `schema.sql` - Script para MySQL/MariaDB
- `backend/src/config/database.js` - Configuración de conexión

---

## 📊 Opciones de Motores de Base de Datos

### 1. MySQL (Por defecto) ⭐ RECOMENDADO

**Características:**
- ✅ Gratuito y open source
- ✅ Ideal para aplicaciones financieras
- ✅ ACID compliant (transacciones seguras)
- ✅ Excelente rendimiento en transacciones
- ✅ Amplia adopción y soporte

**Instalación:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install mysql-server

# macOS (Homebrew)
brew install mysql

# Windows
# Descargar desde: https://dev.mysql.com/downloads/installer/
```

**Configuración (.env):**
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=culqui_db
```

**Script SQL:**
```bash
mysql -u root -p < schema.sql
```

**Dependencia NPM:**
```bash
npm install mysql2
```

---

### 2. MariaDB (Compatible 100% con MySQL)

**Características:**
- ✅ Fork de MySQL (100% compatible)
- ✅ Mismo SQL que MySQL
- ✅ Mejor rendimiento en algunos casos
- ✅ Más features open source
- ✅ **NO requiere cambios en el código**

**Instalación:**

```bash
# Ubuntu/Debian
sudo apt install mariadb-server

# macOS
brew install mariadb

# Windows
# Descargar desde: https://mariadb.org/download/
```

**Configuración (.env):**
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=culqui_db
```

**Script SQL:**
```bash
# Mismo que MySQL
mysql -u root -p < schema.sql
```

**Dependencia NPM:**
```bash
# Usa la misma librería que MySQL
npm install mysql2
```

---

### 3. PostgreSQL ⭐ RECOMENDADO PARA ESCALAR

**Características:**
- ✅ Más robusto que MySQL
- ✅ Soporte JSON superior
- ✅ Mejor para consultas complejas
- ✅ Excelente escalabilidad
- ✅ ACID compliant
- ⚠️ Requiere ajustes en SQL y código

**Instalación:**

```bash
# Ubuntu/Debian
sudo apt install postgresql postgresql-contrib

# macOS
brew install postgresql

# Windows
# Descargar desde: https://www.postgresql.org/download/windows/
```

**Configuración (.env):**
```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=tu_password
DB_NAME=culqui_db
```

**Script SQL:**
```bash
# Usar el schema específico de PostgreSQL
psql -U postgres -d culqui_db -f schema-postgresql.sql
```

**Dependencia NPM:**
```bash
# Reemplazar mysql2 por pg
npm uninstall mysql2
npm install pg
```

**Cambios en el código:**

`backend/src/config/database.js`:
```javascript
const { Pool } = require('pg');
require('dotenv').config();

// Pool de conexiones para PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'culqui_db',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Función para verificar la conexión
const testConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('✓ Conexión a PostgreSQL establecida correctamente');
    client.release();
    return true;
  } catch (error) {
    console.error('✗ Error al conectar con PostgreSQL:', error.message);
    return false;
  }
};

module.exports = {
  pool,
  testConnection,
  // Wrapper para mantener compatibilidad con sintaxis de MySQL
  query: async (text, params) => {
    const start = Date.now();
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { text, duration, rows: res.rowCount });
    return res.rows; // PostgreSQL retorna .rows en lugar de array directo
  }
};
```

**Diferencias en Queries:**

```javascript
// MySQL - Placeholders con ?
const [rows] = await pool.query('SELECT * FROM usuarios WHERE email = ?', [email]);

// PostgreSQL - Placeholders con $1, $2, etc.
const result = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email]);
const rows = result.rows;
```

---

### 4. SQLite (Solo desarrollo/testing)

**Características:**
- ✅ Cero configuración
- ✅ Archivo único
- ✅ Perfecto para testing
- ❌ NO para producción
- ❌ Sin concurrencia
- ❌ Sin escalabilidad

**Instalación:**
```bash
# No requiere servidor, solo la librería
npm install sqlite3
```

**Configuración (.env):**
```env
DB_PATH=./culqui.db
```

**Código:**
```javascript
const sqlite3 = require('sqlite3').verbose();

const db = new sqlite3.Database('./culqui.db', (err) => {
  if (err) {
    console.error(err.message);
  }
  console.log('Conectado a SQLite');
});
```

---

## ☁️ Opciones de Base de Datos en la Nube

### 1. PlanetScale (MySQL) ⭐ RECOMENDADO

**Características:**
- MySQL compatible (serverless)
- Branching de base de datos
- Auto-scaling
- **Gratis hasta 5GB**

**URL:** https://planetscale.com/

**Configuración (.env):**
```env
DB_HOST=your-db.us-east-1.psdb.cloud
DB_PORT=3306
DB_USER=your_username
DB_PASSWORD=your_password
DB_NAME=culqui_db
DB_SSL=true
```

**Código (agregar SSL):**
```javascript
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: {
    rejectUnauthorized: true
  }
});
```

---

### 2. Supabase (PostgreSQL)

**Características:**
- PostgreSQL managed
- APIs automáticas
- Auth incluido
- **Gratis hasta 500MB**

**URL:** https://supabase.com/

**Configuración (.env):**
```env
DB_HOST=db.your-project.supabase.co
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=postgres
```

---

### 3. Railway

**Características:**
- Soporta MySQL y PostgreSQL
- Deploy automático
- **$5/mes**

**URL:** https://railway.app/

---

### 4. Render

**Características:**
- PostgreSQL managed
- Gratis con limitaciones
- Fácil setup

**URL:** https://render.com/

---

## 🔄 Cómo Migrar entre Motores

### De MySQL a PostgreSQL

**Paso 1:** Exportar datos de MySQL
```bash
mysqldump -u root -p culqui_db > culqui_backup.sql
```

**Paso 2:** Convertir dump a PostgreSQL
```bash
# Usar herramienta de conversión
# https://github.com/lanyrd/mysql-postgresql-converter

# O manualmente ajustar:
# - AUTO_INCREMENT → SERIAL
# - ENUM → CREATE TYPE
# - Backticks ` → Comillas dobles "
```

**Paso 3:** Importar a PostgreSQL
```bash
psql -U postgres -d culqui_db -f schema-postgresql.sql
```

**Paso 4:** Actualizar código (ver sección PostgreSQL arriba)

---

### De PostgreSQL a MySQL

**Paso 1:** Exportar datos
```bash
pg_dump -U postgres culqui_db > culqui_backup.sql
```

**Paso 2:** Convertir a MySQL
```bash
# Ajustar manualmente:
# - SERIAL → AUTO_INCREMENT
# - TYPE enums → ENUM()
# - Comillas dobles " → Backticks `
```

**Paso 3:** Importar a MySQL
```bash
mysql -u root -p culqui_db < schema.sql
```

---

## 📋 Tabla Comparativa

| Característica | MySQL | MariaDB | PostgreSQL | SQLite |
|---------------|-------|---------|------------|--------|
| **Tipo** | RDBMS | RDBMS | RDBMS | Embedded |
| **Licencia** | GPL | GPL | PostgreSQL | Public Domain |
| **Rendimiento (Transacciones)** | Excelente | Excelente | Muy Bueno | Bueno |
| **Escalabilidad** | Alta | Alta | Muy Alta | Baja |
| **JSON Support** | Básico | Básico | Avanzado | Básico |
| **Complejidad** | Baja | Baja | Media | Muy Baja |
| **Comunidad** | Muy Grande | Grande | Grande | Grande |
| **Ideal para** | Fintech, Apps | Same as MySQL | Apps complejas | Testing |
| **Hosting Gratis** | ✅ | ✅ | ✅ | ✅ |

---

## 🎯 Recomendación Final

### Para tu proyecto Culqui:

**Opción 1: MySQL + PlanetScale (RECOMENDADO)**
- ✅ Código ya listo
- ✅ Gratis hasta 5GB
- ✅ Ideal para fintech
- ✅ Fácil escalabilidad

**Opción 2: PostgreSQL + Supabase**
- ✅ Más robusto
- ✅ Gratis hasta 500MB
- ⚠️ Requiere ajustes de código

**Opción 3: MySQL Local + Migrar después**
- ✅ Desarrollo local gratis
- ✅ Sin cambios
- ✅ Migrar a la nube cuando sea necesario

---

## 📝 Checklist de Migración

Si decides cambiar de motor:

- [ ] Exportar datos actuales
- [ ] Instalar nuevo motor
- [ ] Ejecutar schema correspondiente
- [ ] Actualizar dependencias NPM
- [ ] Modificar `config/database.js`
- [ ] Ajustar queries si es necesario
- [ ] Actualizar variables de entorno (.env)
- [ ] Probar conexión
- [ ] Migrar datos
- [ ] Ejecutar tests
- [ ] Desplegar

---

## 🆘 Troubleshooting

### Error: "Cannot connect to MySQL"
```bash
# Verificar que el servicio esté corriendo
sudo systemctl status mysql

# Iniciar MySQL
sudo systemctl start mysql

# Verificar puerto
netstat -tlnp | grep 3306
```

### Error: "Access denied for user"
```bash
# Resetear password de root
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'new_password';
FLUSH PRIVILEGES;
```

### Error: "Database does not exist"
```bash
# Crear base de datos
mysql -u root -p
CREATE DATABASE culqui_db;
```

---

## 📚 Recursos Adicionales

- **MySQL Docs:** https://dev.mysql.com/doc/
- **PostgreSQL Docs:** https://www.postgresql.org/docs/
- **MariaDB Docs:** https://mariadb.com/kb/en/
- **PlanetScale:** https://planetscale.com/docs
- **Supabase:** https://supabase.com/docs

---

¿Necesitas ayuda con la migración? Consulta esta guía y los archivos de schema incluidos en este proyecto.
