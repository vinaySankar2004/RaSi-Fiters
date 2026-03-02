-- Add member_push_tokens table for iOS push notification device registration.
-- Run this on existing databases that were created before this table was added to db-schema.sql.

CREATE TABLE IF NOT EXISTS member_push_tokens (
    id           UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id     UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    device_token  VARCHAR(512) NOT NULL UNIQUE,
    platform      VARCHAR(16) NOT NULL DEFAULT 'ios',
    device_id     VARCHAR(256),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_member_push_tokens_member_id ON member_push_tokens(member_id);
CREATE INDEX IF NOT EXISTS idx_member_push_tokens_platform ON member_push_tokens(platform);
