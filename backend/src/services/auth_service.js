const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const {
  avatarPresetIds,
  getPresetId,
  removeUploadedAvatar,
  resolveUploadedAvatarPath,
} = require('./avatar_service');

const BCRYPT_ROUNDS = 12;
const TOKEN_LIFETIME = '1h';

function getJwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.length < 32) {
    throw new ApiError(503, 'AUTH_NOT_CONFIGURED', 'Authentication is not configured');
  }
  return secret;
}

function safeUser(row) {
  const avatarType = row.avatar_type === 'preset' && avatarPresetIds.includes(row.avatar_value)
    ? 'preset'
    : row.avatar_type === 'upload' && resolveUploadedAvatarPath(row.avatar_value)
      ? 'upload'
      : 'initial';
  return {
    userId: row.user_id,
    name: row.display_name,
    email: row.email,
    avatarType,
    avatarValue: avatarType === 'initial' ? null : row.avatar_value,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function createAccessToken(userId) {
  return jwt.sign({ type: 'access' }, getJwtSecret(), {
    algorithm: 'HS256',
    expiresIn: TOKEN_LIFETIME,
    subject: userId,
  });
}

async function registerUser(name, email, password) {
  const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
  try {
    const result = await pool.query(
      `INSERT INTO users (email, display_name, password_hash)
       VALUES ($1, $2, $3)
       RETURNING user_id, email, display_name, avatar_type, avatar_value,
                 created_at, updated_at`,
      [email, name, passwordHash],
    );
    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      throw new ApiError(409, 'EMAIL_ALREADY_REGISTERED', 'An account already uses this email');
    }
    throw error;
  }
}

async function authenticateUser(email, password) {
  const result = await pool.query(
    `SELECT user_id, email, display_name, password_hash, avatar_type,
            avatar_value, created_at, updated_at
       FROM users WHERE email = $1`,
    [email],
  );
  const row = result.rows[0];
  if (!row || !await bcrypt.compare(password, row.password_hash)) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect');
  }
  return row;
}

async function findUserById(userId) {
  const result = await pool.query(
    `SELECT user_id, email, display_name, avatar_type, avatar_value,
            created_at, updated_at
       FROM users WHERE user_id = $1`,
    [userId],
  );
  return result.rows[0] ?? null;
}

async function updateProfile(userId, updates) {
  const client = await pool.connect();
  let previous;
  try {
    await client.query('BEGIN');
    const current = await client.query(
      `SELECT user_id, email, display_name, avatar_type, avatar_value,
              created_at, updated_at
         FROM users WHERE user_id = $1 FOR UPDATE`,
      [userId],
    );
    if (!current.rowCount) {
      throw new ApiError(404, 'USER_NOT_FOUND', 'User profile was not found');
    }
    previous = current.rows[0];
    let avatarType = previous.avatar_type;
    let avatarValue = previous.avatar_value;
    if (updates.avatarType === 'initial') {
      avatarType = 'initial';
      avatarValue = null;
    } else if (updates.avatarType === 'preset') {
      avatarType = 'preset';
      avatarValue = getPresetId(updates.avatarValue);
    } else if (updates.avatarType !== undefined) {
      throw new ApiError(400, 'VALIDATION_ERROR', 'Uploaded avatars must use the avatar upload endpoint');
    }
    const result = await client.query(
      `UPDATE users
          SET display_name = $1, avatar_type = $2, avatar_value = $3,
              updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $4
        RETURNING user_id, email, display_name, avatar_type, avatar_value,
                  created_at, updated_at`,
      [updates.name ?? previous.display_name, avatarType, avatarValue, userId],
    );
    await client.query('COMMIT');
    if (
      previous.avatar_type === 'upload' &&
      (avatarType !== 'upload' || avatarValue !== previous.avatar_value)
    ) {
      await removeUploadedAvatar(previous.avatar_value).catch(() => {
        console.warn('Previous avatar file could not be removed');
      });
    }
    return result.rows[0];
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  authenticateUser,
  createAccessToken,
  findUserById,
  getJwtSecret,
  registerUser,
  safeUser,
  updateProfile,
};
