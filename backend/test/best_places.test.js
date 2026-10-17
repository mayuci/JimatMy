const test = require('node:test');
const assert = require('node:assert/strict');

const { buildBestPlacesResponse } = require('../src/services/planner_service');
const { getBestPlacesQuery } = require('../src/utils/planner_validation');

const defaults = {
  coverage: 'all',
  sort: 'price_asc',
  state: null,
  district: null,
  maxTotal: null,
  latitude: null,
  longitude: null,
  radiusKm: null,
  page: 1,
  limit: 20,
};

function row(itemCode, itemName, requestedQuantity, premiseCode, unitPrice, extra = {}) {
  return {
    itemCode,
    itemName,
    unit: '1 unit',
    requestedQuantity,
    premiseCode,
    premiseName: `STORE ${premiseCode}`,
    premiseType: 'SUPERMARKET',
    address: 'Official address',
    district: 'Petaling',
    state: 'Selangor',
    unitPrice,
    priceDate: '2026-07-31',
    ...extra,
  };
}

function response(rows, options = {}) {
  return buildBestPlacesResponse({
    listId: 'list-1',
    listName: 'Weekly groceries',
    rows,
    options: { ...defaults, ...options },
  });
}

test('joined premise rows never multiply requested shopping-list quantities', () => {
  const data = response([
    row(1, 'Item A', '1.00', 10, '2.90'),
    row(1, 'Item A', '1.00', 11, '3.20'),
    row(2, 'Item B', '1.00', 10, '7.95'),
    row(2, 'Item B', '1.00', 11, '8.10'),
  ]);

  assert.deepEqual(data.requestedItems.map((item) => item.requestedQuantity), [1, 1]);
  assert.deepEqual(data.stores[0].items.map((item) => item.requestedQuantity), [1, 1]);
});

test('uses exact requested quantities for line totals and basket total', () => {
  const data = response([
    row(1, 'Item A', '2.00', 10, '2.90'),
    row(2, 'Item B', '3.00', 10, '7.95'),
  ]);

  assert.equal(data.stores[0].items[0].lineTotal, 5.8);
  assert.equal(data.stores[0].items[1].lineTotal, 23.85);
  assert.equal(data.stores[0].basketTotal, 29.65);
});

test('uses only the newest price for an item and premise', () => {
  const data = response([
    row(1, 'Item A', '1.00', 10, '2.90', { priceDate: '2026-07-31' }),
    row(1, 'Item A', '1.00', 10, '3.20', { priceDate: '2026-06-30' }),
  ]);

  assert.equal(data.stores[0].items.length, 1);
  assert.equal(data.stores[0].items[0].unitPrice, 2.9);
  assert.equal(data.stores[0].items[0].priceDate, '2026-07-31');
});

test('complete stores rank before cheaper incomplete partial totals', () => {
  const data = response([
    row(1, 'Item A', '1.00', 10, '2.90'),
    row(2, 'Item B', '1.00', 10, '7.95'),
    row(1, 'Item A', '1.00', 11, '1.00'),
  ]);

  assert.equal(data.stores[0].premiseCode, 10);
  assert.equal(data.stores[0].basketTotal, 10.85);
  assert.equal(data.stores[1].basketTotal, null);
  assert.equal(data.stores[1].partialTotal, 1);
  assert.deepEqual(data.stores[1].missingItems, [
    { itemCode: 2, itemName: 'Item B', requestedQuantity: 1 },
  ]);
});

test('price sorting, coverage and location filters are deterministic', () => {
  const rows = [
    row(1, 'A', '1.00', 10, '4.00'),
    row(2, 'B', '1.00', 10, '6.00'),
    row(1, 'A', '1.00', 11, '5.00', { district: 'Klang' }),
    row(2, 'B', '1.00', 11, '8.00', { district: 'Klang' }),
    row(1, 'A', '1.00', 12, '2.00', { state: 'W.P. Kuala Lumpur', district: 'Kuala Lumpur' }),
  ];

  assert.deepEqual(response(rows).stores.map((store) => store.premiseCode), [10, 11, 12]);
  assert.deepEqual(
    response(rows, { sort: 'price_desc' }).stores.map((store) => store.premiseCode),
    [11, 10, 12],
  );
  assert.deepEqual(
    response(rows, { coverage: 'complete' }).stores.map((store) => store.premiseCode),
    [10, 11],
  );
  assert.deepEqual(
    response(rows, { coverage: 'incomplete' }).stores.map((store) => store.premiseCode),
    [12],
  );
  assert.deepEqual(
    response(rows, { state: 'Selangor', district: 'Klang' }).stores.map((store) => store.premiseCode),
    [11],
  );
});

