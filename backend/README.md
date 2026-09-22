# Bill Intelligence — Backend

## Stack
- **Supabase** (local-first): PostgreSQL + Auth + Storage
- Migrations are in `supabase/migrations/`, applied in order.
- Seed data in `supabase/seed.sql`.

---

## Quick start

```bash
# 1. Install Supabase CLI (if not installed)
brew install supabase/tap/supabase

# 2. Start local Supabase (requires Docker)
cd backend
supabase start

# 3. Apply migrations + seed
supabase db reset   # re-runs all migrations and seed.sql

# 4. Copy the local credentials printed by `supabase start` into frontend/.env
```

---

## Environment variables (frontend/.env)

```
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_ANON_KEY=<printed by supabase start>
BYPASS_AUTH=true          # skip OAuth in dev; uses seeded demo user
BYPASS_EMAIL=alice@split.local
BYPASS_PASSWORD=demo1234
```

---

## Migration history

| File | Contents |
|---|---|
| `0001_init.sql` | Original bill-intelligence tables (properties, accounts, bills, line_items, extraction_fields) |
| `0002_rls.sql` | RLS for bill tables |
| `0003_storage.sql` | Supabase Storage bucket for bill images |
| `0004_split.sql` | **SplitWise tables**: profiles, groups, group_members, friends, expenses, expense_members, settlements. Auto-creates a profile row on auth.users insert via trigger `handle_new_split_user`. |
| `0005_split_rls.sql` | RLS for all split tables + helper function `is_group_member()` |

---

## Seed data (seed.sql)

Creates three demo users for offline/bypass-auth testing:

| Username | Email | Password |
|---|---|---|
| alice | alice@split.local | demo1234 |
| bob | bob@split.local | demo1234 |
| carol | carol@split.local | demo1234 |

Includes: 1 group ("Goa Trip"), 3 expenses, 1 settlement.

**Note:** Auth rows must be created via the Supabase Dashboard or CLI (`supabase auth --help`) before the seed inserts profile rows. The seed uses `ON CONFLICT DO NOTHING` so it is safe to re-run.

---

## Schema overview

```
profiles   ──< group_members >── groups ──< expenses ──< expense_members
               friends (bidirectional)             settlements
```

All monetary amounts are `NUMERIC(12, 2)` (not strings).

Debt simplification runs **client-side** (see `frontend/lib/shared/logic/simplify.dart`).
