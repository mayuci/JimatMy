const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const {
  getEmail,
  getObjectBody,
  getPassword,
  getResetCode,
} = require('../utils/auth_validation');
const passwordResetService = require('../services/password_reset_service');
const {
  buildPasswordResetEmail,
  createMailer,
  getMailerFrom,
  sendMail,
} = require('../services/mail_service');

const GENERIC_FORGOT_MESSAGE =
  'If an account exists for that email, a reset code has been sent.';
const GENERIC_RESET_MESSAGE =
  'Your password has been reset. You can now log in.';

function getSecret() {
  const secret = process.env.PASSWORD_RESET_SECRET;
  if (!secret || secret.length < 16) {
    throw new ApiError(503, 'PASSWORD_RESET_NOT_CONFIGURED', 'Password reset is not configured');
  }
  return secret;
}

function getTtlMinutes() {
  const raw = process.env.PASSWORD_RESET_CODE_TTL_MINUTES;
  if (raw === undefined || raw === '') return passwordResetService.DEFAULT_TTL_MINUTES;
  const value = Number(raw);
  return Number.isFinite(value) && value > 0 ? value : passwordResetService.DEFAULT_TTL_MINUTES;
}

async function sendResetEmail({ to, code, expiresInMinutes, userName }) {
  const mailer = createMailer();
  if (!mailer) return;
  const from = getMailerFrom();
  if (!from) return;
  const { subject, text, html } = buildPasswordResetEmail({
    code,
    expiresInMinutes,
    userName,
  });
  await sendMail(mailer, { to, from, subject, text, html });
}

async function forgotPassword(req, res) {
  const body = getObjectBody(req.body);
  const email = getEmail(body.email);
  const secret = getSecret();
  const ttlMinutes = getTtlMinutes();

  let result;
  try {
    result = await passwordResetService.requestReset({
      db: pool,
      email,
      secret,
      ttlMinutes,
    });
  } catch (error) {
    // Never leak internal database errors to the client.
    console.error('Password reset request failed:', error.message);
    return res.json({ success: true, message: GENERIC_FORGOT_MESSAGE });
  }

  if (result.found) {
    try {
      await sendResetEmail({
        to: email,
        code: result.code,
        expiresInMinutes: ttlMinutes,
        userName: result.displayName,
      });
    } catch (error) {
      // SMTP failures must not crash the backend or be exposed to the client.
      // Log only a short error code; never the reset code or credentials.
      console.error(
        'Password reset email delivery failed:',
        error?.code ?? 'EMAIL_FAILURE',
      );
    }
  }

  return res.json({ success: true, message: GENERIC_FORGOT_MESSAGE });
}

async function resetPassword(req, res) {
  const body = getObjectBody(req.body);
  const email = getEmail(body.email);
  const code = getResetCode(body.code);
  const newPassword = getPassword(body.newPassword);
  const secret = getSecret();

  const result = await passwordResetService.resetPassword({
    db: pool,
    email,
    code,
    newPassword,
    secret,
    maxAttempts: passwordResetService.DEFAULT_MAX_ATTEMPTS,
  });

  switch (result.status) {
    case 'success':
      return res.json({ success: true, message: GENERIC_RESET_MESSAGE });
    case 'attempt_limit':
      throw new ApiError(
        429,
        'RESET_ATTEMPT_LIMIT',
        'Too many incorrect attempts. Request a new reset code.',
      );
    case 'expired':
      throw new ApiError(400, 'INVALID_RESET_CODE', 'That reset code has expired. Request a new one.');
    default:
      throw new ApiError(400, 'INVALID_RESET_CODE', 'That reset code is invalid or has expired.');
  }
}

module.exports = { forgotPassword, resetPassword };
