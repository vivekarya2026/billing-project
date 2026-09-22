-- seed.sql — SplitWise demo data
-- ─────────────────────────────────────────────────────────────────────────
-- Creates three demo users + a group + expenses for offline/bypass testing.
-- Auth users must be created manually via Supabase dashboard or CLI
-- (auth.users rows are managed by GoTrue, not directly insertable in seed).
-- 
-- Profile rows are inserted directly; the trigger will not fire on seed.
-- Run AFTER migrations 0001-0005.
-- Demo credentials (create these in Supabase Auth first):
--   alice@split.local  / demo1234
--   bob@split.local    / demo1234
--   carol@split.local  / demo1234
-- ─────────────────────────────────────────────────────────────────────────

-- Well-known UUIDs for seed repeatability
DO $$
DECLARE
  alice_id  UUID := '00000000-0000-0000-0000-000000000101';
  bob_id    UUID := '00000000-0000-0000-0000-000000000102';
  carol_id  UUID := '00000000-0000-0000-0000-000000000103';
  grp_id    UUID := '00000000-0000-0000-0000-000000000201';
  exp1_id   UUID := '00000000-0000-0000-0000-000000000301';
  exp2_id   UUID := '00000000-0000-0000-0000-000000000302';
  exp3_id   UUID := '00000000-0000-0000-0000-000000000303';
BEGIN

-- ── Profiles ────────────────────────────────────────────────────────────
INSERT INTO public.profiles (id, username, name, email) VALUES
  (alice_id, 'alice',  'Alice Kumar',   'alice@split.local'),
  (bob_id,   'bob',    'Bob Sharma',    'bob@split.local'),
  (carol_id, 'carol',  'Carol Patel',   'carol@split.local')
ON CONFLICT (id) DO NOTHING;

-- ── Friends (bidirectional) ──────────────────────────────────────────────
INSERT INTO public.friends (owner_id, friend_id) VALUES
  (alice_id, bob_id),   (bob_id, alice_id),
  (alice_id, carol_id), (carol_id, alice_id),
  (bob_id,   carol_id), (carol_id, bob_id)
ON CONFLICT DO NOTHING;

-- ── Group ────────────────────────────────────────────────────────────────
INSERT INTO public.groups (id, group_name, creator_id) VALUES
  (grp_id, 'Goa Trip 🏖️', alice_id)
ON CONFLICT (id) DO NOTHING;

-- ── Group members ────────────────────────────────────────────────────────
INSERT INTO public.group_members (group_id, member_id) VALUES
  (grp_id, alice_id),
  (grp_id, bob_id),
  (grp_id, carol_id)
ON CONFLICT DO NOTHING;

-- ── Expenses ────────────────────────────────────────────────────────────
-- Expense 1: Alice paid ₹1500 for dinner, split 3 ways
INSERT INTO public.expenses (id, group_id, description, amount, paid_by, created_at) VALUES
  (exp1_id, grp_id, 'Dinner at shack', 1500.00, alice_id, NOW() - INTERVAL '2 days')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.expense_members (expense_id, member_id) VALUES
  (exp1_id, alice_id), (exp1_id, bob_id), (exp1_id, carol_id)
ON CONFLICT DO NOTHING;

-- Expense 2: Bob paid ₹900 for taxi, split 3 ways
INSERT INTO public.expenses (id, group_id, description, amount, paid_by, created_at) VALUES
  (exp2_id, grp_id, 'Taxi to airport', 900.00, bob_id, NOW() - INTERVAL '1 day')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.expense_members (expense_id, member_id) VALUES
  (exp2_id, alice_id), (exp2_id, bob_id), (exp2_id, carol_id)
ON CONFLICT DO NOTHING;

-- Expense 3: Carol paid ₹600 for groceries, split 2 ways (alice + carol)
INSERT INTO public.expenses (id, group_id, description, amount, paid_by, created_at) VALUES
  (exp3_id, grp_id, 'Grocery shopping', 600.00, carol_id, NOW() - INTERVAL '6 hours')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.expense_members (expense_id, member_id) VALUES
  (exp3_id, alice_id), (exp3_id, carol_id)
ON CONFLICT DO NOTHING;

-- ── Settlement (Bob paid Alice ₹400 already) ────────────────────────────
INSERT INTO public.settlements (group_id, payer_id, receiver_id, amount, created_at) VALUES
  (grp_id, bob_id, alice_id, 400.00, NOW() - INTERVAL '12 hours')
ON CONFLICT DO NOTHING;

END $$;
