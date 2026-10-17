BEGIN;

ALTER TABLE users
    ADD COLUMN avatar_type TEXT NOT NULL DEFAULT 'initial',
    ADD COLUMN avatar_value TEXT;

ALTER TABLE users
    ADD CONSTRAINT users_avatar_type_check
        CHECK (avatar_type IN ('initial', 'preset', 'upload')),
    ADD CONSTRAINT users_avatar_value_check
        CHECK (
            (avatar_type = 'initial' AND avatar_value IS NULL)
            OR (avatar_type IN ('preset', 'upload')
                AND length(trim(avatar_value)) > 0)
        );

COMMIT;
