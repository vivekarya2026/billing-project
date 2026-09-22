-- migration: 0002_rls.sql
-- ─────────────────────────────────────────────────────────────────────────
-- Row-Level Security (RLS) for every table.
--
-- Policy: users can only read and write their own rows.
-- auth.uid() = user_id is the universal predicate.
--
-- The AI service uses the service_role key and bypasses RLS entirely —
-- this is correct and intentional: the service writes extraction data
-- for any user after verifying a signed storage URL.
-- ─────────────────────────────────────────────────────────────────────────

-- ── Enable RLS ────────────────────────────────────────────────────────────
ALTER TABLE public.properties           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bills                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extraction_fields    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.line_items           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bill_classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anomalies            ENABLE ROW LEVEL SECURITY;

-- ── properties ────────────────────────────────────────────────────────────
CREATE POLICY "owner can select properties"
  ON public.properties FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "owner can insert properties"
  ON public.properties FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can update properties"
  ON public.properties FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can delete properties"
  ON public.properties FOR DELETE
  USING (auth.uid() = user_id);

-- ── accounts ──────────────────────────────────────────────────────────────
CREATE POLICY "owner can select accounts"
  ON public.accounts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "owner can insert accounts"
  ON public.accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can update accounts"
  ON public.accounts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can delete accounts"
  ON public.accounts FOR DELETE
  USING (auth.uid() = user_id);

-- ── bills ─────────────────────────────────────────────────────────────────
CREATE POLICY "owner can select bills"
  ON public.bills FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "owner can insert bills"
  ON public.bills FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can update bills"
  ON public.bills FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can delete bills"
  ON public.bills FOR DELETE
  USING (auth.uid() = user_id);

-- ── extraction_fields ─────────────────────────────────────────────────────
-- Joins through bills to get user_id (avoids duplicate column)
CREATE POLICY "owner can select extraction_fields"
  ON public.extraction_fields FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = extraction_fields.bill_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "owner can insert extraction_fields"
  ON public.extraction_fields FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = extraction_fields.bill_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "owner can update extraction_fields"
  ON public.extraction_fields FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = extraction_fields.bill_id
        AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "owner can delete extraction_fields"
  ON public.extraction_fields FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = extraction_fields.bill_id
        AND b.user_id = auth.uid()
    )
  );

-- ── line_items ────────────────────────────────────────────────────────────
CREATE POLICY "owner can select line_items"
  ON public.line_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = line_items.bill_id AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "owner can insert line_items"
  ON public.line_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = line_items.bill_id AND b.user_id = auth.uid()
    )
  );

-- ── bill_classifications ──────────────────────────────────────────────────
CREATE POLICY "owner can select bill_classifications"
  ON public.bill_classifications FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = bill_classifications.bill_id AND b.user_id = auth.uid()
    )
  );

CREATE POLICY "owner can insert bill_classifications"
  ON public.bill_classifications FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bills b
      WHERE b.id = bill_classifications.bill_id AND b.user_id = auth.uid()
    )
  );

-- ── anomalies ─────────────────────────────────────────────────────────────
CREATE POLICY "owner can select anomalies"
  ON public.anomalies FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "owner can insert anomalies"
  ON public.anomalies FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "owner can update anomalies"
  ON public.anomalies FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
