const nodemailer = require('nodemailer');

const DEFAULT_FROM_NAME = 'JimatMY';
const DEFAULT_PORT = 465;

function getConfig(env = process.env) {
  return {
    host: env.SMTP_HOST,
    port: env.SMTP_PORT ? Number(env.SMTP_PORT) : DEFAULT_PORT,
    secure: String(env.SMTP_SECURE).toLowerCase() === 'true',
    user: env.SMTP_USER,
    pass: env.SMTP_APP_PASSWORD,
    fromName: env.SMTP_FROM_NAME || DEFAULT_FROM_NAME,
  };
}

function isConfigured(config) {
  return Boolean(config.host && config.user && config.pass);
}

/**
 * Builds a Nodemailer transport from environment variables. Returns null when
 * SMTP is not configured so callers can skip delivery without crashing.
 */
function createMailer({ env = process.env, factory = nodemailer.createTransport } = {}) {
  const config = getConfig(env);
  if (!isConfigured(config)) return null;
  return factory({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: { user: config.user, pass: config.pass },
  });
}

function getMailerFrom(env = process.env) {
  const config = getConfig(env);
  if (!config.user) return null;
  return `"${config.fromName}" <${config.user}>`;
}

function buildPasswordResetEmail({
  code,
  expiresInMinutes,
  appName = 'JimatMY',
  userName,
}) {
  const expiry = `${expiresInMinutes} minutes`;
  const greeting = userName ? `Hello ${userName},` : 'Hello,';

  const text =
    `${greeting}\n\n` +
    `We received a request to reset your ${appName} password.\n\n` +
    `Your six-digit reset code is: ${code}\n\n` +
    `This code expires in ${expiry}. If you did not request this reset, ` +
    `you can safely ignore this email — your password will not be changed.\n\n` +
    `Thank you,\n${appName}`;

  const html =
    '<!doctype html><html><body style="font-family:Arial,Helvetica,sans-serif;' +
    'color:#1b2b27;line-height:1.7">' +
    `<p>${greeting}</p>` +
    `<p>We received a request to reset your <strong>${appName}</strong> password.</p>` +
    `<p style="font-size:30px;font-weight:bold;letter-spacing:10px">${code}</p>` +
    `<p>This code expires in <strong>${expiry}</strong>.</p>` +
    '<p>If you did not request this reset, you can safely ignore this email — ' +
    'your password will not be changed.</p>' +
    `<p>Thank you,<br>${appName}</p>` +
    '</body></html>';

  return { subject: `${appName}: Your password reset code`, text, html };
}

async function sendMail(mailer, { to, from, subject, text, html }) {
  return mailer.sendMail({ to, from, subject, text, html });
}

module.exports = {
  buildPasswordResetEmail,
  createMailer,
  getConfig,
  getMailerFrom,
  isConfigured,
  sendMail,
};
