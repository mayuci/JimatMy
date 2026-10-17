const express = require('express');
const {
  login,
  me,
  register,
  removeAvatar,
  updateMe,
  uploadAvatar,
} = require('../controllers/auth_controller');
const { requireAuth } = require('../middleware/auth_middleware');
const {
  forgotPasswordLimiter,
  resetPasswordLimiter,
} = require('../middleware/rate_limits');
const { avatarUploadMiddleware } = require('../services/avatar_service');
const {
  addFavoriteItem,
  clearHistory,
  getFavoriteStatus,
  getProfileSummary,
  listFavoriteItems,
  listHistory,
  recordHistory,
  removeFavoriteItem,
} = require('../controllers/user_feature_controller');

const {
  forgotPassword,
  resetPassword,
} = require('../controllers/password_reset_controller');

const router = express.Router();
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPasswordLimiter, forgotPassword);
router.post('/reset-password', resetPasswordLimiter, resetPassword);
router.get('/me', requireAuth, me);
router.patch('/me', requireAuth, updateMe);
router.post('/me/avatar', requireAuth, avatarUploadMiddleware, uploadAvatar);
router.delete('/me/avatar', requireAuth, removeAvatar);
router.get('/me/summary', requireAuth, getProfileSummary);
router.get('/me/favorites/items', requireAuth, listFavoriteItems);
router.get('/me/favorites/items/:itemCode', requireAuth, getFavoriteStatus);
router.put('/me/favorites/items/:itemCode', requireAuth, addFavoriteItem);
router.delete('/me/favorites/items/:itemCode', requireAuth, removeFavoriteItem);
router.get('/me/history', requireAuth, listHistory);
router.post('/me/history', requireAuth, recordHistory);
router.delete('/me/history', requireAuth, clearHistory);

module.exports = router;
