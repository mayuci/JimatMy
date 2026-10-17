const test = require('node:test');
const assert = require('node:assert/strict');
const {
  PREPARED_FOOD_GROUP,
  categoryWhereClause,
  groceryWhereClause,
  isGroceryItem,
  parseIncludePreparedFood,
  parsePricedOnly,
  parseCategory,
} = require('../src/utils/grocery_filter');

test('keeps grocery categories and raw noodle products', () => {
  assert.equal(isGroceryItem({ item_code: 1, item: 'AYAM BERSIH - STANDARD', item_group: 'BARANGAN SEGAR', item_category: 'AYAM' }), true);
  assert.equal(isGroceryItem({ item: '100 PLUS (ORIGINAL)', item_group: 'MINUMAN' }), true);
  assert.equal(isGroceryItem({ item: 'MEE KUNING BASAH', item_group: 'MI' }), true);
  assert.equal(isGroceryItem({ item_code: 108, item: 'KUNYIT HIDUP', item_group: 'BARANGAN SEGAR', item_category: 'SAYUR-SAYURAN' }), true);
});

test('hides prepared food, clear non-grocery categories and live animals', () => {
  for (const item of ['NASI GORENG KAMPUNG', 'BIHUN GORENG', 'AYAM MASAK MERAH', 'MILO PANAS', 'AIR KOSONG', 'ROTI SARDIN']) {
    assert.equal(isGroceryItem({ item, item_group: `  ${PREPARED_FOOD_GROUP} ` }), false);
  }
  assert.equal(isGroceryItem({ item_code: 1680, item: 'PANADOL ACTIFAST 10S', item_group: 'BARANGAN KEDAI SERBANEKA', item_category: 'UBAT-UBATAN' }), false);
  assert.equal(isGroceryItem({ item_code: 1654, item: 'MAJALAH CLEO', item_group: 'BARANGAN KEDAI SERBANEKA', item_category: 'MAJALAH' }), false);
  assert.equal(isGroceryItem({ item_code: 3, item: 'AYAM HIDUP', item_group: 'BARANGAN SEGAR', item_category: 'AYAM' }), false);
  assert.equal(isGroceryItem({ item_code: 1364, item: 'AYAM TUA HIDUP', item_group: 'BARANGAN SEGAR', item_category: 'AYAM' }), false);
  assert.equal(isGroceryItem({ item_code: 1384, item: 'BABI HIDUP', item_group: 'BARANGAN SEGAR', item_category: 'DAGING' }), false);
});

test('builds the official item-group query and validates the opt-in flag', () => {
  assert.match(groceryWhereClause(), /UPPER\(TRIM\(COALESCE\(item_group/);
  assert.equal(parseIncludePreparedFood(undefined), false);
  assert.equal(parseIncludePreparedFood('false'), false);
  assert.equal(parseIncludePreparedFood('true'), true);
  assert.throws(() => parseIncludePreparedFood('yes'), /includePreparedFood/);
  assert.equal(parsePricedOnly(undefined), false);
  assert.equal(parsePricedOnly('false'), false);
  assert.equal(parsePricedOnly('true'), true);
  assert.throws(() => parsePricedOnly('yes'), /pricedOnly/);
  assert.match(groceryWhereClause('i'), /i\.item_code NOT IN \(3, 1364, 1384\)/);
});

test('maps supported consumer categories to official fields', () => {
  assert.match(categoryWhereClause('fresh-food'), /BARANGAN SEGAR/);
  assert.match(categoryWhereClause('chicken'), /item_category.*AYAM/);
  assert.match(categoryWhereClause('vegetables'), /SAYUR-SAYURAN/);
  assert.match(categoryWhereClause('fruits'), /BUAH-BUAHAN/);
  assert.match(categoryWhereClause('eggs'), /TELUR/);
  assert.match(categoryWhereClause('meat'), /DAGING/);
  assert.match(categoryWhereClause('drinks'), /item_group.*MINUMAN/);
  assert.match(categoryWhereClause('dry-goods'), /BARANGAN KERING/);
  assert.match(categoryWhereClause('baby'), /SUSU DAN BARANGAN BAYI/);
  assert.match(categoryWhereClause('household'), /PRODUK KEBERSIHAN/);
  assert.equal(parseCategory(undefined), null);
  assert.equal(parseCategory('drinks'), 'drinks');
  assert.equal(parseCategory('chicken'), 'chicken');
  assert.throws(() => parseCategory('fresh'), /category must be one of/);
});
