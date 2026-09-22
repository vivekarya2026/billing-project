"""
pipeline/stage_1_ocr.py
------------------------
STUB — Phase 2

Runs OCR on the raw document bytes.
Default engine: PaddleOCR (lightweight, no cloud API needed).
Fallback: Tesseract.

Returns raw text + per-word bounding boxes.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from .stage_0_ingest import RawDocument


@dataclass
class OcrWord:
    text: str
    confidence: float
    bbox: dict  # {x, y, w, h, page}


@dataclass
class OcrResult:
    bill_id: str
    full_text: str
    words: list[OcrWord] = field(default_factory=list)
    engine_used: str = "stub"


def run_ocr(doc: RawDocument) -> OcrResult:
    """
    Phase 1 stub — returns empty OcrResult.
    TODO Phase 2: import models.ocr.PaddleOcrModel and call .extract(doc)
    """
    return OcrResult(
        bill_id=doc.bill_id,
        full_text="",  # empty until wired
        engine_used="stub",
    )
