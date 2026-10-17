const pool = require('../config/database');
const { runPriceCatcherImport } = require('../services/pricecatcher_import_service');

const DEFAULT_STATES = ['W.P. Kuala Lumpur', 'Selangor'];

function readOption(args, name) {
  const index = args.indexOf(name);
  if (index === -1) return null;
  if (!args[index + 1] || args[index + 1].startsWith('--')) {
    throw new Error(`${name} requires a value`);
  }
  return args[index + 1];
}

function parseArguments(args) {
  const supported = new Set(['--month', '--states', '--limit']);
  for (let index = 0; index < args.length; index += 2) {
    if (!supported.has(args[index])) throw new Error(`Unknown option: ${args[index]}`);
  }

  const month = readOption(args, '--month');
  if (!month || !/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    throw new Error('--month is required and must use YYYY-MM format');
  }

  const statesValue = readOption(args, '--states');
  const states = statesValue
    ? statesValue.split(',').map((state) => state.trim()).filter(Boolean)
    : DEFAULT_STATES;
  if (states.length === 0) throw new Error('--states must contain at least one state');

  const limitValue = readOption(args, '--limit');
  const limit = limitValue === null ? null : Number(limitValue);
  if (limit !== null && (!Number.isSafeInteger(limit) || limit <= 0)) {
    throw new Error('--limit must be a positive integer');
  }

  return { month, states, limit };
}

async function main() {
  try {
    const options = parseArguments(process.argv.slice(2));
    await runPriceCatcherImport(pool, options);
    console.log('PriceCatcher import completed.');
  } catch (error) {
    console.error(`PriceCatcher import failed: ${error.message}`);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
