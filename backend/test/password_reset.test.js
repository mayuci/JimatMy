const assert = require('node:assert/strict');
const test = require('node:test');

const service = require('../src/services/password_reset_service');
const {
  buildPasswordResetEmail,
  createMailer,
  getConfig,
  getMailerFrom,
  isConfigured,
  sendMail,
} = require('../src/services/mail_service');
const authValidation = require('../src/utils/auth_validation');
const { forgotPasswordLimiter } = require('../src/middleware/rate_limits');

const EMAIL = 'user@example.com';
const SECRET = 'reset-secret-at-least-16-chars';
const CODE = '123456';
const NEW_PASSWORD = 'StrongPass1';

function makeDb({ user = null, resetRows = [], failUpdateUsers = false } = {}) {
  const calls = [];
  const client = {
    async query(sql, params = []) {
      calls.push({ scope: 'client', sql, params });
      if (sql.includes('SELECT password_reset_id')) {
        return { rows: resetRows, rowCount: resetRows.length };
      }
      if (sql.includes('UPDATE users') && sql.includes('password_hash')) {
        if (failUpdateUsers) throw new Error('database unavailable');
        return { rowCount: 1, rows: [] };
      }
      return { rows: [], rowCount: 0 };
    },
    async release() {},
  };
  return {
    calls,
    async query(sql, params = []) {
      calls.push({ scope: 'pool', sql, params });
      if (sql.includes('WHERE email =')) {
        return { rows: user ? [user] : [], rowCount: user ? 1 : 0 };
      }
      if (sql.includes('DELETE FROM password_resets WHERE expires_at')) {
        return { rows: [], rowCount: 4 };
      }
      return { rows: [], rowCount: 0 };
    },
    async connect() {
      return client;
    },
  };
}

function clientCall(db, needle) {
  return db.calls.find((call) => call.scope === 'client' && call.sql.includes(needle));
}


test('normaliseEmail trims and lowercases', () => {
  assert.equal(service.normaliseEmail('  User@Example.COM '), 'user@example.com');
});

test('generateResetCode is six digits and zero-pads using crypto.randomInt', () => {
  assert.match(service.generateResetCode({ randomInt: () => 0 }), /^000000$/);
  assert.match(service.generateResetCode({ randomInt: () => 5 }), /^000005$/);
  assert.match(service.generateResetCode({ randomInt: () => 999999 }), /^999999$/);
  assert.match(service.generateResetCode(), /^[0-9]{6}$/);
});

test('codeHash is deterministic and depends on email, code and secret', () => {
  const a = service.codeHash(EMAIL, CODE, SECRET);
  const b = service.codeHash(EMAIL, CODE, SECRET);
  assert.equal(a, b);
  assert.notEqual(a, service.codeHash(EMAIL, '654321', SECRET));
  assert.notEqual(a, service.codeHash('other@example.com', CODE, SECRET));
  assert.notEqual(a, service.codeHash(EMAIL, CODE, 'different-secret-16chars'));
  assert.match(a, /^[0-9a-f]{64}$/);
});

test('isExpired and expiryFromNow use the configured TTL', () => {
  const now = new Date('2026-09-01T12:00:00Z');
  const expiresAt = service.expiryFromNow(10, now);
  assert.equal(expiresAt.toISOString(), '2026-09-01T12:10:00.000Z');
  assert.equal(service.isExpired(expiresAt, new Date(Date.now() + 60000)), true);
  assert.equal(service.isExpired(expiresAt, new Date('2026-09-01T12:09:59Z')), false);
});

test('hasExceededAttempts and safeEqualHex behave correctly', () => {
  assert.equal(service.hasExceededAttempts(4, 5), false);
  assert.equal(service.hasExceededAttempts(5, 5), true);
  const hash = service.codeHash(EMAIL, CODE, SECRET);
  assert.equal(service.safeEqualHex(hash, service.codeHash(EMAIL, CODE, SECRET)), true);
  assert.equal(service.safeEqualHex(hash, service.codeHash(EMAIL, '000000', SECRET)), false);
});

