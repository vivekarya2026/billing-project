-- migration: 0005_split_rls.sql
-- ─────────────────────────────────────────────────────────────────────────
-- Row-Level Security policies for the split-expense tables.
-- Policy philosophy:
--   • profiles   — readable by any authenticated user (username search)
--   • groups     — readable/writable by members only
--   • expenses   — readable/writable by group members
--   • settlements — readable/writable by the two parties involved
--   • friends    — a user owns their own rows
-- ─────────────────────────────────────────────────────────────────────────

-- Helper: is the current user a member of a given group?
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND member_id = auth.uid()
  );
$$;

-- ── profiles ──────────────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);   -- any signed-in user can search profiles by username

CREATE POLICY "profiles_insert_own"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ── groups ────────────────────────────────────────────────────────────────
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "groups_select_member"
  ON public.groups FOR SELECT
  TO authenticated
  USING (public.is_group_member(id));

CREATE POLICY "groups_insert_authenticated"
  ON public.groups FOR INSERT
  TO authenticated
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "groups_delete_creator"
  ON public.groups FOR DELETE
  TO authenticated
  USING (creator_id = auth.uid());

-- ── group_members ─────────────────────────────────────────────────────────
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "group_members_select_member"
  ON public.group_members FOR SELECT
  TO authenticated
  USING (public.is_group_member(group_id));

CREATE POLICY "group_members_insert_member"
  ON public.group_members FOR INSERT
  TO authenticated
  WITH CHECK (public.is_group_member(group_id) OR member_id = auth.uid());

CREATE POLICY "group_members_delete_creator"
  ON public.group_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.groups
      WHERE id = group_id AND creator_id = auth.uid()
    )
  );

-- ── friends ───────────────────────────────────────────────────────────────
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;

CREATE POLICY "friends_select_own"
  ON public.friends FOR SELECT
  TO authenticated
  USING (owner_id = auth.uid() OR friend_id = auth.uid());

CREATE POLICY "friends_insert_own"
  ON public.friends FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "friends_delete_own"
  ON public.friends FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- ── expenses ──────────────────────────────────────────────────────────────
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "expenses_select_member"
  ON public.expenses FOR SELECT
  TO authenticated
  USING (public.is_group_member(group_id));

CREATE POLICY "expenses_insert_member"
  ON public.expenses FOR INSERT
  TO authenticated
  WITH CHECK (public.is_group_member(group_id) AND paid_by = auth.uid());

CREATE POLICY "expenses_delete_payer_or_creator"
  ON public.expenses FOR DELETE
  TO authenticated
  USING (
    paid_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.groups
      WHERE id = group_id AND creator_id = auth.uid()
    )
  );

-- ── expense_members ───────────────────────────────────────────────────────
ALTER TABLE public.expense_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "expense_members_select_member"
  ON public.expense_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = expense_id AND public.is_group_member(e.group_id)
    )
  );

CREATE POLICY "expense_members_insert_member"
  ON public.expense_members FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = expense_id AND public.is_group_member(e.group_id)
    )
  );

CREATE POLICY "expense_members_delete_member"
  ON public.expense_members FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.id = expense_id AND public.is_group_member(e.group_id)
    )
  );

-- ── settlements ───────────────────────────────────────────────────────────
ALTER TABLE public.settlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "settlements_select_party"
  ON public.settlements FOR SELECT
  TO authenticated
  USING (payer_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "settlements_insert_payer"
  ON public.settlements FOR INSERT
  TO authenticated
  WITH CHECK (payer_id = auth.uid());

CREATE POLICY "settlements_delete_payer"
  ON public.settlements FOR DELETE
  TO authenticated
  USING (payer_id = auth.uid());
