"""
routers/narrate.py
-------------------
POST /narrate

Phase 1 stub: returns a template sentence based on the register.
Phase 6: wire to pipeline/stage_6_narration.py with a real LLM.

CRITICAL RULE: narration is the ONLY stage that uses an LLM.
All arithmetic stays in stage_2 and stage_5. The LLM receives
only structured data (AnalysisResult) and must output exactly
one sentence per register.
"""

from __future__ import annotations

from fastapi import APIRouter
from schemas import NarrationRequest, NarrationResult

router = APIRouter()


@router.post("", response_model=NarrationResult)
async def narrate_bill(req: NarrationRequest) -> NarrationResult:
    """
    Phase 1 stub — returns template sentence.
    TODO Phase 6: run pipeline.stage_6_narration.narrate(req.analysis, req.register)
    """
    analysis = req.analysis
    delta = analysis.total_delta
    register = req.narration_register

    # Template sentences — replace with LLM-generated in Phase 6
    if register == "brief":
        if delta is None:
            sentence = "Normal for this time of year. Nothing looks unusual."
        elif delta > 0:
            sentence = f"Up ${delta:.2f} from last period."
        else:
            sentence = f"Down ${abs(delta):.2f} from last period."

    elif register == "explained":
        if delta is None:
            sentence = "This bill looks normal compared to your history."
        elif delta > 0:
            drivers = analysis.drivers
            if drivers:
                top = drivers[0]
                sentence = f"Up ${delta:.2f}: mostly {top.label.lower()}."
            else:
                sentence = f"Up ${delta:.2f} from last period."
        else:
            sentence = f"Down ${abs(delta):.2f} — usage is lower than last period."

    else:  # full
        sentence = (
            "See the breakdown below for a full accounting of every charge."
        )

    return NarrationResult(sentence=sentence, register=register)
