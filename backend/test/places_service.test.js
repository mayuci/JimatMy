const test = require('node:test');
const assert = require('node:assert/strict');
const {
  buildNavigationQuery,
  resolveNavigationMatch,
  searchPlaces,
  selectNavigationMatch,
} = require('../src/services/places_service');

const premise = {
  premise: 'OFFICIAL TEST PREMISE',
  address: 'NO 1, JALAN TEST, 47301 PETALING JAYA',
  district: 'Petaling Jaya',
  state: 'Selangor',
};

function response(status, body) {
  return { ok: status >= 200 && status < 300, status, json: async () => body };
}

// Candidate shape after mapPlace() has flattened the Places API response.
const mappedCandidate = {
  id: 'ChIJexact-branch',
  displayName: 'OFFICIAL TEST PREMISE',
  formattedAddress: 'No 1, Jalan Test, 47301 Petaling Jaya, Selangor, Malaysia',
  latitude: 3.1,
  longitude: 101.6,
};

// Raw Places API (New) response shape used by the mocked upstream.
const rawPlace = {
  id: 'ChIJexact-branch',
  displayName: { text: 'OFFICIAL TEST PREMISE' },
  formattedAddress: 'No 1, Jalan Test, 47301 Petaling Jaya, Selangor, Malaysia',
  location: { latitude: 3.1, longitude: 101.6 },
};

test('navigation query includes name, address, postcode, district, state and Malaysia', () => {
  const query = buildNavigationQuery(premise);
  assert.match(query, /^OFFICIAL TEST PREMISE,/);
  assert.match(query, /NO 1, JALAN TEST, 47301 PETALING JAYA/);
  assert.match(query, /47301/);
  assert.match(query, /Petaling Jaya/);
  assert.match(query, /Selangor/);
  assert.match(query, /Malaysia$/);
});

test('selects the exact branch and returns its Place ID', () => {
  const result = selectNavigationMatch(premise, [
    mappedCandidate,
    {
      id: 'ChIJother',
      displayName: 'SOME OTHER MART',
      formattedAddress: 'No 99, Jalan Lain, 50000 Kuala Lumpur, Malaysia',
      latitude: 3.2,
      longitude: 101.7,
    },
  ]);
  assert.equal(result.confirmed, true);
  assert.equal(result.placeId, 'ChIJexact-branch');
  assert.equal(result.displayName, 'OFFICIAL TEST PREMISE');
  assert.equal(result.latitude, 3.1);
  assert.equal(result.longitude, 101.6);
});

test('ambiguous candidates return confirmed=false', () => {
  const result = selectNavigationMatch(premise, [
    { ...mappedCandidate, id: 'ChIJbranch-a' },
    {
      ...mappedCandidate,
      id: 'ChIJbranch-b',
      formattedAddress: 'No 2, Jalan Test, 47301 Petaling Jaya, Selangor, Malaysia',
    },
  ]);
  assert.equal(result.confirmed, false);
});

test('weak evidence never claims an exact match', () => {
  const result = selectNavigationMatch(premise, [
    {
      id: 'ChIJweak',
      displayName: 'OFFICIAL TEST PREMISE',
      formattedAddress: 'Petaling Jaya, Selangor, Malaysia',
      latitude: 3.1,
      longitude: 101.6,
    },
  ]);
  assert.equal(result.confirmed, false);
});

test('AEON BIG SUBANG JAYA matches AEON BiG Subang Jaya with postcode 47500', () => {
  const result = selectNavigationMatch(
    {
      premise: 'AEON BIG SUBANG JAYA',
      address: 'NO 1, PERSIARAN SUBANG, 47500 SUBANG JAYA',
      district: 'Petaling Jaya',
      state: 'Selangor',
    },
    [
      {
        id: 'ChIJaeon-subang',
        displayName: 'AEON BiG Subang Jaya',
        formattedAddress:
          'No 1, Persiaran Subang, 47500 Subang Jaya, Selangor, Malaysia',
        latitude: 3.07,
        longitude: 101.58,
      },
    ],
  );
  assert.equal(result.confirmed, true);
  assert.equal(result.placeId, 'ChIJaeon-subang');
});

test('similarly named branch with a different postcode remains unconfirmed', () => {
  const result = selectNavigationMatch(
    {
      premise: 'AEON BIG SUBANG JAYA',
      address: 'NO 1, PERSIARAN SUBANG, 47500 SUBANG JAYA',
      district: 'Petaling Jaya',
      state: 'Selangor',
    },
    [
      {
        id: 'ChIJaeon-elsewhere',
        displayName: 'AEON BiG Subang Jaya',
        formattedAddress:
          'No 2, Jalan Lain, 47600 Subang Jaya, Selangor, Malaysia',
        latitude: 3.08,
        longitude: 101.59,
      },
    ],
  );
  assert.equal(result.confirmed, false);
});

