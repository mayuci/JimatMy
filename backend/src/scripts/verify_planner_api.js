const app = require('../app');
const pool = require('../config/database');

function currentMonth() {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kuala_Lumpur',
    year: 'numeric',
    month: '2-digit',
  }).format(new Date());
}

async function requestResult(baseUrl, method, path, body, token) {
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await response.json();
  return { status: response.status, body: json };
}

async function request(baseUrl, method, path, body, token) {
  const result = await requestResult(baseUrl, method, path, body, token);
  const { status, body: json } = result;
  if (status < 200 || status >= 300) {
    throw new Error(`${method} ${path} -> ${status}: ${JSON.stringify(json)}`);
  }
  return result;
}

async function verify() {
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}/api`;
  let listId;
  let deleted = false;
  let userId;
  let token;

  try {
    const unauthenticated = await requestResult(baseUrl, 'GET', '/planner/overview');
    if (unauthenticated.status !== 401 || unauthenticated.body.error.code !== 'AUTH_REQUIRED') {
      throw new Error(`Planner route was not protected: ${JSON.stringify(unauthenticated)}`);
    }
    const publicItems = await request(baseUrl, 'GET', '/items?limit=1&offset=0');
    console.log(JSON.stringify({
      step: 'routeProtection',
      plannerWithoutToken: unauthenticated.status,
      publicItems: publicItems.status,
    }));

    const email = `planner-verification-${Date.now()}@jimatmy.local`;
    const registered = await request(baseUrl, 'POST', '/auth/register', {
      name: 'Planner Verification User',
      email,
      password: 'PlannerVerify9Secure',
    });
    token = registered.body.data.token;
    userId = registered.body.data.user.userId;
    console.log(JSON.stringify({ step: 'registerLoginUser', status: registered.status }));

    const initial = await request(baseUrl, 'GET', '/planner/overview', undefined, token);
    console.log(JSON.stringify({ step: 'overview', status: initial.status }));

    const invalidId = await requestResult(baseUrl, 'GET', '/shopping-lists/not-a-uuid', undefined, token);
    console.log(JSON.stringify({
      step: 'invalidUuid',
      status: invalidId.status,
      errorCode: invalidId.body.error.code,
    }));

    const missing = await requestResult(
      baseUrl,
      'GET',
      '/shopping-lists/00000000-0000-4000-8000-000000000000', undefined, token,
    );
    console.log(JSON.stringify({
      step: 'missingOwnedList',
      status: missing.status,
      errorCode: missing.body.error.code,
    }));

    const created = await request(baseUrl, 'POST', '/shopping-lists', {
      name: `Planner verification ${Date.now()}`,
    }, token);
    listId = created.body.data.shoppingListId;
    console.log(JSON.stringify({ step: 'createList', status: created.status, listId }));

    const lists = await request(baseUrl, 'GET', '/shopping-lists', undefined, token);
    console.log(JSON.stringify({
      step: 'listShoppingLists',
      status: lists.status,
      containsCreatedList: lists.body.data.some((list) => list.shoppingListId === listId),
    }));

    const renamed = await request(baseUrl, 'PATCH', `/shopping-lists/${listId}`, {
      name: 'Renamed planner verification',
    }, token);
    console.log(JSON.stringify({
      step: 'renameList',
      status: renamed.status,
      name: renamed.body.data.name,
    }));

    const added = await request(baseUrl, 'POST', `/shopping-lists/${listId}/items`, {
      itemCode: 1,
      quantity: 1,
    }, token);
    const listItemId = added.body.data.listItemId;
    console.log(JSON.stringify({
      step: 'addItem',
      status: added.status,
      itemCode: added.body.data.itemCode,
      bestPrice: added.body.data.bestPrice,
      availabilityStatus: added.body.data.availabilityStatus,
    }));

    const duplicate = await requestResult(
      baseUrl,
      'POST',
      `/shopping-lists/${listId}/items`,
      { itemCode: 1, quantity: 1 }, token,
    );
    console.log(JSON.stringify({
      step: 'duplicateItem',
      status: duplicate.status,
      errorCode: duplicate.body.error.code,
    }));

    const quantity = await request(
      baseUrl,
      'PATCH',
      `/shopping-lists/${listId}/items/${listItemId}`,
      { quantity: 2 }, token,
    );
    console.log(JSON.stringify({
      step: 'updateQuantity',
      status: quantity.status,
      quantity: quantity.body.data.quantity,
      estimatedLineTotal: quantity.body.data.estimatedLineTotal,
    }));

    const completed = await request(
      baseUrl,
      'PATCH',
      `/shopping-lists/${listId}/items/${listItemId}`,
      { isChecked: true }, token,
    );
    console.log(JSON.stringify({
      step: 'markComplete',
      status: completed.status,
      isChecked: completed.body.data.isChecked,
    }));

    const budget = await request(baseUrl, 'PUT', '/budget', {
      month: currentMonth(),
      amount: 10,
    }, token);
    console.log(JSON.stringify({
      step: 'setBudget',
      status: budget.status,
      amount: budget.body.data.budget.amount,
      plannerEstimatedTotal: budget.body.data.plannerEstimatedTotal,
      remainingBudget: budget.body.data.remainingBudget,
      overBudget: budget.body.data.overBudget,
    }));

    const currentBudget = await request(baseUrl, 'GET', '/budget', undefined, token);
    console.log(JSON.stringify({
      step: 'getBudget',
      status: currentBudget.status,
      amount: currentBudget.body.data.budget.amount,
      remainingBudget: currentBudget.body.data.remainingBudget,
      overBudget: currentBudget.body.data.overBudget,
    }));

    const detail = await request(baseUrl, 'GET', `/shopping-lists/${listId}`, undefined, token);
    console.log(JSON.stringify({
      step: 'listDetail',
      status: detail.status,
      itemCount: detail.body.data.itemCount,
      estimatedTotal: detail.body.data.estimatedTotal,
      cheapestPremise: detail.body.data.items[0].cheapestPremise?.premiseName ?? null,
    }));

    const verified = await request(baseUrl, 'GET', '/planner/overview', undefined, token);
    console.log(JSON.stringify({
      step: 'verifyOverview',
      status: verified.status,
      remainingBudget: verified.body.data.remainingBudget,
      overBudget: verified.body.data.overBudget,
    }));

    const removedItem = await request(
      baseUrl,
      'DELETE',
      `/shopping-lists/${listId}/items/${listItemId}`, undefined, token,
    );
    console.log(JSON.stringify({
      step: 'deleteItem',
      status: removedItem.status,
      deleted: removedItem.body.data.deleted,
    }));

    const removed = await request(baseUrl, 'DELETE', `/shopping-lists/${listId}`, undefined, token);
    deleted = removed.body.data.deleted;
    console.log(JSON.stringify({ step: 'deleteList', status: removed.status, deleted }));
  } finally {
    if (listId && !deleted) {
      await request(baseUrl, 'DELETE', `/shopping-lists/${listId}`, undefined, token).catch(() => {});
    }
    if (userId) await pool.query('DELETE FROM users WHERE user_id = $1', [userId]);
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }
}

verify().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
