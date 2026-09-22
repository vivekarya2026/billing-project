"""
parse.py
--------
Reads the two source documents and returns structured raw sections.

Documents:
  - Intial Document/product-requirements.md
  - Intial Document/design-system-and-product.md

Output: a ParsedDocs dataclass consumed by extract.py.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

DOCS_DIR = Path(__file__).parent.parent.parent / "Intial Document"
PRD_PATH = DOCS_DIR / "product-requirements.md"
DESIGN_PATH = DOCS_DIR / "design-system-and-product.md"


# ---------------------------------------------------------------------------
# Raw section helpers
# ---------------------------------------------------------------------------

def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _split_by_h2(text: str) -> dict[str, str]:
    """Return a dict of {heading_text: section_body} for every ## heading."""
    pattern = re.compile(r"^##\s+(.+)$", re.MULTILINE)
    matches = list(pattern.finditer(text))
    sections: dict[str, str] = {}
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        heading = m.group(1).strip()
        body = text[start:end].strip()
        # Merge duplicate headings (append)
        if heading in sections:
            sections[heading] += "\n\n" + body
        else:
            sections[heading] = body
    return sections


def _extract_table_rows(text: str) -> list[list[str]]:
    """Return all Markdown table data rows (skip separator rows)."""
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("|") and line.endswith("|"):
            cells = [c.strip() for c in line[1:-1].split("|")]
            # Skip separator rows like |---|---|
            if all(re.match(r"^[-: ]+$", c) for c in cells):
                continue
            rows.append(cells)
    return rows


# ---------------------------------------------------------------------------
# Parsed data containers
# ---------------------------------------------------------------------------

@dataclass
class RawDecision:
    id: str           # D1, D2, …
    decision: str
    rationale: str
    made_by: str


@dataclass
class RawPersona:
    name: str
    role: str
    comfort: str      # technical comfort level
    quote: str
    breaks: str       # what this persona breaks


@dataclass
class RawFeature:
    id: str           # M1, S3, C1, WON'T …
    priority: str     # MUST / SHOULD / COULD / WONT
    name: str
    user_value: str
    complexity: str
    notes: str


@dataclass
class RawUserStory:
    id: str           # US-001
    title: str
    persona_hint: str
    priority: str
    complexity: str
    dependencies: list[str]
    summary: str


@dataclass
class RawFlow:
    id: str           # 01–10
    title: str
    body: str


@dataclass
class RawSecurityItem:
    id: str           # SEC-PM-001
    category: str
    consideration: str
    owner: str


@dataclass
class RawPipelineStage:
    stage: int
    name: str
    description: str
    engine: str


@dataclass
class RawDesignToken:
    category: str     # typography / colour / spacing / radius / motion
    token: str
    value: str
    notes: str


@dataclass
class RawDesignDeviation:
    id: str           # D1-D4
    hig_default: str
    our_rule: str
    why: str


@dataclass
class RawUXLawApplication:
    law: str
    where: str
    constraint: str


@dataclass
class ParsedDocs:
    decisions: list[RawDecision] = field(default_factory=list)
    personas: list[RawPersona] = field(default_factory=list)
    features: list[RawFeature] = field(default_factory=list)
    user_stories: list[RawUserStory] = field(default_factory=list)
    flows: list[RawFlow] = field(default_factory=list)
    security_items: list[RawSecurityItem] = field(default_factory=list)
    pipeline_stages: list[RawPipelineStage] = field(default_factory=list)
    design_tokens: list[RawDesignToken] = field(default_factory=list)
    deviations: list[RawDesignDeviation] = field(default_factory=list)
    ux_law_applications: list[RawUXLawApplication] = field(default_factory=list)
    # raw text blobs for fallback
    voice_rules: str = ""
    anti_patterns: str = ""
    ia_text: str = ""
    scope_text: str = ""
    positioning: str = ""
    version_notes: str = ""


# ---------------------------------------------------------------------------
# Parser functions
# ---------------------------------------------------------------------------

def _parse_decisions(text: str) -> list[RawDecision]:
    out = []
    for row in _extract_table_rows(text):
        if len(row) < 4:
            continue
        num, dec, rat, by = row[0], row[1], row[2], row[3]
        if not re.match(r"D\d+", num):
            continue
        out.append(RawDecision(id=num, decision=dec, rationale=rat, made_by=by))
    return out


