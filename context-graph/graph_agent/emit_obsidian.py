"""
emit_obsidian.py
----------------
Writes one Markdown note per entity into the vault directory.
Notes use [[wikilinks]] so Obsidian's Graph View renders them natively.

Folder layout:
  vault/
    Versions/
    Decisions/
    Personas/
    UX-Laws/
    Design/
    Features/
    Stories/
    Security/
    Pipeline/
    Code-Practices/
    Tech-Stack/
    Flows/
    _index.md

All prose is written at ~6th grade reading level (dumbify).
Design notes are grounded in Laws of UX.
"""

from __future__ import annotations

import re
from pathlib import Path
from .extract import Graph, Node

VAULT_DIR = Path(__file__).parent.parent / "vault"

FOLDER_MAP = {
    "Version":       "Versions",
    "Decision":      "Decisions",
    "Persona":       "Personas",
    "UXLaw":         "UX-Laws",
    "Deviation":     "Design",
    "DesignToken":   "Design",
    "DesignRule":    "Design",
    "Feature":       "Features",
    "UserStory":     "Stories",
    "SecurityItem":  "Security",
    "PipelineStage": "Pipeline",
    "CodePractice":  "Code-Practices",
    "TechComponent": "Tech-Stack",
    "Flow":          "Flows",
}

# Map node id -> Obsidian note title (for [[wikilinks]])
_id_to_title: dict[str, str] = {}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _slug(text: str) -> str:
    """Turn a label into a safe filename."""
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"\s+", "-", text.strip())
    return text[:80]


def _wikilink(node_id: str) -> str:
    title = _id_to_title.get(node_id, node_id)
    return f"[[{title}]]"


def _frontmatter(entity_type: str, attrs: dict) -> str:
    lines = ["---", f"type: {entity_type}"]
    for k, v in attrs.items():
        if isinstance(v, list):
            if v:
                lines.append(f"{k}:")
                for item in v:
                    lines.append(f"  - {str(item)[:120]}")
        elif isinstance(v, dict):
            pass  # skip nested dicts in frontmatter
        elif isinstance(v, str) and v:
            safe = v.replace('"', "'")[:200]
            lines.append(f'{k}: "{safe}"')
        elif isinstance(v, bool):
            lines.append(f"{k}: {str(v).lower()}")
    lines.append("---")
    return "\n".join(lines)


def _outbound_links(node_id: str, graph: Graph) -> list[tuple[str, str, str]]:
    """Return [(relation, target_id, note)] for outbound edges from node_id."""
    return [
        (e.relation, e.target, e.note)
        for e in graph.edges
        if e.source == node_id
    ]


def _inbound_links(node_id: str, graph: Graph) -> list[tuple[str, str, str]]:
    """Return [(relation, source_id, note)] for inbound edges to node_id."""
    return [
        (e.relation, e.source, e.note)
        for e in graph.edges
        if e.target == node_id
    ]


# ---------------------------------------------------------------------------
# Note writers per entity type
# ---------------------------------------------------------------------------

def _write_version(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("Version", a), "", f"# {node.label}", ""]
    out.append(f"> {a.get('summary', '')}")
    out.append("")
    out.append(f"**Date:** {a.get('date', 'unknown')}  ")
    out.append(f"**Status:** {a.get('status', 'unknown')}  ")
    out.append("")
    out.append("## What changed")
    out.append("")
    out.append(a.get("summary", ""))
    out.append("")

    links = _outbound_links(node.id, graph)
    if links:
        out.append("## Supersedes")
        out.append("")
        for rel, target, note in links:
            out.append(f"- {_wikilink(target)} — {note or rel}")
        out.append("")
    return "\n".join(out)


