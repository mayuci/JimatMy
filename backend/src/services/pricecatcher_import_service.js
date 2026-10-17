const { Readable } = require('node:stream');
const csv = require('csv-parser');

const ITEM_URL = 'https://storage.data.gov.my/pricecatcher/lookup_item.csv';
const PREMISE_URL = 'https://storage.data.gov.my/pricecatcher/lookup_premise.csv';
const TRANSACTION_URL = (month) =>
  `https://storage.data.gov.my/pricecatcher/pricecatcher_${month}.csv`;
const BATCH_SIZE = 500;
const MAX_SKIPPED_ROW_LOGS = 10;
const skippedLogCounts = new Map();

function parseInteger(value) {
  const text = String(value ?? '').trim();
  if (!/^\d+(?:\.0+)?$/.test(text)) return null;
  const parsed = Number(text);
  return Number.isSafeInteger(parsed) ? parsed : null;
}

function parsePositivePrice(value) {
  const text = String(value ?? '').trim();
  if (!/^\d+(\.\d+)?$/.test(text)) return null;
  const parsed = Number(text);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

function parseIsoDate(value) {
  const text = String(value ?? '').trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(text)) return null;
  const date = new Date(`${text}T00:00:00Z`);
  return !Number.isNaN(date.valueOf()) && date.toISOString().slice(0, 10) === text
    ? text
    : null;
}

function requiredText(value) {
  const text = String(value ?? '').trim();
  return text.length > 0 ? text : null;
}

async function csvRows(url) {
  const response = await fetch(url);
  if (!response.ok || !response.body) {
    throw new Error(`Download failed (${response.status}) for ${url}`);
  }

  return Readable.fromWeb(response.body).pipe(
    csv({ mapHeaders: ({ header }) => header.replace(/^\uFEFF/, '').trim() }),
  );
}

function logSkipped(dataset, rowNumber, reason) {
  const count = (skippedLogCounts.get(dataset) ?? 0) + 1;
  skippedLogCounts.set(dataset, count);
  if (count <= MAX_SKIPPED_ROW_LOGS) {
    console.warn(`[${dataset}] skipped row ${rowNumber}: ${reason}`);
  }
}

async function insertBatch(client, table, columns, conflictClause, rows) {
  if (rows.length === 0) return;

  const values = [];
  const tuples = rows.map((row, rowIndex) => {
    const placeholders = row.map((value, columnIndex) => {
      values.push(value);
      return `$${rowIndex * columns.length + columnIndex + 1}`;
    });
    return `(${placeholders.join(', ')})`;
  });

  await client.query(
    `INSERT INTO ${table} (${columns.join(', ')}) VALUES ${tuples.join(', ')} ${conflictClause}`,
    values,
  );
}

async function importItems(client) {
  const stream = await csvRows(ITEM_URL);
  const batch = [];
  let rowNumber = 1;
  let imported = 0;
  let skipped = 0;

  for await (const row of stream) {
    rowNumber += 1;
    const values = [
      parseInteger(row.item_code),
      requiredText(row.item),
      requiredText(row.unit),
      requiredText(row.item_group),
      requiredText(row.item_category),
    ];

    if (values.some((value) => value === null)) {
      skipped += 1;
      logSkipped('items', rowNumber, 'invalid code or missing required text');
      continue;
    }

    batch.push(values);
    if (batch.length >= BATCH_SIZE) {
      await insertBatch(client, 'items',
        ['item_code', 'item', 'unit', 'item_group', 'item_category'],
        `ON CONFLICT (item_code) DO UPDATE SET
          item = EXCLUDED.item,
          unit = EXCLUDED.unit,
          item_group = EXCLUDED.item_group,
          item_category = EXCLUDED.item_category,
          updated_at = CURRENT_TIMESTAMP`,
        batch);
      imported += batch.length;
      batch.length = 0;
    }
  }

  await insertBatch(client, 'items',
    ['item_code', 'item', 'unit', 'item_group', 'item_category'],
    `ON CONFLICT (item_code) DO UPDATE SET
      item = EXCLUDED.item,
      unit = EXCLUDED.unit,
      item_group = EXCLUDED.item_group,
      item_category = EXCLUDED.item_category,
      updated_at = CURRENT_TIMESTAMP`,
    batch);
  imported += batch.length;

  const result = await client.query('SELECT item_code FROM items');
  return {
    imported,
    skipped,
    itemCodes: new Set(result.rows.map((row) => row.item_code)),
  };
}

