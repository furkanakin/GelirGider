-- Evimiz / GelirGider — initial schema
-- PostgreSQL 17

-- Required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text for emails

-- Schema
CREATE SCHEMA IF NOT EXISTS evimiz;
SET search_path TO evimiz, public;

-- ========================================================================
-- USERS & AUTH
-- ========================================================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    display_name    TEXT NOT NULL,
    avatar_color    TEXT,                    -- e.g. '#E8B5A0'
    locale          TEXT NOT NULL DEFAULT 'tr-TR',
    timezone        TEXT NOT NULL DEFAULT 'Europe/Istanbul',
    preferred_llm   TEXT NOT NULL DEFAULT 'qwen3-coder-next',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_login_at   TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      TEXT NOT NULL UNIQUE,
    user_agent      TEXT,
    ip_address      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_expiry ON refresh_tokens(expires_at) WHERE revoked_at IS NULL;

-- ========================================================================
-- HOUSEHOLDS (Aile)
-- ========================================================================
CREATE TABLE IF NOT EXISTS households (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    currency        TEXT NOT NULL DEFAULT 'TRY',
    monthly_budget  NUMERIC(14,2),
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TYPE household_role AS ENUM ('owner', 'admin', 'member', 'child');

CREATE TABLE IF NOT EXISTS household_members (
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role            household_role NOT NULL DEFAULT 'member',
    nickname        TEXT,                    -- display name in this household: "Anne", "Baba"
    avatar_color    TEXT,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (household_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_member_user ON household_members(user_id);

CREATE TABLE IF NOT EXISTS household_invites (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    code            TEXT NOT NULL UNIQUE,
    role            household_role NOT NULL DEFAULT 'member',
    invited_email   CITEXT,
    invited_by      UUID NOT NULL REFERENCES users(id),
    expires_at      TIMESTAMPTZ NOT NULL,
    accepted_by     UUID REFERENCES users(id),
    accepted_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_invite_code ON household_invites(code);

-- ========================================================================
-- ACCOUNTS (cüzdan/kart/banka)
-- ========================================================================
CREATE TYPE account_type AS ENUM ('cash', 'bank', 'credit_card', 'savings');

CREATE TABLE IF NOT EXISTS accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    type            account_type NOT NULL DEFAULT 'cash',
    currency        TEXT NOT NULL DEFAULT 'TRY',
    starting_balance NUMERIC(14,2) NOT NULL DEFAULT 0,
    is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_account_household ON accounts(household_id) WHERE NOT is_archived;

-- ========================================================================
-- CATEGORIES
-- ========================================================================
CREATE TYPE tx_kind AS ENUM ('expense', 'income');

CREATE TABLE IF NOT EXISTS categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    slug            TEXT NOT NULL,           -- 'market', 'fatura', etc.
    label           TEXT NOT NULL,
    kind            tx_kind NOT NULL,
    icon            TEXT NOT NULL,           -- icon name from design (e.g. 'cart')
    color           TEXT NOT NULL,           -- hex
    tint            TEXT NOT NULL,           -- hex for chip background
    monthly_budget  NUMERIC(14,2),
    sort_order      INTEGER NOT NULL DEFAULT 0,
    is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (household_id, slug)
);
CREATE INDEX IF NOT EXISTS idx_cat_household ON categories(household_id) WHERE NOT is_archived;

-- ========================================================================
-- TRANSACTIONS
-- ========================================================================
CREATE TYPE tx_source AS ENUM ('text', 'voice', 'photo', 'manual', 'auto', 'recurring');
CREATE TYPE tx_status AS ENUM ('pending_review', 'confirmed', 'archived');

CREATE TABLE IF NOT EXISTS transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),               -- who recorded
    actor_user_id   UUID REFERENCES users(id),                        -- "kim harcadı" — may differ
    account_id      UUID REFERENCES accounts(id) ON DELETE SET NULL,
    category_id     UUID REFERENCES categories(id) ON DELETE SET NULL,
    kind            tx_kind NOT NULL,
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency        TEXT NOT NULL DEFAULT 'TRY',
    merchant        TEXT,
    note            TEXT,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    source          tx_source NOT NULL DEFAULT 'manual',
    status          tx_status NOT NULL DEFAULT 'confirmed',
    ai_job_id       UUID,                                             -- back-link, FK added below
    ai_confidence   NUMERIC(4,3),                                     -- 0.000–1.000
    metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_tx_household_time ON transactions(household_id, occurred_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_actor ON transactions(actor_user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_category ON transactions(category_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_status ON transactions(household_id, status) WHERE deleted_at IS NULL;

-- ========================================================================
-- ATTACHMENTS (receipts, photos)
-- ========================================================================
CREATE TYPE attachment_kind AS ENUM ('receipt', 'invoice', 'photo', 'audio');

CREATE TABLE IF NOT EXISTS attachments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    transaction_id  UUID REFERENCES transactions(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    kind            attachment_kind NOT NULL,
    storage_key     TEXT NOT NULL,           -- path in object storage / disk
    mime_type       TEXT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    sha256          TEXT,
    ocr_text        TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_att_tx ON attachments(transaction_id);

-- ========================================================================
-- AI JOBS (text/voice/photo extraction)
-- ========================================================================
CREATE TYPE ai_job_kind AS ENUM ('classify_text', 'transcribe_voice', 'extract_receipt', 'summarize_period');
CREATE TYPE ai_job_status AS ENUM ('pending', 'running', 'succeeded', 'failed');

CREATE TABLE IF NOT EXISTS ai_jobs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    kind            ai_job_kind NOT NULL,
    status          ai_job_status NOT NULL DEFAULT 'pending',
    model           TEXT NOT NULL,            -- e.g. 'qwen3-coder-next'
    input_text      TEXT,
    input_attachment_id UUID REFERENCES attachments(id) ON DELETE SET NULL,
    output          JSONB,                    -- { "lines": [{ "merchant": "...", "amount": 847.50, ... }] }
    error           TEXT,
    latency_ms      INTEGER,
    cost_usd        NUMERIC(10,6),
    tokens_in       INTEGER,
    tokens_out      INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_aijob_household ON ai_jobs(household_id, created_at DESC);

ALTER TABLE transactions
    ADD CONSTRAINT fk_tx_aijob FOREIGN KEY (ai_job_id) REFERENCES ai_jobs(id) ON DELETE SET NULL;

-- ========================================================================
-- RECURRING TEMPLATES (sık kullanılan)
-- ========================================================================
CREATE TABLE IF NOT EXISTS quick_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    label           TEXT NOT NULL,
    category_id     UUID REFERENCES categories(id),
    typical_amount  NUMERIC(14,2),
    use_count       INTEGER NOT NULL DEFAULT 0,
    last_used_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_quick_household ON quick_entries(household_id, use_count DESC);

-- ========================================================================
-- AUDIT updated_at trigger
-- ========================================================================
CREATE OR REPLACE FUNCTION evimiz.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY['users','households','accounts','transactions']) LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_touch_%I ON evimiz.%I; CREATE TRIGGER trg_touch_%I BEFORE UPDATE ON evimiz.%I FOR EACH ROW EXECUTE FUNCTION evimiz.touch_updated_at();',
            t, t, t, t
        );
    END LOOP;
END $$;

-- ========================================================================
-- REPORTING VIEW: monthly aggregates
-- ========================================================================
CREATE OR REPLACE VIEW v_monthly_summary AS
SELECT
    t.household_id,
    date_trunc('month', t.occurred_at AT TIME ZONE 'Europe/Istanbul') AS month,
    t.kind,
    t.category_id,
    COUNT(*) AS tx_count,
    SUM(t.amount) AS total_amount
FROM transactions t
WHERE t.deleted_at IS NULL AND t.status = 'confirmed'
GROUP BY 1,2,3,4;

-- ========================================================================
-- SEED — default categories template (per household, on creation)
-- ========================================================================
-- Function to seed a household with default categories matching the design palette.
CREATE OR REPLACE FUNCTION evimiz.seed_default_categories(p_household_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO categories (household_id, slug, label, kind, icon, color, tint, sort_order) VALUES
        (p_household_id, 'market',   'Market',     'expense', 'cart',        '#C4593C', '#F6E4D8', 1),
        (p_household_id, 'fatura',   'Faturalar',  'expense', 'bolt',        '#3D5A4A', '#DCE7DF', 2),
        (p_household_id, 'ulasim',   'Ulaşım',     'expense', 'fuel',        '#7A6F65', '#EFE8DA', 3),
        (p_household_id, 'yemek',    'Yemek',      'expense', 'cup',         '#A4452C', '#F0D9CC', 4),
        (p_household_id, 'cocuk',    'Çocuklar',   'expense', 'baby',        '#C9933A', '#F6E9C0', 5),
        (p_household_id, 'saglik',   'Sağlık',     'expense', 'leaf',        '#3D5A4A', '#DCE7DF', 6),
        (p_household_id, 'eglence',  'Eğlence',    'expense', 'gift',        '#8B5A8B', '#EBDBEB', 7),
        (p_household_id, 'kira',     'Kira',       'expense', 'house-heart', '#1A1A1A', '#E8E0D0', 8),
        (p_household_id, 'maas',     'Maaş',       'income',  'wallet',      '#3D5A4A', '#DCE7DF', 1),
        (p_household_id, 'ek',       'Ek Gelir',   'income',  'spark2',      '#C9933A', '#F6E9C0', 2)
    ON CONFLICT (household_id, slug) DO NOTHING;
END;
$$ LANGUAGE plpgsql;
