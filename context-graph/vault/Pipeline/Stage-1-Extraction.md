---
type: PipelineStage
name: "Extraction"
description: "Structured line items, per-field confidence, bounding region on source"
engine: "Vision OCR + on-device model"
---

# Stage 1: Extraction

**Engine:** Vision OCR + on-device model  

## What this stage does

Structured line items, per-field confidence, bounding region on source

**Previous:** [[Stage 0: Triage]]  
**Next:** [[Stage 2: Self-validation]]  

## Implements

- [[M4: Extraction with confidence and provenance]] — Extraction stage implements provenance
