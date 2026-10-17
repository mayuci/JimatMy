const test = require('node:test');
const assert = require('node:assert/strict');
const {
  PREPARED_FOOD_GROUP,
  isGroceryItem,
  parseIncludePreparedFood,
} = require('../src/utils/grocery_filter');
const pool = require('../src/config/database');
const { listItems } = require('../src/controllers/item_controller');

test('consumer discovery rows are filtered by official item_group', () => {
  const rows = [
    { item: 'NASI GORENG KAMPUNG', item_group: PREPARED_FOOD_GROUP },
    { item_code: 1, item: 'AYAM BERSIH - STANDARD', item_group: 'BARANGAN SEGAR', item_category: 'AYAM' },
    { item_code: 1364, item: 'AYAM TUA HIDUP', item_group: 'BARANGAN SEGAR', item_category: 'AYAM' },
    { item: '100 PLUS (ORIGINAL)', item_group: 'MINUMAN' },
    { item_code: 1680, item: 'PANADOL ACTIFAST 10S', item_group: 'BARANGAN KEDAI SERBANEKA', item_category: 'UBAT-UBATAN' },
    { item_code: 108, item: 'KUNYIT HIDUP', item_group: 'BARANGAN SEGAR', item_category: 'SAYUR-SAYURAN' },
  ];
  const visible = rows.filter(isGroceryItem);
  assert.deepEqual(visible.map((row) => row.item), [
    'AYAM BERSIH - STANDARD',
    '100 PLUS (ORIGINAL)',
    'KUNYIT HIDUP',
  ]);
  assert.equal(rows.filter((row) => !isGroceryItem(row)).length, 3);
});

test('prepared-food opt-in is strict and backward-safe by default', () => {
  assert.equal(parseIncludePreparedFood(undefined), false);
  assert.equal(parseIncludePreparedFood('false'), false);
  assert.equal(parseIncludePreparedFood('true'), true);
  assert.throws(() => parseIncludePreparedFood('1'), /includePreparedFood/);
  assert.throws(() => parseIncludePreparedFood('TRUE '), /includePreparedFood/);
});

test('item discovery uses official filters and returns aggregated price data', async () => {
  const originalQuery = pool.query;
  let capturedSql;
  let capturedValues;
  pool.query = async (sql, values) => {
    capturedSql = sql;
    capturedValues = values;
    return {
      rows: [{
        itemCode: 42,
        itemName: 'DAGING LEMBU TEMPATAN',
        unit: '1 kg',
        itemGroup: 'BARANGAN SEGAR',
        itemCategory: 'DAGING',
        lowestPrice: '18.50',
        premiseCount: 7,
        totalCount: 12,
      }],
    };
  };

  let payload;
  try {
    await listItems(
      {
        query: {
          category: 'meat',
          state: 'Selangor',
          district: 'Petaling',
          pricedOnly: 'true',
          limit: '10',
          offset: '20',
        },
      },
      { json: (value) => { payload = value; } },
    );
  } finally {
    pool.query = originalQuery;
  }

  assert.match(capturedSql, /item_category.*DAGING/);
  assert.match(capturedSql, /MAKANAN SIAP MASAK/);
  assert.match(capturedSql, /p\.state ILIKE \$1/);
  assert.match(capturedSql, /p\.district ILIKE \$2/);
  assert.match(capturedSql, /MIN\(lfp\.price\).*"lowestPrice"/s);
  assert.deepEqual(capturedValues, ['Selangor', 'Petaling', 10, 20]);
  assert.equal(payload.data[0].lowestPrice, 18.5);
  assert.equal(payload.data[0].premiseCount, 7);
  assert.equal(payload.meta.total, 12);
});