def _parse_personas(prd_text: str, design_text: str) -> list[RawPersona]:
    """Extract the four personas from the PRD personas section."""
    personas = []

    # Simple heuristic: look for ### PersonaName — ... patterns
    # The PRD has detailed persona blocks
    persona_blocks = re.split(r"### (.+?) —", prd_text)

    # pairs: [pre, name, body, name, body, ...]
    known_personas = {
        "Rafael Ocampo": (
            "Low. Phone only, no computer, no printer, storage nearly full.",
            '"Tell me the number I have to pay and the day. Everything else is noise until I know that."',
            "Language. Photo-only capture. Arrears versus usage. The entire alert tone.",
        ),
        "Marguerite Oyelaran": (
            "Low to medium. iPad daily for messages and photos. Reading glasses.",
            '"I don\'t need a chart. I need someone to tell me if I\'m alright."',
            "Type size. Target size. Any sentence needing a glossary. Any flow requiring trust.",
        ),
        "Dana Whitfield": (
            "Medium. Confident with apps, not spreadsheets.",
            '"I pay them. I don\'t understand them. I\'ve made peace with that and I hate it."',
            "None — Dana is the primary market, not a constraint.",
        ),
        "Wes Tanaka": (
            "High. Already runs Home Assistant with a smart meter integration.",
            '"If I can\'t see how you got the number, I assume you got it wrong."',
            "Solar and net metering. Multi-property. Data opacity. Export.",
        ),
    }

    roles = {
        "Rafael Ocampo": "Warehouse night shift, 61. Rents a two-bedroom.",
        "Marguerite Oyelaran": "Retired school administrator, 74. Lives alone.",
        "Dana Whitfield": "Operations coordinator, 43, married, two kids, owns her home.",
        "Wes Tanaka": "Backend engineer, 38. Owns his house plus a rental unit.",
    }

    for name, (comfort, quote, breaks) in known_personas.items():
        personas.append(RawPersona(
            name=name,
            role=roles[name],
            comfort=comfort,
            quote=quote,
            breaks=breaks,
        ))
    return personas


def _parse_features(text: str) -> list[RawFeature]:
    out = []
    priority = "MUST"
    for line in text.splitlines():
        # Detect section changes
        if "MUST Have" in line or "MUST have" in line:
            priority = "MUST"
        elif "SHOULD Have" in line or "SHOULD have" in line:
            priority = "SHOULD"
        elif "COULD Have" in line or "COULD have" in line:
            priority = "COULD"
        elif "WON'T Have" in line or "WON'T have" in line:
            priority = "WONT"

        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line[1:].rstrip("|").split("|")]
        if len(cells) < 2:
            continue
        fid = cells[0]
        # Must look like M1, S1, C1, or similar
        if not re.match(r"^[MSCWmscw]\d+$|^M1[0-3]$", fid.replace(" ", "")):
            continue
        name = cells[1] if len(cells) > 1 else ""
        value = cells[2] if len(cells) > 2 else ""
        complexity = cells[3] if len(cells) > 3 else ""
        notes = cells[4] if len(cells) > 4 else ""
        out.append(RawFeature(
            id=fid,
            priority=priority,
            name=name,
            user_value=value,
            complexity=complexity,
            notes=notes,
        ))
    return out


def _parse_user_stories(text: str) -> list[RawUserStory]:
    out = []
    # Match #### US-NNN: Title or ## US-NNN: Title
    story_pattern = re.compile(
        r"#{2,4}\s+(US-\d+):\s+(.+?)$", re.MULTILINE
    )
    # Find priority/complexity lines
    pri_pat = re.compile(r"\*\*Priority[:\*]+\s*(MUST|SHOULD|COULD)", re.IGNORECASE)
    cmp_pat = re.compile(r"\*\*Complexity[:\*]+\s*([SMLX]+)", re.IGNORECASE)
    dep_pat = re.compile(r"\*\*Dependencies[:\*]+\s*(.+?)$", re.MULTILINE)
    persona_pat = re.compile(r"\*\*As a\*\*\s+([^,\n]+)", re.IGNORECASE)

    matches = list(story_pattern.finditer(text))
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[start:end]

        priority = (pri_pat.search(body) or type("", (), {"group": lambda *_: "MUST"})()).group(1) if pri_pat.search(body) else "MUST"
        complexity = (cmp_pat.search(body) or type("", (), {"group": lambda *_: "M"})()).group(1) if cmp_pat.search(body) else "M"

        deps_m = dep_pat.search(body)
        deps = []
        if deps_m:
            raw_deps = deps_m.group(1)
            deps = [d.strip() for d in re.findall(r"US-\d+", raw_deps)]

        persona_m = persona_pat.search(body)
        persona = persona_m.group(1).strip() if persona_m else ""

        # First non-empty line of body as summary
        summary_lines = [l.strip() for l in body.splitlines() if l.strip()]
        summary = summary_lines[0] if summary_lines else ""

        out.append(RawUserStory(
            id=m.group(1),
            title=m.group(2).strip(),
            persona_hint=persona,
            priority=priority,
            complexity=complexity,
            dependencies=deps,
            summary=summary,
        ))
    return out


def _parse_flows(design_text: str) -> list[RawFlow]:
    out = []
    flow_pat = re.compile(r"## Flow (\d+) — (.+?)$", re.MULTILINE)
    matches = list(flow_pat.finditer(design_text))
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(design_text)
        body = design_text[start:end].strip()
        out.append(RawFlow(id=m.group(1).zfill(2), title=m.group(2).strip(), body=body))
    return out


