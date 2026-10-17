const PREPARED_FOOD_GROUP = 'MAKANAN SIAP MASAK';
const CONVENIENCE_GROUP = 'BARANGAN KEDAI SERBANEKA';
const NON_GROCERY_CATEGORIES = Object.freeze([
  'ALAT TULIS DAN BAHAN BACAAN',
  'MAJALAH',
  'UBAT-UBATAN',
]);
const LIVE_ANIMAL_ITEM_CODES = Object.freeze([3, 1364, 1384]);

const CATEGORY_FILTERS = Object.freeze({
  'fresh-food': `(UPPER(TRIM(COALESCE(item_group, ''))) = 'BARANGAN SEGAR')`,
  chicken: `(UPPER(TRIM(COALESCE(item_category, ''))) = 'AYAM')`,
  vegetables: `(UPPER(TRIM(COALESCE(item_category, ''))) = 'SAYUR-SAYURAN')`,
  fruits: `(UPPER(TRIM(COALESCE(item_category, ''))) = 'BUAH-BUAHAN')`,
  eggs: `(UPPER(TRIM(COALESCE(item_category, ''))) = 'TELUR')`,
  meat: `(UPPER(TRIM(COALESCE(item_category, ''))) = 'DAGING')`,
  drinks: `(UPPER(TRIM(COALESCE(item_group, ''))) = 'MINUMAN')`,
  'dry-goods': `(UPPER(TRIM(COALESCE(item_group, ''))) IN ('BARANGAN KERING', 'BARANGAN BERBUNGKUS'))`,
  baby: `(UPPER(TRIM(COALESCE(item_group, ''))) = 'SUSU DAN BARANGAN BAYI')`,
  household: `(UPPER(TRIM(COALESCE(item_group, ''))) = 'PRODUK KEBERSIHAN')`,
});

function isGroceryItem(item) {
  const group = String(item.item_group ?? item.itemGroup ?? '').trim().toUpperCase();
  const category = String(item.item_category ?? item.itemCategory ?? '').trim().toUpperCase();
  const itemCode = Number(item.item_code ?? item.itemCode);
  if (group === PREPARED_FOOD_GROUP) return false;
  if (group === CONVENIENCE_GROUP && NON_GROCERY_CATEGORIES.includes(category)) {
    return false;
  }
  return !LIVE_ANIMAL_ITEM_CODES.includes(itemCode);
}

function groceryWhereClause(alias = '') {
  const prefix = alias ? `${alias}.` : '';
  const categories = NON_GROCERY_CATEGORIES.map((category) => `'${category}'`).join(', ');
  return `(UPPER(TRIM(COALESCE(${prefix}item_group, ''))) <> '${PREPARED_FOOD_GROUP}'
    AND NOT (
      UPPER(TRIM(COALESCE(${prefix}item_group, ''))) = '${CONVENIENCE_GROUP}'
      AND UPPER(TRIM(COALESCE(${prefix}item_category, ''))) IN (${categories})
    )
    AND ${prefix}item_code NOT IN (${LIVE_ANIMAL_ITEM_CODES.join(', ')}))`;
}

function categoryWhereClause(category, alias = '') {
  const filter = CATEGORY_FILTERS[category];
  if (!filter) return null;
  const prefix = alias ? `${alias}.` : '';
  return filter.replaceAll('item_group', `${prefix}item_group`).replaceAll('item_category', `${prefix}item_category`);
}

function parseCategory(value) {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string' || !Object.hasOwn(CATEGORY_FILTERS, value)) {
    const error = new Error(
      'category must be one of fresh-food, chicken, vegetables, fruits, eggs, meat, drinks, dry-goods, baby, household',
    );
    error.statusCode = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  return value;
}

function parseIncludePreparedFood(value) {
  if (value === undefined) return false;
  if (typeof value !== 'string' || !['true', 'false'].includes(value.toLowerCase())) {
    const error = new Error('includePreparedFood must be true or false');
    error.statusCode = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  return value.toLowerCase() === 'true';
}

function parsePricedOnly(value) {
  if (value === undefined) return false;
  if (typeof value !== 'string' || !['true', 'false'].includes(value.toLowerCase())) {
    const error = new Error('pricedOnly must be true or false');
    error.statusCode = 400;
    error.code = 'VALIDATION_ERROR';
    throw error;
  }
  return value.toLowerCase() === 'true';
}

module.exports = {
  PREPARED_FOOD_GROUP,
  CONVENIENCE_GROUP,
  NON_GROCERY_CATEGORIES,
  LIVE_ANIMAL_ITEM_CODES,
  CATEGORY_FILTERS,
  categoryWhereClause,
  parseCategory,
  parseIncludePreparedFood,
  parsePricedOnly,
  groceryWhereClause,
  isGroceryItem,
};