def _write_decision(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("Decision", {k: v for k, v in a.items() if not isinstance(v, dict)}), "", f"# {node.label}", ""]
    out.append(f"**Decision:** {a.get('decision', '')}  ")
    out.append(f"**Why:** {a.get('rationale', '')}  ")
    out.append(f"**Made by:** {a.get('made_by', '')}  ")
    if a.get("superseded_by_v2"):
        out.append("")
        out.append("> **Superseded by v2.0 pivot.** The new stack changes this decision. See [[v2.0 — Cloud / Multi-platform]].")
    out.append("")

    inbound = _inbound_links(node.id, graph)
    if inbound:
        out.append("## Referenced by")
        out.append("")
        for rel, src, note in inbound:
            out.append(f"- {_wikilink(src)} ({rel})")
        out.append("")
    return "\n".join(out)


def _write_persona(node: Node, graph: Graph) -> str:
    a = node.attributes
    persona_type = "Market persona" if a.get("is_market") else "Constraint persona (design stress-test)"

    out = [_frontmatter("Persona", {k: v for k, v in a.items() if not isinstance(v, dict)}), "", f"# {node.label}", ""]
    out.append(f"*{persona_type}*")
    out.append("")
    out.append(f"**Role:** {a.get('role', '')}  ")
    out.append(f"**Tech comfort:** {a.get('technical_comfort', '')}  ")
    out.append("")
    out.append("## Their words")
    out.append("")
    out.append(f"> {a.get('quote', '')}")
    out.append("")
    out.append("## What this persona breaks")
    out.append("")
    out.append(a.get("breaks", "Nothing specific."))
    out.append("")
    out.append("## Why this matters for design")
    out.append("")
    if "Rafael" in node.label:
        out.append("Rafael sets the bar for the hardest case. Low tech, cracked screen, standing at 6am. If the app works for him, it works for everyone. His scam history means we never use alarm-colour or countdown timers — ever.")
    elif "Marguerite" in node.label:
        out.append("Marguerite is not an edge case — she is the floor. If a target is too small for her, it annoys Dana too. Design for Marguerite and Dana gets a better product for free. No accessibility mode. The default IS accessible.")
    elif "Dana" in node.label:
        out.append("Dana is the primary market. She opens the app five times a month, under two minutes each. She needs an answer in one sentence, not a dashboard. Time spent > 2 minutes means the main flow failed.")
    elif "Wes" in node.label:
        out.append("Wes sets the depth floor. Every number must be tappable to its source. Export must be real and complete. He will trash the product in one sentence if the arithmetic is hidden.")
    out.append("")

    # Features linked to this persona
    inbound = _inbound_links(node.id, graph)
    feat_links = [(rel, src) for rel, src, _ in inbound if "feat_" in src]
    if feat_links:
        out.append("## Features built for this persona")
        out.append("")
        for _, src in feat_links:
            out.append(f"- {_wikilink(src)}")
        out.append("")
    return "\n".join(out)


def _write_ux_law(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("UXLaw", a), "", f"# {node.label}", ""]
    out.append(a.get("description", ""))
    out.append("")

    # Where it is applied in this product
    inbound = _inbound_links(node.id, graph)
    applied = [(rel, src) for rel, src, _ in inbound if rel in ("justifies", "appliesTo")]
    if applied:
        out.append("## Applied in this product")
        out.append("")
        for rel, src in applied:
            out.append(f"- {_wikilink(src)} ({rel})")
        out.append("")

    # Reference to full Laws of UX source
    out.append("## Reference")
    out.append("")
    out.append("Source: *Laws of UX* by Jon Yablonski (2020, O'Reilly). See also [lawsofux.com](https://lawsofux.com).")
    out.append("")
    return "\n".join(out)


def _write_deviation(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("Deviation", {k: v for k, v in a.items()}), "", f"# {node.label}", ""]
    out.append("This is a place where we break Apple's standard rules on purpose.")
    out.append("")
    out.append(f"**HIG default:** {a.get('hig_default', '')}  ")
    out.append(f"**Our rule:** {a.get('our_rule', '')}  ")
    out.append(f"**Why:** {a.get('why', '')}  ")
    out.append("")
    links = _outbound_links(node.id, graph)
    if links:
        out.append("## Justified by")
        out.append("")
        for rel, target, note in links:
            out.append(f"- {_wikilink(target)}")
        out.append("")
    return "\n".join(out)


