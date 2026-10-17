BEGIN;

-- Single-use password reset codes. Only a server-side HMAC of the code is
-- stored; the raw code is never persisted. Each user has at most one active
-- (unused, unexpired) code because creating a new one invalidates the old.
CREATE TABLE password_resets (
    password_reset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    code_hash TEXT NOT NULL CHECK (length(code_hash) > 0),
    expires_at TIMESTAMPTZ NOT NULL,
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_password_resets_user ON password_resets (user_id);
CREATE INDEX idx_password_resets_expiry ON password_resets (expires_at);
CREATE INDEX idx_password_resets_user_unused
    ON password_resets (user_id)
    WHERE used_at IS NULL;

COMMIT;