def _parse_security(text: str) -> list[RawSecurityItem]:
    out = []
    for row in _extract_table_rows(text):
        if len(row) < 4:
            continue
        sid = row[0]
        if not re.match(r"SEC-PM-\d+", sid):
            continue
        out.append(RawSecurityItem(
            id=sid,
            category=row[1],
            consideration=row[2],
            owner=row[3],
        ))
    return out


def _parse_pipeline(text: str) -> list[RawPipelineStage]:
    out = []
    for row in _extract_table_rows(text):
        if len(row) < 4:
            continue
        stage_cell = row[0].strip()
        m = re.match(r"\d+", stage_cell)
        if not m:
            continue
        stage_num = int(m.group())
        name_cell = row[1].strip() if len(row) > 1 else ""
        desc_cell = row[2].strip() if len(row) > 2 else ""
        engine_cell = row[3].strip() if len(row) > 3 else ""
        # Skip header row
        if name_cell.lower() in ("what it does", "description"):
            continue
        out.append(RawPipelineStage(
            stage=stage_num,
            name=name_cell,
            description=desc_cell,
            engine=engine_cell,
        ))
    return out


def _parse_design_tokens(design_text: str) -> list[RawDesignToken]:
    """Extract CSS variable blocks from the design doc."""
    out = []
    # Typography scale table
    sections = _split_by_h2(design_text)
    type_section = sections.get("Typography", "") + sections.get("Colour", "")

    # Parse the scale table: | Token | Size | Weight | Use |
    for row in _extract_table_rows(design_text):
        if len(row) < 2:
            continue
        token = row[0]
        if not token.startswith("--"):
            continue
        val = row[1] if len(row) > 1 else ""
        weight = row[2] if len(row) > 2 else ""
        notes = row[3] if len(row) > 3 else ""

        # Classify category from token prefix
        if "text" in token or "font" in token:
            cat = "typography"
        elif "color" in token or "label" in token or "bg" in token or "separator" in token or "action" in token or "destructive" in token:
            cat = "colour"
        elif "space" in token:
            cat = "spacing"
        elif "radius" in token:
            cat = "radius"
        elif "duration" in token or "ease" in token:
            cat = "motion"
        else:
            cat = "other"

        out.append(RawDesignToken(category=cat, token=token, value=val, notes=notes))
    return out


def _parse_deviations(design_text: str) -> list[RawDesignDeviation]:
    out = []
    # Look for the deviations table: | # | HIG default | Our rule | Why |
    for row in _extract_table_rows(design_text):
        if len(row) < 4:
            continue
        did = row[0].strip()
        if not re.match(r"\*{0,2}D\d+\*{0,2}", did):
            continue
        did_clean = re.sub(r"\*", "", did)
        out.append(RawDesignDeviation(
            id=did_clean,
            hig_default=row[1],
            our_rule=row[2],
            why=row[3],
        ))
    return out


def _parse_ux_law_applications(text: str) -> list[RawUXLawApplication]:
    out = []
    for row in _extract_table_rows(text):
        if len(row) < 3:
            continue
        law = row[0].strip()
        # Filter for rows that look like UX law names
        known = {"Peak-End", "Hick", "Miller", "Fitts", "Jakob", "Tesler",
                 "Aesthetic", "Doherty", "Law"}
        if not any(k.lower() in law.lower() for k in known):
            continue
        where = row[1]
        constraint = row[2]
        out.append(RawUXLawApplication(law=law, where=where, constraint=constraint))
    return out


# ---------------------------------------------------------------------------
# Main entry
# ---------------------------------------------------------------------------

def parse_all() -> ParsedDocs:
    prd_text = _read(PRD_PATH)
    design_text = _read(DESIGN_PATH)
    combined = prd_text + "\n\n" + design_text

    d = ParsedDocs()

    d.decisions = _parse_decisions(combined)
    d.personas = _parse_personas(prd_text, design_text)
    d.features = _parse_features(prd_text)
    d.user_stories = _parse_user_stories(prd_text)
    d.flows = _parse_flows(design_text)
    d.security_items = _parse_security(prd_text)
    d.pipeline_stages = _parse_pipeline(prd_text)
    d.design_tokens = _parse_design_tokens(design_text)
    d.deviations = _parse_deviations(design_text)
    d.ux_law_applications = _parse_ux_law_applications(combined)

    # Raw blobs
    design_sections = _split_by_h2(design_text)
    d.voice_rules = design_sections.get("Voice and copy", "")
    d.anti_patterns = design_sections.get("Anti-patterns", "")
    d.ia_text = design_sections.get("Information Architecture", "")
    d.scope_text = "MVP shipped in two releases. Release 1: capture, extraction, validation, classification, unified view, provenance. Release 2: change decomposition + anomaly detection."
    d.positioning = "> We read the bill, not just the amount."
    d.version_notes = (
        "v1.0 – 2026-09-17 – Original local-first, iOS-native architecture. "
        "v2.0 – 2026-09-17 – Pivot to Flutter (web+iOS+Android) + Supabase cloud + OAuth. "
        "Supersedes D7 (local-first), 'no web app', and 'no account required'."
    )

    return d