test('registered email stores only a hash, returns a six-digit code, and invalidates the previous code', async () => {
  const db = makeDb({
    user: { userId: 'u1', displayName: 'Aina' },
    resetRows: [{
      resetId: 'old',
      codeHash: service.codeHash(EMAIL, '654321', SECRET),
      expiresAt: new Date(Date.now() + 60000),
      attemptCount: 1,
    }],
  });
  const result = await service.requestReset({ db, email: EMAIL, secret: SECRET, ttlMinutes: 10 });
  assert.equal(result.found, true);
  assert.match(result.code, /^[0-9]{6}$/);
  const insert = clientCall(db, 'INSERT INTO password_resets');
  assert.ok(insert);
  assert.equal(insert.params[0], 'u1');
  assert.match(insert.params[1], /^[0-9a-f]{64}$/);
  assert.notEqual(insert.params[1], result.code);
  const invalidate = clientCall(db, 'SET used_at = $1');
  assert.ok(invalidate);
  assert.equal(invalidate.params[1], 'u1');
});

test('unregistered email returns found false without writing to the database', async () => {
  const db = makeDb({ user: null });
  const result = await service.requestReset({ db, email: EMAIL, secret: SECRET });
  assert.equal(result.found, false);
  assert.equal(db.calls.some((call) => call.scope === 'client'), false);
});


test('valid code resets the password and invalidates every code in one transaction', async () => {
  const row = {
    resetId: 'r1',
    codeHash: service.codeHash(EMAIL, CODE, SECRET),
    expiresAt: new Date(Date.now() + 60000),
    attemptCount: 0,
  };
  const db = makeDb({ user: { userId: 'u1', displayName: 'Aina' }, resetRows: [row] });
  const result = await service.resetPassword({
    db, email: EMAIL, code: CODE, newPassword: NEW_PASSWORD, secret: SECRET,
  });
  assert.equal(result.status, 'success');
  const updateUser = clientCall(db, 'UPDATE users');
  assert.ok(updateUser);
  assert.match(updateUser.params[0], /^\$2[aby]\$/, 'password must use bcrypt hash format');
  assert.doesNotMatch(updateUser.params[0], /StrongPass1/, 'raw password must not be stored');
  assert.ok(clientCall(db, 'SET used_at = $1'), 'codes must be marked used after reset');
  assert.ok(clientCall(db, 'COMMIT'), 'reset should commit');
});

test('incorrect code increments the attempt count', async () => {
  const row = {
    resetId: 'r1',
    codeHash: service.codeHash(EMAIL, CODE, SECRET),
    expiresAt: new Date(Date.now() + 60000),
    attemptCount: 0,
  };
  const db = makeDb({ user: { userId: 'u1', displayName: 'Aina' }, resetRows: [row] });
  const result = await service.resetPassword({
    db, email: EMAIL, code: '000000', newPassword: NEW_PASSWORD, secret: SECRET,
  });
  assert.equal(result.status, 'invalid_code');
  assert.ok(clientCall(db, 'attempt_count = attempt_count + 1'), 'attempt count should increase on a wrong code');
});

test('expired code is rejected and marked used', async () => {
  const row = {
    resetId: 'r1',
    codeHash: service.codeHash(EMAIL, CODE, SECRET),
    expiresAt: new Date(Date.now() - 60000),
    attemptCount: 0,
  };
  const db = makeDb({ user: { userId: 'u1', displayName: 'Aina' }, resetRows: [row] });
  const result = await service.resetPassword({
    db, email: EMAIL, code: CODE, newPassword: NEW_PASSWORD, secret: SECRET,
  });
  assert.equal(result.status, 'expired');
  assert.ok(clientCall(db, 'SET used_at = $1'), 'expired code should be marked used');
});

test('a code at the attempt limit is rejected', async () => {
  const row = {
    resetId: 'r1',
    codeHash: service.codeHash(EMAIL, CODE, SECRET),
    expiresAt: new Date(Date.now() + 60000),
    attemptCount: service.DEFAULT_MAX_ATTEMPTS,
  };
  const db = makeDb({ user: { userId: 'u1', displayName: 'Aina' }, resetRows: [row] });
  const result = await service.resetPassword({
    db, email: EMAIL, code: CODE, newPassword: NEW_PASSWORD, secret: SECRET,
  });
  assert.equal(result.status, 'attempt_limit');
});


test('reused code (no active row) and unknown email return invalid_code without revealing registration', async () => {
  const db = makeDb({ user: { userId: 'u1', displayName: 'Aina' }, resetRows: [] });
  const reused = await service.resetPassword({
    db, email: EMAIL, code: CODE, newPassword: NEW_PASSWORD, secret: SECRET,
  });
  assert.equal(reused.status, 'invalid_code');
  const unknown = await service.resetPassword({
    db: makeDb({ user: null }), email: 'nobody@example.com', code: CODE,
    newPassword: NEW_PASSWORD, secret: SECRET,
  });
  assert.equal(unknown.status, 'invalid_code');
});

