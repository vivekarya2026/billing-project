"""
pipeline/stage_3_parse.py
--------------------------
STUB — Phase 2

Takes OcrResult text + bounding boxes and extracts structured fields
(amount_due, due_date, kWh, rate, line items, etc.)

Phase 1: not wired. Returns an empty ExtractedBill.
Phase 2: implement regex + layout heuristics for common utility bill formats.
"""

from __future__ import annotations

from schemas import ExtractedBill
from .stage_1_ocr import OcrResult


def parse(ocr: OcrResult) -> ExtractedBill:
    """
    Phase 1 stub.
    TODO Phase 2: parse OCR text into structured ExtractedBill.
    """
    return ExtractedBill(
        bill_id=ocr.bill_id,
        raw_text=ocr.full_text,
    )
