BEGIN;

CREATE TABLE favorite_items (
    favorite_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    item_code INTEGER NOT NULL REFERENCES items(item_code) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, item_code)
);

CREATE TABLE favorite_premises (
    favorite_premise_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    premise_code INTEGER NOT NULL REFERENCES premises(premise_code) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, premise_code)
);

CREATE TABLE search_history (
    search_history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    query TEXT NOT NULL CHECK (length(trim(query)) > 0),
    searched_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_favorite_items_user ON favorite_items (user_id);
CREATE INDEX idx_favorite_premises_user ON favorite_premises (user_id);
CREATE INDEX idx_search_history_user_date ON search_history (user_id, searched_at DESC);

COMMIT;