test('database failure rolls back the transaction', async () => {
  const row = {
    resetId: 'r1',
    codeHash: service.codeHash(EMAIL, CODE, SECRET),
    expiresAt: new Date(Date.now() + 60000),
    attemptCount: 0,
  };
  const db = makeDb({
    user: { userId: 'u1', displayName: 'Aina' },
    resetRows: [row],
    failUpdateUsers: true,
  });
  await assert.rejects(() => service.resetPassword({
    db, email: EMAIL, code: CODE, newPassword: NEW_PASSWORD, secret: SECRET,
  }), /database unavailable/);
  assert.ok(clientCall(db, 'ROLLBACK'), 'an error must roll back the transaction');
});

test('cleanupExpiredPasswordResets deletes expired records', async () => {
  const removed = await service.cleanupExpiredPasswordResets(makeDb(), new Date('2026-09-01T12:00:00Z'));
  assert.equal(removed, 4);
});

test('password validation enforces the same strength rules as registration', () => {
  assert.equal(authValidation.getResetCode('123456'), '123456');
  assert.throws(() => authValidation.getResetCode('12345'), /exactly 6 digits/);
  assert.throws(() => authValidation.getResetCode('12345a'), /exactly 6 digits/);
  assert.equal(authValidation.getPassword('StrongPass1'), 'StrongPass1');
  assert.throws(() => authValidation.getPassword('weak'), /password must/);
  assert.throws(() => authValidation.getPassword('NoDigitHere'), /password must/);
});

test('password reset email contains the code, expiry and a safety warning in text and html', () => {
  const email = buildPasswordResetEmail({
    code: CODE,
    expiresInMinutes: 10,
    appName: 'JimatMY',
    userName: 'Aina',
  });
  assert.match(email.subject, /JimatMY/);
  assert.match(email.text, /123456/);
  assert.match(email.text, /10 minutes/);
  assert.match(email.text, /safely ignore this email/);
  assert.match(email.html, /123456/);
  assert.match(email.html, /10 minutes/);
  assert.doesNotMatch(email.html, /http|src=/, 'no external assets expected');
});


test('mail config requires host, user and app password', () => {
  const empty = getConfig({});
  assert.equal(isConfigured(empty), false);
  const configured = getConfig({
    SMTP_HOST: 'smtp.gmail.com',
    SMTP_USER: 'sender@gmail.com',
    SMTP_APP_PASSWORD: 'app-password',
  });
  assert.equal(isConfigured(configured), true);
  assert.equal(configured.port, 465);
  assert.equal(getMailerFrom({
    SMTP_USER: 'sender@gmail.com', SMTP_FROM_NAME: 'JimatMY',
  }), '"JimatMY" <sender@gmail.com>');
});

test('createMailer returns null when unconfigured and a transport when configured', () => {
  assert.equal(createMailer({ env: {} }), null);
  let received;
  const transport = createMailer({
    env: {
      SMTP_HOST: 'smtp.gmail.com',
      SMTP_USER: 'sender@gmail.com',
      SMTP_APP_PASSWORD: 'app-password',
      SMTP_PORT: '465',
      SMTP_SECURE: 'true',
    },
    factory: (options) => { received = options; return { options }; },
  });
  assert.ok(transport);
  assert.equal(received.auth.user, 'sender@gmail.com');
});

test('sendMail forwards to the transport and surfaces SMTP failure', async () => {
  let forwarded;
  const mailer = { sendMail: async (payload) => { forwarded = payload; return { messageId: 'm1' }; } };
  await sendMail(mailer, { to: 'a@b.com', from: 'JimatMY <a@b.com>', subject: 'S', text: 'T', html: 'H' });
  assert.equal(forwarded.to, 'a@b.com');
  const throwing = { sendMail: async () => { throw new Error('smtp unavailable'); } };
  await assert.rejects(
    () => sendMail(throwing, { to: 'a@b.com', subject: 'S', text: 'T', html: 'H' }),
    /smtp unavailable/,
  );
});

test('forgot-password endpoint is rate limited', async () => {
  const express = require('express');
  const app = express();
  app.use(express.json());
  app.post('/api/auth/forgot-password', forgotPasswordLimiter, (req, res) => res.json({ ok: true }));
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const url = `http://127.0.0.1:${server.address().port}/api/auth/forgot-password`;
  try {
    let lastStatus = 0;
    for (let index = 0; index < 6; index += 1) {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: EMAIL }),
      });
      lastStatus = response.status;
    }
    assert.equal(lastStatus, 429);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});