test('query removes repeated postcode and state components', () => {
  const query = buildNavigationQuery({
    premise: 'AEON BIG SUBANG JAYA',
    address: 'NO 1, PERSIARAN SUBANG, 47500 SUBANG JAYA',
    district: 'Petaling Jaya',
    state: 'Selangor',
  });
  assert.equal(
    query,
    'AEON BIG SUBANG JAYA, NO 1, PERSIARAN SUBANG, 47500 SUBANG JAYA, Petaling Jaya, Selangor, Malaysia',
  );
  assert.equal(query.split('47500').length - 1, 1);
  assert.equal(query.split('Selangor').length - 1, 1);
});

test('query does not repeat a state already inside the address', () => {
  const query = buildNavigationQuery({
    premise: 'TEST MART',
    address: 'NO 1, JALAN TEST, 50000 KUALA LUMPUR, W.P. KUALA LUMPUR',
    district: 'Kuala Lumpur',
    state: 'W.P. Kuala Lumpur',
  });
  assert.equal(
    query,
    'TEST MART, NO 1, JALAN TEST, 50000 KUALA LUMPUR, W.P. KUALA LUMPUR, Kuala Lumpur, Malaysia',
  );
});

test('reports missing Places configuration', async () => {
  await assert.rejects(
    searchPlaces({ query: 'TEST', apiKey: '  ' }),
    (error) => error.code === 'PLACES_NOT_CONFIGURED' && error.status === 503,
  );
});

test('reports timeout without retrying', async () => {
  let calls = 0;
  const fetchImpl = async () => {
    calls += 1;
    const error = new Error('aborted');
    error.name = 'AbortError';
    throw error;
  };
  await assert.rejects(
    searchPlaces({ query: 'TEST', apiKey: 'key', fetchImpl }),
    (error) => error.code === 'PLACES_TIMEOUT' && error.status === 504,
  );
  assert.equal(calls, 1);
});

test('reports denied request safely', async () => {
  await assert.rejects(
    searchPlaces({ query: 'TEST', apiKey: 'key', fetchImpl: async () => response(403, {}) }),
    (error) => error.code === 'PLACES_DENIED' && error.status === 403,
  );
});

test('reports rate limit safely', async () => {
  await assert.rejects(
    searchPlaces({ query: 'TEST', apiKey: 'key', fetchImpl: async () => response(429, {}) }),
    (error) => error.code === 'PLACES_RATE_LIMITED' && error.status === 429,
  );
});

test('makes exactly one Malaysia-restricted Text Search request', async () => {
  let calls = 0;
  const fetchImpl = async (url, options) => {
    calls += 1;
    assert.equal(url, 'https://places.googleapis.com/v1/places:searchText');
    assert.equal(options.method, 'POST');
    assert.equal(options.headers['Content-Type'], 'application/json');
    assert.equal(options.headers['X-Goog-Api-Key'], 'test-key');
    assert.equal(
      options.headers['X-Goog-FieldMask'],
      'places.id,places.displayName,places.formattedAddress,places.location',
    );
    const body = JSON.parse(options.body);
    assert.equal(body.regionCode, 'MY');
    assert.equal(body.maxResultCount, 5);
    assert.match(body.textQuery, /OFFICIAL TEST PREMISE/);
    return response(200, { places: [rawPlace] });
  };
  const result = await searchPlaces({
    query: 'OFFICIAL TEST PREMISE, ...',
    apiKey: 'test-key',
    fetchImpl,
  });
  assert.equal(calls, 1);
  assert.deepEqual(result[0], mappedCandidate);
});

test('deduplicates simultaneous requests for the same premise', async () => {
  let searchCalls = 0;
  const gate = {};
  gate.promise = new Promise((resolve) => {
    gate.resolve = resolve;
  });
  const fetchImpl = async () => {
    searchCalls += 1;
    await gate.promise;
    return response(200, { places: [rawPlace] });
  };
  const fakePool = {
    query: async () => ({ rowCount: 1, rows: [premise] }),
  };
  const first = resolveNavigationMatch({
    premiseCode: 22063,
    pool: fakePool,
    apiKey: 'key',
    fetchImpl,
  });
  const second = resolveNavigationMatch({
    premiseCode: 22063,
    pool: fakePool,
    apiKey: 'key',
    fetchImpl,
  });
  gate.resolve();
  const [a, b] = await Promise.all([first, second]);
  assert.equal(searchCalls, 1);
  assert.equal(a.confirmed, true);
  assert.equal(a.placeId, 'ChIJexact-branch');
  assert.deepEqual(a, b);
});
