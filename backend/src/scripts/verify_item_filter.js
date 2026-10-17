const app = require('../app');
const pool = require('../config/database');

async function get(baseUrl, path, expectedStatus = 200) {
  const response = await fetch(`${baseUrl}${path}`);
  const body = await response.json();
  if (response.status !== expectedStatus) {
    throw new Error(`${path} -> ${response.status}: ${JSON.stringify(body)}`);
  }
  return body;
}

async function verify() {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}/api`;
  try {
    const filtered = await get(baseUrl, '/items?limit=100&offset=0');
    const all = await get(baseUrl, '/items?limit=100&offset=0&includePreparedFood=true');
    const explicitFalse = await get(baseUrl, '/items?limit=100&offset=0&includePreparedFood=false');
    const invalid = await get(baseUrl, '/items?includePreparedFood=yes', 400);
    const priced = await get(baseUrl, '/items?pricedOnly=true&limit=100&offset=0');
    const invalidPriced = await get(baseUrl, '/items?pricedOnly=yes', 400);
    const searches = {};
    for (const term of ['NASI GORENG', 'AYAM MASAK MERAH', 'BIHUN', 'MILO', 'AIR KOSONG']) {
      const encoded = encodeURIComponent(term);
      const normal = await get(baseUrl, `/items?q=${encoded}&limit=100&offset=0`);
      const optedIn = await get(baseUrl, `/items?q=${encoded}&limit=100&offset=0&includePreparedFood=true`);
      searches[term] = { normal: normal.meta.total, optedIn: optedIn.meta.total };
    }
    const prepared = all.data.find((item) => item.itemGroup?.trim().toUpperCase() === 'MAKANAN SIAP MASAK');
    let direct = null;
    if (prepared) direct = await get(baseUrl, `/items/${prepared.itemCode}`);
    console.log(JSON.stringify({
      totalAll: all.meta.total,
      totalVisible: filtered.meta.total,
      totalExplicitFalse: explicitFalse.meta.total,
      excluded: all.meta.total - filtered.meta.total,
      invalid: { status: 400, code: invalid.error.code },
      pricedOnly: priced.meta.total,
      invalidPricedOnly: { status: 400, code: invalidPriced.error.code },
      searches,
      preparedExample: prepared?.itemName ?? null,
      directLookup: direct?.data?.itemCode ?? null,
    }, null, 2));
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }
}

verify().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
