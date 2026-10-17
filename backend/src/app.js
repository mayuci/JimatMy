const cors = require('cors');
const express = require('express');
const healthRoutes = require('./routes/health_routes');
const itemRoutes = require('./routes/item_routes');
const plannerRoutes = require('./routes/planner_routes');
const shoppingListRoutes = require('./routes/shopping_list_routes');
const budgetRoutes = require('./routes/budget_routes');
const premiseRoutes = require('./routes/premise_routes');
const authRoutes = require('./routes/auth_routes');
const { errorHandler, notFoundHandler } = require('./middleware/error_handler');
const { avatarUploadDirectory } = require('./services/avatar_service');

const app = express();

app.disable('x-powered-by');
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Accept', 'Authorization', 'Content-Type'],
}));
app.use(express.json({ limit: '50kb' }));
app.use('/media/avatars', express.static(avatarUploadDirectory, {
  dotfiles: 'deny',
  index: false,
  redirect: false,
}));

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/items', itemRoutes);
app.use('/api/planner', plannerRoutes);
app.use('/api/shopping-lists', shoppingListRoutes);
app.use('/api/budget', budgetRoutes);
app.use('/api/premises', premiseRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
