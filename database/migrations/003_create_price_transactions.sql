BEGIN;

CREATE TABLE price_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    record_date DATE NOT NULL,
    premise_code INTEGER NOT NULL REFERENCES premises(premise_code) ON DELETE RESTRICT,
    item_code INTEGER NOT NULL REFERENCES items(item_code) ON DELETE RESTRICT,
    price NUMERIC(10,2) NOT NULL CHECK (price > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (record_date, premise_code, item_code)
);

CREATE INDEX idx_price_transactions_item_date
    ON price_transactions (item_code, record_date DESC);

CREATE INDEX idx_price_transactions_item_premise
    ON price_transactions (item_code, premise_code, record_date DESC, price);

COMMIT;
