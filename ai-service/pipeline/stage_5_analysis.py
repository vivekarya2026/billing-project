"""
pipeline/stage_5_analysis.py
-----------------------------
REAL — deterministic spend decomposition.
No LLM involved. Python Decimal only.

Given the current bill and an optional prior bill, quantifies what changed
and why, producing a list of SpendDrivers.

Driver attribution logic:
  1. Rate change  — if rate_per_kwh changed between periods
  2. Usage change — if kWh changed between periods
  3. New charge   — a line item present in current but not in prior
  4. Removed charge — a line item present in prior but not in current
  5. Charge change  — a line item present in both with a different amount

If prior is None, drivers is an empty list (no comparison baseline).
Anomaly detection: usage spike > 15% is flagged as an anomaly.
"""

from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from typing import Optional

from schemas import (
    ExtractedBill,
    AnalysisResult,
    SpendDriver,
)

USAGE_SPIKE_THRESHOLD_PCT = 0.15   # 15% increase in usage = anomaly


def run_analysis(
    current: ExtractedBill,
    prior: Optional[ExtractedBill] = None,
) -> AnalysisResult:
    """
    Deterministic spend decomposition.
    Returns structured AnalysisResult — no LLM.
    """
    if prior is None:
        return AnalysisResult(
            bill_id=current.bill_id,
            prior_bill_id=None,
            total_delta=None,
            total_delta_pct=None,
            drivers=[],
            anomalies=[],
        )

    current_amount = Decimal(str(current.amount_due or 0))
    prior_amount   = Decimal(str(prior.amount_due or 0))
    total_delta    = current_amount - prior_amount
    total_delta_pct = (
        float(total_delta / prior_amount * 100)
        if prior_amount != 0 else None
    )

    drivers: list[SpendDriver] = []
    anomalies: list[dict] = []

    # ── Driver 1: Rate change ────────────────────────────────────────────
    current_fields = {f.field_name: f for f in current.fields}
    prior_fields   = {f.field_name: f for f in prior.fields}

    cur_rate  = current_fields.get("rate_per_kwh")
    prior_rate = prior_fields.get("rate_per_kwh")
    cur_kwh   = current_fields.get("kwh_used")

    if (
        cur_rate and prior_rate
        and cur_rate.parsed_value is not None
        and prior_rate.parsed_value is not None
        and cur_kwh and cur_kwh.parsed_value is not None
    ):
        rate_delta_per_unit = Decimal(str(cur_rate.parsed_value)) - Decimal(str(prior_rate.parsed_value))
        rate_impact = rate_delta_per_unit * Decimal(str(cur_kwh.parsed_value))
        if abs(rate_impact) >= Decimal("0.01"):
            pct = float(rate_impact / total_delta) if total_delta != 0 else 0.0
            drivers.append(SpendDriver(
                label="Rate change",
                amount_delta=float(rate_impact.quantize(Decimal("0.01"), ROUND_HALF_UP)),
                pct_of_delta=round(pct, 4),
                source="rate_table",
            ))

    # ── Driver 2: Usage change ────────────────────────────────────────────
    prior_kwh = prior_fields.get("kwh_used")
    if (
        cur_kwh and prior_kwh
        and cur_kwh.parsed_value is not None
        and prior_kwh.parsed_value is not None
    ):
        usage_delta_kwh = Decimal(str(cur_kwh.parsed_value)) - Decimal(str(prior_kwh.parsed_value))
        # Estimate dollar impact using current rate
        rate_for_calc = Decimal(str(cur_rate.parsed_value)) if cur_rate and cur_rate.parsed_value else Decimal("0.12")
        usage_impact = usage_delta_kwh * rate_for_calc
        if abs(usage_impact) >= Decimal("0.01"):
            pct = float(usage_impact / total_delta) if total_delta != 0 else 0.0
            drivers.append(SpendDriver(
                label="You used more" if usage_delta_kwh > 0 else "You used less",
                amount_delta=float(usage_impact.quantize(Decimal("0.01"), ROUND_HALF_UP)),
                pct_of_delta=round(pct, 4),
                source="usage_comparison",
            ))

        # Anomaly: usage spike > 15%
        prior_kwh_val = Decimal(str(prior_kwh.parsed_value))
        if prior_kwh_val > 0:
            spike_pct = float(usage_delta_kwh / prior_kwh_val)
            if spike_pct > USAGE_SPIKE_THRESHOLD_PCT:
                anomalies.append({
                    "anomaly_type": "usage_spike",
                    "severity": "warn",
                    "description": (
                        f"Usage is up {spike_pct * 100:.1f}% from last period "
                        f"({float(prior_kwh_val):.0f} to {cur_kwh.parsed_value:.0f} kWh)."
                    ),
                })

    # ── Driver 3: New / removed / changed line items ──────────────────────
    prior_items  = {li.description: li for li in prior.line_items}
    cur_items    = {li.description: li for li in current.line_items}

    for desc, cur_item in cur_items.items():
        if desc not in prior_items:
            impact = Decimal(str(cur_item.amount))
            pct = float(impact / total_delta) if total_delta != 0 else 0.0
            drivers.append(SpendDriver(
                label=f"New charge: {desc}",
                amount_delta=float(impact),
                pct_of_delta=round(pct, 4),
                source="line_item_diff",
            ))
        else:
            prior_item = prior_items[desc]
            item_delta = Decimal(str(cur_item.amount)) - Decimal(str(prior_item.amount))
            if abs(item_delta) >= Decimal("0.01"):
                pct = float(item_delta / total_delta) if total_delta != 0 else 0.0
                drivers.append(SpendDriver(
                    label=f"{desc} changed",
                    amount_delta=float(item_delta.quantize(Decimal("0.01"), ROUND_HALF_UP)),
                    pct_of_delta=round(pct, 4),
                    source="line_item_diff",
                ))

    for desc in prior_items:
        if desc not in cur_items:
            impact = -Decimal(str(prior_items[desc].amount))
            pct = float(impact / total_delta) if total_delta != 0 else 0.0
            drivers.append(SpendDriver(
                label=f"Removed: {desc}",
                amount_delta=float(impact),
                pct_of_delta=round(pct, 4),
                source="line_item_diff",
            ))

    # Sort drivers by absolute impact descending
    drivers.sort(key=lambda d: abs(d.amount_delta), reverse=True)

    return AnalysisResult(
        bill_id=current.bill_id,
        prior_bill_id=prior.bill_id,
        total_delta=float(total_delta.quantize(Decimal("0.01"), ROUND_HALF_UP)),
        total_delta_pct=total_delta_pct,
        drivers=drivers,
        anomalies=anomalies,
    )
