-- migration: 0001_init.sql
-- ─────────────────────────────────────────────────────────────────────────
-- Creates the core schema for the Billing Intelligence app.
--
-- Key design decisions (from TECH-REQUIREMENTS.md):
--
--   • property is first-class — Wes persona manages multiple addresses.
--   • extraction_fields stores field-level provenance: confidence score +
--     bounding_box JSONB so the frontend can highlight the source region.
--   • bill_type uses a text check rather than an enum so values can be
--     added without a migration.
--   • All timestamps are timestamptz (UTC) — app converts on display.
--   • user_id FK references auth.users (Supabase auth table).
--   • RLS is added in 0002_rls.sql; tables are created without it here
--     so the migration order is clear.
-- ─────────────────────────────────────────────────────────────────────────

-- Enable pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── properties ───────────────────────────────────────────────────────────
-- A user may have multiple properties (home, rental, vacation).
-- Every account and bill ultimately belongs to a property.

CREATE TABLE public.properties (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,                 -- "Main home", "221B Baker St"
  address    TEXT,                          -- optional free text
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX properties_user_id_idx ON public.properties(user_id);

-- ── accounts ─────────────────────────────────────────────────────────────
-- One account per utility provider per property.
-- e.g. "Ohio Edison – Main home"

CREATE TABLE public.accounts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  property_id  UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  provider     TEXT NOT NULL,               -- "Ohio Edison", "Columbia Gas"
  account_number TEXT,                      -- masked: "****-4892"
  service_type TEXT NOT NULL                -- "electric" | "gas" | "water" | "sewer" | "trash" | "internet"
                CHECK (service_type IN (
                  'electric','gas','water','sewer','trash','internet','other'
                )),
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX accounts_user_id_idx     ON public.accounts(user_id);
CREATE INDEX accounts_property_id_idx ON public.accounts(property_id);

-- ── bills ─────────────────────────────────────────────────────────────────
-- One row per statement / invoice.
-- extraction_status tracks the AI pipeline lifecycle.

CREATE TABLE public.bills (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id        UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  period_start      DATE,
  period_end        DATE,
  amount_due        NUMERIC(10, 2),
  amount_paid       NUMERIC(10, 2),
  due_date          DATE,
  paid_date         DATE,
  bill_type         TEXT NOT NULL DEFAULT 'utility'
                    CHECK (bill_type IN ('utility','telecom','subscription','other')),
  raw_image_path    TEXT,                   -- Supabase Storage path
  raw_text          TEXT,                   -- OCR output (full text)
  extraction_status TEXT NOT NULL DEFAULT 'pending'
                    CHECK (extraction_status IN (
                      'pending','processing','done','failed','needs_review'
                    )),
  narration_sentence TEXT,            -- the one sentence, stored after /narrate
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX bills_user_id_idx    ON public.bills(user_id);
CREATE INDEX bills_account_id_idx ON public.bills(account_id);
CREATE INDEX bills_due_date_idx   ON public.bills(due_date);

-- ── extraction_fields ─────────────────────────────────────────────────────
-- One row per extracted field per bill.
-- Stores provenance: confidence + bounding_box so the UI can highlight
-- the source region on the original bill image.
--
-- field_name examples: "amount_due", "due_date", "kwh_used",
--                       "rate_per_kwh", "distribution_charge"

CREATE TABLE public.extraction_fields (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id      UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  field_name   TEXT NOT NULL,
  raw_value    TEXT NOT NULL,               -- as it appears on the bill
  parsed_value NUMERIC,                     -- null for non-numeric fields
  confidence   NUMERIC(4, 3) NOT NULL       -- 0.000–1.000
               CHECK (confidence BETWEEN 0 AND 1),
  bounding_box JSONB,                       -- {x, y, w, h} in image pixels
  source_page  INT NOT NULL DEFAULT 0,      -- 0-indexed page number
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX extraction_fields_bill_id_idx ON public.extraction_fields(bill_id);

-- ── line_items ────────────────────────────────────────────────────────────
-- Individual charges on a bill (rate charges, taxes, riders, credits, etc.)

CREATE TABLE public.line_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id      UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  user_id      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  description  TEXT NOT NULL,
  amount       NUMERIC(10, 2) NOT NULL,
  item_type    TEXT NOT NULL DEFAULT 'charge'
               CHECK (item_type IN ('charge','credit','tax','fee','other')),
  sort_order   INT NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX line_items_bill_id_idx ON public.line_items(bill_id);

-- ── bill_classifications ──────────────────────────────────────────────────
-- AI-assigned classification tags per bill.
-- Supports multi-label (one row per tag).
-- confidence: 0–1; user_verified: true after user confirms/corrects.

CREATE TABLE public.bill_classifications (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id        UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  tag            TEXT NOT NULL,             -- "rate_increase", "usage_spike", "new_charge"
  confidence     NUMERIC(4, 3) NOT NULL CHECK (confidence BETWEEN 0 AND 1),
  user_verified  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX bill_classifications_bill_id_idx ON public.bill_classifications(bill_id);

-- ── anomalies ─────────────────────────────────────────────────────────────
-- Detected anomalies for a bill. Surfaced in the detail view with wording.
-- D2: the frontend reads anomaly_type to form a sentence — never colour code.

CREATE TABLE public.anomalies (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bill_id             UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  anomaly_type        TEXT NOT NULL,        -- "usage_spike", "rate_increase", "charge_added"
  description         TEXT NOT NULL,        -- plain English, ready to display
  severity            TEXT NOT NULL DEFAULT 'info'
                      CHECK (severity IN ('info','warn','action_required')),
  user_dismissed      BOOLEAN NOT NULL DEFAULT FALSE,
  user_confirmed_wrong BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX anomalies_bill_id_idx ON public.anomalies(bill_id);
CREATE INDEX anomalies_user_id_idx ON public.anomalies(user_id);

-- ── updated_at trigger ────────────────────────────────────────────────────
-- Keeps updated_at columns current on every UPDATE.

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER bills_updated_at
  BEFORE UPDATE ON public.bills
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER properties_updated_at
  BEFORE UPDATE ON public.properties
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
