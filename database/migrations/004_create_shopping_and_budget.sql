BEGIN;

CREATE TABLE shopping_lists (
    shopping_list_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE shopping_list_items (
    shopping_list_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(shopping_list_id) ON DELETE CASCADE,
    item_code INTEGER NOT NULL REFERENCES items(item_code) ON DELETE RESTRICT,
    quantity NUMERIC(10,2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    is_checked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (shopping_list_id, item_code)
);

CREATE TABLE budgets (
    budget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    shopping_list_id UUID REFERENCES shopping_lists(shopping_list_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    period_start DATE,
    period_end DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (period_end IS NULL OR period_start IS NOT NULL),
    CHECK (period_end IS NULL OR period_end >= period_start)
);

CREATE INDEX idx_shopping_lists_user ON shopping_lists (user_id, updated_at DESC);
CREATE INDEX idx_shopping_list_items_list ON shopping_list_items (shopping_list_id);
CREATE INDEX idx_budgets_user_period ON budgets (user_id, period_start, period_end);

COMMIT;
