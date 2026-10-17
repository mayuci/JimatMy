const {
  authenticateUser,
  createAccessToken,
  registerUser,
  safeUser,
  updateProfile,
} = require('../services/auth_service');
const { saveUploadedAvatar } = require('../services/avatar_service');
const ApiError = require('../utils/api_error');
const {
  getDisplayName,
  getEmail,
  getLoginPassword,
  getObjectBody,
  getPassword,
} = require('../utils/auth_validation');

async function register(req, res) {
  const body = getObjectBody(req.body);
  const user = await registerUser(
    getDisplayName(body.name),
    getEmail(body.email),
    getPassword(body.password),
  );
  return res.status(201).json({
    success: true,
    data: { token: createAccessToken(user.user_id), user: safeUser(user) },
  });
}

async function login(req, res) {
  const body = getObjectBody(req.body);
  const user = await authenticateUser(getEmail(body.email), getLoginPassword(body.password));
  return res.json({
    success: true,
    data: { token: createAccessToken(user.user_id), user: safeUser(user) },
  });
}

async function me(req, res) {
  return res.json({ success: true, data: safeUser(req.user) });
}

async function updateMe(req, res) {
  const body = getObjectBody(req.body);
  const keys = Object.keys(body);
  const allowed = ['name', 'avatarType', 'avatarValue'];
  if (!keys.length || keys.some((key) => !allowed.includes(key))) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Only name or avatar selection may be updated');
  }
  if (body.avatarValue !== undefined && body.avatarType !== 'preset') {
    throw new ApiError(400, 'VALIDATION_ERROR', 'avatarValue requires avatarType preset');
  }
  const user = await updateProfile(req.auth.userId, {
    name: body.name === undefined ? undefined : getDisplayName(body.name),
    avatarType: body.avatarType,
    avatarValue: body.avatarValue,
  });
  return res.json({ success: true, data: safeUser(user) });
}

async function uploadAvatar(req, res) {
  if (!req.file) {
    throw new ApiError(400, 'INVALID_AVATAR_UPLOAD', 'Choose one avatar image to upload');
  }
  const user = await saveUploadedAvatar(req.auth.userId, req.file);
  return res.json({ success: true, data: safeUser(user) });
}

async function removeAvatar(req, res) {
  const user = await updateProfile(req.auth.userId, { avatarType: 'initial' });
  return res.json({ success: true, data: safeUser(user) });
}

module.exports = { login, me, register, removeAvatar, updateMe, uploadAvatar };
