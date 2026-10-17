const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const { getItemCode } = require('../utils/validation');
const { priceReliability } = require('../utils/price_freshness');

async function assertItem(itemCode) {
  const result = await pool.query('SELECT item_code FROM items WHERE item_code = $1', [itemCode]);
  if (!result.rowCount) throw new ApiError(404, 'ITEM_NOT_FOUND', `Item ${itemCode} was not found`);
}

async function listFavoriteItems(req, res) {
  const result = await pool.query(
    `SELECT i.item_code AS "itemCode", i.item AS "itemName", i.unit,
            i.item_group AS "itemGroup", i.item_category AS "itemCategory",
            fi.created_at AS "favoritedAt",
            prices."latestLowestPrice", prices."premiseCount",
            TO_CHAR(prices."latestRecordDate", 'YYYY-MM-DD') AS "latestRecordDate"
       FROM favorite_items fi
       JOIN items i ON i.item_code = fi.item_code
       LEFT JOIN LATERAL (
         SELECT MIN(latest.price)::DOUBLE PRECISION AS "latestLowestPrice",
                COUNT(*)::INTEGER AS "premiseCount",
                MAX(latest.record_date) AS "latestRecordDate"
           FROM (
             SELECT DISTINCT ON (pt.premise_code)
                    pt.premise_code, pt.price, pt.record_date
               FROM price_transactions pt
              WHERE pt.item_code = fi.item_code
              ORDER BY pt.premise_code, pt.record_date DESC
           ) latest
       ) prices ON TRUE
      WHERE fi.user_id = $1
      ORDER BY fi.created_at DESC, i.item ASC`,
    [req.auth.userId],
  );
  return res.json({
    success: true,
    data: result.rows.map((row) => ({
      ...row,
      reliability: priceReliability(row.latestRecordDate, row.premiseCount),
    })),
  });
}

async function getFavoriteStatus(req, res) {
  const itemCode = getItemCode(req.params.itemCode);
  const result = await pool.query(
    `SELECT 1 FROM favorite_items WHERE user_id = $1 AND item_code = $2`,
    [req.auth.userId, itemCode],
  );
  return res.json({ success: true, data: { itemCode, isFavorite: result.rowCount > 0 } });
}

async function addFavoriteItem(req, res) {
  const itemCode = getItemCode(req.params.itemCode);
  await assertItem(itemCode);
  const result = await pool.query(
    `INSERT INTO favorite_items (user_id, item_code)
     VALUES ($1, $2)
     ON CONFLICT (user_id, item_code) DO NOTHING
     RETURNING favorite_item_id`,
    [req.auth.userId, itemCode],
  );
  return res.status(result.rowCount ? 201 : 200).json({
    success: true,
    data: { itemCode, isFavorite: true, alreadyFavorite: result.rowCount === 0 },
  });
}

async function removeFavoriteItem(req, res) {
  const itemCode = getItemCode(req.params.itemCode);
  const result = await pool.query(
    `DELETE FROM favorite_items WHERE user_id = $1 AND item_code = $2`,
    [req.auth.userId, itemCode],
  );
  return res.json({ success: true, data: { itemCode, isFavorite: false, removed: result.rowCount > 0 } });
}

async function recordHistory(req, res) {
  const itemCode = getItemCode(String(req.body?.itemCode ?? ''));
  const itemResult = await pool.query(
    `SELECT item_code AS "itemCode", item AS "itemName", unit,
            item_group AS "itemGroup", item_category AS "itemCategory"
       FROM items WHERE item_code = $1`,
    [itemCode],
  );
  if (!itemResult.rowCount) {
    throw new ApiError(404, 'ITEM_NOT_FOUND', `Item ${itemCode} was not found`);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      `INSERT INTO search_history (user_id, item_code, query, searched_at, last_viewed_at)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id, item_code) WHERE item_code IS NOT NULL
       DO UPDATE SET query = EXCLUDED.query,
                     searched_at = CURRENT_TIMESTAMP,
                     last_viewed_at = CURRENT_TIMESTAMP
       RETURNING search_history_id AS "historyId",
                 last_viewed_at AS "lastViewedAt",
                 (xmax = 0) AS "wasCreated"`,
      [req.auth.userId, itemCode, itemResult.rows[0].itemName],
    );
    await client.query(
      `DELETE FROM search_history
        WHERE search_history_id IN (
          SELECT search_history_id
            FROM search_history
           WHERE user_id = $1 AND item_code IS NOT NULL
           ORDER BY last_viewed_at DESC, search_history_id DESC
          OFFSET 50
        )`,
      [req.auth.userId],
    );
    await client.query('COMMIT');
    return res.status(result.rows[0].wasCreated ? 201 : 200).json({
      success: true,
      data: { ...itemResult.rows[0], ...result.rows[0] },
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function listHistory(req, res) {
  const result = await pool.query(
    `SELECT sh.search_history_id AS "historyId",
            sh.last_viewed_at AS "lastViewedAt", i.item_code AS "itemCode",
            i.item AS "itemName", i.unit,
            i.item_group AS "itemGroup", i.item_category AS "itemCategory"
       FROM search_history sh
       JOIN items i ON i.item_code = sh.item_code
      WHERE sh.user_id = $1 AND sh.item_code IS NOT NULL
      ORDER BY sh.last_viewed_at DESC, sh.search_history_id DESC LIMIT 50`,
    [req.auth.userId],
  );
  return res.json({ success: true, data: result.rows });
}

async function clearHistory(req, res) {
  const result = await pool.query(
    `DELETE FROM search_history WHERE user_id = $1 AND item_code IS NOT NULL`,
    [req.auth.userId],
  );
  return res.json({ success: true, data: { clearedCount: result.rowCount } });
}

async function getProfileSummary(req, res) {
  const result = await pool.query(
    `SELECT
       (SELECT COUNT(*)::INTEGER FROM favorite_items WHERE user_id = $1) AS "favoriteItemCount",
       (SELECT COUNT(*)::INTEGER FROM search_history
         WHERE user_id = $1 AND item_code IS NOT NULL) AS "historyCount",
       (SELECT COUNT(*)::INTEGER FROM shopping_lists WHERE user_id = $1) AS "shoppingListCount"`,
    [req.auth.userId],
  );
  return res.json({ success: true, data: result.rows[0] });
}

module.exports = {
  addFavoriteItem,
  clearHistory,
  getFavoriteStatus,
  getProfileSummary,
  listFavoriteItems,
  listHistory,
  recordHistory,
  removeFavoriteItem,
};