def _write_design_token(node: Node, graph: Graph) -> str:
    a = node.attributes
    tokens = a.get("tokens", [])
    out = [f"---\ntype: DesignToken\ncategory: {a.get('category', '')}\n---", "", f"# {node.label}", ""]
    out.append(f"These are the **{a.get('category', '')} design tokens** for the product.")
    out.append("")
    if tokens:
        out.append("| Token | Value | Notes |")
        out.append("|---|---|---|")
        for t in tokens:
            out.append(f"| `{t.get('token','')}` | `{t.get('value','')}` | {t.get('notes','')} |")
        out.append("")
    out.append("## How to use")
    out.append("")
    cat = a.get("category", "")
    if cat == "typography":
        out.append("Use these size tokens, not raw pixel values. Always support Dynamic Type on iOS and font scaling on web. Body text is 19pt by default (HIG Deviation D4).")
    elif cat == "colour":
        out.append("Colour never carries bill status. Words do that. System blue means tappable — nothing else is blue. Red appears exactly once: on the delete confirm button.")
    elif cat == "spacing":
        out.append("Everything sits on an 8pt grid. Screen edge margin is 20px. Card padding is 20px. Minimum gap between tappable targets is 12px.")
    elif cat == "radius":
        out.append("Follow the concentric rule: inner radius + padding = outer radius. Bill cards use 16px. Sheets use 20px. Buttons are full capsule (9999px).")
    elif cat == "motion":
        out.append("Motion explains — it never decorates. No celebration animations. Processing shows real per-file progress. Honour prefers-reduced-motion absolutely.")
    out.append("")
    return "\n".join(out)


def _write_feature(node: Node, graph: Graph) -> str:
    a = node.attributes
    priority_note = {
        "MUST": "This feature MUST ship. Without it, the product does not work.",
        "SHOULD": "This feature is important but has workarounds. Plan for v1.1.",
        "COULD": "This is a nice-to-have. Build it if time and priority allow.",
        "WONT": "This feature is explicitly out of scope for this release.",
    }.get(a.get("priority", ""), "")

    out = [_frontmatter("Feature", {k: v for k, v in a.items() if not isinstance(v, list)}), "", f"# {node.label}", ""]
    out.append(f"**Priority:** {a.get('priority', '')} | **Complexity:** {a.get('complexity', '')} | **Release:** {a.get('release', 'Release 1')}  ")
    out.append("")
    out.append(f"*{priority_note}*")
    out.append("")
    out.append("## Why this matters")
    out.append("")
    out.append(a.get("user_value", ""))
    out.append("")

    # Linked personas
    persona_links = [(rel, tgt) for rel, tgt, _ in _outbound_links(node.id, graph) if "persona_" in tgt]
    if persona_links:
        out.append("## Personas served")
        out.append("")
        for _, pid in persona_links:
            out.append(f"- {_wikilink(pid)}")
        out.append("")

    # Linked UX law
    ux_links = [(rel, tgt) for rel, tgt, _ in _outbound_links(node.id, graph) if "ux_" in tgt]
    if ux_links:
        out.append("## UX law behind this")
        out.append("")
        for _, uid in ux_links:
            out.append(f"- {_wikilink(uid)}")
        out.append("")

    # Linked user stories
    story_links = [(rel, src) for rel, src, _ in _inbound_links(node.id, graph) if "story_" in src]
    if story_links:
        out.append("## User stories")
        out.append("")
        for _, sid in story_links:
            out.append(f"- {_wikilink(sid)}")
        out.append("")
    return "\n".join(out)


def _write_user_story(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("UserStory", {k: v for k, v in a.items() if not isinstance(v, list)}), "", f"# {node.label}", ""]
    out.append(f"**Priority:** {a.get('priority', '')} | **Complexity:** {a.get('complexity', '')}  ")
    out.append("")

    deps = a.get("dependencies", [])
    if deps:
        out.append("## Depends on")
        out.append("")
        for dep in deps:
            dep_nid = f"story_{dep.lower().replace('-', '_')}"
            out.append(f"- {_wikilink(dep_nid)}")
        out.append("")

    # Linked feature
    feat_links = [(rel, tgt) for rel, tgt, _ in _outbound_links(node.id, graph) if "feat_" in tgt]
    if feat_links:
        out.append("## Implements")
        out.append("")
        for _, fid in feat_links:
            out.append(f"- {_wikilink(fid)}")
        out.append("")
    return "\n".join(out)


