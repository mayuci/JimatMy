const ApiError = require('./api_error');

function getObjectBody(body) {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Request body must be a JSON object');
  }
  return body;
}

function getDisplayName(value) {
  if (typeof value !== 'string') {
    throw new ApiError(400, 'VALIDATION_ERROR', 'name must be text');
  }
  const name = value.trim().replace(/\s+/g, ' ');
  if (name.length < 2 || name.length > 100) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'name must contain 2 to 100 characters');
  }
  return name;
}

function getEmail(value) {
  if (typeof value !== 'string') {
    throw new ApiError(400, 'VALIDATION_ERROR', 'email must be text');
  }
  const email = value.trim().toLowerCase();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'email must be a valid email address');
  }
  return email;
}

function getPassword(value) {
  if (typeof value !== 'string' || value.length < 10 || value.length > 72 ||
      !/[a-z]/.test(value) || !/[A-Z]/.test(value) || !/\d/.test(value)) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      'password must be 10 to 72 characters and include uppercase, lowercase, and a number',
    );
  }
  return value;
}

function getLoginPassword(value) {
  if (typeof value !== 'string' || value.length === 0 || value.length > 72) {
    throw new ApiError(401, 'INVALID_CREDENTIALS', 'Email or password is incorrect');
  }
  return value;
}

function getResetCode(value) {
  if (typeof value !== 'string' || !/^[0-9]{6}$/.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'code must be exactly 6 digits');
  }
  return value;
}

module.exports = {
  getDisplayName,
  getEmail,
  getLoginPassword,
  getObjectBody,
  getPassword,
  getResetCode,
};
