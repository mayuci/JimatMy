const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const { getShoppingList } = require('./planner_service');
const { normalizeRecordDate, priceReliability } = require('../utils/price_freshness');

const ITEM_CODES = [1, 1109, 1582, 918, 1440, 1559, 1590, 224];
const TEMPLATES = Object.freeze({
  student: { name: 'Student Essentials', household: '1 student', quantities: [1, 1, 1, 1, 1, 2, 1, 1] },
  couple: { name: 'Couple Essentials', household: '2 people', quantities: [2, 1, 1, 1, 2, 4, 1, 2] },
  'family-4': { name: 'Family of 4', household: '4 people', quantities: [4, 2, 2, 2, 3, 7, 1, 3] },
  'family-6': { name: 'Family of 6', household: '6 people', quantities: [6, 3, 3, 2, 4, 10, 2, 4] },
});

async function templateItems(client = pool) {
  const result = await client.query(
    `SELECT i.item_code AS "itemCode", i.item AS "itemName", i.unit,
            best.price AS "bestPrice", best.record_date AS "recordDate",
            COALESCE(best.premise_count, 0)::INTEGER AS "premiseCount"
       FROM items i
       LEFT JOIN LATERAL (
         SELECT MIN(latest.price)::DOUBLE PRECISION AS price,
                MAX(latest.record_date) AS record_date,
                COUNT(*)::INTEGER AS premise_count
           FROM (
             SELECT DISTINCT ON (pt.premise_code)
                    pt.premise_code, pt.price, pt.record_date
               FROM price_transactions pt
              WHERE pt.item_code = i.item_code
              ORDER BY pt.premise_code, pt.record_date DESC
           ) latest
       ) best ON TRUE
      WHERE i.item_code = ANY($1::INTEGER[])
      ORDER BY array_position($1::INTEGER[], i.item_code)`,
    [ITEM_CODES],
  );
  if (result.rowCount !== ITEM_CODES.length) {
    throw new ApiError(500, 'TEMPLATE_CONFIGURATION_ERROR', 'A basket item is unavailable');
  }
  return result.rows;
}

function mapTemplate(key, template, items) {
  let estimate = 0;
  let unavailableItemCount = 0;
  let latestRecordDate = null;
  const mappedItems = items.map((item, index) => {
    const quantity = template.quantities[index];
    const price = item.bestPrice === null ? null : Number(item.bestPrice);
    if (price === null) unavailableItemCount += 1;
    else estimate += price * quantity;
    const date = normalizeRecordDate(item.recordDate);
    if (date && (!latestRecordDate || date > latestRecordDate)) latestRecordDate = date;
    return {
      itemCode: item.itemCode,
      itemName: item.itemName,
      unit: item.unit,
      quantity,
      bestPrice: price,
      estimatedLineTotal: price === null ? null : Number((price * quantity).toFixed(2)),
    };
  });
  return {
    templateKey: key,
    name: template.name,
    household: template.household,
    itemCount: mappedItems.length,
    estimatedTotal: Number(estimate.toFixed(2)),
    unavailableItemCount,
    reliability: priceReliability(latestRecordDate, items.reduce((sum, item) => sum + item.premiseCount, 0)),
    items: mappedItems,
  };
}

async function listBasketTemplates() {
  const items = await templateItems();
  return Object.entries(TEMPLATES).map(([key, template]) => mapTemplate(key, template, items));
}

async function createBasketFromTemplate(userId, templateKey) {
  const template = TEMPLATES[templateKey];
  if (!template) {
    throw new ApiError(404, 'TEMPLATE_NOT_FOUND', 'Basket template was not found');
  }
  const client = await pool.connect();
  let listId;
  try {
    await client.query('BEGIN');
    const items = await templateItems(client);
    const list = await client.query(
      `INSERT INTO shopping_lists (user_id, name)
       VALUES ($1, $2) RETURNING shopping_list_id`,
      [userId, template.name],
    );
    listId = list.rows[0].shopping_list_id;
    for (let index = 0; index < items.length; index += 1) {
      await client.query(
        `INSERT INTO shopping_list_items (shopping_list_id, item_code, quantity)
         VALUES ($1, $2, $3)`,
        [listId, items[index].itemCode, template.quantities[index]],
      );
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
  return getShoppingList(userId, listId);
}

module.exports = { ITEM_CODES, TEMPLATES, createBasketFromTemplate, listBasketTemplates, mapTemplate };
