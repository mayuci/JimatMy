const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const { getMonth } = require('../utils/planner_validation');
const { priceReliability } = require('../utils/price_freshness');

const SUMMARY_CTES = `
  WITH relevant_items AS (
    SELECT DISTINCT sli.item_code
      FROM shopping_lists sl
      JOIN shopping_list_items sli ON sli.shopping_list_id = sl.shopping_list_id
     WHERE sl.user_id = $1
  ), latest_prices AS (
    SELECT DISTINCT ON (pt.item_code, pt.premise_code)
           pt.item_code, pt.premise_code, pt.price, pt.record_date
      FROM price_transactions pt
      JOIN relevant_items ri ON ri.item_code = pt.item_code
     ORDER BY pt.item_code, pt.premise_code, pt.record_date DESC
  ), best_prices AS (
    SELECT DISTINCT ON (lp.item_code) lp.item_code, lp.price
      FROM latest_prices lp
     ORDER BY lp.item_code, lp.price ASC, lp.premise_code ASC
  )`;

function money(value) {
  return Number(Number(value ?? 0).toFixed(2));
}

function mapListSummary(row) {
  return {
    shoppingListId: row.shoppingListId,
    name: row.name,
    itemCount: row.itemCount,
    completedItemCount: row.completedItemCount,
    unavailableItemCount: row.unavailableItemCount,
    estimatedTotal: money(row.estimatedTotal),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function getListSummaries(userId) {
  const result = await pool.query(
    `${SUMMARY_CTES}
     SELECT sl.shopping_list_id AS "shoppingListId", sl.name,
            COUNT(sli.shopping_list_item_id)::INTEGER AS "itemCount",
            COUNT(sli.shopping_list_item_id) FILTER (WHERE sli.is_checked)::INTEGER
              AS "completedItemCount",
            COUNT(sli.shopping_list_item_id) FILTER (
              WHERE sli.shopping_list_item_id IS NOT NULL AND bp.price IS NULL
            )::INTEGER AS "unavailableItemCount",
            COALESCE(SUM(sli.quantity * bp.price), 0) AS "estimatedTotal",
            sl.created_at AS "createdAt", sl.updated_at AS "updatedAt"
       FROM shopping_lists sl
       LEFT JOIN shopping_list_items sli ON sli.shopping_list_id = sl.shopping_list_id
       LEFT JOIN best_prices bp ON bp.item_code = sli.item_code
      WHERE sl.user_id = $1
      GROUP BY sl.shopping_list_id
      ORDER BY sl.updated_at DESC, sl.created_at DESC`,
    [userId],
  );
  return result.rows.map(mapListSummary);
}

async function findOwnedList(client, userId, listId) {
  const result = await client.query(
    `SELECT shopping_list_id AS "shoppingListId", name,
            created_at AS "createdAt", updated_at AS "updatedAt"
       FROM shopping_lists
      WHERE shopping_list_id = $1 AND user_id = $2`,
    [listId, userId],
  );
  if (!result.rowCount) {
    throw new ApiError(404, 'SHOPPING_LIST_NOT_FOUND', 'Shopping list was not found');
  }
  return result.rows[0];
}

async function getShoppingList(userId, listId) {
  const list = await findOwnedList(pool, userId, listId);
  const result = await pool.query(
    `SELECT sli.shopping_list_item_id AS "listItemId", sli.item_code AS "itemCode",
            i.item AS "itemName", i.unit, sli.quantity, sli.is_checked AS "isChecked",
            best.price AS "bestPrice", best.record_date_text, best.premise_count,
            best.premise_code AS "premiseCode", best.premise AS "premiseName",
            best.address, best.district, best.state,
            sli.created_at AS "createdAt", sli.updated_at AS "updatedAt"
       FROM shopping_list_items sli
       JOIN items i ON i.item_code = sli.item_code
       LEFT JOIN LATERAL (
         SELECT latest.price, latest.record_date_text, latest.premise_count,
                p.premise_code, p.premise,
                p.address, p.district, p.state
           FROM (
             SELECT distinct_prices.*,
                    COUNT(*) OVER()::INTEGER AS premise_count
               FROM (
                 SELECT DISTINCT ON (pt.premise_code)
                        pt.premise_code, pt.price,
                        TO_CHAR(pt.record_date, 'YYYY-MM-DD') AS record_date_text
                   FROM price_transactions pt
                  WHERE pt.item_code = sli.item_code
                  ORDER BY pt.premise_code, pt.record_date DESC
               ) distinct_prices
           ) latest
           JOIN premises p ON p.premise_code = latest.premise_code
          ORDER BY latest.price ASC, p.premise ASC
          LIMIT 1
       ) best ON TRUE
      WHERE sli.shopping_list_id = $1
      ORDER BY sli.created_at ASC`,
    [listId],
  );
  const items = result.rows.map((row) => {
    const bestPrice = row.bestPrice === null ? null : money(row.bestPrice);
    return {
      listItemId: row.listItemId,
      itemCode: row.itemCode,
      itemName: row.itemName,
      unit: row.unit,
      quantity: Number(row.quantity),
      isChecked: row.isChecked,
      availabilityStatus: bestPrice === null ? 'price_unavailable' : 'available',
      bestPrice,
      estimatedLineTotal: bestPrice === null ? null : money(bestPrice * Number(row.quantity)),
      reliability: priceReliability(row.record_date_text, row.premise_count),
      cheapestPremise: bestPrice === null
        ? null
        : {
            premiseCode: row.premiseCode,
            premiseName: row.premiseName,
            address: row.address,
            district: row.district,
            state: row.state,
            recordDate: row.record_date_text,
          },
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  });
  return {
    ...list,
    itemCount: items.length,
    completedItemCount: items.filter((item) => item.isChecked).length,
    estimatedTotal: money(
      items.reduce((total, item) => total + (item.estimatedLineTotal ?? 0), 0),
    ),
    items,
  };
}

function decimalHundredths(value, fieldName) {
  const text = String(value);
  const match = /^(\d+)(?:\.(\d{1,2}))?$/.exec(text);
  if (!match) {
    throw new ApiError(422, 'INVALID_BASKET_DATA', `${fieldName} is not a valid positive number`);
  }
  const amount = (BigInt(match[1]) * 100n) + BigInt((match[2] || '').padEnd(2, '0') || '0');
  if (amount <= 0n) {
    throw new ApiError(422, 'INVALID_BASKET_DATA', `${fieldName} must be greater than zero`);
  }
  return amount;
}

function scaledLineToMoney(value) {
  const cents = (value + 50n) / 100n;
  if (cents > BigInt(Number.MAX_SAFE_INTEGER)) {
    throw new ApiError(422, 'INVALID_BASKET_DATA', 'Calculated basket total is too large');
  }
  return Number(cents) / 100;
}

function compareScaled(first, second) {
  if (first === second) return 0;
  return first < second ? -1 : 1;
}

function publicStore(store) {
  return {
    premiseCode: store.premiseCode,
    premiseName: store.premiseName,
    premiseType: store.premiseType,
    address: store.address,
    district: store.district,
    state: store.state,
    distanceKm: store.distanceKm,
    coveredItemCount: store.coveredItemCount,
    totalItemCount: store.totalItemCount,
    isComplete: store.isComplete,
    basketTotal: store.isComplete ? scaledLineToMoney(store._totalScaled) : null,
    partialTotal: store.isComplete ? null : scaledLineToMoney(store._totalScaled),
    latestPriceDate: store.latestPriceDate,
    items: store.items.map((item) => ({
      itemCode: item.itemCode,
      itemName: item.itemName,
      unit: item.unit,
      requestedQuantity: item.requestedQuantity,
      unitPrice: item.unitPrice,
      lineTotal: scaledLineToMoney(item._lineScaled),
      priceDate: item.priceDate,
      available: true,
    })),
    missingItems: store.missingItems,
  };
}

function rankStores(stores, sort) {
  stores.sort((first, second) => {
    if (first.isComplete !== second.isComplete) return first.isComplete ? -1 : 1;

    if (sort === 'coverage') {
      const coverage = second.coveredItemCount - first.coveredItemCount;
      if (coverage !== 0) return coverage;
    } else if (!first.isComplete) {
      const coverage = second.coveredItemCount - first.coveredItemCount;
      if (coverage !== 0) return coverage;
    }

    const total = compareScaled(first._totalScaled, second._totalScaled);
    if (total !== 0) return sort === 'price_desc' ? -total : total;

    const freshness = (second.oldestPriceDate || '').localeCompare(first.oldestPriceDate || '');
    if (freshness !== 0) return freshness;
    if (first.distanceKm !== null && second.distanceKm !== null) {
      const distance = first.distanceKm - second.distanceKm;
      if (Math.abs(distance) > 0.000001) return distance;
    }
    return first.premiseName.localeCompare(second.premiseName);
  });
}

function distanceKm(latitude, longitude, targetLatitude, targetLongitude) {
  const values = [latitude, longitude, targetLatitude, targetLongitude].map(Number);
  if (!values.every(Number.isFinite)) return null;
  const [lat1, lon1, lat2, lon2] = values;
  if (lat2 < 0.5 || lat2 > 7.5 || lon2 < 99 || lon2 > 120.5) return null;
  const radians = (degrees) => degrees * Math.PI / 180;
  const latDelta = radians(lat2 - lat1);
  const lonDelta = radians(lon2 - lon1);
  const first = Math.sin(latDelta / 2) ** 2
    + Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(lonDelta / 2) ** 2;
  return Number((6371 * 2 * Math.atan2(Math.sqrt(first), Math.sqrt(1 - first))).toFixed(3));
}

function findTwoStoreCombination(stores, requestedItems, bestComplete) {
  if (requestedItems.length < 2 || stores.length < 2) return null;
  let best = null;

  for (let firstIndex = 0; firstIndex < stores.length; firstIndex += 1) {
    for (let secondIndex = firstIndex + 1; secondIndex < stores.length; secondIndex += 1) {
      const first = stores[firstIndex];
      const second = stores[secondIndex];
      const firstItems = [];
      const secondItems = [];
      let totalScaled = 0n;

      for (const requested of requestedItems) {
        const firstItem = first._itemsByCode.get(requested.itemCode);
        const secondItem = second._itemsByCode.get(requested.itemCode);
        if (!firstItem && !secondItem) {
          totalScaled = -1n;
          break;
        }
        const useFirst = firstItem && (!secondItem || firstItem._lineScaled <= secondItem._lineScaled);
        const selected = useFirst ? firstItem : secondItem;
        totalScaled += selected._lineScaled;
        (useFirst ? firstItems : secondItems).push(selected);
      }

      if (totalScaled < 0n || firstItems.length === 0 || secondItems.length === 0) continue;
      if (bestComplete && totalScaled >= bestComplete._totalScaled) continue;
      if (best && totalScaled >= best._totalScaled) continue;

      best = { first, second, firstItems, secondItems, _totalScaled: totalScaled };
    }
  }

  if (!best) return null;
  const combinationStore = (store, items) => ({
    premiseCode: store.premiseCode,
    premiseName: store.premiseName,
    itemTotal: scaledLineToMoney(items.reduce((sum, item) => sum + item._lineScaled, 0n)),
    items: items.map((item) => ({
      itemCode: item.itemCode,
      itemName: item.itemName,
      requestedQuantity: item.requestedQuantity,
      unitPrice: item.unitPrice,
      lineTotal: scaledLineToMoney(item._lineScaled),
    })),
  });
  return {
    basketTotal: scaledLineToMoney(best._totalScaled),
    savingVsBestSingle: bestComplete
      ? scaledLineToMoney(bestComplete._totalScaled - best._totalScaled)
      : null,
    stores: [
      combinationStore(best.first, best.firstItems),
      combinationStore(best.second, best.secondItems),
    ],
  };
}

function buildBestPlacesResponse({ listId, listName, rows, options }) {
  const requestedByCode = new Map();
  for (const row of rows) {
    if (requestedByCode.has(row.itemCode)) continue;
    const quantityScaled = decimalHundredths(row.requestedQuantity, 'requested quantity');
    requestedByCode.set(row.itemCode, {
      itemCode: Number(row.itemCode),
      itemName: row.itemName,
      unit: row.unit,
      requestedQuantity: Number(quantityScaled) / 100,
      _quantityScaled: quantityScaled,
    });
  }
  const requestedItems = [...requestedByCode.values()];

  const storesByCode = new Map();
  const latestRows = new Map();
  for (const row of rows) {
    if (row.premiseCode === null || row.premiseCode === undefined) continue;
    const priceKey = `${row.itemCode}:${row.premiseCode}`;
    const current = latestRows.get(priceKey);
    if (!current || row.priceDate > current.priceDate) {
      latestRows.set(priceKey, row);
    }
  }

  for (const row of latestRows.values()) {
    const requested = requestedByCode.get(row.itemCode);
    const priceScaled = decimalHundredths(row.unitPrice, 'unit price');
    const lineScaled = requested._quantityScaled * priceScaled;
    let store = storesByCode.get(row.premiseCode);
    if (!store) {
      store = {
        premiseCode: Number(row.premiseCode),
        premiseName: row.premiseName,
        premiseType: row.premiseType,
        address: row.address,
        district: row.district,
        state: row.state,
        distanceKm: options.latitude == null
          ? null
          : distanceKm(options.latitude, options.longitude, row.latitude, row.longitude),
        items: [],
        missingItems: [],
        _itemsByCode: new Map(),
        _totalScaled: 0n,
        latestPriceDate: null,
        oldestPriceDate: null,
      };
      storesByCode.set(row.premiseCode, store);
    }
    const item = {
      itemCode: requested.itemCode,
      itemName: requested.itemName,
      unit: requested.unit,
      requestedQuantity: requested.requestedQuantity,
      unitPrice: Number(priceScaled) / 100,
      priceDate: row.priceDate,
      _lineScaled: lineScaled,
    };
    store.items.push(item);
    store._itemsByCode.set(item.itemCode, item);
    store._totalScaled += lineScaled;
    if (!store.latestPriceDate || row.priceDate > store.latestPriceDate) {
      store.latestPriceDate = row.priceDate;
    }
    if (!store.oldestPriceDate || row.priceDate < store.oldestPriceDate) {
      store.oldestPriceDate = row.priceDate;
    }
  }

  const allStores = [...storesByCode.values()];
  for (const store of allStores) {
    store.missingItems = requestedItems
      .filter((item) => !store._itemsByCode.has(item.itemCode))
      .map((item) => ({
        itemCode: item.itemCode,
        itemName: item.itemName,
        requestedQuantity: item.requestedQuantity,
      }));
    store.coveredItemCount = store.items.length;
    store.totalItemCount = requestedItems.length;
    store.isComplete = store.coveredItemCount === store.totalItemCount;
  }

  const filterOptions = {
    states: [...new Set(allStores.map((store) => store.state))].sort(),
    districts: [...new Map(
      allStores.map((store) => [`${store.state}\u0000${store.district}`, {
        state: store.state,
        district: store.district,
      }]),
    ).values()].sort((a, b) => a.state.localeCompare(b.state) || a.district.localeCompare(b.district)),
  };

  const equalsFilter = (value, filter) =>
    !filter || String(value).trim().toLowerCase() === filter.trim().toLowerCase();
  const locationStores = allStores.filter(
    (store) => equalsFilter(store.state, options.state)
      && equalsFilter(store.district, options.district)
      && (options.radiusKm == null
        || (store.distanceKm !== null && store.distanceKm <= options.radiusKm)),
  );
  const completeStores = locationStores.filter((store) => store.isComplete);
  const incompleteStores = locationStores.filter((store) => !store.isComplete);
  const lowestComplete = completeStores.reduce(
    (best, store) => (!best || store._totalScaled < best._totalScaled ? store : best),
    null,
  );
  const highestComplete = completeStores.reduce(
    (best, store) => (!best || store._totalScaled > best._totalScaled ? store : best),
    null,
  );

  let filtered = locationStores.filter((store) => {
    if (options.coverage === 'complete' && !store.isComplete) return false;
    if (options.coverage === 'incomplete' && store.isComplete) return false;
    if (options.maxTotal !== null) {
      return store.isComplete && scaledLineToMoney(store._totalScaled) <= options.maxTotal;
    }
    return true;
  });
  rankStores(filtered, options.sort);

  const totalResults = filtered.length;
  const totalPages = totalResults === 0 ? 0 : Math.ceil(totalResults / options.limit);
  const start = (options.page - 1) * options.limit;
  filtered = filtered.slice(start, start + options.limit);

  return {
    listId,
    listName,
    itemCount: requestedItems.length,
    requestedItems: requestedItems.map(({ _quantityScaled, ...item }) => item),
    summary: {
      totalPremises: locationStores.length,
      completePremises: completeStores.length,
      incompletePremises: incompleteStores.length,
      lowestCompleteTotal: lowestComplete ? scaledLineToMoney(lowestComplete._totalScaled) : null,
      highestCompleteTotal: highestComplete ? scaledLineToMoney(highestComplete._totalScaled) : null,
    },
    stores: filtered.map(publicStore),
    twoStoreCombination: findTwoStoreCombination(locationStores, requestedItems, lowestComplete),
    filterOptions,
    pagination: {
      page: options.page,
      limit: options.limit,
      totalResults,
      totalPages,
    },
  };
}

/** Returns a server-ranked, paginated whole-basket comparison in one price query. */
async function getBestPlacesData(userId, listId, options) {
  const list = await findOwnedList(pool, userId, listId);
  const result = await pool.query(
    `WITH active_item_totals AS (
       SELECT sli.item_code AS "itemCode", i.item AS "itemName", i.unit,
              SUM(sli.quantity) AS "requestedQuantity",
              MIN(sli.created_at) AS first_added_at
         FROM shopping_list_items sli
         JOIN items i ON i.item_code = sli.item_code
        WHERE sli.shopping_list_id = $1 AND sli.is_checked = FALSE
        GROUP BY sli.item_code, i.item, i.unit
     ), active_count AS (
       SELECT COUNT(*)::integer AS count FROM active_item_totals
     ), active_items AS (
       SELECT * FROM active_item_totals
        ORDER BY first_added_at ASC, "itemCode" ASC
        LIMIT 10
     ), latest_prices AS (
       SELECT DISTINCT ON (pt.item_code, pt.premise_code)
              pt.item_code AS "itemCode", pt.premise_code AS "premiseCode",
              p.premise AS "premiseName", p.premise_type AS "premiseType",
              p.address, p.state, p.district,
              p.latitude, p.longitude,
              pt.price AS "unitPrice",
              TO_CHAR(pt.record_date, 'YYYY-MM-DD') AS "priceDate"
         FROM price_transactions pt
         JOIN active_items ai ON ai."itemCode" = pt.item_code
         JOIN premises p ON p.premise_code = pt.premise_code
        ORDER BY pt.item_code, pt.premise_code, pt.record_date DESC,
                 pt.transaction_id DESC
     )
     SELECT ai."itemCode", ai."itemName", ai.unit, ai."requestedQuantity",
            ac.count AS "activeItemCount", lp."premiseCode", lp."premiseName",
            lp."premiseType", lp.address, lp.state, lp.district,
            lp.latitude, lp.longitude,
            lp."unitPrice", lp."priceDate"
       FROM active_items ai
       CROSS JOIN active_count ac
       LEFT JOIN latest_prices lp ON lp."itemCode" = ai."itemCode"
      ORDER BY ai.first_added_at ASC, ai."itemCode" ASC,
               lp."premiseName" ASC`,
    [listId],
  );

  const activeItemCount = result.rows.length ? Number(result.rows[0].activeItemCount) : 0;
  if (activeItemCount > 10) {
    throw new ApiError(
      400,
      'ACTIVE_ITEM_LIMIT_EXCEEDED',
      'Find best places supports up to 10 active shopping-list items',
    );
  }
  return buildBestPlacesResponse({
    listId,
    listName: list.name,
    rows: result.rows,
    options,
  });
}

async function createShoppingList(userId, name) {
  const result = await pool.query(
    `INSERT INTO shopping_lists (user_id, name)
     VALUES ($1, $2)
     RETURNING shopping_list_id AS "shoppingListId", name,
               created_at AS "createdAt", updated_at AS "updatedAt"`,
    [userId, name],
  );
  return { ...result.rows[0], itemCount: 0, completedItemCount: 0, estimatedTotal: 0 };
}

async function renameShoppingList(userId, listId, name) {
  const result = await pool.query(
    `UPDATE shopping_lists SET name = $3, updated_at = CURRENT_TIMESTAMP
      WHERE shopping_list_id = $1 AND user_id = $2
      RETURNING shopping_list_id AS "shoppingListId", name,
                created_at AS "createdAt", updated_at AS "updatedAt"`,
    [listId, userId, name],
  );
  if (!result.rowCount) {
    throw new ApiError(404, 'SHOPPING_LIST_NOT_FOUND', 'Shopping list was not found');
  }
  return result.rows[0];
}

async function deleteShoppingList(userId, listId) {
  const result = await pool.query(
    'DELETE FROM shopping_lists WHERE shopping_list_id = $1 AND user_id = $2 RETURNING shopping_list_id',
    [listId, userId],
  );
  if (!result.rowCount) {
    throw new ApiError(404, 'SHOPPING_LIST_NOT_FOUND', 'Shopping list was not found');
  }
}

async function addShoppingListItem(userId, listId, itemCode, quantity) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await findOwnedList(client, userId, listId);
    const item = await client.query('SELECT item_code FROM items WHERE item_code = $1', [itemCode]);
    if (!item.rowCount) {
      throw new ApiError(404, 'ITEM_NOT_FOUND', `Item ${itemCode} was not found`);
    }
    try {
      await client.query(
        `INSERT INTO shopping_list_items (shopping_list_id, item_code, quantity)
         VALUES ($1, $2, $3)`,
        [listId, itemCode, quantity],
      );
    } catch (error) {
      if (error.code === '23505') {
        throw new ApiError(409, 'DUPLICATE_LIST_ITEM', 'Item is already in this shopping list');
      }
      throw error;
    }
    await client.query(
      'UPDATE shopping_lists SET updated_at = CURRENT_TIMESTAMP WHERE shopping_list_id = $1',
      [listId],
    );
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
  const list = await getShoppingList(userId, listId);
  return list.items.find((item) => item.itemCode === itemCode);
}

async function updateShoppingListItem(userId, listId, listItemId, updates) {
  const values = [listId, userId, listItemId];
  const assignments = [];
  if (updates.quantity !== undefined) {
    values.push(updates.quantity);
    assignments.push(`quantity = $${values.length}`);
  }
  if (updates.isChecked !== undefined) {
    values.push(updates.isChecked);
    assignments.push(`is_checked = $${values.length}`);
  }
  assignments.push('updated_at = CURRENT_TIMESTAMP');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      `UPDATE shopping_list_items sli
          SET ${assignments.join(', ')}
         FROM shopping_lists sl
        WHERE sli.shopping_list_id = $1
          AND sl.user_id = $2
          AND sli.shopping_list_item_id = $3
          AND sl.shopping_list_id = sli.shopping_list_id
        RETURNING sli.shopping_list_item_id`,
      values,
    );
    if (!result.rowCount) {
      throw new ApiError(404, 'LIST_ITEM_NOT_FOUND', 'Shopping list item was not found');
    }
    await client.query(
      'UPDATE shopping_lists SET updated_at = CURRENT_TIMESTAMP WHERE shopping_list_id = $1',
      [listId],
    );
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
  const list = await getShoppingList(userId, listId);
  return list.items.find((item) => item.listItemId === listItemId);
}

async function deleteShoppingListItem(userId, listId, listItemId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query(
      `DELETE FROM shopping_list_items sli
        USING shopping_lists sl
        WHERE sli.shopping_list_id = $1
          AND sl.user_id = $2
          AND sli.shopping_list_item_id = $3
          AND sl.shopping_list_id = sli.shopping_list_id
        RETURNING sli.shopping_list_item_id`,
      [listId, userId, listItemId],
    );
    if (!result.rowCount) {
      throw new ApiError(404, 'LIST_ITEM_NOT_FOUND', 'Shopping list item was not found');
    }
    await client.query(
      'UPDATE shopping_lists SET updated_at = CURRENT_TIMESTAMP WHERE shopping_list_id = $1',
      [listId],
    );
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function getMonthlyBudget(userId, month) {
  const { periodStart, periodEnd } = getMonth(month);
  const result = await pool.query(
    `SELECT budget_id AS "budgetId", amount, period_start, period_end,
            created_at AS "createdAt", updated_at AS "updatedAt"
       FROM budgets
      WHERE user_id = $1 AND shopping_list_id IS NULL
        AND period_start = $2 AND period_end = $3
      ORDER BY updated_at DESC
      LIMIT 1`,
    [userId, periodStart, periodEnd],
  );
  if (!result.rowCount) return null;
  const row = result.rows[0];
  return {
    budgetId: row.budgetId,
    month,
    amount: money(row.amount),
    periodStart,
    periodEnd,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function putMonthlyBudget(userId, month, amount) {
  const { periodStart, periodEnd } = getMonth(month);
  const client = await pool.connect();
  let created = false;
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1))', [
      `jimatmy-budget:${userId}:${month}`,
    ]);
    const existing = await client.query(
      `SELECT budget_id FROM budgets
        WHERE user_id = $1 AND shopping_list_id IS NULL
          AND period_start = $2 AND period_end = $3
        ORDER BY updated_at DESC LIMIT 1 FOR UPDATE`,
      [userId, periodStart, periodEnd],
    );
    if (existing.rowCount) {
      await client.query(
        `UPDATE budgets SET amount = $2, updated_at = CURRENT_TIMESTAMP
          WHERE budget_id = $1`,
        [existing.rows[0].budget_id, amount],
      );
    } else {
      created = true;
      await client.query(
        `INSERT INTO budgets (user_id, amount, period_start, period_end)
         VALUES ($1, $2, $3, $4)`,
        [userId, amount, periodStart, periodEnd],
      );
    }
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
  return { budget: await getMonthlyBudget(userId, month), created };
}

async function getPlannerFinancials(userId, month) {
  const lists = await getListSummaries(userId);
  const plannerEstimatedTotal = money(
    lists.reduce((total, list) => total + list.estimatedTotal, 0),
  );
  const budget = await getMonthlyBudget(userId, month);
  const remainingBudget = budget === null
    ? null
    : money(budget.amount - plannerEstimatedTotal);
  return {
    lists,
    plannerEstimatedTotal,
    budget,
    remainingBudget,
    overBudget: budget !== null && plannerEstimatedTotal > budget.amount,
  };
}

module.exports = {
  addShoppingListItem,
  buildBestPlacesResponse,
  distanceKm,
  createShoppingList,
  deleteShoppingList,
  deleteShoppingListItem,
  getBestPlacesData,
  getListSummaries,
  getPlannerFinancials,
  getShoppingList,
  putMonthlyBudget,
  renameShoppingList,
  updateShoppingListItem,
};
