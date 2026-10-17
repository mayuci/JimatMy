const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const multer = require('multer');

const pool = require('../config/database');
const ApiError = require('../utils/api_error');

const MAX_AVATAR_BYTES = 5 * 1024 * 1024;
const AVATAR_PUBLIC_PREFIX = '/media/avatars/';
const avatarUploadDirectory = path.resolve(__dirname, '../../uploads/avatars');
const avatarPresetIds = Object.freeze([
  'basket_green',
  'apple_yellow',
  'carrot_mint',
  'drink_green',
  'rice_yellow',
  'shop_mint',
  'leaf_green',
  'egg_yellow',
  'orange_mint',
  'grocery_green',
]);
const presetSet = new Set(avatarPresetIds);

fs.mkdirSync(avatarUploadDirectory, { recursive: true });

function detectAvatarFile(buffer, mimeType) {
  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throw new ApiError(400, 'INVALID_AVATAR_FILE', 'Choose a non-empty JPEG, PNG, or WebP image');
  }
  if (buffer.length > MAX_AVATAR_BYTES) {
    throw new ApiError(413, 'AVATAR_TOO_LARGE', 'Avatar images must be 5 MB or smaller');
  }

  const jpeg = buffer.length >= 3 &&
    buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  const pngSignature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const png = buffer.length >= 8 && buffer.subarray(0, 8).equals(pngSignature);
  const webp = buffer.length >= 12 &&
    buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buffer.subarray(8, 12).toString('ascii') === 'WEBP';

  const detected = jpeg
    ? { mimeType: 'image/jpeg', extension: '.jpg' }
    : png
      ? { mimeType: 'image/png', extension: '.png' }
      : webp
        ? { mimeType: 'image/webp', extension: '.webp' }
        : null;
  if (!detected || detected.mimeType !== mimeType) {
    throw new ApiError(
      400,
      'INVALID_AVATAR_FILE',
      'The selected file is not a valid JPEG, PNG, or WebP image',
    );
  }
  return detected;
}

function getPresetId(value) {
  if (typeof value !== 'string' || !presetSet.has(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Choose a valid JimatMY avatar');
  }
  return value;
}

function resolveUploadedAvatarPath(value, directory = avatarUploadDirectory) {
  if (typeof value !== 'string' || !value.startsWith(AVATAR_PUBLIC_PREFIX)) return null;
  const filename = value.slice(AVATAR_PUBLIC_PREFIX.length);
  if (!/^[0-9a-f-]+\.(?:jpg|png|webp)$/i.test(filename) || path.basename(filename) !== filename) {
    return null;
  }
  const resolvedDirectory = path.resolve(directory);
  const resolved = path.resolve(resolvedDirectory, filename);
  return resolved.startsWith(`${resolvedDirectory}${path.sep}`) ? resolved : null;
}

async function removeUploadedAvatar(value, options = {}) {
  const fileSystem = options.fileSystem || fs.promises;
  const target = resolveUploadedAvatarPath(value, options.uploadDirectory);
  if (!target) return false;
  try {
    await fileSystem.unlink(target);
    return true;
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}

async function saveUploadedAvatarWithClient({
  client,
  userId,
  file,
  fileSystem = fs.promises,
  uploadDirectory = avatarUploadDirectory,
  randomId = crypto.randomUUID,
}) {
  const detected = detectAvatarFile(file?.buffer, file?.mimetype);
  await fileSystem.mkdir(uploadDirectory, { recursive: true });
  const filename = `${randomId()}${detected.extension}`;
  const target = path.resolve(uploadDirectory, filename);
  const relativeUrl = `${AVATAR_PUBLIC_PREFIX}${filename}`;
  await fileSystem.writeFile(target, file.buffer, { flag: 'wx' });

  let previous;
  try {
    await client.query('BEGIN');
    const current = await client.query(
      `SELECT avatar_type, avatar_value FROM users
        WHERE user_id = $1 FOR UPDATE`,
      [userId],
    );
    if (!current.rowCount) {
      throw new ApiError(404, 'USER_NOT_FOUND', 'User profile was not found');
    }
    previous = current.rows[0];
    const updated = await client.query(
      `UPDATE users
          SET avatar_type = 'upload', avatar_value = $1,
              updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $2
        RETURNING user_id, email, display_name, avatar_type, avatar_value,
                  created_at, updated_at`,
      [relativeUrl, userId],
    );
    await client.query('COMMIT');
    if (previous.avatar_type === 'upload') {
      await removeUploadedAvatar(previous.avatar_value, {
        fileSystem,
        uploadDirectory,
      });
    }
    return updated.rows[0];
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    await removeUploadedAvatar(relativeUrl, { fileSystem, uploadDirectory }).catch(() => {});
    throw error;
  }
}

async function saveUploadedAvatar(userId, file) {
  const client = await pool.connect();
  try {
    return await saveUploadedAvatarWithClient({ client, userId, file });
  } finally {
    client.release();
  }
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { files: 1, fileSize: MAX_AVATAR_BYTES },
}).single('avatar');

function avatarUploadMiddleware(req, res, next) {
  upload(req, res, (error) => {
    if (!error) return next();
    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
      return next(new ApiError(413, 'AVATAR_TOO_LARGE', 'Avatar images must be 5 MB or smaller'));
    }
    if (error instanceof multer.MulterError) {
      return next(new ApiError(400, 'INVALID_AVATAR_UPLOAD', 'Upload exactly one avatar image'));
    }
    return next(error);
  });
}

module.exports = {
  AVATAR_PUBLIC_PREFIX,
  MAX_AVATAR_BYTES,
  avatarPresetIds,
  avatarUploadDirectory,
  avatarUploadMiddleware,
  detectAvatarFile,
  getPresetId,
  removeUploadedAvatar,
  resolveUploadedAvatarPath,
  saveUploadedAvatar,
  saveUploadedAvatarWithClient,
};
