"""
routers/analyse.py
-------------------
POST /analyse

Deterministic spend-decomposition (stage 5).
Accepts the current ExtractedBill and optionally a prior bill for comparison.
Returns structured spend drivers and anomalies — no LLM.

Phase 1: prior_bill is optional; if absent, drivers list is empty (no comparison).
Phase 2: pull prior bill from Supabase using service_role key.
"""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional

from schemas import ExtractedBill, AnalysisResult
from pipeline.stage_5_analysis import run_analysis

router = APIRouter()


class AnalyseRequest(BaseModel):
    bill: ExtractedBill
    prior_bill: Optional[ExtractedBill] = None


@router.post("", response_model=AnalysisResult)
async def analyse_bill(req: AnalyseRequest) -> AnalysisResult:
    """
    Deterministic spend decomposition.
    Returns structured drivers — no LLM involved.
    """
    return run_analysis(current=req.bill, prior=req.prior_bill)
