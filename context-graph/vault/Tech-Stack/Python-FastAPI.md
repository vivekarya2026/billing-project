---
type: TechComponent
layer: "ai-service"
description: "REST microservice for OCR (image-to-text), bill parsing, and deterministic self-validation engine."
---

# Python FastAPI

**Layer:** ai-service  

REST microservice for OCR (image-to-text), bill parsing, and deterministic self-validation engine.

## Connects to

- [[PaddleOCR / Tesseract]] — FastAPI orchestrates OCR
- [[Supabase]] — FastAPI writes extraction results to Supabase

## Governed by

- [[Frontend / Backend separation]]
- [[Python for AI + Graphs]]