async function importPremises(client, states) {
  const selectedStates = new Set(states.map((state) => state.toLocaleLowerCase('en-MY')));
  const stream = await csvRows(PREMISE_URL);
  const batch = [];
  let rowNumber = 1;
  let imported = 0;
  let skipped = 0;

  for await (const row of stream) {
    rowNumber += 1;
    const state = requiredText(row.state);
    if (!state || !selectedStates.has(state.toLocaleLowerCase('en-MY'))) continue;

    const values = [
      parseInteger(row.premise_code),
      requiredText(row.premise),
      requiredText(row.address),
      requiredText(row.premise_type),
      state,
      requiredText(row.district),
    ];

    if (values.some((value) => value === null)) {
      skipped += 1;
      logSkipped('premises', rowNumber, 'invalid code or missing required text');
      continue;
    }

    batch.push(values);
    if (batch.length >= BATCH_SIZE) {
      await insertBatch(client, 'premises',
        ['premise_code', 'premise', 'address', 'premise_type', 'state', 'district'],
        `ON CONFLICT (premise_code) DO UPDATE SET
          premise = EXCLUDED.premise,
          address = EXCLUDED.address,
          premise_type = EXCLUDED.premise_type,
          state = EXCLUDED.state,
          district = EXCLUDED.district,
          updated_at = CURRENT_TIMESTAMP`,
        batch);
      imported += batch.length;
      batch.length = 0;
    }
  }

  await insertBatch(client, 'premises',
    ['premise_code', 'premise', 'address', 'premise_type', 'state', 'district'],
    `ON CONFLICT (premise_code) DO UPDATE SET
      premise = EXCLUDED.premise,
      address = EXCLUDED.address,
      premise_type = EXCLUDED.premise_type,
      state = EXCLUDED.state,
      district = EXCLUDED.district,
      updated_at = CURRENT_TIMESTAMP`,
    batch);
  imported += batch.length;

  const result = await client.query(
    'SELECT premise_code FROM premises WHERE lower(state) = ANY($1::text[])',
    [Array.from(selectedStates)],
  );
  return {
    imported,
    skipped,
    premiseCodes: new Set(result.rows.map((row) => row.premise_code)),
  };
}

async function importTransactions(client, month, premiseCodes, itemCodes, limit) {
  const stream = await csvRows(TRANSACTION_URL(month));
  const batch = [];
  let rowNumber = 1;
  let imported = 0;
  let skipped = 0;
  let accepted = 0;

  for await (const row of stream) {
    if (limit !== null && accepted >= limit) break;
    rowNumber += 1;

    const recordDate = parseIsoDate(row.date);
    const premiseCode = parseInteger(row.premise_code);
    const itemCode = parseInteger(row.item_code);
    const price = parsePositivePrice(row.price);

    if (recordDate === null || premiseCode === null || itemCode === null || price === null) {
      skipped += 1;
      logSkipped('transactions', rowNumber, 'invalid date, code, or non-positive price');
      continue;
    }
    if (!premiseCodes.has(premiseCode)) continue;
    if (!itemCodes.has(itemCode)) {
      skipped += 1;
      logSkipped('transactions', rowNumber, `item_code ${itemCode} is missing from items`);
      continue;
    }

    batch.push([recordDate, premiseCode, itemCode, price]);
    accepted += 1;
    if (batch.length >= BATCH_SIZE) {
      await insertBatch(client, 'price_transactions',
        ['record_date', 'premise_code', 'item_code', 'price'],
        `ON CONFLICT (record_date, premise_code, item_code) DO UPDATE SET
          price = EXCLUDED.price`,
        batch);
      imported += batch.length;
      batch.length = 0;
    }
  }

  await insertBatch(client, 'price_transactions',
    ['record_date', 'premise_code', 'item_code', 'price'],
    `ON CONFLICT (record_date, premise_code, item_code) DO UPDATE SET
      price = EXCLUDED.price`,
    batch);
  imported += batch.length;
  return { imported, skipped };
}

async function runPriceCatcherImport(pool, options) {
  const client = await pool.connect();
  try {
    console.log('Importing PriceCatcher item lookup...');
    const items = await importItems(client);
    console.log(`Items processed: ${items.imported}; skipped: ${items.skipped}`);

    console.log(`Importing premises for: ${options.states.join(', ')}...`);
    const premises = await importPremises(client, options.states);
    console.log(`Premises processed: ${premises.imported}; skipped: ${premises.skipped}`);

    console.log(`Importing PriceCatcher transactions for ${options.month}...`);
    const transactions = await importTransactions(
      client,
      options.month,
      premises.premiseCodes,
      items.itemCodes,
      options.limit,
    );
    console.log(
      `Transactions processed: ${transactions.imported}; skipped: ${transactions.skipped}`,
    );
  } finally {
    client.release();
  }
}

module.exports = { runPriceCatcherImport };
