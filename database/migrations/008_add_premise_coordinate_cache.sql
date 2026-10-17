BEGIN;

ALTER TABLE premises
    ADD COLUMN coordinate_source TEXT,
    ADD COLUMN coordinate_cached_at TIMESTAMPTZ,
    ADD COLUMN coordinate_match_confidence TEXT,
    ADD COLUMN coordinate_partial_match BOOLEAN,
    ADD COLUMN coordinate_location_type TEXT,
    ADD COLUMN coordinate_last_attempted_at TIMESTAMPTZ,
    ADD COLUMN coordinate_resolution_status TEXT,
    ADD COLUMN google_place_id TEXT;

ALTER TABLE premises
    ADD CONSTRAINT premises_coordinate_source_check
        CHECK (coordinate_source IS NULL OR coordinate_source IN ('google_geocoding')),
    ADD CONSTRAINT premises_coordinate_confidence_check
        CHECK (
            coordinate_match_confidence IS NULL
            OR coordinate_match_confidence IN ('high', 'possible')
        ),
    ADD CONSTRAINT premises_coordinate_resolution_status_check
        CHECK (
            coordinate_resolution_status IS NULL
            OR coordinate_resolution_status IN ('cached', 'no_results', 'ambiguous')
        ),
    ADD CONSTRAINT premises_coordinate_cache_metadata_check
        CHECK (
            coordinate_source IS NULL
            OR (
                latitude IS NOT NULL
                AND longitude IS NOT NULL
                AND coordinate_cached_at IS NOT NULL
            )
        );

CREATE INDEX idx_premises_fresh_coordinate_cache
    ON premises (coordinate_cached_at, premise_code)
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

COMMIT;
