const jwt = require('jsonwebtoken');
const ApiError = require('../utils/api_error');
const { findUserById, getJwtSecret } = require('../services/auth_service');

async function requireAuth(req, res, next) {
  const authorization = req.get('Authorization');
  if (!authorization) {
    return next(new ApiError(401, 'AUTH_REQUIRED', 'A Bearer token is required'));
  }
  const match = authorization.match(/^Bearer ([^\s]+)$/);
  if (!match) {
    return next(new ApiError(401, 'INVALID_TOKEN', 'Bearer token is malformed'));
  }

  try {
    const payload = jwt.verify(match[1], getJwtSecret(), { algorithms: ['HS256'] });
    if (payload.type !== 'access' || typeof payload.sub !== 'string') {
      throw new ApiError(401, 'INVALID_TOKEN', 'Token format is no longer valid');
    }
    const user = await findUserById(payload.sub);
    if (!user) throw new ApiError(401, 'INVALID_TOKEN', 'Token user is unavailable');
    req.auth = { userId: user.user_id, mode: 'authenticated' };
    req.user = user;
    return next();
  } catch (error) {
    if (error instanceof ApiError) return next(error);
    if (error.name === 'TokenExpiredError') {
      return next(new ApiError(401, 'TOKEN_EXPIRED', 'Token has expired'));
    }
    return next(new ApiError(401, 'INVALID_TOKEN', 'Token is invalid'));
  }
}

module.exports = { requireAuth };