def _write_security(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("SecurityItem", a), "", f"# {node.label}", ""]
    out.append(f"**Category:** {a.get('category', '')}  ")
    out.append(f"**Owner:** {a.get('owner', '')}  ")
    out.append("")
    out.append("## What to watch out for")
    out.append("")
    out.append(a.get("consideration", ""))
    out.append("")
    out.append("> **Note:** These items are identified, not solved. The architect owns the solution.")
    out.append("")

    outbound = _outbound_links(node.id, graph)
    if outbound:
        out.append("## Constrains")
        out.append("")
        for rel, tgt, note in outbound:
            out.append(f"- {_wikilink(tgt)} — {note or rel}")
        out.append("")
    return "\n".join(out)


def _write_pipeline(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("PipelineStage", a), "", f"# {node.label}", ""]
    out.append(f"**Engine:** {a.get('engine', '')}  ")
    out.append("")
    out.append("## What this stage does")
    out.append("")
    out.append(a.get("description", ""))
    out.append("")

    # Key rule for deterministic stages
    if "Deterministic" in a.get("engine", ""):
        out.append("> **Rule:** No language model is involved here. Code does the arithmetic. Models read images and write sentences — they never compute totals.")
        out.append("")

    # Next / previous stage links
    outbound = [(rel, tgt) for rel, tgt, _ in _outbound_links(node.id, graph) if "pipe_" in tgt]
    inbound = [(rel, src) for rel, src, _ in _inbound_links(node.id, graph) if "pipe_" in src]
    if inbound:
        out.append(f"**Previous:** {_wikilink(inbound[0][1])}  ")
    if outbound:
        out.append(f"**Next:** {_wikilink(outbound[0][1])}  ")
    out.append("")

    # Feature links
    feat_outbound = [(rel, tgt, note) for rel, tgt, note in _outbound_links(node.id, graph) if "feat_" in tgt]
    if feat_outbound:
        out.append("## Implements")
        out.append("")
        for _, fid, note in feat_outbound:
            out.append(f"- {_wikilink(fid)} — {note}")
        out.append("")
    return "\n".join(out)


def _write_code_practice(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("CodePractice", a), "", f"# {node.label}", ""]
    out.append(a.get("description", ""))
    out.append("")

    # Tech components this practice constrains
    outbound = [(rel, tgt) for rel, tgt, _ in _outbound_links(node.id, graph) if "tc_" in tgt]
    if outbound:
        out.append("## Applies to")
        out.append("")
        for _, tid in outbound:
            out.append(f"- {_wikilink(tid)}")
        out.append("")
    return "\n".join(out)


def _write_tech_component(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("TechComponent", a), "", f"# {node.label}", ""]
    out.append(f"**Layer:** {a.get('layer', '')}  ")
    out.append("")
    out.append(a.get("description", ""))
    out.append("")

    # Linked to
    outbound = [(rel, tgt, note) for rel, tgt, note in _outbound_links(node.id, graph) if "tc_" in tgt]
    if outbound:
        out.append("## Connects to")
        out.append("")
        for rel, tid, note in outbound:
            out.append(f"- {_wikilink(tid)} — {note or rel}")
        out.append("")

    # Code practices that govern this component
    cp_inbound = [(rel, src) for rel, src, _ in _inbound_links(node.id, graph) if "cp_" in src]
    if cp_inbound:
        out.append("## Governed by")
        out.append("")
        for _, cpid in cp_inbound:
            out.append(f"- {_wikilink(cpid)}")
        out.append("")
    return "\n".join(out)


