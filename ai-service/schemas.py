"""
schemas.py
----------
Pydantic models shared across routers and pipeline stages.

Design rules from TECH-REQUIREMENTS.md:
  - All arithmetic is deterministic Python — never delegated to an LLM.
  - ExtractedBill.fields stores per-field provenance (confidence + bounding_box)
    so the Flutter frontend can highlight source regions on the original image.
  - ValidationResult.failures is a list of named check failures — structured,
    not free text, so the UI can localise the message.
  - NarrationResult.sentence is always exactly one sentence. No exceptions.
  - Confidence: 0.0–1.0 float. Floor at 0.0, ceiling at 1.0.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, Optional
from pydantic import BaseModel, Field, field_validator


# ── Extraction ─────────────────────────────────────────────────────────────


class BoundingBox(BaseModel):
    """Image-space coordinates for a single extracted field."""
    x: float = Field(..., description="Left edge in pixels")
    y: float = Field(..., description="Top edge in pixels")
    w: float = Field(..., description="Width in pixels")
    h: float = Field(..., description="Height in pixels")
    page: int = Field(0, description="0-indexed page number")


class ExtractionField(BaseModel):
    """A single field extracted from the bill image."""
    field_name: str = Field(..., examples=["amount_due", "kwh_used", "due_date"])
    raw_value: str = Field(..., description="Verbatim text as it appears on the bill")
    parsed_value: Optional[float] = Field(None, description="Numeric value; null for dates/text")
    confidence: float = Field(..., ge=0.0, le=1.0)
    bounding_box: Optional[BoundingBox] = None
    source_page: int = Field(0, ge=0)


class LineItem(BaseModel):
    """A single charge / credit on the bill."""
    description: str
    amount: Decimal = Field(..., decimal_places=2)
    item_type: str = Field("charge", pattern=r"^(charge|credit|tax|fee|other)$")
    sort_order: int = 0


class ExtractedBill(BaseModel):
    """
    Full structured output from the extraction pipeline (stages 0–3).
    This is also the input body for POST /validate.
    """
    bill_id: Optional[str] = None
    provider: Optional[str] = None
    account_number: Optional[str] = None
    service_type: Optional[str] = None
    period_start: Optional[str] = None  # ISO date string: "2024-01-01"
    period_end: Optional[str] = None
    due_date: Optional[str] = None
    amount_due: Optional[float] = None
    total_usage: Optional[float] = None   # kWh, CCF, gallons, etc.
    usage_unit: Optional[str] = None      # "kWh", "CCF", "gal"
    fields: list[ExtractionField] = Field(default_factory=list)
    line_items: list[LineItem] = Field(default_factory=list)
    raw_text: Optional[str] = None
    validation_passed: bool = False
    extraction_confidence: float = Field(0.0, ge=0.0, le=1.0)


# ── Validation ─────────────────────────────────────────────────────────────


class ValidationFailure(BaseModel):
    """A single deterministic check that failed."""
    check_name: str = Field(..., examples=["line_items_sum_matches_amount_due"])
    expected: Optional[Any] = None   # what arithmetic says it should be
    actual: Optional[Any] = None     # what was on the bill
    delta: Optional[float] = None    # difference (for numeric checks)
    message: str = ""                # human-readable, but not displayed to end users


class ValidationResult(BaseModel):
    """
    Result of the deterministic arithmetic checks (stage 2).
    No LLM involved — pure Python Decimal arithmetic.
    """
    passed: bool
    failures: list[ValidationFailure] = Field(default_factory=list)
    tolerance_cents: int = Field(1, description="Acceptable rounding delta in cents")


# ── Classification ─────────────────────────────────────────────────────────


class ClassificationTag(BaseModel):
    tag: str = Field(..., examples=["rate_increase", "usage_spike", "new_charge"])
    confidence: float = Field(..., ge=0.0, le=1.0)


class ClassificationResult(BaseModel):
    bill_id: Optional[str] = None
    tags: list[ClassificationTag] = Field(default_factory=list)


# ── Analysis ───────────────────────────────────────────────────────────────


class SpendDriver(BaseModel):
    """A quantified reason why the bill changed from the prior period."""
    label: str          # "Rate increase, effective Jan 1"
    amount_delta: float  # signed dollars: positive = more expensive
    pct_of_delta: float  # fraction of the total bill change this driver explains
    source: str          # "rate_table" | "usage_comparison" | "line_item_diff"


class AnalysisResult(BaseModel):
    """
    Deterministic arithmetic output (stage 5).
    Explains what changed and by how much — no LLM involved.
    """
    bill_id: Optional[str] = None
    prior_bill_id: Optional[str] = None
    total_delta: Optional[float] = None          # current – prior (dollars)
    total_delta_pct: Optional[float] = None       # % change
    drivers: list[SpendDriver] = Field(default_factory=list)
    anomalies: list[dict] = Field(default_factory=list)  # typed further in stage_5


# ── Narration ──────────────────────────────────────────────────────────────


class NarrationRequest(BaseModel):
    model_config = {"populate_by_name": True}

    analysis: AnalysisResult
    narration_register: str = Field(
        "brief",
        alias="register",
        pattern=r"^(brief|explained|full)$",
        description="brief=1 sentence / explained=sentence+bullets / full=table",
    )


class NarrationResult(BaseModel):
    """
    The one sentence of plain-language explanation.
    Never two sentences. Never a list. One sentence.
    """
    model_config = {"populate_by_name": True}

    sentence: str
    narration_register: str = Field("brief", alias="register")


# ── Health ─────────────────────────────────────────────────────────────────


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "0.1.0"
