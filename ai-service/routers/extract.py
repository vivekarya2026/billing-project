"""
routers/extract.py
------------------
POST /extract

Accepts an image URL (signed Supabase Storage URL) + bill_id.
Phase 1: returns a hardcoded sample ExtractedBill.
Phase 2: wire pipeline/stage_0_ingest.py → stage_1_ocr.py → stage_3_parse.py.

The extract endpoint intentionally does NOT run the LLM narration —
that is /narrate.  It does run /validate internally so the response
always carries a validation_passed flag.
"""

from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from schemas import ExtractedBill, ExtractionField, LineItem
from decimal import Decimal

router = APIRouter()


class ExtractRequest(BaseModel):
    image_url: str
    bill_id: str | None = None


@router.post("", response_model=ExtractedBill)
async def extract_bill(req: ExtractRequest) -> ExtractedBill:
    """
    Phase 1 stub: returns a sample ExtractedBill.
    Replace with real OCR pipeline in Phase 2.
    """
    # TODO Phase 2: call pipeline stages 0→1→3
    # from pipeline.stage_0_ingest import ingest
    # from pipeline.stage_1_ocr import run_ocr
    # from pipeline.stage_3_parse import parse

    sample = _sample_extracted_bill(req.bill_id)
    return sample


def _sample_extracted_bill(bill_id: str | None) -> ExtractedBill:
    """Hardcoded sample — used until OCR is wired."""
    return ExtractedBill(
        bill_id=bill_id,
        provider="Ohio Edison",
        account_number="****-4892",
        service_type="electric",
        period_start="2024-02-01",
        period_end="2024-02-29",
        due_date="2024-03-22",
        amount_due=148.20,
        total_usage=812.0,
        usage_unit="kWh",
        fields=[
            ExtractionField(
                field_name="amount_due",
                raw_value="$148.20",
                parsed_value=148.20,
                confidence=0.97,
            ),
            ExtractionField(
                field_name="kwh_used",
                raw_value="812 kWh",
                parsed_value=812.0,
                confidence=0.95,
            ),
            ExtractionField(
                field_name="due_date",
                raw_value="March 22, 2024",
                parsed_value=None,
                confidence=0.99,
            ),
        ],
        line_items=[
            LineItem(description="Distribution charge",    amount=Decimal("42.00"), item_type="charge", sort_order=0),
            LineItem(description="Generation charge",      amount=Decimal("68.20"), item_type="charge", sort_order=1),
            LineItem(description="Transmission charge",    amount=Decimal("18.00"), item_type="charge", sort_order=2),
            LineItem(description="State taxes and fees",   amount=Decimal("12.00"), item_type="tax",    sort_order=3),
            LineItem(description="Renewable energy rider", amount=Decimal("8.00"),  item_type="fee",    sort_order=4),
        ],
        validation_passed=True,
        extraction_confidence=0.96,
    )
