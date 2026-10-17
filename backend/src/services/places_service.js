const ApiError = require('../utils/api_error');

const PLACES_TEXT_SEARCH_URL = 'https://places.googleapis.com/v1/places:searchText';
const PLACES_TIMEOUT_MS = 5000;
const MAX_RESULT_COUNT = 5;
const FIELD_MASK = 'places.id,places.displayName,places.formattedAddress,places.location';

// Tokens that never distinguish one branch from another.
const CORPORATE_SUFFIXES = new Set([
  'sdn', 'bhd', 'berhad', 'ltd', 'co', 'inc',
]);

const MALAYSIAN_STATES = new Set([
  'johor', 'kedah', 'kelantan', 'melaka', 'negeri sembilan', 'pahang',
  'perak', 'perlis', 'pulau pinang', 'sabah', 'sarawak', 'selangor',
  'terengganu', 'kuala lumpur', 'labuan', 'putrajaya',
]);

const IGNORED_MATCH_TOKENS = new Set([
  'jalan', 'malaysia', 'premis', 'kedai', 'pasar', 'pusat', 'tingkat',
  'blok', 'lot', 'dan', 'the', 'no', 'cawangan',
]);

function normalizeText(value) {
  return String(value ?? '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function meaningfulTokens(value) {
  return [...new Set(normalizeText(value).split(' '))].filter(
    (token) =>
      token.length >= 3 &&
      !IGNORED_MATCH_TOKENS.has(token) &&
      !/^\d{5}$/.test(token),
  );
}

function normalizedName(value) {
  return meaningfulTokens(value)
    .filter((token) => !CORPORATE_SUFFIXES.has(token))
    .join(' ');
}

function buildNavigationQuery(premise) {
  const name = String(premise.premise ?? '').trim();
  const address = String(premise.address ?? '').trim();
  const normalizedAddress = normalizeText(address);
  const postcode = address.match(/\b\d{5}\b/)?.[0] ?? null;
  const district = String(premise.district ?? '').trim();
  const state = String(premise.state ?? '').trim();

  const components = [];
  if (name) components.push(name);
  if (address) components.push(address);
  if (postcode !== null && !normalizedAddress.includes(postcode)) {
    components.push(postcode);
  }
  if (district) components.push(district);
  if (state && !normalizedAddress.includes(normalizeText(state))) {
    components.push(state);
  }
  components.push('Malaysia');

  return components
    .join(', ')
    .replace(/,+/g, ',')
    .replace(/,\s+/g, ', ')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

function mapPlace(place) {
  return {
    id: place.id,
    displayName: place.displayName?.text ?? '',
    formattedAddress: place.formattedAddress ?? '',
    latitude: place.location?.latitude ?? null,
    longitude: place.location?.longitude ?? null,
  };
}

/**
 * Calls the Places API (New) Text Search endpoint. The API key, request
 * headers, and raw Google response are intentionally never logged.
 */
async function searchPlaces({
  query,
  apiKey = process.env.GOOGLE_PLACES_API_KEY,
  fetchImpl = fetch,
  timeoutMs = PLACES_TIMEOUT_MS,
}) {
  if (!apiKey || apiKey.trim().length === 0) {
    throw new ApiError(503, 'PLACES_NOT_CONFIGURED', 'Store navigation is not configured');
  }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  let response;
  try {
    response = await fetchImpl(PLACES_TEXT_SEARCH_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': FIELD_MASK,
      },
      body: JSON.stringify({
        textQuery: query,
        regionCode: 'MY',
        maxResultCount: MAX_RESULT_COUNT,
      }),
      signal: controller.signal,
    });
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new ApiError(504, 'PLACES_TIMEOUT', 'Store navigation timed out');
    }
    throw new ApiError(502, 'PLACES_NETWORK_ERROR', 'The backend could not reach Google Places');
  } finally {
    clearTimeout(timeout);
  }

  if (response.status === 403) {
    throw new ApiError(
      403,
      'PLACES_DENIED',
      'Google denied the navigation request; check API enablement, billing, and key restrictions',
    );
  }
  if (response.status === 429) {
    throw new ApiError(429, 'PLACES_RATE_LIMITED', 'Store navigation rate limit was reached');
  }
  if (!response.ok) {
    throw new ApiError(502, 'PLACES_UPSTREAM_ERROR', 'Google Places returned an error');
  }

  let payload;
  try {
    payload = await response.json();
  } catch (_) {
    throw new ApiError(502, 'PLACES_INVALID_RESPONSE', 'Store navigation returned an invalid response');
  }
  if (payload === null || typeof payload !== 'object' || !Array.isArray(payload.places)) {
    throw new ApiError(502, 'PLACES_INVALID_RESPONSE', 'Store navigation returned an invalid response');
  }
  return payload.places.map(mapPlace);
}

