const express = require('express');
const { getBudget, putBudget } = require('../controllers/budget_controller');
const { requireAuth } = require('../middleware/auth_middleware');

const router = express.Router();
router.use(requireAuth);
router.get('/', getBudget);
router.put('/', putBudget);

module.exports = router;
