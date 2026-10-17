const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');

const DEFAULT_TTL_MINUTES = 10;
const DEFAULT_MAX_ATTEMPTS = 5;
const BCRYPT_ROUNDS = 12;

function normaliseEmail(email) {
  return String(email ?? '').trim().toLowerCase();
}

function generateResetCode({ randomInt = crypto.randomInt } = {}) {
  const value = randomInt(0, 1000000);
  return String(value).padStart(6, '0');
}

function codeHash(email, code, secret) {
  return crypto
    .createHmac('sha256', secret)
    .update(`${email}|${code}`)
    .digest('hex');
}

function isExpired(expiresAt, now = new Date()) {
  return new Date(expiresAt).getTime() <= now.getTime();
}

function hasExceededAttempts(attemptCount, maxAttempts) {
  return Number(attemptCount) >= Number(maxAttempts);
}

function expiryFromNow(ttlMinutes, now = new Date()) {
  return new Date(now.getTime() + Number(ttlMinutes) * 60 * 1000);
}

function safeEqualHex(first, second) {
  const left = Buffer.from(String(first), 'hex');
  const right = Buffer.from(String(second), 'hex');
  if (left.length === 0 || right.length === 0 || left.length !== right.length) {
    return false;
  }
  return crypto.timingSafeEqual(left, right);
}

async function withTransaction(db, fn) {
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      // Ignore rollback failures and surface the original error.
    }
    throw error;
  } finally {
    client.release();
  }
}

async function findUserByEmail(db, email) {
  const result = await db.query(
    `SELECT user_id AS "userId", display_name AS "displayName"
       FROM users
      WHERE email = $1`,
    [email],
  );
  return result.rows[0] ?? null;
}

/**
 * Creates a new six-digit reset code for the user matching `email`. When the
 * email is not registered it returns `{ found: false }` without touching the
 * database, so callers can reply with a generic message. Any previously
 * unused code for the same user is invalidated inside a transaction.
 */
async function requestReset({
  db,
  email,
  secret,
  ttlMinutes = DEFAULT_TTL_MINUTES,
  now = new Date(),
  randomInt = crypto.randomInt,
}) {
  const normalised = normaliseEmail(email);
  const user = await findUserByEmail(db, normalised);
  if (!user) return { found: false };

  const code = generateResetCode({ randomInt });
  const hash = codeHash(normalised, code, secret);
  const expiresAt = expiryFromNow(ttlMinutes, now);

  await withTransaction(db, async (client) => {
    await client.query(
      `UPDATE password_resets
          SET used_at = $1
        WHERE user_id = $2 AND used_at IS NULL`,
      [now, user.userId],
    );
    await client.query(
      `INSERT INTO password_resets (user_id, code_hash, expires_at, attempt_count)
       VALUES ($1, $2, $3, 0)`,
      [user.userId, hash, expiresAt],
    );
  });

  return { found: true, code, expiresAt, displayName: user.displayName };
}

/**
 * Validates a submitted reset code and, on success, updates the password hash
 * and invalidates every unused reset code for the user. Attempts are counted
 * against the active code so brute-forcing a six-digit code is limited.
 * The whole password update and token invalidation run in one transaction.
 */
async function resetPassword({
  db,
  email,
  code,
  newPassword,
  secret,
  maxAttempts = DEFAULT_MAX_ATTEMPTS,
  now = new Date(),
}) {
  const normalised = normaliseEmail(email);
  const user = await findUserByEmail(db, normalised);
  if (!user) return { status: 'invalid_code' };

  const hash = codeHash(normalised, code, secret);

  return withTransaction(db, async (client) => {
    const result = await client.query(
      `SELECT password_reset_id AS "resetId", code_hash AS "codeHash",
              expires_at AS "expiresAt", attempt_count AS "attemptCount"
         FROM password_resets
        WHERE user_id = $1 AND used_at IS NULL
        ORDER BY created_at DESC
        LIMIT 1
        FOR UPDATE`,
      [user.userId],
    );
    const row = result.rows[0];
    if (!row) return { status: 'invalid_code' };

    if (isExpired(row.expiresAt, now)) {
      await client.query(
        'UPDATE password_resets SET used_at = $1 WHERE password_reset_id = $2',
        [now, row.resetId],
      );
      return { status: 'expired' };
    }

    if (hasExceededAttempts(row.attemptCount, maxAttempts)) {
      await client.query(
        'UPDATE password_resets SET used_at = $1 WHERE password_reset_id = $2',
        [now, row.resetId],
      );
      return { status: 'attempt_limit' };
    }

    if (!safeEqualHex(row.codeHash, hash)) {
      await client.query(
        'UPDATE password_resets SET attempt_count = attempt_count + 1 WHERE password_reset_id = $1',
        [row.resetId],
      );
      return { status: 'invalid_code' };
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await client.query(
      `UPDATE users
          SET password_hash = $1, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $2`,
      [passwordHash, user.userId],
    );
    await client.query(
      `UPDATE password_resets
          SET used_at = $1
        WHERE user_id = $2 AND (used_at IS NULL OR password_reset_id <> $3)`,
      [now, user.userId, row.resetId],
    );
    return { status: 'success' };
  });
}

async function cleanupExpiredPasswordResets(db, now = new Date()) {
  const result = await db.query('DELETE FROM password_resets WHERE expires_at <= $1', [now]);
  return result.rowCount ?? 0;
}

module.exports = {
  DEFAULT_MAX_ATTEMPTS,
  DEFAULT_TTL_MINUTES,
  cleanupExpiredPasswordResets,
  codeHash,
  expiryFromNow,
  generateResetCode,
  hasExceededAttempts,
  isExpired,
  normaliseEmail,
  requestReset,
  resetPassword,
  safeEqualHex,
  withTransaction,
};
