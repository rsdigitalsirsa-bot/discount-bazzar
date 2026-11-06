const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl:
    process.env.DATABASE_SSL === 'true'
      ? { rejectUnauthorized: false }
      : false,
});

pool.on('error', (error) => {
  console.error('Unexpected database pool error:', error);
});

const query = (text, params) => {
  return pool.query(text, params);
};

const connect = () => {
  return pool.connect();
};

module.exports = {
  pool,
  query,
  connect,
};
