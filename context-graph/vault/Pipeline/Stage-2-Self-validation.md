---
type: PipelineStage
name: "Self-validation"
description: "Does the arithmetic close? Deterministic only."
engine: "Deterministic code — no model"
---

# Stage 2: Self-validation

**Engine:** Deterministic code — no model  

## What this stage does

Does the arithmetic close? Deterministic only.

> **Rule:** No language model is involved here. Code does the arithmetic. Models read images and write sentences — they never compute totals.

**Previous:** [[Stage 1: Extraction]]  
**Next:** [[Stage 3: Classification]]  

## Implements

- [[M5: Arithmetic self-validation]] — Self-validation implements arithmetic check
