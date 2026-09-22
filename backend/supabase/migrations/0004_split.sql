-- migration: 0004_split.sql
-- ─────────────────────────────────────────────────────────────────────────
-- SplitWise-style group expense-splitting schema.
-- Additive: does not drop or alter tables from 0001–0003.
-- 
-- Tables:
--   profiles          — public user info (username, display name)
--   groups            — named expense groups
--   group_members     — who is in each group
--   friends           — bidirectional friendship pairs (two rows per link)
--   expenses          — an individual expense in a group
--   expense_members   — who shares each expense (equal split)
--   settlements       — recorded cash payments between two people
-- ─────────────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── profiles ─────────────────────────────────────────────────────────────
-- One row per auth.users. Created by trigger handle_new_split_user.
-- Searchable by username (unique, lowercase).

CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username   TEXT NOT NULL UNIQUE,          -- @handle, always lowercase
  name       TEXT NOT NULL,                 -- display name
  email      TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── groups ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.groups (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_name  TEXT NOT NULL,
  creator_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── group_members ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.group_members (
  group_id   UUID NOT NULL REFERENCES public.groups(id)   ON DELETE CASCADE,
  member_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, member_id)
);

-- ── friends ───────────────────────────────────────────────────────────────
-- Bidirectional: two rows per link (A→B and B→A).
-- Duplicates prevented by the primary key.
CREATE TABLE IF NOT EXISTS public.friends (
  owner_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (owner_id, friend_id),
  CHECK (owner_id <> friend_id)
);

-- ── expenses ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.expenses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount      NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  paid_by     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── expense_members ───────────────────────────────────────────────────────
-- Who shares each expense (equal split among all rows for that expense).
CREATE TABLE IF NOT EXISTS public.expense_members (
  expense_id  UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
  member_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (expense_id, member_id)
);

-- ── settlements ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.settlements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  payer_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount      NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (payer_id <> receiver_id)
);

-- ── Indexes ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_group_members_member   ON public.group_members(member_id);
CREATE INDEX IF NOT EXISTS idx_expenses_group         ON public.expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by       ON public.expenses(paid_by);
CREATE INDEX IF NOT EXISTS idx_expense_members_member ON public.expense_members(member_id);
CREATE INDEX IF NOT EXISTS idx_settlements_payer      ON public.settlements(payer_id);
CREATE INDEX IF NOT EXISTS idx_settlements_receiver   ON public.settlements(receiver_id);
CREATE INDEX IF NOT EXISTS idx_friends_owner          ON public.friends(owner_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username      ON public.profiles(username);

-- ── Trigger: auto-create profile on sign-up ───────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_split_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, name, email)
  VALUES (
    NEW.id,
    -- derive a username from email prefix; uniqueness enforced by table
    lower(split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Drop old trigger if it exists so we can recreate cleanly
DROP TRIGGER IF EXISTS on_auth_user_created_split ON auth.users;

CREATE TRIGGER on_auth_user_created_split
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_split_user();
