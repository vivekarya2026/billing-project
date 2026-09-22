# Context Graph — Home Utility Bill Intelligence

This folder holds the project's knowledge graph.
It was built by a Python agent from the source docs in `Intial Document/`.

---

## What's in here

```
context-graph/
├── graph_agent/           ← Python agent that builds the graph
│   ├── parse.py           ← reads source docs, returns structured sections
│   ├── extract.py         ← builds typed nodes + edges
│   ├── emit_obsidian.py   ← writes Obsidian vault notes
│   └── emit_mermaid.py    ← writes the Mermaid overview
├── vault/                 ← Obsidian vault (115 notes, [[wikilinks]])
│   ├── _index.md          ← home page — start here
│   ├── Versions/          ← v1.0 + v2.0 (the pivot)
│   ├── Decisions/         ← D1–D10 from the PRD
│   ├── Personas/          ← Rafael, Marguerite, Dana, Wes
│   ├── UX-Laws/           ← Fitts, Hick, Miller, Jakob, Tesler, Peak-End …
│   ├── Design/            ← HIG deviations + design tokens
│   ├── Features/          ← M1–M13, S1–S9, C1–C5
│   ├── Stories/           ← US-001 to US-020
│   ├── Security/          ← SEC-PM-001 to SEC-PM-007
│   ├── Pipeline/          ← Stage 0–7 (the AI pipeline)
│   ├── Code-Practices/    ← code rules for the whole project
│   ├── Tech-Stack/        ← Flutter, Supabase, FastAPI, OAuth …
│   └── Flows/             ← Flow 01–10 (user flows)
├── OVERVIEW.md            ← Mermaid diagram + entity counts
├── TECH-REQUIREMENTS.md   ← full tech plan for the v2 stack
├── build.py               ← entry point — run this to regenerate
└── graph.json             ← serialised graph (for inspection or tooling)
```

---

## How to open the graph in Obsidian

1. Open Obsidian
2. Click **Open another vault** → **Open folder as vault**
3. Select `context-graph/vault/`
4. Press **Cmd+G** (Mac) or **Ctrl+G** (Windows/Linux) to open **Graph View**

You will see all 115 notes connected by their relationships.

---

## How to regenerate

Run this from the project root whenever you change the source docs:

```bash
python3 context-graph/build.py
```

The script:
1. Parses `Intial Document/product-requirements.md` and `design-system-and-product.md`
2. Extracts 115 entities and 114 relationships
3. Writes one Obsidian note per entity with `[[wikilinks]]`
4. Writes `OVERVIEW.md` with a Mermaid diagram
5. Writes `graph.json` for programmatic use

It is **idempotent** — running it twice produces the same output.

---

## Requirements

- Python 3.9 or later (no extra packages needed — stdlib only)

---

## Graph stats

| Metric | Value |
|---|---|
| Total nodes | 115 |
| Total edges | 114 |
| Confidence threshold | 0.5 (edges below this are filtered) |
| Relation types | supersedes, justifies, constrains, implements, appliesTo, dependsOn, mappedToFlow, linkedTo |

---

## Key relationships to explore in Obsidian

- `Rafael Ocampo` → features that serve him → UX laws behind those features
- `v2.0 — Cloud / Multi-platform` → supersedes → `v1.0 — Local-first iOS`
- `M5: Arithmetic self-validation` → implements → `US-005` → justifies → `Tesler's Law`
- `Stage 2: Self-validation` → constrained by → `No Model Arithmetic` (code practice)
- `HIG Deviation D1` → justified by → `Fitts's Law`
- `SEC-PM-002` → constrains → `M11: Per-bill cloud consent`
