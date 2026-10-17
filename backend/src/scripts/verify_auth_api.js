const crypto = require('node:crypto');

process.env.JWT_SECRET = crypto.randomBytes(48).toString('base64url');

const jwt = require('jsonwebtoken');
const app = require('../app');
const pool = require('../config/database');

async function request(baseUrl, method, path, body, token) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: response.status, body: await response.json() };
}

async function uploadAvatar(baseUrl, token) {
  const form = new FormData();
  form.append(
    'avatar',
    new Blob([
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    ], { type: 'image/png' }),
    'verification.png',
  );
  const response = await fetch(`${baseUrl}/me/avatar`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  });
  return { status: response.status, body: await response.json() };
}

function check(result, status, code) {
  if (result.status !== status || (code && result.body.error?.code !== code)) {
    throw new Error(`Expected ${status}${code ? ` ${code}` : ''}, received ${JSON.stringify(result)}`);
  }
}

async function verify() {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}/api/auth`;
  const email = `auth-verification-${Date.now()}@jimatmy.local`;
  const password = 'VerifyAuth9Secure';

  try {
    const registered = await request(baseUrl, 'POST', '/register', {
      name: 'Authentication Verification', email, password,
    });
    check(registered, 201);
    const token = registered.body.data.token;
    console.log(JSON.stringify({ step: 'register', status: 201, safeUser: !('passwordHash' in registered.body.data.user) }));

    const duplicate = await request(baseUrl, 'POST', '/register', {
      name: 'Duplicate User', email: email.toUpperCase(), password,
    });
    check(duplicate, 409, 'EMAIL_ALREADY_REGISTERED');
    console.log(JSON.stringify({ step: 'duplicateEmail', status: 409 }));

    const login = await request(baseUrl, 'POST', '/login', { email, password });
    check(login, 200);
    console.log(JSON.stringify({ step: 'login', status: 200 }));

    const badLogin = await request(baseUrl, 'POST', '/login', { email, password: 'WrongPassword9' });
    check(badLogin, 401, 'INVALID_CREDENTIALS');
    console.log(JSON.stringify({ step: 'invalidLogin', status: 401 }));

    const missing = await request(baseUrl, 'GET', '/me');
    check(missing, 401, 'AUTH_REQUIRED');
    const profile = await request(baseUrl, 'GET', '/me', undefined, token);
    check(profile, 200);
    console.log(JSON.stringify({ step: 'protectedRoutes', missing: 401, valid: 200 }));

    const invalid = await request(baseUrl, 'GET', '/me', undefined, 'invalid.token.value');
    check(invalid, 401, 'INVALID_TOKEN');
    const expiredToken = jwt.sign(
      { type: 'access' }, process.env.JWT_SECRET,
      { algorithm: 'HS256', subject: registered.body.data.user.userId, expiresIn: -1 },
    );
    const expired = await request(baseUrl, 'GET', '/me', undefined, expiredToken);
    check(expired, 401, 'TOKEN_EXPIRED');
    const unsupportedToken = jwt.sign(
      { type: 'refresh' }, process.env.JWT_SECRET,
      { algorithm: 'HS256', subject: registered.body.data.user.userId, expiresIn: '1h' },
    );
    const unsupported = await request(baseUrl, 'GET', '/me', undefined, unsupportedToken);
    check(unsupported, 401, 'INVALID_TOKEN');
    console.log(JSON.stringify({
      step: 'invalidTokens', invalid: 401, expired: 401, unsupportedFormat: 401,
    }));

    const updated = await request(baseUrl, 'PATCH', '/me', { name: 'Updated Verification User' }, token);
    check(updated, 200);
    if (updated.body.data.name !== 'Updated Verification User') throw new Error('Profile name was not updated');
    console.log(JSON.stringify({ step: 'updateProfile', status: 200 }));

    const ownershipAttempt = await request(
      baseUrl,
      'PATCH',
      '/me',
      { name: 'Other User', userId: crypto.randomUUID() },
      token,
    );
    check(ownershipAttempt, 400, 'VALIDATION_ERROR');

    const unknownPreset = await request(
      baseUrl,
      'PATCH',
      '/me',
      { avatarType: 'preset', avatarValue: 'unknown_avatar' },
      token,
    );
    check(unknownPreset, 400, 'VALIDATION_ERROR');
    const preset = await request(
      baseUrl,
      'PATCH',
      '/me',
      { avatarType: 'preset', avatarValue: 'basket_green' },
      token,
    );
    check(preset, 200);
    if (preset.body.data.avatarType !== 'preset') throw new Error('Preset avatar was not saved');

    const uploaded = await uploadAvatar(baseUrl, token);
    check(uploaded, 200);
    if (
      uploaded.body.data.avatarType !== 'upload' ||
      !uploaded.body.data.avatarValue?.startsWith('/media/avatars/')
    ) {
      throw new Error('Uploaded avatar response was not safe');
    }
    const removed = await request(baseUrl, 'DELETE', '/me/avatar', undefined, token);
    check(removed, 200);
    if (removed.body.data.avatarType !== 'initial' || removed.body.data.avatarValue !== null) {
      throw new Error('Removing an avatar did not restore the initial fallback');
    }
    console.log(JSON.stringify({
      step: 'avatarProfile',
      unknownPreset: 400,
      preset: 200,
      upload: 200,
      remove: 200,
    }));
  } finally {
    await pool.query('DELETE FROM users WHERE email = $1', [email]);
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }
}

verify().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
