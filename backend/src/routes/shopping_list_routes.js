const express = require('express');
const {
  addItem,
  createList,
  getBestPlaces,
  getList,
  listShoppingLists,
  removeItem,
  removeList,
  renameList,
  updateItem,
} = require('../controllers/shopping_list_controller');
const { requireAuth } = require('../middleware/auth_middleware');

const router = express.Router();
router.use(requireAuth);
router.get('/', listShoppingLists);
router.post('/', createList);
router.get('/:listId', getList);
router.get('/:listId/best-places', getBestPlaces);
router.patch('/:listId', renameList);
router.delete('/:listId', removeList);
router.post('/:listId/items', addItem);
router.patch('/:listId/items/:listItemId', updateItem);
router.delete('/:listId/items/:listItemId', removeItem);

module.exports = router;
