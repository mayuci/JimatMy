const app = require('../app');
const pool = require('../config/database');

async function get(baseUrl, path, expectedStatus = 200) {
  const response = await fetch(`${baseUrl}${path}`);
  const body = await response.json();
  if (response.status !== expectedStatus) {
    throw new Error(`${path} -> ${response.status}: ${JSON.stringify(body)}`);
  }
  return { status: response.status, body };
}

async function verify() {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}/api`;
  try {
    const kl = await get(baseUrl, '/premises?state=W.P.%20Kuala%20Lumpur&limit=3');
    const selangor = await get(baseUrl, '/premises?state=Selangor&q=99&limit=3');
    const filters = await get(baseUrl, '/premises/filters');
    const coordinates = await get(baseUrl, '/premises?coordinatesOnly=true&limit=5');
    const detailCode = kl.body.data[0]?.premiseCode ?? selangor.body.data[0]?.premiseCode;
    if (!detailCode) throw new Error('No Kuala Lumpur or Selangor premise was available');
    const detail = await get(baseUrl, `/premises/${detailCode}`);
    const invalid = await get(baseUrl, '/premises?coordinatesOnly=yes', 400);
    const missing = await get(baseUrl, '/premises/999999999', 404);

    console.log(JSON.stringify({
      kualaLumpur: { status: kl.status, total: kl.body.meta.total, returned: kl.body.data.length },
      selangorSearch: { status: selangor.status, total: selangor.body.meta.total, returned: selangor.body.data.length },
      filters: { status: filters.status, states: filters.body.data.states.length },
      coordinatesOnly: { status: coordinates.status, total: coordinates.body.meta.total },
      detail: { status: detail.status, premiseCode: detail.body.data.premiseCode, postcode: detail.body.data.postcode },
      validation: { status: invalid.status, code: invalid.body.error.code },
      missing: { status: missing.status, code: missing.body.error.code },
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
