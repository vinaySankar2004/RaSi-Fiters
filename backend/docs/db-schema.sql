-- ============================================================
-- SECTION 0: Prereqs (UUID defaults for new tables)
-- ============================================================
BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- SECTION 1: Rename existing tables to legacy_*
-- ============================================================
ALTER TABLE daily_health_logs RENAME TO legacy_daily_health_logs;
ALTER TABLE members RENAME TO legacy_members;
ALTER TABLE program_memberships RENAME TO legacy_program_memberships;
ALTER TABLE programs RENAME TO legacy_programs;
ALTER TABLE refresh_tokens RENAME TO legacy_refresh_tokens;
ALTER TABLE workout_logs RENAME TO legacy_workout_logs;
ALTER TABLE workouts RENAME TO legacy_workouts;

-- ============================================================
-- SECTION 1B: Rename legacy constraints/indexes that would collide
-- ============================================================

-- legacy_daily_health_logs
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_pkey TO legacy_daily_health_logs_pkey;
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_sleep_hours_check TO legacy_daily_health_logs_sleep_hours_check;
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_diet_quality_check TO legacy_daily_health_logs_diet_quality_check;
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_program_membership_fkey TO legacy_daily_health_logs_program_membership_fkey;
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_at_least_one_check TO legacy_daily_health_logs_at_least_one_check;
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_program_id_fkey TO legacy_daily_health_logs_program_id_fkey;
ALTER TABLE legacy_daily_health_logs RENAME CONSTRAINT daily_health_logs_member_id_fkey TO legacy_daily_health_logs_member_id_fkey;

ALTER INDEX idx_daily_health_logs_program_id RENAME TO legacy_idx_daily_health_logs_program_id;
ALTER INDEX idx_daily_health_logs_member_id RENAME TO legacy_idx_daily_health_logs_member_id;
ALTER INDEX idx_daily_health_logs_log_date RENAME TO legacy_idx_daily_health_logs_log_date;

-- legacy_members
ALTER TABLE legacy_members RENAME CONSTRAINT members_global_role_check TO legacy_members_global_role_check;

-- legacy_program_memberships
ALTER TABLE legacy_program_memberships RENAME CONSTRAINT program_memberships_pkey TO legacy_program_memberships_pkey;
ALTER TABLE legacy_program_memberships RENAME CONSTRAINT program_memberships_role_check TO legacy_program_memberships_role_check;
ALTER TABLE legacy_program_memberships RENAME CONSTRAINT program_memberships_program_id_fkey TO legacy_program_memberships_program_id_fkey;
ALTER TABLE legacy_program_memberships RENAME CONSTRAINT program_memberships_member_id_fkey TO legacy_program_memberships_member_id_fkey;

ALTER INDEX idx_program_memberships_program_id RENAME TO legacy_idx_program_memberships_program_id;
ALTER INDEX idx_program_memberships_member_id RENAME TO legacy_idx_program_memberships_member_id;

-- legacy_programs
ALTER TABLE legacy_programs RENAME CONSTRAINT programs_pkey TO legacy_programs_pkey;
ALTER TABLE legacy_programs RENAME CONSTRAINT programs_status_check TO legacy_programs_status_check;

-- legacy_refresh_tokens
ALTER TABLE legacy_refresh_tokens RENAME CONSTRAINT refresh_tokens_pkey TO legacy_refresh_tokens_pkey;
ALTER TABLE legacy_refresh_tokens RENAME CONSTRAINT refresh_tokens_member_id_fkey TO legacy_refresh_tokens_member_id_fkey;
ALTER TABLE legacy_refresh_tokens RENAME CONSTRAINT refresh_tokens_token_hash_key TO legacy_refresh_tokens_token_hash_key;

ALTER INDEX idx_refresh_tokens_member_id RENAME TO legacy_idx_refresh_tokens_member_id;
ALTER INDEX idx_refresh_tokens_token_hash RENAME TO legacy_idx_refresh_tokens_token_hash;

-- legacy_workout_logs
ALTER TABLE legacy_workout_logs RENAME CONSTRAINT workout_logs_pkey TO legacy_workout_logs_pkey;
ALTER INDEX idx_workout_logs_member_id RENAME TO legacy_idx_workout_logs_member_id;
ALTER INDEX idx_workout_logs_workout_name RENAME TO legacy_idx_workout_logs_workout_name;

