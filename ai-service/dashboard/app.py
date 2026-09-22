"""
dashboard/app.py
-----------------
Streamlit spend-decomposition dashboard.
Phase 1 placeholder — renders with sample data.
Phase 7: connect to Supabase and show real bill history.

Run:
  streamlit run dashboard/app.py
"""

from __future__ import annotations

import sys
from pathlib import Path

# Add ai-service root to path so we can import schemas
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    import streamlit as st
    _HAS_STREAMLIT = True
except ImportError:
    _HAS_STREAMLIT = False


def main() -> None:
    if not _HAS_STREAMLIT:
        print("Streamlit not installed. Run: pip install streamlit")
        return

    st.set_page_config(
        page_title="Bill Intelligence — Dashboard",
        page_icon="💡",
        layout="wide",
    )

    st.title("Bill Intelligence")
    st.caption("Spend decomposition dashboard — Phase 1 placeholder")

    # ── Sample data ───────────────────────────────────────────────────
    MONTHS = ["Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]
    ELECTRIC = [112.0, 125.0, 163.0, 179.0, 148.0, 151.0]
    GAS      = [28.0,  42.0,  65.0,  71.0,  62.0,  48.0]

    # ── Summary row ───────────────────────────────────────────────────
    col1, col2, col3 = st.columns(3)
    col1.metric("This month",         "$199.00", "$-10.20 vs last month")
    col2.metric("6-month average",    "$151.50")
    col3.metric("Anomalies detected", "0")

    st.divider()

    # ── Chart: monthly totals ─────────────────────────────────────────
    st.subheader("Monthly spend by utility")

    import json
    chart_data = {
        "labels": MONTHS,
        "electric": ELECTRIC,
        "gas": GAS,
    }

    # Simple bar chart using st.bar_chart
    import pandas as pd
    df = pd.DataFrame({
        "Electric": ELECTRIC,
        "Gas": GAS,
    }, index=MONTHS)
    st.bar_chart(df)

    st.divider()

    # ── Spend drivers table (Phase 7: replace with real data) ─────────
    st.subheader("Spend drivers — last bill vs prior (sample)")
    st.table({
        "Driver":         ["Rate increase, effective Jan 1", "You used more", "New distribution rider"],
        "Impact ($)":     ["+$26.00", "+$11.00", "+$4.00"],
        "% of change":    ["63%", "27%", "10%"],
    })

    st.info(
        "This dashboard shows sample data. "
        "Connect to Supabase in Phase 7 to display real bill history.",
        icon="ℹ️",
    )


if __name__ == "__main__":
    main()
