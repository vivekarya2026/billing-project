"""
pipeline/stage_2_validation.py
-------------------------------
REAL — deterministic arithmetic checks.
No LLM involved. Python Decimal only.

Checks performed:
  1. line_items_sum_matches_amount_due
     Sum of all line_item.amount must equal amount_due within tolerance.
  2. usage_times_rate_plausible
     If kWh + rate_per_kwh are present, kWh × rate should ≈ generation_charge.
  3. no_negative_usage
     Usage values (kWh, CCF, gal) must be ≥ 0.
  4. date_range_valid
     period_end must be ≥ period_start (if both present).
  5. amount_due_positive
     amount_due must be > 0.

All checks are independent — a failure in one does not stop the others.
The result carries a list of named failures so the UI can localise messages.

TOLERANCE: default 1 cent ($0.01). Utilities round line items to 2 decimal
places but the sum can be off by ±$0.01 due to their own rounding.
"""

from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from datetime import date as Date

from schemas import ExtractedBill, ValidationResult, ValidationFailure

# ── Tolerance ──────────────────────────────────────────────────────────────
TOLERANCE_CENTS = 1   # 1 cent = $0.01


def run_validation(bill: ExtractedBill) -> ValidationResult:
    """
    Run all deterministic checks and return a ValidationResult.
    Always returns 200 — the 'passed' field carries the verdict.
    """
    failures: list[ValidationFailure] = []

    # 1. Line items sum == amount_due
    f = _check_line_items_sum(bill)
    if f:
        failures.append(f)

    # 2. Usage × rate plausibility
    f = _check_usage_rate_plausibility(bill)
    if f:
        failures.append(f)

    # 3. No negative usage
    f = _check_no_negative_usage(bill)
    if f:
        failures.append(f)

    # 4. Date range valid
    f = _check_date_range(bill)
    if f:
        failures.append(f)

    # 5. Amount due positive
    f = _check_amount_due_positive(bill)
    if f:
        failures.append(f)

    return ValidationResult(
        passed=len(failures) == 0,
        failures=failures,
        tolerance_cents=TOLERANCE_CENTS,
    )


# ── Individual checks ──────────────────────────────────────────────────────

def _check_line_items_sum(bill: ExtractedBill) -> ValidationFailure | None:
    """
    Verify: sum(line_items.amount) ≈ amount_due  (within TOLERANCE_CENTS).
    Only runs when both are present and there is at least one line item.
    """
    if bill.amount_due is None or not bill.line_items:
        return None

    expected = Decimal(str(bill.amount_due)).quantize(Decimal("0.01"), ROUND_HALF_UP)
    actual = sum(
        Decimal(str(item.amount)).quantize(Decimal("0.01"), ROUND_HALF_UP)
        for item in bill.line_items
    )
    delta_cents = int(abs(actual - expected) * 100)

    if delta_cents > TOLERANCE_CENTS:
        return ValidationFailure(
            check_name="line_items_sum_matches_amount_due",
            expected=float(expected),
            actual=float(actual),
            delta=float(actual - expected),
            message=(
                f"Line items sum to ${actual} but amount_due is ${expected}. "
                f"Difference: ${actual - expected} ({delta_cents}¢)."
            ),
        )
    return None


def _check_usage_rate_plausibility(bill: ExtractedBill) -> ValidationFailure | None:
    """
    If kWh and rate_per_kwh are both present in extraction_fields, verify that
    kWh × rate ≈ the generation_charge line item (if present).
    This is a soft plausibility check, not a hard requirement.
    Tolerance is generous: 5% of the generation charge.
    """
    fields_by_name = {f.field_name: f for f in bill.fields}
    kwh_field  = fields_by_name.get("kwh_used")
    rate_field = fields_by_name.get("rate_per_kwh")

    if not kwh_field or not rate_field:
        return None
    if kwh_field.parsed_value is None or rate_field.parsed_value is None:
        return None

    computed_gen = Decimal(str(kwh_field.parsed_value)) * Decimal(str(rate_field.parsed_value))

    # Find generation_charge line item if present
    gen_item = next(
        (li for li in bill.line_items if "generation" in li.description.lower()),
        None,
    )
    if gen_item is None:
        return None  # cannot compare — no generation line item

    actual_gen = Decimal(str(gen_item.amount))
    tolerance_5pct = actual_gen * Decimal("0.05")

    if abs(computed_gen - actual_gen) > tolerance_5pct:
        return ValidationFailure(
            check_name="usage_times_rate_plausible",
            expected=float(computed_gen),
            actual=float(actual_gen),
            delta=float(computed_gen - actual_gen),
            message=(
                f"kWh ({kwh_field.parsed_value}) × rate ({rate_field.parsed_value}) "
                f"= ${computed_gen:.2f} but generation charge is ${actual_gen:.2f}."
            ),
        )
    return None


def _check_no_negative_usage(bill: ExtractedBill) -> ValidationFailure | None:
    """Usage values must be ≥ 0 (credits are negative line items, not usage)."""
    usage_field_names = {"kwh_used", "ccf_used", "gallons_used", "total_usage"}
    for field in bill.fields:
        if field.field_name in usage_field_names:
            if field.parsed_value is not None and field.parsed_value < 0:
                return ValidationFailure(
                    check_name="no_negative_usage",
                    expected=0.0,
                    actual=field.parsed_value,
                    message=f"Field '{field.field_name}' has negative usage: {field.parsed_value}.",
                )

    if bill.total_usage is not None and bill.total_usage < 0:
        return ValidationFailure(
            check_name="no_negative_usage",
            expected=0.0,
            actual=bill.total_usage,
            message=f"total_usage is negative: {bill.total_usage}.",
        )
    return None


def _check_date_range(bill: ExtractedBill) -> ValidationFailure | None:
    """period_end must be ≥ period_start."""
    if not bill.period_start or not bill.period_end:
        return None
    try:
        start = Date.fromisoformat(bill.period_start)
        end   = Date.fromisoformat(bill.period_end)
    except ValueError:
        return ValidationFailure(
            check_name="date_range_valid",
            message=f"Could not parse dates: period_start={bill.period_start}, period_end={bill.period_end}.",
        )
    if end < start:
        return ValidationFailure(
            check_name="date_range_valid",
            expected=f">= {bill.period_start}",
            actual=bill.period_end,
            message=f"period_end ({bill.period_end}) is before period_start ({bill.period_start}).",
        )
    return None


def _check_amount_due_positive(bill: ExtractedBill) -> ValidationFailure | None:
    """amount_due must be > 0 (credits come as negative line items)."""
    if bill.amount_due is None:
        return None
    if bill.amount_due <= 0:
        return ValidationFailure(
            check_name="amount_due_positive",
            expected="> 0",
            actual=bill.amount_due,
            message=f"amount_due is {bill.amount_due}, expected a positive value.",
        )
    return None