-- ============================================================
-- SECTION 2: New members + auth tables
-- ============================================================
CREATE TABLE members (
    id          UUID NOT NULL PRIMARY KEY,
    username    VARCHAR(255) NOT NULL UNIQUE,
    first_name  VARCHAR(255) NOT NULL,
    last_name   VARCHAR(255) NOT NULL,
    gender      VARCHAR(10),
    global_role TEXT NOT NULL DEFAULT 'standard'
        CHECK (global_role IN ('standard', 'global_admin')),
    status      TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'disabled')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE member_credentials (
    member_id     UUID NOT NULL PRIMARY KEY
        REFERENCES members(id) ON DELETE CASCADE,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE member_emails (
    id          UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id   UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    email       TEXT NOT NULL UNIQUE,
    is_primary  BOOLEAN NOT NULL DEFAULT true,
    verified_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_member_emails_member_id ON member_emails(member_id);

CREATE TABLE email_verification_tokens (
    id              UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    member_email_id UUID NOT NULL
        REFERENCES member_emails(id) ON DELETE CASCADE,
    token_hash      TEXT NOT NULL UNIQUE,
    expires_at      TIMESTAMPTZ NOT NULL,
    used_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth_identities (
    id               UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id        UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    provider         TEXT NOT NULL
        CHECK (provider IN ('apple')),
    provider_user_id TEXT NOT NULL UNIQUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- SECTION 3: Programs + memberships + invites
-- ============================================================
CREATE TABLE programs (
    id          UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    start_date  DATE,
    end_date    DATE,
    status      TEXT NOT NULL DEFAULT 'planned'
        CHECK (status IN ('planned', 'active', 'completed')),
    description TEXT,
    created_by  UUID NOT NULL
        REFERENCES members(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted  BOOLEAN NOT NULL DEFAULT false
);

-- program_memberships (v1) with roles: admin, logger, member

CREATE TABLE IF NOT EXISTS program_memberships
(
    program_id uuid NOT NULL,
    member_id  uuid NOT NULL,
    role       text NOT NULL DEFAULT 'member',
    status     text NOT NULL DEFAULT 'active',
    joined_at  timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at    timestamptz,

    CONSTRAINT program_memberships_pkey PRIMARY KEY (program_id, member_id),

    CONSTRAINT program_memberships_program_id_fkey
        FOREIGN KEY (program_id) REFERENCES programs(id) ON DELETE CASCADE,

    CONSTRAINT program_memberships_member_id_fkey
        FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,

    CONSTRAINT program_memberships_role_check
        CHECK (role IN ('admin', 'logger', 'member')),

    CONSTRAINT program_memberships_status_check
        CHECK (status IN ('active', 'invited', 'requested', 'removed'))
);

-- Ensure owner
ALTER TABLE program_memberships OWNER TO rasi_fiters_db_user;

-- Ensure indexes (idempotent)
CREATE INDEX IF NOT EXISTS idx_program_memberships_program_id
    ON program_memberships (program_id);

CREATE INDEX IF NOT EXISTS idx_program_memberships_member_id
    ON program_memberships (member_id);

CREATE TABLE program_invites (
    id               UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id       UUID NOT NULL
        REFERENCES programs(id) ON DELETE CASCADE,
    invited_by       UUID NOT NULL
        REFERENCES members(id),
    invited_username TEXT,
    invited_email    TEXT,
    token_hash       TEXT NOT NULL UNIQUE,
    status           TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'revoked')),
    max_uses         INTEGER NOT NULL DEFAULT 1,
    uses_count       INTEGER NOT NULL DEFAULT 0,
    expires_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Allow multiple historical invites, but only one pending invite per program/user
CREATE UNIQUE INDEX uniq_program_invites_program_username_pending
    ON program_invites(program_id, invited_username)
    WHERE invited_username IS NOT NULL AND status = 'pending';

CREATE INDEX idx_program_invites_program_id ON program_invites(program_id);
CREATE INDEX idx_program_invites_invited_by ON program_invites(invited_by);

-- Table to track when members block invites from specific programs
CREATE TABLE program_invite_blocks (
    id          UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id  UUID NOT NULL
        REFERENCES programs(id) ON DELETE CASCADE,
    member_id   UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (program_id, member_id)
);

CREATE INDEX idx_program_invite_blocks_program_id ON program_invite_blocks(program_id);
CREATE INDEX idx_program_invite_blocks_member_id ON program_invite_blocks(member_id);

-- ============================================================
-- SECTION 3B: Notifications
-- ============================================================

CREATE TABLE notifications (
    id               UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    type             TEXT NOT NULL,
    program_id       UUID
        REFERENCES programs(id) ON DELETE SET NULL,
    actor_member_id  UUID
        REFERENCES members(id) ON DELETE SET NULL,
    title            TEXT NOT NULL,
    body             TEXT NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_program_id ON notifications(program_id);
CREATE INDEX idx_notifications_actor_member_id ON notifications(actor_member_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

CREATE TABLE notification_recipients (
    notification_id  UUID NOT NULL
        REFERENCES notifications(id) ON DELETE CASCADE,
    member_id        UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    acknowledged_at  TIMESTAMPTZ,
    PRIMARY KEY (notification_id, member_id)
);

CREATE INDEX idx_notification_recipients_member_id ON notification_recipients(member_id);
CREATE INDEX idx_notification_recipients_ack ON notification_recipients(member_id, acknowledged_at);

-- ============================================================
-- SECTION 4: Workouts library + program workouts + logs
-- ============================================================
CREATE TABLE workouts_library (
    id         UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE program_workouts (
    id                 UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id         UUID NOT NULL
        REFERENCES programs(id) ON DELETE CASCADE,
    library_workout_id UUID
        REFERENCES workouts_library(id),
    workout_name       TEXT NOT NULL,
    is_hidden          BOOLEAN NOT NULL DEFAULT false,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (program_id, workout_name)
);

CREATE INDEX idx_program_workouts_program_id ON program_workouts(program_id);
CREATE INDEX idx_program_workouts_library_workout_id ON program_workouts(library_workout_id);

CREATE TABLE workout_logs (
    program_id         UUID NOT NULL,
    member_id          UUID NOT NULL,
    program_workout_id UUID NOT NULL
        REFERENCES program_workouts(id),
    log_date           DATE NOT NULL,
    duration           INTEGER,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (program_id, member_id, program_workout_id, log_date),
    FOREIGN KEY (program_id, member_id)
        REFERENCES program_memberships(program_id, member_id) ON DELETE CASCADE
);

CREATE INDEX idx_workout_logs_program_id ON workout_logs(program_id);
CREATE INDEX idx_workout_logs_member_id ON workout_logs(member_id);
CREATE INDEX idx_workout_logs_program_workout_id ON workout_logs(program_workout_id);
CREATE INDEX idx_workout_logs_log_date ON workout_logs(log_date);

-- ============================================================
-- SECTION 5: Daily health logs + refresh tokens
-- ============================================================
CREATE TABLE daily_health_logs (
    program_id   UUID NOT NULL
        REFERENCES programs(id) ON DELETE CASCADE,
    member_id    UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    log_date     DATE NOT NULL,
    sleep_hours  NUMERIC(4, 2)
        CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
    diet_quality SMALLINT
        CHECK (diet_quality >= 0 AND diet_quality <= 5),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (program_id, member_id, log_date),
    CONSTRAINT daily_health_logs_program_membership_fkey
        FOREIGN KEY (program_id, member_id)
        REFERENCES program_memberships(program_id, member_id) ON DELETE CASCADE,
    CONSTRAINT daily_health_logs_at_least_one_check
        CHECK (sleep_hours IS NOT NULL OR diet_quality IS NOT NULL)
);

CREATE INDEX idx_daily_health_logs_program_id ON daily_health_logs(program_id);
CREATE INDEX idx_daily_health_logs_member_id ON daily_health_logs(member_id);
CREATE INDEX idx_daily_health_logs_log_date ON daily_health_logs(log_date);

CREATE TABLE refresh_tokens (
    id               UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id        UUID NOT NULL
        REFERENCES members(id) ON DELETE CASCADE,
    token_hash       TEXT NOT NULL UNIQUE,
    client_type      TEXT NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at       TIMESTAMPTZ,
    revoked_at       TIMESTAMPTZ,
    replaced_by_hash TEXT
);

CREATE INDEX idx_refresh_tokens_member_id ON refresh_tokens(member_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

COMMIT;
