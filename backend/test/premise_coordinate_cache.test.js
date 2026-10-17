const assert = require('node:assert/strict');
const test = require('node:test');
const {
  cacheResolvedPremise,
  clearExpiredCoordinateCache,
  isValidMalaysianCoordinate,
} = require('../src/services/premise_coordinate_cache_service');

const premise = {
  premise_code: 123,
  premise: 'TEST MARKET',
  address: '1 JALAN TEST, 50000 KUALA LUMPUR',
  district: 'Kuala Lumpur',
  state: 'W.P. Kuala Lumpur',
  google_place_id: null,
};

test('accepts Malaysian coordinates and rejects invalid/global coordinates', () => {
  assert.equal(isValidMalaysianCoordinate(3.1, 101.6), true);
  assert.equal(isValidMalaysianCoordinate(0, 0), false);
  assert.equal(isValidMalaysianCoordinate(51.5, -0.1), false);
});

test('caches only a reviewed high or possible address match', async () => {
  const calls = [];
  const client = {
    query: async (sql, values) => {
      calls.push({ sql, values });
      return { rowCount: 1 };
    },
  };
  const outcome = await cacheResolvedPremise({
    client,
    premise,
    buildAddress: () => 'Official address, Malaysia',
    scoreMatch: () => 'high',
    geocode: async () => ({
      latitude: 3.1,
      longitude: 101.6,
      formattedAddress: 'Resolved address, Malaysia',
      partialMatch: false,
      locationType: 'ROOFTOP',
      placeId: 'place-123',
    }),
  });
  assert.deepEqual(outcome, { status: 'cached', confidence: 'high' });
  assert.equal(calls.length, 1);
  assert.match(calls[0].sql, /coordinate_cached_at = CURRENT_TIMESTAMP/);
  assert.deepEqual(calls[0].values, [
    123, 3.1, 101.6, 'high', false, 'ROOFTOP', 'place-123',
  ]);
});

test('does not store ambiguous matches', async () => {
  const writes = [];
  const outcome = await cacheResolvedPremise({
    client: { query: async (sql, values) => { writes.push({ sql, values }); } },
    premise,
    buildAddress: () => 'Official address, Malaysia',
    scoreMatch: () => 'low_ambiguous',
    geocode: async () => ({
      latitude: 3.1,
      longitude: 101.6,
      formattedAddress: 'Other state, Malaysia',
      partialMatch: true,
      locationType: 'APPROXIMATE',
      placeId: null,
    }),
  });
  assert.deepEqual(outcome, { status: 'ambiguous' });
  assert.equal(writes.length, 1);
  assert.match(writes[0].sql, /coordinate_last_attempted_at/);
  assert.deepEqual(writes[0].values, [123, 'ambiguous']);
});

test('records zero results so they are not requested again immediately', async () => {
  const writes = [];
  const outcome = await cacheResolvedPremise({
    client: { query: async (sql, values) => { writes.push({ sql, values }); } },
    premise,
    buildAddress: () => 'Official address, Malaysia',
    scoreMatch: () => 'high',
    geocode: async () => null,
  });
  assert.deepEqual(outcome, { status: 'no_results' });
  assert.equal(writes.length, 1);
  assert.deepEqual(writes[0].values, [123, 'no_results']);
});

test('expired shared coordinates are deleted while place IDs are retained', async () => {
  let statement = '';
  const removed = await clearExpiredCoordinateCache({
    query: async (sql) => {
      statement = sql;
      return { rowCount: 4 };
    },
  });
  assert.equal(removed, 4);
  assert.match(statement, /latitude = NULL/);
  assert.doesNotMatch(statement, /google_place_id = NULL/);
});
