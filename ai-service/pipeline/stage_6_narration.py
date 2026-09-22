"""
pipeline/stage_6_narration.py
------------------------------
STUB — Phase 6

Takes a structured AnalysisResult and returns exactly ONE sentence
in the requested register (brief / explained / full).

CRITICAL RULE: this is the ONLY stage that uses an LLM.
All arithmetic must be done in stage_5 before this stage is called.
The LLM receives only structured data — never raw OCR text or bill images.

Phase 1: not wired. Template sentence returned by the router stub.
Phase 6: implement with an LLM call (GPT-4o / Gemini Flash).
         The prompt must constrain to exactly one sentence.
"""

from __future__ import annotations

from schemas import AnalysisResult, NarrationResult


def narrate(analysis: AnalysisResult, register: str = "brief") -> NarrationResult:
    """
    Phase 1 stub.
    TODO Phase 6: call LLM with structured analysis data.
                  Constrain to exactly one sentence.
                  Never let the LLM do arithmetic.
    """
    return NarrationResult(
        sentence="Normal for this time of year. Nothing looks unusual.",
        register=register,
    )
