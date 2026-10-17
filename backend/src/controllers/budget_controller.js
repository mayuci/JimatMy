const {
  getPlannerFinancials,
  putMonthlyBudget,
} = require('../services/planner_service');
const {
  currentMalaysiaMonth,
  getBody,
  getMonth,
  getPositiveDecimal,
  rejectUnknownFields,
} = require('../utils/planner_validation');

function budgetResponse(data, month) {
  return {
    month,
    budget: data.budget,
    plannerEstimatedTotal: data.plannerEstimatedTotal,
    remainingBudget: data.remainingBudget,
    overBudget: data.overBudget,
  };
}

async function getBudget(req, res) {
  const month = currentMalaysiaMonth();
  const data = await getPlannerFinancials(req.auth.userId, month);
  return res.json({ success: true, data: budgetResponse(data, month) });
}

async function putBudget(req, res) {
  const body = getBody(req.body);
  rejectUnknownFields(body, ['month', 'amount']);
  const { month } = getMonth(body.month);
  const amount = getPositiveDecimal(body.amount, 'amount', 99999999.99);
  const result = await putMonthlyBudget(req.auth.userId, month, amount);
  const data = await getPlannerFinancials(req.auth.userId, month);
  return res
    .status(result.created ? 201 : 200)
    .json({ success: true, data: budgetResponse(data, month) });
}

module.exports = { getBudget, putBudget };