test('radius filters valid coordinates before basket ranking', () => {
  const rows = [
    row(1, 'A', '1.00', 10, '6.00', { latitude: 3.139, longitude: 101.6869 }),
    row(1, 'A', '1.00', 11, '2.00', { latitude: 3.35, longitude: 101.7 }),
    row(1, 'A', '1.00', 12, '1.00', { latitude: null, longitude: null }),
  ];
  const data = response(rows, {
    latitude: 3.139,
    longitude: 101.6869,
    radiusKm: 10,
  });
  assert.deepEqual(data.stores.map((store) => store.premiseCode), [10]);
  assert.equal(data.stores[0].distanceKm, 0);
});

test('maximum total applies only to complete baskets', () => {
  const data = response([
    row(1, 'A', '1.00', 10, '4.00'),
    row(2, 'B', '1.00', 10, '6.00'),
    row(1, 'A', '1.00', 11, '2.00'),
  ], { maxTotal: 9 });

  assert.equal(data.stores.length, 0);
  assert.equal(data.pagination.totalResults, 0);
});

test('pagination totals are calculated after filters', () => {
  const rows = [];
  for (let premiseCode = 1; premiseCode <= 5; premiseCode += 1) {
    rows.push(row(1, 'A', '1.00', premiseCode, `${premiseCode}.00`));
  }
  const data = response(rows, { page: 2, limit: 2 });

  assert.equal(data.pagination.totalResults, 5);
  assert.equal(data.pagination.totalPages, 3);
  assert.deepEqual(data.stores.map((store) => store.premiseCode), [3, 4]);
});

test('two-store recommendation appears only when it covers the full basket', () => {
  const data = response([
    row(1, 'A', '1.00', 10, '2.00'),
    row(2, 'B', '1.00', 11, '3.00'),
  ]);

  assert.equal(data.twoStoreCombination.basketTotal, 5);
  assert.equal(data.twoStoreCombination.stores.length, 2);
});

test('best-places query parameters are validated strictly', () => {
  assert.deepEqual(getBestPlacesQuery({}), defaults);
  assert.equal(getBestPlacesQuery({ limit: '50' }).limit, 50);
  assert.throws(() => getBestPlacesQuery({ coverage: 'sometimes' }), /coverage must be one of/);
  assert.throws(() => getBestPlacesQuery({ sort: 'DROP TABLE' }), /sort must be one of/);
  assert.throws(() => getBestPlacesQuery({ limit: '51' }), /limit must be between/);
  assert.throws(() => getBestPlacesQuery({ maxTotal: '0' }), /maxTotal must be a positive/);
  assert.throws(() => getBestPlacesQuery({ unknown: 'value' }), /Unsupported field/);
  assert.equal(getBestPlacesQuery({ latitude: '3.139', longitude: '101.6869', radiusKm: '25' }).radiusKm, 25);
  assert.throws(() => getBestPlacesQuery({ radiusKm: '10' }), /requires latitude/);
  assert.throws(() => getBestPlacesQuery({ latitude: '3.139', longitude: '101.6869', radiusKm: '20' }), /10, 25, or 50/);
});

test('invalid stored quantities fail explicitly instead of being reinterpreted', () => {
  assert.throws(
    () => response([row(1, 'A', 'not-a-number', 10, '2.00')]),
    /requested quantity is not a valid positive number/,
  );
  assert.throws(
    () => response([row(1, 'A', '0.00', 10, '2.00')]),
    /requested quantity must be greater than zero/,
  );
});
