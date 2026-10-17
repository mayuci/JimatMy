const assert = require('node:assert/strict');
const test = require('node:test');
const { buildGeocodingAddress } = require('../src/controllers/premise_controller');
const { geocodeMalaysianAddress } = require('../src/services/geocoding_service');

function response(payload, status = 200) {
  return { ok: status >= 200 && status < 300, status, json: async () => payload };
}

test('builds a precise official Malaysian address query', () => {
  const address = buildGeocodingAddress({
    premise: 'OFFICIAL PREMISE',
    address: 'NO 1, JALAN TEST, 47301 PETALING JAYA',
    district: 'Petaling Jaya',
    state: 'Selangor',
  });
  assert.match(address, /^OFFICIAL PREMISE,/);
  assert.match(address, /47301/);
  assert.match(address, /Petaling Jaya, Selangor, Malaysia$/);
});

test('makes exactly one Malaysia-restricted request and maps the first result', async () => {
  let calls = 0;
  const fetchImpl = async (url) => {
    calls += 1;
    assert.equal(url.searchParams.get('components'), 'country:MY');
    assert.equal(url.searchParams.get('region'), 'my');
    assert.equal(url.searchParams.get('address'), 'Official address, Malaysia');
    return response({
      status: 'OK',
      results: [{
        place_id: 'place-test-1',
        formatted_address: 'Resolved address, Malaysia',
        partial_match: false,
        geometry: {
          location: { lat: 3.1, lng: 101.6 },
          location_type: 'ROOFTOP',
        },
      }],
    });
  };
  const result = await geocodeMalaysianAddress({
    address: 'Official address, Malaysia',
    apiKey: 'mock-key',
    fetchImpl,
  });
  assert.equal(calls, 1);
  assert.deepEqual(result, {
    latitude: 3.1,
    longitude: 101.6,
    formattedAddress: 'Resolved address, Malaysia',
    partialMatch: false,
    locationType: 'ROOFTOP',
    placeId: 'place-test-1',
  });
});

test('refreshes a cached place ID without also sending an address', async () => {
  await geocodeMalaysianAddress({
    address: 'Fallback address, Malaysia',
    placeId: 'saved-place-id',
    apiKey: 'mock-key',
    fetchImpl: async (url) => {
      assert.equal(url.searchParams.get('place_id'), 'saved-place-id');
      assert.equal(url.searchParams.has('address'), false);
      return response({
        status: 'OK',
        results: [{
          place_id: 'saved-place-id',
          formatted_address: 'Resolved address, Malaysia',
          geometry: {
            location: { lat: 3.1, lng: 101.6 },
            location_type: 'ROOFTOP',
          },
        }],
      });
    },
  });
});

test('returns null for zero results without retrying', async () => {
  let calls = 0;
  const result = await geocodeMalaysianAddress({
    address: 'Unknown address, Malaysia',
    apiKey: 'mock-key',
    fetchImpl: async () => {
      calls += 1;
      return response({ status: 'ZERO_RESULTS', results: [] });
    },
  });
  assert.equal(result, null);
  assert.equal(calls, 1);
});

test('reports missing configuration and rate limits clearly', async () => {
  await assert.rejects(
    geocodeMalaysianAddress({ address: 'Address', apiKey: '' }),
    (error) => error.code === 'GEOCODING_NOT_CONFIGURED' && error.status === 503,
  );
  await assert.rejects(
    geocodeMalaysianAddress({
      address: 'Address',
      apiKey: 'mock-key',
      fetchImpl: async () => response({ status: 'OVER_QUERY_LIMIT' }),
    }),
    (error) => error.code === 'GEOCODING_RATE_LIMITED' && error.status === 429,
  );
});