/**
 * Conservatively selects one exact branch. A candidate is confirmed only when
 * its normalized premise name AND postcode match and the state/address
 * evidence does not conflict. Ambiguous or conflicting branches stay
 * unconfirmed so navigation never selects the wrong branch.
 */
function selectNavigationMatch(premise, candidates) {
  const postcode = String(premise.address ?? '').match(/\b\d{5}\b/)?.[0] ?? null;
  const expectedName = normalizedName(premise.premise);
  const stateText = normalizeText(premise.state);

  const qualifying = candidates.filter((candidate) => {
    const displayName = candidate.displayName ?? '';
    const formattedAddress = candidate.formattedAddress ?? '';
    const normalizedAddress = normalizeText(formattedAddress);
    const addressPostcodes = formattedAddress.match(/\b\d{5}\b/g) ?? [];
    const nameMatches =
      expectedName.length > 0 && normalizedName(displayName) === expectedName;
    const postcodeMatches =
      postcode !== null && addressPostcodes.includes(postcode);
    const postcodeConflicts =
      postcode !== null && addressPostcodes.length > 0 && !postcodeMatches;
    const conflictingState = [...MALAYSIAN_STATES].some(
      (state) => state !== stateText && normalizedAddress.includes(state),
    );
    return (
      nameMatches &&
      postcodeMatches &&
      !postcodeConflicts &&
      !conflictingState
    );
  });

  if (qualifying.length === 1) {
    const exact = qualifying[0];
    return {
      confirmed: true,
      placeId: exact.id,
      displayName: exact.displayName,
      formattedAddress: exact.formattedAddress,
      latitude: exact.latitude,
      longitude: exact.longitude,
    };
  }
  return { confirmed: false };
}

// In-memory deduplication of simultaneous requests per premise. Nothing is
// cached or persisted; results are never written to PostgreSQL.
const inflightNavigation = new Map();

function resolveNavigationMatch({ premiseCode, pool, apiKey, fetchImpl, timeoutMs }) {
  const existing = inflightNavigation.get(premiseCode);
  if (existing) return existing;
  const operation = doResolveNavigationMatch({
    premiseCode,
    pool,
    apiKey,
    fetchImpl,
    timeoutMs,
  });
  inflightNavigation.set(premiseCode, operation);
  operation.then(
    () => inflightNavigation.delete(premiseCode),
    () => inflightNavigation.delete(premiseCode),
  );
  return operation;
}

async function doResolveNavigationMatch({ premiseCode, pool, apiKey, fetchImpl, timeoutMs }) {
  const result = await pool.query(
    `SELECT premise, address, district, state
       FROM premises WHERE premise_code = $1`,
    [premiseCode],
  );
  if (!result.rowCount) {
    throw new ApiError(404, 'PREMISE_NOT_FOUND', `Premise ${premiseCode} was not found`);
  }
  const premise = result.rows[0];
  const places = await searchPlaces({
    query: buildNavigationQuery(premise),
    apiKey,
    fetchImpl,
    timeoutMs,
  });
  return selectNavigationMatch(premise, places);
}

module.exports = {
  buildNavigationQuery,
  mapPlace,
  resolveNavigationMatch,
  searchPlaces,
  selectNavigationMatch,
};

