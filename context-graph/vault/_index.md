# Home Utility Bill Intelligence — Context Graph

> This vault is the living knowledge graph for the project.
> Open it in Obsidian and use the Graph View to explore relationships.

## What's in here

| Folder | Type | Count |
|---|---|---|
| `Code-Practices/` | CodePractice | 10 |
| `Decisions/` | Decision | 10 |
| `Design/` | Deviation | 4 |
| `Features/` | Feature | 30 |
| `Flows/` | Flow | 10 |
| `Personas/` | Persona | 4 |
| `Pipeline/` | PipelineStage | 8 |
| `Security/` | SecurityItem | 7 |
| `Tech-Stack/` | TechComponent | 7 |
| `UX-Laws/` | UXLaw | 8 |
| `Stories/` | UserStory | 20 |
| `Versions/` | Version | 2 |

## The product in one sentence

> Take a photo of your utility bill and the app tells you,
> in one sentence, whether this month is normal and why it changed.

## Quick navigation

- **Versions** → [[v1.0 — Local-first iOS]] | [[v2.0 — Cloud / Multi-platform]]
- **Personas** → [[Rafael Ocampo]] | [[Marguerite Oyelaran]] | [[Dana Whitfield]] | [[Wes Tanaka]]
- **Core features** → [[M1: Batch multi-file drop]] | [[M4: Extraction with confidence and provenance]] | [[M5: Arithmetic self-validation]] | [[M12: Change decomposition (R2)]] | [[M13: Anomaly flagging (R2)]]
- **Post-pivot additions** → [[M14: Manual quick entry]] | [[M15: Edit and delete entries]] | [[M16: Billing-only interface]] | [[Category Icon Auto-Detection]] | [[Edit-Delete Edge Cases]]
- **Stack** → [[Flutter]] | [[Supabase]] | [[Python FastAPI]] | [[OAuth 2.0]]
- **Key UX laws** → [[Fitts's Law]] | [[Hick's Law]] | [[Miller's Law]] | [[Peak-End Rule]] | [[Tesler's Law]]

## How to regenerate

```bash
python context-graph/build.py
```

This re-parses both source docs and rewrites all notes. It is idempotent.
