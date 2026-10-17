BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE items (
    item_code INTEGER PRIMARY KEY,
    item TEXT NOT NULL,
    unit TEXT NOT NULL,
    item_group TEXT NOT NULL,
    item_category TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (length(trim(item)) > 0),
    CHECK (length(trim(unit)) > 0),
    CHECK (length(trim(item_group)) > 0),
    CHECK (length(trim(item_category)) > 0)
);

CREATE TABLE premises (
    premise_code INTEGER PRIMARY KEY,
    premise TEXT NOT NULL,
    address TEXT NOT NULL,
    premise_type TEXT NOT NULL,
    state TEXT NOT NULL,
    district TEXT NOT NULL,
    latitude NUMERIC(10,7),
    longitude NUMERIC(10,7),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (length(trim(premise)) > 0),
    CHECK (length(trim(address)) > 0),
    CHECK (length(trim(premise_type)) > 0),
    CHECK (length(trim(state)) > 0),
    CHECK (length(trim(district)) > 0),
    CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX idx_items_item_trgm ON items USING GIN (item gin_trgm_ops);
CREATE INDEX idx_items_category ON items (item_category);
CREATE INDEX idx_premises_state_district ON premises (state, district);

COMMIT;
