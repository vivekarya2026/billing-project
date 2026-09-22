"""
pipeline/stage_7_persist.py
-----------------------------
STUB — Phase 3

Writes the validated + analysed bill back to Supabase using the
service_role key. RLS is bypassed at this layer intentionally.

Writes to: bills, extraction_fields, line_items, bill_classifications, anomalies.

Phase 1: not wired.
Phase 3: implement with supabase-py client.
"""

from __future__ import annotations

from schemas import ExtractedBill, ValidationResult, AnalysisResult, ClassificationResult


async def persist(
    bill: ExtractedBill,
    validation: ValidationResult,
    analysis: AnalysisResult,
    classification: ClassificationResult,
) -> None:
    """
    Phase 1 stub.
    TODO Phase 3: upsert bill + related rows to Supabase.
    """
    pass
