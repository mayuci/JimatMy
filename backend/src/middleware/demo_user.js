const pool = require('../config/database');

const DEMO_USER_EMAIL = 'built-in-planner@jimatmy.local';
const DEMO_DISPLAY_NAME = 'JimatMY Development User';
const AUTH_DISABLED_MARKER = 'authentication-disabled-for-built-in-development-user';

async function resolveDemoUser(req, res, next) {
  try {
    const result = await pool.query(
      `INSERT INTO users (email, display_name, password_hash)
       VALUES ($1, $2, $3)
       ON CONFLICT (email) DO UPDATE SET
         display_name = EXCLUDED.display_name,
         updated_at = CURRENT_TIMESTAMP
       RETURNING user_id`,
      [DEMO_USER_EMAIL, DEMO_DISPLAY_NAME, AUTH_DISABLED_MARKER],
    );
    req.auth = { userId: result.rows[0].user_id, mode: 'development' };
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = { resolveDemoUser };
