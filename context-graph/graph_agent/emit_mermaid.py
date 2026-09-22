"""
emit_mermaid.py
---------------
Generates OVERVIEW.md with a Mermaid diagram of the highest-signal
relationships in the graph.

Only the top relationships are shown (not all edges) so the diagram
stays readable. Full detail is in the individual Obsidian notes.
"""

from __future__ import annotations

from pathlib import Path
from .extract import Graph

OVERVIEW_PATH = Path(__file__).parent.parent / "OVERVIEW.md"


def _safe_id(s: str) -> str:
    """Make a Mermaid-safe node ID."""
    import re
    s = re.sub(r"[^a-zA-Z0-9_]", "_", s)
    if s[0].isdigit():
        s = "n" + s
    return s[:40]


# Which relations to include in the overview diagram
HIGH_SIGNAL_RELATIONS = {
    "supersedes", "justifies", "constrains", "implements", "appliesTo", "linkedTo"
}

# Entity types to show in the overview (filter to keep diagram readable)
OVERVIEW_TYPES = {
    "Version", "Persona", "Feature", "UXLaw", "Deviation",
    "TechComponent", "CodePractice", "PipelineStage", "SecurityItem",
}

# Only show these specific node IDs in the overview (most important ones)
OVERVIEW_NODE_IDS = {
    # Versions
    "ver_1_0", "ver_2_0",
    # Personas
    "persona_rafael", "persona_marguerite", "persona_dana", "persona_wes",
    # Core features
    "feat_m1", "feat_m3", "feat_m4", "feat_m5", "feat_m8",
    "feat_m9", "feat_m11", "feat_m12", "feat_m13",
    # Key UX laws
    "ux_fitts", "ux_hick", "ux_miller", "ux_tesler", "ux_peak_end",
    # HIG deviations
    "dev_d1", "dev_d2", "dev_d3", "dev_d4",
    # Tech stack
    "tc_flutter", "tc_supabase", "tc_fastapi", "tc_oauth",
    # Key pipeline stages
    "pipe_0", "pipe_1", "pipe_2", "pipe_3", "pipe_5", "pipe_6",
    # Key security items
    "sec_sec_pm_001", "sec_sec_pm_002", "sec_sec_pm_007",
    # Code practices
    "cp_fe_be_sep", "cp_python_ai", "cp_no_model_math", "cp_provenance",
}


def emit(graph: Graph) -> None:
    # Build a node label lookup
    id_to_label: dict[str, str] = {n.id: n.label for n in graph.nodes}
    id_to_type: dict[str, str] = {n.id: n.entity_type for n in graph.nodes}

    # Filter to overview nodes
    overview_nodes = {
        nid: id_to_label[nid]
        for nid in OVERVIEW_NODE_IDS
        if nid in id_to_label
    }

    # Filter edges: both endpoints must be in overview set + high-signal relation
    overview_edges = [
        e for e in graph.edges
        if e.source in overview_nodes
        and e.target in overview_nodes
        and e.relation in HIGH_SIGNAL_RELATIONS
    ]

    # Build mermaid
    lines = ["```mermaid", "graph TD"]

    # Subgraphs by entity type
    type_groups: dict[str, list[str]] = {}
    for nid, label in overview_nodes.items():
        etype = id_to_type.get(nid, "Other")
        type_groups.setdefault(etype, []).append(nid)

    subgraph_order = [
        "Version", "Persona", "Feature", "UXLaw", "Deviation",
        "TechComponent", "CodePractice", "PipelineStage", "SecurityItem",
    ]

    for etype in subgraph_order:
        nids = type_groups.get(etype, [])
        if not nids:
            continue
        sg_id = _safe_id(etype)
        lines.append(f"  subgraph {sg_id} [{etype}]")
        for nid in nids:
            label = overview_nodes[nid]
            # Truncate long labels
            short = label[:40].replace('"', "'")
            safe_nid = _safe_id(nid)
            lines.append(f'    {safe_nid}["{short}"]')
        lines.append("  end")

    # Edges
    relation_arrow = {
        "supersedes":  "-->|supersedes|",
        "justifies":   "-->|justifies|",
        "constrains":  "-->|constrains|",
        "implements":  "-->|implements|",
        "appliesTo":   "-->|applies to|",
        "linkedTo":    "-->",
    }

    for e in overview_edges:
        src = _safe_id(e.source)
        tgt = _safe_id(e.target)
        arrow = relation_arrow.get(e.relation, "-->")
        lines.append(f"  {src} {arrow} {tgt}")

    lines.append("```")

    # ── Full document ─────────────────────────────────────────────────────
    doc = [
        "# Context Graph Overview",
        "",
        "> Auto-generated from the project source docs.",
        "> Re-generate with: `python context-graph/build.py`",
        "",
        "## The product",
        "",
        "> Take a photo of your utility bill and the app tells you, in one sentence,",
        "> whether this month is normal and why it changed.",
        "",
        "## Architecture pivot (v1 → v2)",
        "",
        "| Founding decision | v1 (original) | v2 (pivot) |",
        "|---|---|---|",
        "| Architecture | Local-first, on-device | Supabase cloud + local processing |",
        "| Platform | Native iOS only | Flutter: Web + iOS + Android |",
        "| Account | None, no signup | OAuth (Google + Apple), bypass flag in v1 |",
        "| AI/OCR | Apple on-device Foundation Models | Python FastAPI microservice |",
        "",
        "## Relationship map",
        "",
        "The diagram below shows the most important connections.",
        "Open the `vault/` folder in Obsidian for the full interactive graph.",
        "",
    ] + lines + [
        "",
        "## Entity counts",
        "",
    ]

    counts: dict[str, int] = {}
    for n in graph.nodes:
        counts[n.entity_type] = counts.get(n.entity_type, 0) + 1
    total_edges = len(graph.edges)

    doc.append("| Entity type | Count |")
    doc.append("|---|---|")
    for et, c in sorted(counts.items()):
        doc.append(f"| {et} | {c} |")
    doc.append(f"| **Total edges** | **{total_edges}** |")
    doc.append("")
    doc.append("## Key relationships at a glance")
    doc.append("")
    doc.append("| Relationship | What it means |")
    doc.append("|---|---|")
    doc.append("| `supersedes` | A newer version or decision replaces an older one |")
    doc.append("| `justifies` | A UX law or decision explains why a feature or rule exists |")
    doc.append("| `constrains` | A security item or code practice limits a feature or tech component |")
    doc.append("| `implements` | A user story or pipeline stage delivers a feature |")
    doc.append("| `appliesTo` | A feature serves a persona |")
    doc.append("| `dependsOn` | A user story needs another story to exist first |")
    doc.append("| `mappedToFlow` | A flow covers a set of user stories |")
    doc.append("| `linkedTo` | Two tech components communicate, or pipeline stages are in sequence |")
    doc.append("")

    OVERVIEW_PATH.write_text("\n".join(doc), encoding="utf-8")
    print(f"  ✓ Wrote {OVERVIEW_PATH}")
