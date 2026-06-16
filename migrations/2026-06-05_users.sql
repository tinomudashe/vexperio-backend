-- Shared people list for the add-in (editors / reviewers / assignees).
-- The API also auto-creates this table via SQLAlchemy create_all on startup;
-- this script is the explicit form for running by hand against prod.

CREATE TABLE IF NOT EXISTS app_user (
    user_id     SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_app_user_active ON app_user (active);
