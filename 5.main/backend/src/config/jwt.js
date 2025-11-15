require('dotenv').config();

module.exports = {
  secret: process.env.JWT_SECRET || 'your_default_secret_change_in_production',
  expiresIn: process.env.JWT_EXPIRES_IN || '1h',
  refreshSecret: process.env.JWT_REFRESH_SECRET || 'your_refresh_secret',
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
};
