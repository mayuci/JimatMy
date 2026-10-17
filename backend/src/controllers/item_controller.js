const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const {
  getDateQuery,
  getIntegerQuery,
  getItemCode,
  getTextQuery,
} = require('../utils/validation');
const {
  categoryWhereClause,
  groceryWhereClause,
  parseCategory,
  parseIncludePreparedFood,
  parsePricedOnly,
} = require('../utils/grocery_filter');
const { priceReliability } = require('../utils/price_freshness');

function mapPrice(row) {
  const reliability = priceReliability(row.record_date_text, row.premiseCount || 1);
  return {
    premiseCode: row.premiseCode,
    premiseName: row.premiseName,
    address: row.address,
    state: row.state,
    district: row.district,
    price: Number(row.price),
    recordDate: String(row.record_date_text),
    reliability,
  };
}

async function findItem(itemCode) {
  const result = await pool.query(
    `SELECT item_code AS "itemCode", item AS "itemName", unit,
            item_group AS "itemGroup", item_category AS "itemCategory"
       FROM items
      WHERE item_code = $1`,
    [itemCode],
  );
  if (result.rowCount === 0) {
    throw new ApiError(404, 'ITEM_NOT_FOUND', `Item ${itemCode} was not found`);
  }
  return result.rows[0];
}

async function getLatestPrices(itemCode, state, district) {
  const values = [itemCode];
  const filters = ['pt.item_code = $1'];
  if (state !== null) {
    values.push(state);
    filters.push(`p.state ILIKE $${values.length}`);
  }
  if (district !== null) {
    values.push(district);
    filters.push(`p.district ILIKE $${values.length}`);
  }

  const result = await pool.query(
    `WITH latest_prices AS (
       SELECT DISTINCT ON (pt.premise_code)
              p.premise_code AS "premiseCode", p.premise AS "premiseName",
              p.address, p.state, p.district, pt.price,
              TO_CHAR(pt.record_date, 'YYYY-MM-DD') AS record_date_text
         FROM price_transactions pt
         JOIN premises p ON p.premise_code = pt.premise_code
        WHERE ${filters.join(' AND ')}
        ORDER BY pt.premise_code, pt.record_date DESC
     )
     SELECT *, COUNT(*) OVER()::INTEGER AS "premiseCount" FROM latest_prices
     ORDER BY price ASC, "premiseName" ASC`,
    values,
  );
  return result.rows.map(mapPrice);
}

async function listItems(req, res) {
  const q = getTextQuery(req.query.q, 'q', 200);
  const state = getTextQuery(req.query.state, 'state', 100);
  const district = getTextQuery(req.query.district, 'district', 100);
  let category;
  try {
    category = parseCategory(req.query.category);
  } catch (error) {
    throw new ApiError(error.statusCode, error.code, error.message);
  }
  let includePreparedFood;
  try {
    includePreparedFood = parseIncludePreparedFood(req.query.includePreparedFood);
  } catch (error) {
    throw new ApiError(error.statusCode, error.code, error.message);
  }
  let pricedOnly;
  try {
    pricedOnly = parsePricedOnly(req.query.pricedOnly);
  } catch (error) {
    throw new ApiError(error.statusCode, error.code, error.message);
  }
  const limit = getIntegerQuery(req.query.limit, 'limit', 20, 1, 100);
  const offset = getIntegerQuery(req.query.offset, 'offset', 0, 0, 1000000);
  const values = [];
  const priceFilters = [];
  const filters = [];

  if (state !== null) {
    values.push(state);
    priceFilters.push(`p.state ILIKE $${values.length}`);
  }
  if (district !== null) {
    values.push(district);
    priceFilters.push(`p.district ILIKE $${values.length}`);
  }

  if (q !== null) {
    values.push(`%${q}%`);
    filters.push(`i.item ILIKE $${values.length}`);
  }
  if (category !== null) filters.push(categoryWhereClause(category, 'i'));
  if (!includePreparedFood) filters.push(groceryWhereClause('i'));
  if (pricedOnly || state !== null || district !== null) {
    filters.push('lfp.item_code IS NOT NULL');
  }
  values.push(limit, offset);

  const result = await pool.query(
    `WITH latest_filtered_prices AS (
       SELECT DISTINCT ON (pt.item_code, pt.premise_code)
              pt.item_code, pt.premise_code, pt.price, pt.record_date
         FROM price_transactions pt
         JOIN premises p ON p.premise_code = pt.premise_code
        ${priceFilters.length ? `WHERE ${priceFilters.join(' AND ')}` : ''}
        ORDER BY pt.item_code, pt.premise_code, pt.record_date DESC
     )
     SELECT i.item_code AS "itemCode", i.item AS "itemName", i.unit,
            i.item_group AS "itemGroup", i.item_category AS "itemCategory",
            MIN(lfp.price) AS "lowestPrice",
            TO_CHAR(MAX(lfp.record_date), 'YYYY-MM-DD') AS "latestRecordDate",
            COUNT(lfp.premise_code)::INTEGER AS "premiseCount",
            COUNT(*) OVER()::INTEGER AS "totalCount"
       FROM items i
       LEFT JOIN latest_filtered_prices lfp ON lfp.item_code = i.item_code
      ${filters.length ? `WHERE ${filters.join(' AND ')}` : ''}
      GROUP BY i.item_code, i.item, i.unit, i.item_group, i.item_category
      ORDER BY i.item ASC, i.item_code ASC
      LIMIT $${values.length - 1} OFFSET $${values.length}`,
    values,
  );

  const total = result.rows.length ? result.rows[0].totalCount : 0;
  const items = result.rows.map(({ totalCount, lowestPrice, premiseCount, latestRecordDate, ...item }) => ({
    ...item,
    lowestPrice: lowestPrice === null ? null : Number(lowestPrice),
    premiseCount: Number(premiseCount),
    reliability: priceReliability(latestRecordDate, premiseCount),
  }));
  return res.json({
    success: true,
    data: items,
    meta: { total, limit, offset },
  });
}

