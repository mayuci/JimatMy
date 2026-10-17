const pool = require('../config/database');
const {
  buildGeocodingAddress,
  scoreGeocodingMatch,
} = require('../controllers/premise_controller');
const {
  CACHE_LIFETIME_DAYS,
  cacheResolvedPremise,
  clearExpiredCoordinateCache,
} = require('../services/premise_coordinate_cache_service');

function parseArguments(args) {
  let limit = null;
  let all = false;
  let delayMs = 120;
  for (let index = 0; index < args.length; index += 1) {
    const value = args[index];
    if (value === '--all') {
      all = true;
    } else if (value === '--limit') {
      limit = Number(args[++index]);
    } else if (value === '--delay-ms') {
      delayMs = Number(args[++index]);
    } else {
      throw new Error(`Unknown option: ${value}`);
    }
  }
  if (all === (limit !== null)) {
    throw new Error('Use exactly one of --all or --limit N');
  }
  if (limit !== null && (!Number.isSafeInteger(limit) || limit <= 0)) {
    throw new Error('--limit must be a positive integer');
  }
  if (!Number.isSafeInteger(delayMs) || delayMs < 0 || delayMs > 10000) {
    throw new Error('--delay-ms must be an integer from 0 to 10000');
  }
  return { limit, delayMs };
}

const wait = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const removed = await clearExpiredCoordinateCache(pool);
  if (removed > 0) console.log(`Removed ${removed} expired coordinate cache rows.`);

  const values = [];
  const limitClause = options.limit === null ? '' : `LIMIT $${values.push(options.limit)}`;
  const result = await pool.query(
    `SELECT p.premise_code, p.premise, p.address, p.district, p.state,
            p.google_place_id
      FROM premises p
      WHERE (
          p.coordinate_last_attempted_at IS NULL
          OR p.coordinate_last_attempted_at < CURRENT_TIMESTAMP - INTERVAL '${CACHE_LIFETIME_DAYS} days'
          OR (
            p.coordinate_source = 'google_geocoding'
            AND p.coordinate_cached_at < CURRENT_TIMESTAMP - INTERVAL '${CACHE_LIFETIME_DAYS} days'
          )
        )
      ORDER BY p.premise_code ASC
      ${limitClause}`,
    values,
  );

  console.log(`Resolving ${result.rowCount} imported PriceCatcher premises sequentially.`);
  const counts = { cached: 0, no_results: 0, ambiguous: 0 };
  for (let index = 0; index < result.rows.length; index += 1) {
    const outcome = await cacheResolvedPremise({
      client: pool,
      premise: result.rows[index],
      buildAddress: buildGeocodingAddress,
      scoreMatch: scoreGeocodingMatch,
    });
    counts[outcome.status] += 1;
    if ((index + 1) % 10 === 0 || index + 1 === result.rows.length) {
      console.log(`Processed ${index + 1}/${result.rows.length}.`);
    }
    if (index + 1 < result.rows.length && options.delayMs > 0) {
      await wait(options.delayMs);
    }
  }
  console.log(`Coordinate enrichment complete: ${JSON.stringify(counts)}`);
}

main()
  .catch((error) => {
    console.error(`Coordinate enrichment stopped: ${error.code ?? 'ERROR'} - ${error.message}`);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
