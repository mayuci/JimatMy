const pool = require('../config/database');
const ApiError = require('../utils/api_error');
const { getIntegerQuery, getTextQuery } = require('../utils/validation');
const { geocodeMalaysianAddress } = require('../services/geocoding_service');
const { resolveNavigationMatch } = require('../services/places_service');
const { findNearestPremises } = require('../services/premise_nearby_service');

function getBooleanQuery(value, name, defaultValue = false) {
  if (value === undefined) return defaultValue;
  if (typeof value !== 'string' || !['true', 'false'].includes(value.toLowerCase())) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be true or false`);
  }
  return value.toLowerCase() === 'true';
}

function getPremiseCode(value) {
  if (!/^\d+$/.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'premiseCode must be a positive integer');
  }
  const premiseCode = Number(value);
  if (!Number.isSafeInteger(premiseCode) || premiseCode <= 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'premiseCode must be a positive integer');
  }
  return premiseCode;
}

function getCoordinateQuery(value, name, minimum, maximum) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} is required`);
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < minimum || parsed > maximum) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      `${name} must be a valid Malaysian coordinate`,
    );
  }
  return parsed;
}

function getOptionalNumberQuery(value, name, minimum, maximum) {
  if (value === undefined) return null;
  if (typeof value !== 'string' || value.trim() === '') {
    throw new ApiError(400, 'VALIDATION_ERROR', `${name} must be a number`);
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < minimum || parsed > maximum) {
    throw new ApiError(
      400,
      'VALIDATION_ERROR',
      `${name} must be between ${minimum} and ${maximum}`,
    );
  }
  return parsed;
}

function mapPremise(row) {
  const postcode = row.address.match(/\b\d{5}\b/)?.[0] ?? null;
  const latitude = row.latitude === null ? null : Number(row.latitude);
  const longitude = row.longitude === null ? null : Number(row.longitude);
  return {
    premiseCode: row.premiseCode,
    premiseName: row.premiseName,
    address: row.address,
    postcode,
    premiseType: row.premiseType,
    district: row.district,
    state: row.state,
    latitude,
    longitude,
    hasCoordinates: latitude !== null && longitude !== null,
    distanceKm: row.distanceKm === undefined ? undefined : Number(row.distanceKm),
    coordinateAccuracy: row.coordinateAccuracy ?? null,
  };
}

async function listNearbyPremises(req, res) {
  const latitude = getCoordinateQuery(req.query.latitude, 'latitude', 0.5, 7.5);
  const longitude = getCoordinateQuery(req.query.longitude, 'longitude', 99, 120.5);
  const q = getTextQuery(req.query.q, 'q', 200);
  const state = getTextQuery(req.query.state, 'state', 100);
  const district = getTextQuery(req.query.district, 'district', 100);
  const radiusKm = getOptionalNumberQuery(req.query.radiusKm, 'radiusKm', 0.1, 200);
  const limit = getIntegerQuery(req.query.limit, 'limit', 10, 1, 50);
  const offset = getIntegerQuery(req.query.offset, 'offset', 0, 0, 1000000);
  const result = await findNearestPremises({
    client: pool,
    latitude,
    longitude,
    state,
    district,
    query: q,
    radiusKm,
    limit,
    offset,
  });
  const total = result.rows.length ? result.rows[0].totalCount : 0;
  const premises = result.rows.map(({ totalCount, ...row }) => mapPremise(row));
  return res.json({
    success: true,
    data: premises,
    meta: { total, limit, offset },
  });
}

async function listPremises(req, res) {
  const q = getTextQuery(req.query.q, 'q', 200);
  const state = getTextQuery(req.query.state, 'state', 100);
  const district = getTextQuery(req.query.district, 'district', 100);
  const coordinatesOnly = getBooleanQuery(req.query.coordinatesOnly, 'coordinatesOnly');
  const limit = getIntegerQuery(req.query.limit, 'limit', 20, 1, 100);
  const offset = getIntegerQuery(req.query.offset, 'offset', 0, 0, 1000000);
  const values = [];
  const filters = [];

  if (q !== null) {
    values.push(`%${q}%`);
    filters.push(`(premise ILIKE $${values.length} OR address ILIKE $${values.length})`);
  }
  if (state !== null) {
    values.push(state);
    filters.push(`state ILIKE $${values.length}`);
  }
  if (district !== null) {
    values.push(district);
    filters.push(`district ILIKE $${values.length}`);
  }
  if (coordinatesOnly) filters.push('latitude IS NOT NULL AND longitude IS NOT NULL');
  values.push(limit, offset);

  const result = await pool.query(
    `SELECT premise_code AS "premiseCode", premise AS "premiseName", address,
            premise_type AS "premiseType", district, state, latitude, longitude,
            COUNT(*) OVER()::INTEGER AS "totalCount"
       FROM premises
      ${filters.length ? `WHERE ${filters.join(' AND ')}` : ''}
      ORDER BY premise ASC, premise_code ASC
      LIMIT $${values.length - 1} OFFSET $${values.length}`,
    values,
  );
  const total = result.rows.length ? result.rows[0].totalCount : 0;
  const premises = result.rows.map(({ totalCount, ...row }) => mapPremise(row));
  return res.json({ success: true, data: premises, meta: { total, limit, offset } });
}

async function getPremiseFilters(req, res) {
  const result = await pool.query(
    `SELECT state, district FROM premises
      GROUP BY state, district ORDER BY state ASC, district ASC`,
  );
  const byState = new Map();
  for (const row of result.rows) {
    if (!byState.has(row.state)) byState.set(row.state, []);
    byState.get(row.state).push(row.district);
  }
  const states = [...byState.entries()].map(([state, districts]) => ({ state, districts }));
  return res.json({ success: true, data: { states } });
}