def _write_flow(node: Node, graph: Graph) -> str:
    a = node.attributes
    out = [_frontmatter("Flow", a), "", f"# {node.label}", ""]

    # Stories mapped to this flow
    outbound = [(rel, tgt) for rel, tgt, _ in _outbound_links(node.id, graph) if "story_" in tgt]
    if outbound:
        out.append("## User stories in this flow")
        out.append("")
        for _, sid in outbound:
            out.append(f"- {_wikilink(sid)}")
        out.append("")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

WRITERS = {
    "Version":       _write_version,
    "Decision":      _write_decision,
    "Persona":       _write_persona,
    "UXLaw":         _write_ux_law,
    "Deviation":     _write_deviation,
    "DesignToken":   _write_design_token,
    "Feature":       _write_feature,
    "UserStory":     _write_user_story,
    "SecurityItem":  _write_security,
    "PipelineStage": _write_pipeline,
    "CodePractice":  _write_code_practice,
    "TechComponent": _write_tech_component,
    "Flow":          _write_flow,
}


def emit(graph: Graph) -> None:
    """Write all notes to disk."""

    # First pass: build id->title map so wikilinks resolve correctly
    global _id_to_title
    for node in graph.nodes:
        _id_to_title[node.id] = node.label

    # Create folders
    for folder in set(FOLDER_MAP.values()):
        (VAULT_DIR / folder).mkdir(parents=True, exist_ok=True)

    written = 0
    for node in graph.nodes:
        folder = FOLDER_MAP.get(node.entity_type, "Misc")
        folder_path = VAULT_DIR / folder
        folder_path.mkdir(parents=True, exist_ok=True)

        writer = WRITERS.get(node.entity_type)
        if writer is None:
            continue

        content = writer(node, graph)
        filename = _slug(node.label) + ".md"
        (folder_path / filename).write_text(content, encoding="utf-8")
        written += 1

    # Write index
    _write_index(graph)
    print(f"  ✓ Wrote {written} notes to {VAULT_DIR}")


def _write_index(graph: Graph) -> None:
    """Write _index.md — the vault home page."""
    counts: dict[str, int] = {}
    for node in graph.nodes:
        counts[node.entity_type] = counts.get(node.entity_type, 0) + 1

    lines = [
        "# Home Utility Bill Intelligence — Context Graph",
        "",
        "> This vault is the living knowledge graph for the project.",
        "> Open it in Obsidian and use the Graph View to explore relationships.",
        "",
        "## What's in here",
        "",
        "| Folder | Type | Count |",
        "|---|---|---|",
    ]
    for et, folder in sorted(FOLDER_MAP.items()):
        c = counts.get(et, 0)
        if c:
            lines.append(f"| `{folder}/` | {et} | {c} |")

    lines += [
        "",
        "## The product in one sentence",
        "",
        "> Take a photo of your utility bill and the app tells you,",
        "> in one sentence, whether this month is normal and why it changed.",
        "",
        "## Quick navigation",
        "",
        "- **Versions** → [[v1.0 — Local-first iOS]] | [[v2.0 — Cloud / Multi-platform]]",
        "- **Personas** → [[Rafael Ocampo]] | [[Marguerite Oyelaran]] | [[Dana Whitfield]] | [[Wes Tanaka]]",
        "- **Core features** → [[M1: Batch multi-file drop]] | [[M4: Extraction with confidence and provenance]] | [[M5: Arithmetic self-validation]] | [[M12: Change decomposition (R2)]] | [[M13: Anomaly flagging (R2)]]",
        "- **Stack** → [[Flutter]] | [[Supabase]] | [[Python FastAPI]] | [[OAuth 2.0]]",
        "- **Key UX laws** → [[Fitts's Law]] | [[Hick's Law]] | [[Miller's Law]] | [[Peak-End Rule]] | [[Tesler's Law]]",
        "",
        "## How to regenerate",
        "",
        "```bash",
        "python context-graph/build.py",
        "```",
        "",
        "This re-parses both source docs and rewrites all notes. It is idempotent.",
        "",
    ]
    (VAULT_DIR / "_index.md").write_text("\n".join(lines), encoding="utf-8")
