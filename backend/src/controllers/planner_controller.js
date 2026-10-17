const { getPlannerFinancials } = require('../services/planner_service');
const { currentMalaysiaMonth } = require('../utils/planner_validation');
const {
  createBasketFromTemplate,
  listBasketTemplates,
} = require('../services/basket_template_service');

async function getOverview(req, res) {
  const month = currentMalaysiaMonth();
  const data = await getPlannerFinancials(req.auth.userId, month);
  return res.json({
    success: true,
    data: {
      month,
      activeShoppingLists: data.lists,
      activeListCount: data.lists.length,
      totalItemCount: data.lists.reduce((total, list) => total + list.itemCount, 0),
      plannerEstimatedTotal: data.plannerEstimatedTotal,
      currentMonthlyBudget: data.budget,
      remainingBudget: data.remainingBudget,
      overBudget: data.overBudget,
    },
  });
}

async function getTemplates(req, res) {
  return res.json({ success: true, data: await listBasketTemplates() });
}

async function createFromTemplate(req, res) {
  const list = await createBasketFromTemplate(req.auth.userId, req.params.templateKey);
  return res.status(201).json({ success: true, data: list });
}

module.exports = { createFromTemplate, getOverview, getTemplates };
