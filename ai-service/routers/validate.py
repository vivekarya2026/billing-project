"""
routers/validate.py
--------------------
POST /validate

Accepts an ExtractedBill, runs deterministic arithmetic checks,
returns a ValidationResult.

This endpoint is REAL — no stubs. All arithmetic uses Python Decimal
(not float) to avoid rounding errors. No LLM is involved.

See pipeline/stage_2_validation.py for the check implementations.
"""

from __future__ import annotations

from fastapi import APIRouter
from schemas import ExtractedBill, ValidationResult
from pipeline.stage_2_validation import run_validation

router = APIRouter()


@router.post("", response_model=ValidationResult)
async def validate_bill(bill: ExtractedBill) -> ValidationResult:
    """
    Deterministic arithmetic validation.
    Returns 200 regardless of pass/fail — check the 'passed' field.
    """
    return run_validation(bill)
