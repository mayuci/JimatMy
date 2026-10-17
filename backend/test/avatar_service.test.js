const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const app = require('../src/app');
const { safeUser } = require('../src/services/auth_service');
const {
  MAX_AVATAR_BYTES,
  detectAvatarFile,
  getPresetId,
  resolveUploadedAvatarPath,
  saveUploadedAvatarWithClient,
} = require('../src/services/avatar_service');

const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00]);
const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const webp = Buffer.from('RIFF0000WEBP', 'ascii');

function fakeClient({ previousType = 'initial', previousValue = null, failUpdate = false } = {}) {
  const calls = [];
  return {
    calls,
    async query(sql, parameters = []) {
      calls.push({ sql, parameters });
      if (sql.includes('SELECT avatar_type')) {
        return {
          rowCount: 1,
          rows: [{ avatar_type: previousType, avatar_value: previousValue }],
        };
      }
      if (sql.includes('UPDATE users')) {
        if (failUpdate) throw new Error('database unavailable');
        return {
          rowCount: 1,
          rows: [{
            user_id: parameters[1],
            email: 'user@example.com',
            display_name: 'Test User',
            avatar_type: 'upload',
            avatar_value: parameters[0],
            created_at: new Date('2026-08-01T00:00:00Z'),
            updated_at: new Date('2026-08-31T00:00:00Z'),
          }],
        };
      }
      return { rowCount: 0, rows: [] };
    },
  };
}

test('accepts valid JPEG, PNG and WebP signatures with matching MIME types', () => {
  assert.equal(detectAvatarFile(jpeg, 'image/jpeg').extension, '.jpg');
  assert.equal(detectAvatarFile(png, 'image/png').extension, '.png');
  assert.equal(detectAvatarFile(webp, 'image/webp').extension, '.webp');
});

test('rejects oversized, SVG and disguised files', () => {
  assert.throws(
    () => detectAvatarFile(Buffer.alloc(MAX_AVATAR_BYTES + 1), 'image/jpeg'),
    (error) => error.code === 'AVATAR_TOO_LARGE',
  );
  assert.throws(
    () => detectAvatarFile(Buffer.from('<svg></svg>'), 'image/svg+xml'),
    (error) => error.code === 'INVALID_AVATAR_FILE',
  );
  assert.throws(
    () => detectAvatarFile(Buffer.from('not an image'), 'image/png'),
    (error) => error.code === 'INVALID_AVATAR_FILE',
  );
  assert.throws(
    () => detectAvatarFile(jpeg, 'image/png'),
    (error) => error.code === 'INVALID_AVATAR_FILE',
  );
});

test('allowlists built-in preset IDs', () => {
  assert.equal(getPresetId('basket_green'), 'basket_green');
  assert.throws(() => getPresetId('../../admin'), /valid JimatMY avatar/);
});

test('uploaded path resolution prevents traversal and arbitrary paths', () => {
  const directory = path.join(os.tmpdir(), 'jimatmy-avatar-path-test');
  assert.equal(resolveUploadedAvatarPath('/media/avatars/../secret.jpg', directory), null);
  assert.equal(resolveUploadedAvatarPath('C:\\secret.jpg', directory), null);
  assert.equal(resolveUploadedAvatarPath('/media/avatars/avatar.svg', directory), null);
  assert.equal(
    resolveUploadedAvatarPath('/media/avatars/123e4567-e89b-12d3-a456-426614174000.jpg', directory),
    path.join(directory, '123e4567-e89b-12d3-a456-426614174000.jpg'),
  );
});

test('generates a safe server filename and scopes the update to the authenticated user', async () => {
  const directory = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'jimatmy-avatar-'));
  const client = fakeClient();
  try {
    const result = await saveUploadedAvatarWithClient({
      client,
      userId: 'authenticated-user',
      file: { buffer: jpeg, mimetype: 'image/jpeg' },
      uploadDirectory: directory,
      randomId: () => '123e4567-e89b-12d3-a456-426614174000',
    });
    assert.equal(
      result.avatar_value,
      '/media/avatars/123e4567-e89b-12d3-a456-426614174000.jpg',
    );
    const update = client.calls.find((call) => call.sql.includes('UPDATE users'));
    assert.equal(update.parameters[1], 'authenticated-user');
    assert.match(update.sql, /WHERE user_id = \$2/);
    assert.equal((await fs.promises.readdir(directory)).length, 1);
  } finally {
    await fs.promises.rm(directory, { recursive: true, force: true });
  }
});

test('removes an old upload only after successful replacement', async () => {
  const directory = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'jimatmy-avatar-'));
  const oldName = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg';
  await fs.promises.writeFile(path.join(directory, oldName), jpeg);
  const client = fakeClient({
    previousType: 'upload',
    previousValue: `/media/avatars/${oldName}`,
  });
  try {
    await saveUploadedAvatarWithClient({
      client,
      userId: 'user-1',
      file: { buffer: png, mimetype: 'image/png' },
      uploadDirectory: directory,
      randomId: () => 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    });
    assert.equal(fs.existsSync(path.join(directory, oldName)), false);
    assert.equal(fs.existsSync(path.join(directory, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.png')), true);
  } finally {
    await fs.promises.rm(directory, { recursive: true, force: true });
  }
});

test('database failure removes the unused new upload and preserves the old upload', async () => {
  const directory = await fs.promises.mkdtemp(path.join(os.tmpdir(), 'jimatmy-avatar-'));
  const oldName = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.jpg';
  await fs.promises.writeFile(path.join(directory, oldName), jpeg);
  const client = fakeClient({
    previousType: 'upload',
    previousValue: `/media/avatars/${oldName}`,
    failUpdate: true,
  });
  try {
    await assert.rejects(() => saveUploadedAvatarWithClient({
      client,
      userId: 'user-1',
      file: { buffer: png, mimetype: 'image/png' },
      uploadDirectory: directory,
      randomId: () => 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    }), /database unavailable/);
    assert.equal(fs.existsSync(path.join(directory, oldName)), true);
    assert.deepEqual(await fs.promises.readdir(directory), [oldName]);
  } finally {
    await fs.promises.rm(directory, { recursive: true, force: true });
  }
});

test('safe profile response contains avatar metadata but no password or filesystem path', () => {
  const user = safeUser({
    user_id: 'u1',
    display_name: 'Aina',
    email: 'aina@example.com',
    avatar_type: 'preset',
    avatar_value: 'apple_yellow',
    created_at: new Date(),
    updated_at: new Date(),
    password_hash: 'never-return-this',
  });
  assert.equal(user.avatarType, 'preset');
  assert.equal(user.avatarValue, 'apple_yellow');
  assert.equal(user.passwordHash, undefined);
  assert.equal(JSON.stringify(user).includes('uploads\\avatars'), false);
});

test('avatar endpoint requires authentication before processing multipart data', async () => {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  try {
    const response = await fetch(
      `http://127.0.0.1:${server.address().port}/api/auth/me/avatar`,
      { method: 'POST' },
    );
    const body = await response.json();
    assert.equal(response.status, 401);
    assert.equal(body.error.code, 'AUTH_REQUIRED');
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