async function getItem(req, res) {
  const itemCode = getItemCode(req.params.itemCode);
  const [item, latestPrices] = await Promise.all([
    findItem(itemCode),
    getLatestPrices(itemCode, null, null),
  ]);
  const latestDate = latestPrices.reduce(
    (latest, price) => (!latest || price.recordDate > latest ? price.recordDate : latest),
    null,
  );
  return res.json({
    success: true,
    data: { ...item, latestPrices, reliability: priceReliability(latestDate, latestPrices.length) },
  });
}

async function compareItemPrices(req, res) {
  const itemCode = getItemCode(req.params.itemCode);
  const state = getTextQuery(req.query.state, 'state', 100);
  const district = getTextQuery(req.query.district, 'district', 100);
  const item = await findItem(itemCode);
  const prices = await getLatestPrices(itemCode, state, district);
  const cheapestOption = prices.length
    ? {
        premiseCode: prices[0].premiseCode,
        premiseName: prices[0].premiseName,
        price: prices[0].price,
        recordDate: prices[0].recordDate,
      }
    : null;

  return res.json({
    success: true,
    data: {
      item,
      filters: { state, district },
      cheapestOption,
      prices,
      reliability: priceReliability(
        prices.reduce(
          (latest, price) => (!latest || price.recordDate > latest ? price.recordDate : latest),
          null,
        ),
        prices.length,
      ),
    },
  });
}

async function getItemTrends(req, res) {
  const itemCode = getItemCode(req.params.itemCode);
  const from = getDateQuery(req.query.from, 'from');
  const to = getDateQuery(req.query.to, 'to');
  if (from !== null && to !== null && from > to) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'from must be on or before to');
  }

  const item = await findItem(itemCode);
  const values = [itemCode];
  const filters = ['item_code = $1'];
  if (from !== null) {
    values.push(from);
    filters.push(`record_date >= $${values.length}`);
  }
  if (to !== null) {
    values.push(to);
    filters.push(`record_date <= $${values.length}`);
  }

  const result = await pool.query(
    `SELECT TO_CHAR(record_date, 'YYYY-MM-DD') AS record_date_text,
            ROUND(AVG(price), 2) AS "averagePrice",
            MIN(price) AS "minimumPrice",
            MAX(price) AS "maximumPrice"
       FROM price_transactions
      WHERE ${filters.join(' AND ')}
      GROUP BY record_date
      ORDER BY record_date ASC`,
    values,
  );
  const trends = result.rows.map((row) => ({
    recordDate: String(row.record_date_text),
    averagePrice: Number(row.averagePrice),
    minimumPrice: Number(row.minimumPrice),
    maximumPrice: Number(row.maximumPrice),
  }));

  return res.json({
    success: true,
    data: { item, filters: { from, to }, trends },
  });
}

module.exports = { compareItemPrices, getItem, getItemTrends, listItems };
