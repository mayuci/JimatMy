const app = require('../app');
const pool = require('../config/database');

async function call(base, method, path, body, token) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: response.status, body: await response.json() };
}

function expectStatus(result, status) {
  if (result.status !== status) throw new Error(`Expected ${status}, got ${result.status}`);
}

async function verify() {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}/api`;
  const emailA = `features-a-${Date.now()}@jimatmy.local`;
  const emailB = `features-b-${Date.now()}@jimatmy.local`;
  let userIds = [];
  try {
    const unauthenticated = await call(base, 'PUT', '/auth/me/favorites/items/1');
    expectStatus(unauthenticated, 401);
    const accountA = await call(base, 'POST', '/auth/register', {
      name: 'Features A', email: emailA, password: 'FeaturesVerify9',
    });
    const accountB = await call(base, 'POST', '/auth/register', {
      name: 'Features B', email: emailB, password: 'FeaturesVerify9',
    });
    const tokenA = accountA.body.data.token;
    const tokenB = accountB.body.data.token;
    userIds = [accountA.body.data.user.userId, accountB.body.data.user.userId];
    const added = await call(base, 'PUT', '/auth/me/favorites/items/1', undefined, tokenA);
    const duplicate = await call(base, 'PUT', '/auth/me/favorites/items/1', undefined, tokenA);
    const listedA = await call(base, 'GET', '/auth/me/favorites/items', undefined, tokenA);
    const listedB = await call(base, 'GET', '/auth/me/favorites/items', undefined, tokenB);
    const status = await call(base, 'GET', '/auth/me/favorites/items/1', undefined, tokenA);
    const relogin = await call(base, 'POST', '/auth/login', {
      email: emailA, password: 'FeaturesVerify9',
    });
    const persisted = await call(
      base, 'GET', '/auth/me/favorites/items', undefined, relogin.body.data.token,
    );
    const history = await call(base, 'POST', '/auth/me/history', { itemCode: 1 }, tokenA);
    const historyAgain = await call(base, 'POST', '/auth/me/history', { itemCode: 1 }, tokenA);
    const historyList = await call(base, 'GET', '/auth/me/history', undefined, tokenA);
    const otherHistory = await call(base, 'GET', '/auth/me/history', undefined, tokenB);
    const summary = await call(base, 'GET', '/auth/me/summary', undefined, tokenA);
    const cleared = await call(base, 'DELETE', '/auth/me/history', undefined, tokenA);
    const summaryAfterClear = await call(base, 'GET', '/auth/me/summary', undefined, tokenA);
    const removed = await call(base, 'DELETE', '/auth/me/favorites/items/1', undefined, tokenA);
    expectStatus(added, 201);
    expectStatus(duplicate, 200);
    expectStatus(listedA, 200);
    expectStatus(listedB, 200);
    expectStatus(status, 200);
    expectStatus(removed, 200);
    expectStatus(history, 201);
    expectStatus(historyAgain, 200);
    expectStatus(cleared, 200);
    expectStatus(summary, 200);
    if (listedA.body.data.length !== 1 || listedB.body.data.length !== 0 ||
        persisted.body.data.length !== 1 || !status.body.data.isFavorite) {
      throw new Error('Favourite ownership/status verification failed');
    }
    if (historyList.body.data.length !== 1 || historyList.body.data[0].itemCode !== 1 ||
        otherHistory.body.data.length !== 0) {
      throw new Error('Recent-view upsert or ownership verification failed');
    }
    if (summary.body.data.favoriteItemCount !== 1 || summary.body.data.historyCount !== 1 ||
        summary.body.data.shoppingListCount !== 0 || summaryAfterClear.body.data.historyCount !== 0) {
      throw new Error('Profile summary verification failed');
    }
    console.log(JSON.stringify({
      unauthenticated: unauthenticated.status,
      add: added.status,
      duplicate: duplicate.status,
      persistedAfterLogin: persisted.body.data.length,
      userSpecific: listedB.body.data.length === 0,
      remove: removed.status,
      recentViewUpserted: historyList.body.data.length,
      recentViewUserSpecific: otherHistory.body.data.length === 0,
      cleared: cleared.body.data.clearedCount,
      summary: summary.status,
    }));
  } finally {
    for (const userId of userIds) await pool.query('DELETE FROM users WHERE user_id = $1', [userId]);
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }
}

verify().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
