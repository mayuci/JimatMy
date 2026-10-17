const pool = require('../config/database');

async function getHealth(req, res) {
  try {
    await pool.query('SELECT 1');
    return res.json({
      success: true,
      data: { api: 'available', database: 'connected' },
    });
  } catch (error) {
    return res.status(503).json({
      success: false,
      error: {
        code: 'DATABASE_UNAVAILABLE',
        message: 'API is available but the database connection failed',
      },
      data: { api: 'available', database: 'disconnected' },
    });
  }
}

module.exports = { getHealth };
