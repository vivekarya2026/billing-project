"""
tests/test_validation.py
-------------------------
REAL tests for the deterministic arithmetic in stage_2_validation.py.
Run with:  pytest tests/test_validation.py -v

These tests are the CI gate — they must all pass before any pipeline
change is merged. They do not require a running server or any external service.
"""

from __future__ import annotations

from decimal import Decimal
import pytest

from schemas import ExtractedBill, ExtractionField, LineItem
from pipeline.stage_2_validation import run_validation, TOLERANCE_CENTS


# ── Helpers ────────────────────────────────────────────────────────────────

def make_simple_bill(
    amount_due: float = 148.20,
    line_item_total: float = 148.20,
    period_start: str = "2024-02-01",
    period_end: str = "2024-02-29",
    total_usage: float | None = 812.0,
) -> ExtractedBill:
    """Build a minimal valid ExtractedBill for testing."""
    # Distribute line_item_total across two items
    item_a = round(line_item_total * 0.7, 2)
    item_b = round(line_item_total - item_a, 2)
    return ExtractedBill(
        bill_id="test-001",
        amount_due=amount_due,
        period_start=period_start,
        period_end=period_end,
        total_usage=total_usage,
        fields=[
            ExtractionField(
                field_name="amount_due",
                raw_value=f"${amount_due}",
                parsed_value=amount_due,
                confidence=0.99,
            ),
        ],
        line_items=[
            LineItem(description="Charge A", amount=Decimal(str(item_a))),
            LineItem(description="Charge B", amount=Decimal(str(item_b))),
        ],
    )


# ── Test: line items sum matches amount_due ────────────────────────────────

def test_valid_bill_passes():
    """A bill where everything adds up should pass all checks."""
    bill = make_simple_bill(amount_due=148.20, line_item_total=148.20)
    result = run_validation(bill)
    assert result.passed is True
    assert result.failures == []


def test_line_items_sum_exact_match():
    """Line items summing exactly to amount_due must pass."""
    bill = make_simple_bill(amount_due=100.00, line_item_total=100.00)
    result = run_validation(bill)
    assert result.passed is True


def test_line_items_sum_within_tolerance():
    """A 1-cent rounding difference (= TOLERANCE_CENTS) must pass."""
    bill = make_simple_bill(amount_due=100.00, line_item_total=100.01)
    result = run_validation(bill)
    # 1 cent is exactly the tolerance, so it should pass
    assert result.passed is True


def test_line_items_sum_exceeds_tolerance():
    """A 2-cent discrepancy must fail (> TOLERANCE_CENTS = 1)."""
    bill = make_simple_bill(amount_due=100.00, line_item_total=100.02)
    result = run_validation(bill)
    assert result.passed is False
    assert any(f.check_name == "line_items_sum_matches_amount_due" for f in result.failures)


def test_line_items_sum_large_discrepancy():
    """A $10 discrepancy must fail and report the correct delta."""
    bill = make_simple_bill(amount_due=148.20, line_item_total=138.20)
    result = run_validation(bill)
    assert result.passed is False
    failure = next(f for f in result.failures if f.check_name == "line_items_sum_matches_amount_due")
    assert abs(failure.delta - (-10.0)) < 0.001


def test_no_line_items_skips_sum_check():
    """If there are no line items, the sum check should be skipped (not fail)."""
    bill = ExtractedBill(
        bill_id="test-002",
        amount_due=100.00,
        period_start="2024-02-01",
        period_end="2024-02-29",
    )
    result = run_validation(bill)
    assert not any(f.check_name == "line_items_sum_matches_amount_due" for f in result.failures)


# ── Test: amount_due_positive ──────────────────────────────────────────────

def test_positive_amount_due_passes():
    bill = make_simple_bill(amount_due=1.00, line_item_total=1.00)
    result = run_validation(bill)
    assert result.passed is True


def test_zero_amount_due_fails():
    bill = ExtractedBill(bill_id="test-003", amount_due=0.0)
    result = run_validation(bill)
    assert result.passed is False
    assert any(f.check_name == "amount_due_positive" for f in result.failures)


def test_negative_amount_due_fails():
    bill = ExtractedBill(bill_id="test-004", amount_due=-10.00)
    result = run_validation(bill)
    assert result.passed is False
    assert any(f.check_name == "amount_due_positive" for f in result.failures)


def test_none_amount_due_skips_check():
    """Missing amount_due should not raise — the check is skipped."""
    bill = ExtractedBill(bill_id="test-005", amount_due=None)
    result = run_validation(bill)
    assert not any(f.check_name == "amount_due_positive" for f in result.failures)


# ── Test: date range valid ─────────────────────────────────────────────────

def test_valid_date_range_passes():
    bill = make_simple_bill(period_start="2024-02-01", period_end="2024-02-29")
    result = run_validation(bill)
    assert not any(f.check_name == "date_range_valid" for f in result.failures)


def test_inverted_date_range_fails():
    bill = make_simple_bill(period_start="2024-02-29", period_end="2024-02-01")
    result = run_validation(bill)
    assert result.passed is False
    assert any(f.check_name == "date_range_valid" for f in result.failures)


def test_same_day_period_passes():
    """period_end == period_start is valid (daily billing)."""
    bill = make_simple_bill(period_start="2024-02-01", period_end="2024-02-01")
    result = run_validation(bill)
    assert not any(f.check_name == "date_range_valid" for f in result.failures)


def test_missing_dates_skips_check():
    bill = ExtractedBill(bill_id="test-006", amount_due=10.00)
    result = run_validation(bill)
    assert not any(f.check_name == "date_range_valid" for f in result.failures)


# ── Test: no negative usage ────────────────────────────────────────────────

def test_positive_usage_passes():
    bill = make_simple_bill(total_usage=812.0)
    result = run_validation(bill)
    assert not any(f.check_name == "no_negative_usage" for f in result.failures)


def test_negative_total_usage_fails():
    bill = ExtractedBill(bill_id="test-007", amount_due=10.00, total_usage=-100.0)
    result = run_validation(bill)
    assert result.passed is False
    assert any(f.check_name == "no_negative_usage" for f in result.failures)


def test_negative_usage_in_field_fails():
    bill = ExtractedBill(
        bill_id="test-008",
        amount_due=10.00,
        fields=[
            ExtractionField(
                field_name="kwh_used",
                raw_value="-50 kWh",
                parsed_value=-50.0,
                confidence=0.90,
            )
        ],
    )
    result = run_validation(bill)
    assert result.passed is False
    assert any(f.check_name == "no_negative_usage" for f in result.failures)


def test_zero_usage_passes():
    """Zero usage is valid (e.g. vacation period)."""
    bill = make_simple_bill(total_usage=0.0)
    result = run_validation(bill)
    assert not any(f.check_name == "no_negative_usage" for f in result.failures)


# ── Test: multiple failures ────────────────────────────────────────────────

def test_multiple_failures_all_reported():
    """When multiple checks fail, all failures are reported."""
    bill = ExtractedBill(
        bill_id="test-009",
        amount_due=-50.00,
        period_start="2024-03-01",
        period_end="2024-02-01",  # inverted
        total_usage=-100.0,
    )
    result = run_validation(bill)
    assert result.passed is False
    check_names = {f.check_name for f in result.failures}
    assert "amount_due_positive"  in check_names
    assert "date_range_valid"     in check_names
    assert "no_negative_usage"    in check_names


# ── Test: tolerance constant ──────────────────────────────────────────────

def test_tolerance_is_one_cent():
    """TOLERANCE_CENTS must be exactly 1. If this fails, someone changed it."""
    assert TOLERANCE_CENTS == 1
