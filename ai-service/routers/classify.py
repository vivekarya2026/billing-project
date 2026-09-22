"""
routers/classify.py
--------------------
POST /classify

Phase 1 stub: returns a hardcoded classification with high-confidence tags.
Phase 2: wire pipeline/stage_4_classification.py with a real classifier.
"""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from schemas import ClassificationResult, ClassificationTag

router = APIRouter()


class ClassifyRequest(BaseModel):
    bill_id: str | None = None
    extracted_bill: dict  # ExtractedBill as dict — typed loosely for the stub


@router.post("", response_model=ClassificationResult)
async def classify_bill(req: ClassifyRequest) -> ClassificationResult:
    """
    Phase 1 stub — returns sample tags.
    TODO Phase 4: run pipeline.stage_4_classification.classify(extracted_bill)
    """
    return ClassificationResult(
        bill_id=req.bill_id,
        tags=[
            ClassificationTag(tag="normal", confidence=0.82),
        ],
    )
