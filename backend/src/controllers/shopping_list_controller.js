const {
  addShoppingListItem,
  createShoppingList,
  deleteShoppingList,
  deleteShoppingListItem,
  getBestPlacesData,
  getListSummaries,
  getShoppingList,
  renameShoppingList,
  updateShoppingListItem,
} = require('../services/planner_service');
const ApiError = require('../utils/api_error');
const {
  getBody,
  getBoolean,
  getBestPlacesQuery,
  getItemCode,
  getName,
  getPositiveDecimal,
  getUuid,
  rejectUnknownFields,
} = require('../utils/planner_validation');

async function listShoppingLists(req, res) {
  const lists = await getListSummaries(req.auth.userId);
  return res.json({ success: true, data: lists });
}

async function createList(req, res) {
  const body = getBody(req.body);
  rejectUnknownFields(body, ['name']);
  const list = await createShoppingList(req.auth.userId, getName(body.name));
  return res.status(201).json({ success: true, data: list });
}

async function getList(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  const list = await getShoppingList(req.auth.userId, listId);
  return res.json({ success: true, data: list });
}

async function getBestPlaces(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  const data = await getBestPlacesData(
    req.auth.userId,
    listId,
    getBestPlacesQuery(req.query),
  );
  return res.json({ success: true, data });
}

async function renameList(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  const body = getBody(req.body);
  rejectUnknownFields(body, ['name']);
  const list = await renameShoppingList(req.auth.userId, listId, getName(body.name));
  return res.json({ success: true, data: list });
}

async function removeList(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  await deleteShoppingList(req.auth.userId, listId);
  return res.json({ success: true, data: { deleted: true, shoppingListId: listId } });
}

async function addItem(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  const body = getBody(req.body);
  rejectUnknownFields(body, ['itemCode', 'quantity']);
  const itemCode = getItemCode(body.itemCode);
  const quantity = getPositiveDecimal(body.quantity, 'quantity', 99999999.99);
  const item = await addShoppingListItem(req.auth.userId, listId, itemCode, quantity);
  return res.status(201).json({ success: true, data: item });
}

async function updateItem(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  const listItemId = getUuid(req.params.listItemId, 'listItemId');
  const body = getBody(req.body);
  rejectUnknownFields(body, ['quantity', 'isChecked']);
  if (body.quantity === undefined && body.isChecked === undefined) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      'Provide quantity, isChecked, or both',
    );
  }
  const updates = {};
  if (body.quantity !== undefined) {
    updates.quantity = getPositiveDecimal(body.quantity, 'quantity', 99999999.99);
  }
  if (body.isChecked !== undefined) {
    updates.isChecked = getBoolean(body.isChecked, 'isChecked');
  }
  const item = await updateShoppingListItem(
    req.auth.userId,
    listId,
    listItemId,
    updates,
  );
  return res.json({ success: true, data: item });
}

async function removeItem(req, res) {
  const listId = getUuid(req.params.listId, 'listId');
  const listItemId = getUuid(req.params.listItemId, 'listItemId');
  await deleteShoppingListItem(req.auth.userId, listId, listItemId);
  return res.json({ success: true, data: { deleted: true, listItemId } });
}

module.exports = {
  addItem,
  createList,
  getBestPlaces,
  getList,
  listShoppingLists,
  removeItem,
  removeList,
  renameList,
  updateItem,
};
