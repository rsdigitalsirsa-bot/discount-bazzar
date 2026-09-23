const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;

const pool = connectionString
  ? new Pool({
      connectionString,
      ssl: process.env.DATABASE_SSL === 'true'
        ? { rejectUnauthorized: false }
        : false,
    })
  : null;

async function query(text, params = []) {
  if (!pool) {
    throw new Error('DATABASE_URL is not configured');
  }

  return pool.query(text, params);
}

async function checkDatabase() {
  if (!pool) {
    return {
      connected: false,
      reason: 'DATABASE_URL is not configured',
    };
  }

  try {
    await pool.query('SELECT 1');
    return { connected: true };
  } catch (error) {
    return {
      connected: false,
      reason: error.message,
    };
  }
}

module.exports = {
  pool,
  query,
  checkDatabase,
};
