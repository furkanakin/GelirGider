-- Phase 2 — recurring templates, notifications, missing indices.
SET search_path TO evimiz, public;

-- Recurring templates: monthly bills, subscriptions, salary etc.
DO $$ BEGIN
    CREATE TYPE recurring_cadence AS ENUM ('daily', 'weekly', 'monthly', 'yearly');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS recurring_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id),
    actor_user_id   UUID REFERENCES users(id),
    category_id     UUID REFERENCES categories(id) ON DELETE SET NULL,
    account_id      UUID REFERENCES accounts(id) ON DELETE SET NULL,
    label           TEXT NOT NULL,
    kind            tx_kind NOT NULL,
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency        TEXT NOT NULL DEFAULT 'TRY',
    cadence         recurring_cadence NOT NULL,
    day_of_period   INTEGER,                  -- e.g. 1 (1st of month) for monthly
    starts_on       DATE NOT NULL DEFAULT CURRENT_DATE,
    ends_on         DATE,
    last_run_on     DATE,
    is_paused       BOOLEAN NOT NULL DEFAULT FALSE,
    note            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rec_household ON recurring_templates(household_id) WHERE NOT is_paused;

DO $$ BEGIN
    CREATE TRIGGER trg_touch_recurring BEFORE UPDATE ON recurring_templates
        FOR EACH ROW EXECUTE FUNCTION evimiz.touch_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Notifications (in-app feed)
DO $$ BEGIN
    CREATE TYPE notification_kind AS ENUM ('budget_warning', 'recurring_due', 'invite_accepted', 'tip', 'generic');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
    kind            notification_kind NOT NULL DEFAULT 'generic',
    title           TEXT NOT NULL,
    body            TEXT,
    payload         JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id, created_at DESC) WHERE NOT is_read;

-- Search index on transactions
CREATE INDEX IF NOT EXISTS idx_tx_search ON transactions USING gin (
    to_tsvector('simple', coalesce(merchant,'') || ' ' || coalesce(note,''))
);

-- Materialize one occurrence of a recurring template into a transaction.
CREATE OR REPLACE FUNCTION evimiz.materialize_recurring(p_template UUID, p_when TIMESTAMPTZ DEFAULT now())
RETURNS UUID AS $$
DECLARE
    t recurring_templates%ROWTYPE;
    v_tx_id UUID;
BEGIN
    SELECT * INTO t FROM recurring_templates WHERE id = p_template AND NOT is_paused;
    IF NOT FOUND THEN RETURN NULL; END IF;

    INSERT INTO transactions (
        household_id, user_id, actor_user_id, account_id, category_id,
        kind, amount, currency, merchant, note, occurred_at, source, status, metadata
    ) VALUES (
        t.household_id, t.user_id, COALESCE(t.actor_user_id, t.user_id), t.account_id, t.category_id,
        t.kind, t.amount, t.currency, t.label, t.note, p_when, 'recurring', 'confirmed',
        jsonb_build_object('recurring_id', t.id)
    ) RETURNING id INTO v_tx_id;

    UPDATE recurring_templates SET last_run_on = (p_when AT TIME ZONE 'Europe/Istanbul')::date WHERE id = t.id;
    RETURN v_tx_id;
END;
$$ LANGUAGE plpgsql;
