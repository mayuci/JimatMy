const { CACHE_LIFETIME_DAYS } = require('./premise_coordinate_cache_service');

function nearestPremisesQuery() {
  return `WITH candidates AS (
    SELECT p.premise_code AS "premiseCode",
           p.premise AS "premiseName",
           p.address,
           p.premise_type AS "premiseType",
           p.district,
           p.state,
           p.latitude,
           p.longitude,
           p.coordinate_match_confidence AS "coordinateAccuracy",
           6371 * 2 * ASIN(SQRT(LEAST(1, GREATEST(0,
             POWER(SIN(RADIANS(p.latitude::DOUBLE PRECISION - $1) / 2), 2)
             + COS(RADIANS($1))
             * COS(RADIANS(p.latitude::DOUBLE PRECISION))
             * POWER(SIN(RADIANS(p.longitude::DOUBLE PRECISION - $2) / 2), 2)
           )))) AS "distanceKm"
      FROM premises p
     WHERE p.latitude IS NOT NULL
       AND p.longitude IS NOT NULL
       AND (
         p.coordinate_source IS NULL
         OR p.coordinate_cached_at >= CURRENT_TIMESTAMP - INTERVAL '${CACHE_LIFETIME_DAYS} days'
       )
       AND ($3::TEXT IS NULL OR p.state ILIKE $3)
       AND ($4::TEXT IS NULL OR p.district ILIKE $4)
       AND ($5::TEXT IS NULL OR p.premise ILIKE $5 OR p.address ILIKE $5)
  ), filtered AS (
    SELECT * FROM candidates WHERE ($6::DOUBLE PRECISION IS NULL OR "distanceKm" <= $6)
  )
  SELECT *, COUNT(*) OVER()::INTEGER AS "totalCount"
    FROM filtered
   ORDER BY "distanceKm" ASC, "premiseCode" ASC
   LIMIT $7 OFFSET $8`;
}

async function findNearestPremises({
  client,
  latitude,
  longitude,
  state,
  district,
  query,
  radiusKm,
  limit,
  offset,
}) {
  const search = query === null ? null : `%${query}%`;
  return client.query(nearestPremisesQuery(), [
    latitude,
    longitude,
    state,
    district,
    search,
    radiusKm,
    limit,
    offset,
  ]);
}

module.exports = { findNearestPremises, nearestPremisesQuery };
