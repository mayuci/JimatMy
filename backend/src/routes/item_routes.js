const express = require('express');
const {
  compareItemPrices,
  getItem,
  getItemTrends,
  listItems,
} = require('../controllers/item_controller');

const router = express.Router();

router.get('/', listItems);
router.get('/:itemCode/comparison', compareItemPrices);
router.get('/:itemCode/trends', getItemTrends);
router.get('/:itemCode', getItem);

module.exports = router;
