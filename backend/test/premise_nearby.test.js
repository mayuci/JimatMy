const assert = require('node:assert/strict');
const test = require('node:test');
const {
  findNearestPremises,
  nearestPremisesQuery,
} = require('../src/services/premise_nearby_service');

test('nearest query ranks every fresh imported premise before pagination', () => {
  const sql = nearestPremisesQuery();
  assert.doesNotMatch(sql, /price_transactions/);
  assert.match(sql, /coordinate_cached_at >= CURRENT_TIMESTAMP/);
  assert.match(sql, /ORDER BY "distanceKm" ASC/);
  assert.ok(sql.indexOf('ORDER BY "distanceKm" ASC') < sql.indexOf('LIMIT $7'));
});

test('nearest service passes origin, filters and pagination as parameters', async () => {
  let captured;
  const client = {
    query: async (sql, values) => {
      captured = { sql, values };
      return { rows: [] };
    },
  };
  await findNearestPremises({
    client,
    latitude: 3.12,
    longitude: 101.65,
    state: 'Selangor',
    district: null,
    query: 'market',
    radiusKm: 20,
    limit: 10,
    offset: 5,
  });
  assert.deepEqual(captured.values, [
    3.12, 101.65, 'Selangor', null, '%market%', 20, 10, 5,
  ]);
  assert.doesNotMatch(captured.sql, /3\.12|101\.65|market/);
});
