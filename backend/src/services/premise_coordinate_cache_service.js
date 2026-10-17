const pool = require('../config/database');
const { geocodeMalaysianAddress } = require('./geocoding_service');

const CACHE_LIFETIME_DAYS = 29;

function isValidMalaysianCoordinate(latitude, longitude) {
  return Number.isFinite(latitude) && Number.isFinite(longitude)
    && latitude >= 0.5 && latitude <= 7.5
    && longitude >= 99 && longitude <= 120.5;
}

async function clearExpiredCoordinateCache(client = pool) {
  const result = await client.query(
    `UPDATE premises
        SET latitude = NULL,
            longitude = NULL,
            coordinate_source = NULL,
            coordinate_cached_at = NULL,
            coordinate_match_confidence = NULL,
            coordinate_partial_match = NULL,
            coordinate_location_type = NULL
      WHERE coordinate_source = 'google_geocoding'
        AND coordinate_cached_at < CURRENT_TIMESTAMP - INTERVAL '${CACHE_LIFETIME_DAYS} days'`,
  );
  return result.rowCount;
}

async function cacheResolvedPremise({
  client = pool,
  premise,
  buildAddress,
  scoreMatch,
  geocode = geocodeMalaysianAddress,
}) {
  const location = await geocode({
    address: buildAddress(premise),
    placeId: premise.google_place_id ?? undefined,
  });
  if (location === null) {
    await recordAttempt(client, premise.premise_code, 'no_results');
    return { status: 'no_results' };
  }

  const confidence = scoreMatch(premise, location.formattedAddress);
  if (
    !['high', 'possible'].includes(confidence)
    || !isValidMalaysianCoordinate(location.latitude, location.longitude)
  ) {
    await recordAttempt(client, premise.premise_code, 'ambiguous');
    return { status: 'ambiguous' };
  }

  await client.query(
    `UPDATE premises
        SET latitude = $2,
            longitude = $3,
            coordinate_source = 'google_geocoding',
            coordinate_cached_at = CURRENT_TIMESTAMP,
            coordinate_match_confidence = $4,
            coordinate_partial_match = $5,
            coordinate_location_type = $6,
            coordinate_last_attempted_at = CURRENT_TIMESTAMP,
            coordinate_resolution_status = 'cached',
            google_place_id = COALESCE($7, google_place_id)
      WHERE premise_code = $1`,
    [
      premise.premise_code,
      location.latitude,
      location.longitude,
      confidence,
      location.partialMatch,
      location.locationType,
      location.placeId,
    ],
  );
  return { status: 'cached', confidence };
}

async function recordAttempt(client, premiseCode, status) {
  await client.query(
    `UPDATE premises
        SET coordinate_last_attempted_at = CURRENT_TIMESTAMP,
            coordinate_resolution_status = $2
      WHERE premise_code = $1`,
    [premiseCode, status],
  );
}

module.exports = {
  CACHE_LIFETIME_DAYS,
  cacheResolvedPremise,
  clearExpiredCoordinateCache,
  isValidMalaysianCoordinate,
};
