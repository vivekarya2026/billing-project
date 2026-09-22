"""
pipeline/stage_4_classification.py
------------------------------------
STUB — Phase 4

Classifies a validated bill into tags: "rate_increase", "usage_spike",
"new_charge", "normal", etc.

Phase 1: not wired. Returns a single "normal" tag.
Phase 4: compare current bill to prior bills using Supabase; apply
         rule-based classifier first, LLM fallback only for novel patterns.
"""

from __future__ import annotations

from schemas import ExtractedBill, ClassificationResult, ClassificationTag


def classify(bill: ExtractedBill) -> ClassificationResult:
    """
    Phase 1 stub.
    TODO Phase 4: implement rule-based classifier with LLM fallback.
    """
    return ClassificationResult(
        bill_id=bill.bill_id,
        tags=[ClassificationTag(tag="normal", confidence=0.80)],
    )