async function getPremise(req, res) {
  const premiseCode = getPremiseCode(req.params.premiseCode);
  const result = await pool.query(
    `SELECT premise_code AS "premiseCode", premise AS "premiseName", address,
            premise_type AS "premiseType", district, state, latitude, longitude
       FROM premises WHERE premise_code = $1`,
    [premiseCode],
  );
  if (!result.rowCount) {
    throw new ApiError(404, 'PREMISE_NOT_FOUND', `Premise ${premiseCode} was not found`);
  }
  return res.json({ success: true, data: mapPremise(result.rows[0]) });
}

function normalizeOfficialText(value) {
  return value
    ?.trim()
    .replace(/,(?=\S)/g, ', ')
    .replace(/\bJLN\.?\b/gi, 'JALAN')
    .replace(/\s+/g, ' ') ?? '';
}

function buildGeocodingAddress(premise) {
  const postcode = premise.address.match(/\b\d{5}\b/)?.[0];
  return [
    normalizeOfficialText(premise.premise),
    normalizeOfficialText(premise.address),
    postcode,
    normalizeOfficialText(premise.district),
    normalizeOfficialText(premise.state),
    'Malaysia',
  ]
    .filter(Boolean)
    .join(', ');
}

const MALAYSIAN_STATES = [
  'johor', 'kedah', 'kelantan', 'melaka', 'negeri sembilan', 'pahang',
  'penang', 'perak', 'perlis', 'sabah', 'sarawak', 'selangor',
  'terengganu', 'kuala lumpur', 'labuan', 'putrajaya',
];
const IGNORED_MATCH_TOKENS = new Set([
  'jalan', 'malaysia', 'premis', 'kedai', 'pasar', 'pusat', 'tingkat',
  'blok', 'lot', 'dan', 'the',
]);

function comparableText(value) {
  return normalizeOfficialText(value)
    .toLowerCase()
    .replace(/w\.?\s*p\.?/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function meaningfulTokens(value) {
  return [...new Set(comparableText(value).split(' ').filter((token) =>
    token.length >= 3 && !IGNORED_MATCH_TOKENS.has(token) && !/^\d{5}$/.test(token)
  ))];
}

function scoreGeocodingMatch(premise, formattedAddress) {
  const returned = comparableText(formattedAddress);
  const postcode = premise.address.match(/\b\d{5}\b/)?.[0] ?? null;
  const returnedPostcodes = formattedAddress.match(/\b\d{5}\b/g) ?? [];
  const postcodeMatches = postcode === null || returnedPostcodes.includes(postcode);
  const postcodeConflicts = postcode !== null && returnedPostcodes.length > 0 && !postcodeMatches;
  const expectedState = comparableText(premise.state);
  const stateMatches = returned.includes(expectedState) ||
    (expectedState === 'kuala lumpur' && returned.includes('federal territory of kuala lumpur'));
  const conflictingState = MALAYSIAN_STATES.some((state) =>
    state !== expectedState && returned.includes(state)
  );
  const districtTokens = meaningfulTokens(premise.district);
  const districtMatches = districtTokens.length > 0 &&
    districtTokens.every((token) => returned.split(' ').includes(token));
  const addressTokens = meaningfulTokens(`${premise.premise} ${premise.address}`);
  const returnedTokens = new Set(returned.split(' '));
  const matchingTokens = addressTokens.filter((token) => returnedTokens.has(token)).length;

  if (postcodeConflicts || (!stateMatches && conflictingState)) return 'low_ambiguous';
  if (stateMatches && postcodeMatches && (districtMatches || matchingTokens >= 2)) return 'high';
  if ((stateMatches || postcodeMatches) && (districtMatches || matchingTokens >= 1)) return 'possible';
  return 'low_ambiguous';
}

async function resolvePremiseLocation(req, res) {
  const premiseCode = getPremiseCode(req.params.premiseCode);
  if (req.body !== undefined && Object.keys(req.body).length > 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Request body must be empty');
  }
  const result = await pool.query(
    `SELECT premise, address, district, state
       FROM premises WHERE premise_code = $1`,
    [premiseCode],
  );
  if (!result.rowCount) {
    throw new ApiError(404, 'PREMISE_NOT_FOUND', `Premise ${premiseCode} was not found`);
  }

  const location = await geocodeMalaysianAddress({
    address: buildGeocodingAddress(result.rows[0]),
  });
  if (location === null) {
    return res.json({
      success: true,
      data: {
        resolutionStatus: 'no_results',
        latitude: null,
        longitude: null,
        formattedAddress: null,
        matchConfidence: null,
        partialMatch: null,
        locationType: null,
      },
    });
  }
  const { placeId: _placeId, ...publicLocation } = location;
  return res.json({
    success: true,
    data: {
      resolutionStatus: 'resolved',
      ...publicLocation,
      matchConfidence: scoreGeocodingMatch(result.rows[0], location.formattedAddress),
    },
  });
}

async function resolveNavigation(req, res) {
  const premiseCode = getPremiseCode(req.params.premiseCode);
  if (req.body !== undefined && Object.keys(req.body).length > 0) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Request body must be empty');
  }
  const data = await resolveNavigationMatch({ premiseCode, pool });
  return res.json({ success: true, data });
}

module.exports = {
  buildGeocodingAddress,
  normalizeOfficialText,
  scoreGeocodingMatch,
  getPremise,
  getPremiseFilters,
  listNearbyPremises,
  listPremises,
  resolveNavigation,
  resolvePremiseLocation,
};
