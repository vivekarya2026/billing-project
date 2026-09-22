"""
extract.py
----------
Takes ParsedDocs and produces a typed Graph (nodes + edges).

Entity types:
  Feature, Persona, UXLaw, DesignToken, DesignRule, Deviation,
  Decision, Flow, UserStory, SecurityItem, PipelineStage,
  Version, CodePractice, TechComponent

Relationship types:
  justifies, constrains, breaks, dependsOn, supersedes,
  appliesTo, implements, mappedToFlow, linkedTo

Each edge has a confidence score (0.0–1.0).
Edges below CONFIDENCE_THRESHOLD are filtered out.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional
from .parse import ParsedDocs

CONFIDENCE_THRESHOLD = 0.5


# ---------------------------------------------------------------------------
# Graph data model
# ---------------------------------------------------------------------------

@dataclass
class Node:
    id: str
    entity_type: str
    label: str
    attributes: dict = field(default_factory=dict)


@dataclass
class Edge:
    source: str
    target: str
    relation: str
    confidence: float = 1.0
    note: str = ""


@dataclass
class Graph:
    nodes: list[Node] = field(default_factory=list)
    edges: list[Edge] = field(default_factory=list)
    _node_ids: set = field(default_factory=set, repr=False)

    def add_node(self, node: Node) -> None:
        if node.id not in self._node_ids:
            self.nodes.append(node)
            self._node_ids.add(node.id)

    def add_edge(self, edge: Edge) -> None:
        if edge.confidence >= CONFIDENCE_THRESHOLD:
            self.edges.append(edge)

    def node_by_id(self, nid: str) -> Optional[Node]:
        for n in self.nodes:
            if n.id == nid:
                return n
        return None


# ---------------------------------------------------------------------------
# Known UX laws (static definitions)
# ---------------------------------------------------------------------------

UX_LAWS = [
    ("fitts", "Fitts's Law", "Larger, closer targets are faster to hit. Drives 60px minimum target."),
    ("hick", "Hick's Law", "More choices = more time to decide. Drives max 5 items per screen, 2 top-level choices."),
    ("miller", "Miller's Law", "Working memory holds ~7 items. Drives max 5 items per screen and chunked line items."),
    ("jakob", "Jakob's Law", "Users expect sites to work like other sites they know. Borrow bank-statement and text-message patterns."),
    ("tesler", "Tesler's Law", "Complexity can't be removed, only moved. We move it from user to system; depth always reachable."),
    ("peak_end", "Peak-End Rule", "People remember the peak and the end of an experience. Every flow ends on an answer, never a dashboard."),
    ("aesthetic", "Aesthetic-Usability Effect", "Polished design is perceived as more usable. Visual quality IS the trust signal here."),
    ("doherty", "Doherty Threshold", "Responses under 400ms eliminate user impatience. Capture-to-answer target is under 30 seconds."),
]

LAW_KEYWORD_MAP = {
    "fitts": ["fitts", "target size", "60px", "60pt", "touch target"],
    "hick": ["hick", "choices", "decision time", "top-level"],
    "miller": ["miller", "working memory", "5 items", "chunk"],
    "jakob": ["jakob", "mental model", "convention", "familiar"],
    "tesler": ["tesler", "complexity", "three registers", "one engine"],
    "peak_end": ["peak-end", "peak end", "memorable", "flow ends"],
    "aesthetic": ["aesthetic", "trust signal", "visual polish"],
    "doherty": ["doherty", "30 seconds", "threshold", "response time"],
}


# ---------------------------------------------------------------------------
# Static code practices
# ---------------------------------------------------------------------------

CODE_PRACTICES = [
    ("cp_global_css", "Global CSS / JS", "All design tokens live in one global CSS/JS file. Edit one place, change everywhere. No inline styles."),
    ("cp_fe_be_sep", "Frontend / Backend separation", "Frontend (Flutter) and backend (Supabase + FastAPI) are in separate top-level folders. They talk via HTTP/REST."),
    ("cp_flutter_theme", "Flutter Global Theme", "All HIG tokens (60px targets, 19pt body, no-status-colour) are declared in lib/theme/ and injected via ThemeData."),
    ("cp_python_ai", "Python for AI + Graphs", "The AI/OCR pipeline and the analytics dashboard are Python only. No model arithmetic — models narrate, code computes."),
    ("cp_no_model_math", "No Model Arithmetic", "Language models never compute bill totals. Deterministic Python code does arithmetic. Models only read images and write sentences."),
    ("cp_auth_bypass", "Auth Bypass for v1 Testing", "OAuth is wired but a BYPASS_AUTH env flag skips it so you can test without logging in."),
    ("cp_rls", "Supabase Row-Level Security", "Every table has RLS enabled. A user only reads rows where user_id matches their JWT."),
    ("cp_provenance", "Provenance by default", "Every extracted field stores a confidence score and a bounding-box region referencing the source image. Nothing displayed without a source."),
]

TECH_COMPONENTS = [
    ("tc_flutter", "Flutter", "frontend", "Single codebase for Web, iOS, and Android. Renders Apple-HIG-inspired UI via custom ThemeData."),
    ("tc_supabase", "Supabase", "backend", "Postgres + Auth + Storage. Handles user accounts, bill data, image storage, and real-time sync."),
    ("tc_fastapi", "Python FastAPI", "ai-service", "REST microservice for OCR (image-to-text), bill parsing, and deterministic self-validation engine."),
    ("tc_oauth", "OAuth 2.0", "auth", "Google + Apple sign-in via Supabase Auth. Bypassed with BYPASS_AUTH flag in v1 for local testing."),
    ("tc_ocr", "PaddleOCR / Tesseract", "ai-service", "Extracts raw text + bounding boxes from bill images. Feeds the bill-parsing AI layer."),
    ("tc_plotly", "Plotly / Streamlit", "ai-service", "Python dashboard for spend decomposition and usage analysis graphs."),
    ("tc_shadcn_tokens", "shadcn Design Tokens", "frontend", "Token vocabulary (radius, spacing, colour, motion) translated into Flutter ThemeData and global CSS variables for web."),
]


# ---------------------------------------------------------------------------
# Builder
# ---------------------------------------------------------------------------

def build_graph(docs: ParsedDocs) -> Graph:
    g = Graph()

    # ── Version nodes ────────────────────────────────────────────────────────
    g.add_node(Node("ver_1_0", "Version", "v1.0 — Local-first iOS", {
        "date": "2026-09-17",
        "status": "approved",
        "summary": "Original architecture: native iOS, no backend, no account, on-device models.",
    }))
    g.add_node(Node("ver_2_0", "Version", "v2.0 — Cloud / Multi-platform", {
        "date": "2026-09-17",
        "status": "active",
        "summary": "Pivot: Flutter web+iOS+Android, Supabase, OAuth, Python FastAPI AI service.",
    }))
    g.add_edge(Edge("ver_2_0", "ver_1_0", "supersedes", 1.0,
                    "Supersedes D7 (local-first), no-web-app, and no-account decisions"))

    # ── Decisions ────────────────────────────────────────────────────────────
    for dec in docs.decisions:
        nid = f"dec_{dec.id.lower()}"
        g.add_node(Node(nid, "Decision", f"{dec.id}: {dec.decision[:60]}", {
            "id": dec.id,
            "decision": dec.decision,
            "rationale": dec.rationale,
            "made_by": dec.made_by,
            "superseded_by_v2": dec.id in ("D7",),
        }))
    # Mark D7 as superseded
    d7 = g.node_by_id("dec_d7")
    if d7:
        g.add_edge(Edge("ver_2_0", "dec_d7", "supersedes", 1.0, "Pivot from local-first to Supabase cloud"))

    # ── Personas ─────────────────────────────────────────────────────────────
    persona_id_map = {
        "Rafael Ocampo": "persona_rafael",
        "Marguerite Oyelaran": "persona_marguerite",
        "Dana Whitfield": "persona_dana",
        "Wes Tanaka": "persona_wes",
    }
    for p in docs.personas:
        pid = persona_id_map.get(p.name, f"persona_{p.name.split()[0].lower()}")
        g.add_node(Node(pid, "Persona", p.name, {
            "role": p.role,
            "technical_comfort": p.comfort,
            "quote": p.quote,
            "breaks": p.breaks,
            "is_market": p.name in ("Dana Whitfield", "Wes Tanaka"),
            "is_constraint": p.name in ("Rafael Ocampo", "Marguerite Oyelaran"),
        }))

    # ── UX Laws ──────────────────────────────────────────────────────────────
    for law_id, law_name, law_desc in UX_LAWS:
        g.add_node(Node(f"ux_{law_id}", "UXLaw", law_name, {
            "description": law_desc,
        }))

    # ── Design Deviations ────────────────────────────────────────────────────
    deviation_ux_map = {
        "D1": "ux_fitts",     # 60px target
        "D2": "ux_aesthetic", # no red for status
        "D3": "ux_hick",      # no tab bar
        "D4": "ux_miller",    # 19pt body
    }
    for dev in docs.deviations:
        did_clean = dev.id.strip().lstrip("*").rstrip("*").strip()
        nid = f"dev_{did_clean.lower()}"
        g.add_node(Node(nid, "Deviation", f"HIG Deviation {did_clean}", {
            "id": did_clean,
            "hig_default": dev.hig_default,
            "our_rule": dev.our_rule,
            "why": dev.why,
        }))
        # Link deviation to the UX law that motivated it
        ux_target = deviation_ux_map.get(did_clean)
        if ux_target:
            g.add_edge(Edge(nid, ux_target, "justifies", 0.95,
                            f"Deviation {did_clean} is justified by {ux_target}"))

    # ── Design Tokens ────────────────────────────────────────────────────────
    token_categories = {}
    for tok in docs.design_tokens:
        cat_id = f"dt_{tok.category}"
        if cat_id not in token_categories:
            g.add_node(Node(cat_id, "DesignToken", f"Tokens: {tok.category}", {
                "category": tok.category,
                "tokens": [],
            }))
            token_categories[cat_id] = g.node_by_id(cat_id)
        node = token_categories[cat_id]
        if node:
            node.attributes["tokens"].append({"token": tok.token, "value": tok.value, "notes": tok.notes})

    # ── Features ─────────────────────────────────────────────────────────────
    # Hard-coded full feature list from PRD (parser may miss some rows)
    ALL_FEATURES = [
        ("M1", "MUST", "Batch multi-file drop", "Solves cold start. Drop 12 months, get a baseline before first use.", "M"),
        ("M2", "MUST", "Per-file triage and classification", "Identifies provider, service, period, account, duplicates.", "M"),
        ("M3", "MUST", "Guided capture UI", "On-device extraction depends on image quality.", "M"),
        ("M4", "MUST", "Extraction with confidence and provenance", "Turns unreadable document into structured data.", "L"),
        ("M5", "MUST", "Arithmetic self-validation", "Line items must sum to total; usage × rate = energy charge.", "M"),
        ("M6", "MUST", "Targeted confirmation", "Ask only about fields that failed validation.", "S"),
        ("M7", "MUST", "Bill-type classification", "Detects budget billing, estimated reads, arrears, solar credits.", "M"),
        ("M8", "MUST", "Unified due view", "One screen, all providers, what is owed and when.", "S"),
        ("M9", "MUST", "Provenance and audit trail", "Every number traceable to the pixel it was read from.", "M"),
        ("M10", "MUST", "Encrypted local backup and restore", "No server means device loss is total loss.", "M"),
        ("M11", "MUST", "Per-bill cloud consent", "The L2 promise: user controls what leaves the device.", "S"),
        ("M12", "MUST", "Change decomposition (R2)", "Splits bill delta into rate, usage, fixed, one-offs.", "L"),
        ("M13", "MUST", "Anomaly flagging (R2)", "Flags components outside expected bounds, with phone script.", "M"),
        ("S1", "SHOULD", "Plan and contract change detection", "Catches expired supply contracts.", "M"),
        ("S2", "SHOULD", "Due date reminders", "Prevents the late fee.", "S"),
        ("S3", "SHOULD", "Export (CSV and JSON)", "Wes will not commit without it.", "S"),
        ("S4", "SHOULD", "Output language setting", "Rafael reads Spanish; bills stay in English.", "S"),
        ("S5", "SHOULD", "Assistance programme surfacing", "Surfaces help programmes for users with arrears.", "M"),
        ("S6", "SHOULD", "Corrected bill versioning", "Re-issued bill supersedes original without losing it.", "S"),
        ("S7", "SHOULD", "Grounded conversation", "Wes's escape hatch: AI answers from extracted data only.", "M"),
        ("S8", "SHOULD", "Report generation and export", "Wes's artifact.", "S"),
        ("S9", "SHOULD", "Register switching", "One engine, three levels of detail.", "M"),
        ("C1", "COULD", "Utility account connect", "Green Button proof of concept.", "L"),
        ("C2", "COULD", "Smart meter ingest", "Reconciles interval data against what was billed.", "M"),
        ("C3", "COULD", "Voice input and output", "Universal design payoff.", "M"),
        ("C4", "COULD", "Household sharing and sync", "Explicitly deferred.", "L"),
        ("C5", "COULD", "Full solar and net metering support", "MVP detects and flags only.", "L"),
    ]

    persona_feature_map = {
        "M1": ["persona_dana", "persona_wes"],
        "M3": ["persona_rafael"],
        "M4": ["persona_wes"],
        "M5": ["persona_dana"],
        "M6": ["persona_dana"],
        "M8": ["persona_marguerite", "persona_dana"],
        "M9": ["persona_wes"],
        "M10": ["persona_marguerite"],
        "M11": ["persona_marguerite", "persona_wes"],
        "M12": ["persona_dana", "persona_wes"],
        "M13": ["persona_dana"],
        "S3": ["persona_wes"],
        "S4": ["persona_rafael"],
        "S5": ["persona_rafael", "persona_marguerite"],
        "S7": ["persona_wes"],
        "C2": ["persona_wes"],
        "C4": ["persona_wes"],
    }

    feature_ux_map = {
        "M1": "ux_miller",
        "M3": "ux_fitts",
        "M5": "ux_tesler",
        "M6": "ux_hick",
        "M8": "ux_miller",
        "M9": "ux_aesthetic",
        "M12": "ux_peak_end",
        "M13": "ux_peak_end",
        "S2": "ux_jakob",
        "S7": "ux_tesler",
    }

    for (fid, pri, name, value, complexity) in ALL_FEATURES:
        nid = f"feat_{fid.lower()}"
        release = "Release 2" if fid in ("M12", "M13") else "Release 1"
        g.add_node(Node(nid, "Feature", f"{fid}: {name}", {
            "id": fid,
            "priority": pri,
            "name": name,
            "user_value": value,
            "complexity": complexity,
            "release": release,
        }))
        # Link to personas
        for pid in persona_feature_map.get(fid, []):
            g.add_edge(Edge(nid, pid, "appliesTo", 0.9))
        # Link to UX law
        ux_lid = feature_ux_map.get(fid)
        if ux_lid:
            g.add_edge(Edge(nid, ux_lid, "justifies", 0.85))

    # ── User Stories ─────────────────────────────────────────────────────────
    story_feature_map = {
        "US-001": "feat_m1", "US-002": "feat_m2", "US-003": "feat_m3",
        "US-004": "feat_m4", "US-005": "feat_m5", "US-006": "feat_m6",
        "US-007": "feat_m7", "US-008": "feat_m8", "US-009": "feat_m9",
        "US-010": "feat_m10", "US-011": "feat_m11",
        "US-012": "feat_m12", "US-013": "feat_m13",
        "US-014": "feat_s1", "US-015": "feat_s2", "US-016": "feat_s3",
        "US-017": "feat_s4", "US-018": "feat_s5", "US-019": "feat_s6",
        "US-020": "feat_s7",
    }
    for story in docs.user_stories:
        nid = f"story_{story.id.lower().replace('-', '_')}"
        g.add_node(Node(nid, "UserStory", f"{story.id}: {story.title}", {
            "id": story.id,
            "title": story.title,
            "priority": story.priority,
            "complexity": story.complexity,
            "dependencies": story.dependencies,
            "summary": story.summary,
        }))
        feat_target = story_feature_map.get(story.id)
        if feat_target:
            g.add_edge(Edge(nid, feat_target, "implements", 1.0))
        for dep in story.dependencies:
            dep_nid = f"story_{dep.lower().replace('-', '_')}"
            g.add_edge(Edge(nid, dep_nid, "dependsOn", 1.0))

    # ── Pipeline Stages ──────────────────────────────────────────────────────
    PIPELINE = [
        (0, "Triage", "Is this a bill, which provider, period, account, duplicate?", "On-device model"),
        (1, "Extraction", "Structured line items, per-field confidence, bounding region on source", "Vision OCR + on-device model"),
        (2, "Self-validation", "Does the arithmetic close? Deterministic only.", "Deterministic code — no model"),
        (3, "Classification", "Budget billing, estimated read, solar, arrears, mid-cycle rate change", "On-device model + rules"),
        (4, "Reconciliation", "Dedupe, timeline, account identity, invalid comparison windows", "Deterministic code"),
        (5, "Analysis", "Normalise per day, compare like-to-like, decompose delta", "Deterministic code — no model"),
        (6, "Narration", "State the computed result once, clearly, at the right register", "On-device model"),
        (7, "Conversation", "Answer questions grounded in extracted data only", "On-device model"),
    ]

    prev_stage_id = None
    for (num, name, desc, engine) in PIPELINE:
        nid = f"pipe_{num}"
        g.add_node(Node(nid, "PipelineStage", f"Stage {num}: {name}", {
            "stage": num,
            "name": name,
            "description": desc,
            "engine": engine,
        }))
        if prev_stage_id:
            g.add_edge(Edge(prev_stage_id, nid, "linkedTo", 1.0, "pipeline sequence"))
        prev_stage_id = nid

    # Link key pipeline stages to features
    g.add_edge(Edge("pipe_2", "feat_m5", "implements", 0.95, "Self-validation implements arithmetic check"))
    g.add_edge(Edge("pipe_1", "feat_m4", "implements", 0.95, "Extraction stage implements provenance"))
    g.add_edge(Edge("pipe_5", "feat_m12", "implements", 0.9, "Analysis stage implements change decomposition"))
    g.add_edge(Edge("pipe_3", "feat_m7", "implements", 0.9, "Classification stage implements bill-type detection"))

    # ── Security Items ───────────────────────────────────────────────────────
    for sec in docs.security_items:
        nid = f"sec_{sec.id.lower().replace('-', '_')}"
        g.add_node(Node(nid, "SecurityItem", sec.id, {
            "id": sec.id,
            "category": sec.category,
            "consideration": sec.consideration,
            "owner": sec.owner,
        }))
    # Specific cross-links
    g.add_edge(Edge("sec_sec_pm_001", "feat_m4", "constrains", 0.9, "Bill PII constrains extraction storage"))
    g.add_edge(Edge("sec_sec_pm_002", "feat_m11", "constrains", 0.95, "Cloud consent constrains fallback"))
    g.add_edge(Edge("sec_sec_pm_003", "ver_2_0", "constrains", 0.9, "Server components need re-approval per SEC-PM-003"))
    g.add_edge(Edge("sec_sec_pm_007", "feat_m10", "constrains", 0.95, "Encrypted backup key handling"))

    # ── Flows ────────────────────────────────────────────────────────────────
    flow_story_map = {
        "01": ["story_us_001"],
        "03": ["story_us_001", "story_us_002"],
        "05": ["story_us_003", "story_us_004"],
        "07": ["story_us_005", "story_us_006", "story_us_011"],
        "08": ["story_us_012", "story_us_013"],
    }
    for flow in docs.flows:
        nid = f"flow_{flow.id}"
        g.add_node(Node(nid, "Flow", f"Flow {flow.id}: {flow.title}", {
            "id": flow.id,
            "title": flow.title,
        }))
        for story_id in flow_story_map.get(flow.id, []):
            g.add_edge(Edge(nid, story_id, "mappedToFlow", 0.85))

    # ── Code Practices ───────────────────────────────────────────────────────
    for (cpid, name, desc) in CODE_PRACTICES:
        g.add_node(Node(cpid, "CodePractice", name, {"description": desc}))

    # ── Tech Components ──────────────────────────────────────────────────────
    for (tcid, name, layer, desc) in TECH_COMPONENTS:
        g.add_node(Node(tcid, "TechComponent", name, {"layer": layer, "description": desc}))

    # Tech relationships
    g.add_edge(Edge("tc_flutter", "tc_supabase", "linkedTo", 1.0, "Flutter calls Supabase for data/auth"))
    g.add_edge(Edge("tc_flutter", "tc_fastapi", "linkedTo", 1.0, "Flutter calls FastAPI for AI/OCR"))
    g.add_edge(Edge("tc_fastapi", "tc_ocr", "linkedTo", 1.0, "FastAPI orchestrates OCR"))
    g.add_edge(Edge("tc_fastapi", "tc_supabase", "linkedTo", 0.9, "FastAPI writes extraction results to Supabase"))
    g.add_edge(Edge("tc_oauth", "tc_supabase", "linkedTo", 1.0, "OAuth managed by Supabase Auth"))
    g.add_edge(Edge("tc_flutter", "tc_shadcn_tokens", "appliesTo", 0.9, "shadcn token vocabulary translated into Flutter ThemeData"))

    # Code practice → tech
    g.add_edge(Edge("cp_fe_be_sep", "tc_flutter", "constrains", 0.9))
    g.add_edge(Edge("cp_fe_be_sep", "tc_supabase", "constrains", 0.9))
    g.add_edge(Edge("cp_fe_be_sep", "tc_fastapi", "constrains", 0.9))
    g.add_edge(Edge("cp_python_ai", "tc_fastapi", "justifies", 1.0))
    g.add_edge(Edge("cp_python_ai", "tc_plotly", "justifies", 1.0))
    g.add_edge(Edge("cp_no_model_math", "pipe_2", "constrains", 1.0, "Validation must be deterministic code"))
    g.add_edge(Edge("cp_auth_bypass", "tc_oauth", "linkedTo", 1.0))
    g.add_edge(Edge("cp_rls", "tc_supabase", "constrains", 1.0))
    g.add_edge(Edge("cp_provenance", "feat_m9", "implements", 0.95))

    # Version → tech
    g.add_edge(Edge("ver_2_0", "tc_flutter", "justifies", 1.0))
    g.add_edge(Edge("ver_2_0", "tc_supabase", "justifies", 1.0))
    g.add_edge(Edge("ver_2_0", "tc_fastapi", "justifies", 1.0))

    return g
