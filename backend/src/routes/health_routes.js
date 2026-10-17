const express = require('express');
const { getHealth } = require('../controllers/health_controller');

const router = express.Router();

router.get('/', getHealth);

module.exports = router;
