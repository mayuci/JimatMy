const express = require('express');
const { createFromTemplate, getOverview, getTemplates } = require('../controllers/planner_controller');
const { requireAuth } = require('../middleware/auth_middleware');

const router = express.Router();
router.get('/templates', getTemplates);
router.use(requireAuth);
router.get('/overview', getOverview);
router.post('/templates/:templateKey/create', createFromTemplate);

module.exports = router;
