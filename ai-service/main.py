"""
main.py
-------
FastAPI application entry point.

Endpoints:
  GET  /health       → {status: ok}           — always runnable
  POST /extract      → ExtractedBill          — stubbed (returns sample until OCR is wired)
  POST /validate     → ValidationResult       — REAL deterministic arithmetic
  POST /classify     → ClassificationResult   — stubbed
  POST /analyse      → AnalysisResult         — REAL deterministic arithmetic
  POST /narrate      → NarrationResult        — stubbed (returns template sentence)

Run:
  uvicorn main:app --reload

Environment:
  AI_SERVICE_HOST=0.0.0.0
  AI_SERVICE_PORT=8000
  FLUTTER_WEB_ORIGIN=http://localhost:5000   (CORS allow-list)
"""

from __future__ import annotations

import os
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from schemas import HealthResponse
from routers import extract, validate, classify, analyse, narrate

# ── App ────────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Bill Intelligence — AI Service",
    version="0.1.0",
    description=(
        "Python FastAPI microservice for bill extraction, "
        "deterministic validation, spend analysis, and narration."
    ),
)

# ── CORS ───────────────────────────────────────────────────────────────────
# Allow the Flutter web origin (dev + prod).
# In production set FLUTTER_WEB_ORIGIN to your domain.

_flutter_origin = os.getenv("FLUTTER_WEB_ORIGIN", "http://localhost:5000")
_extra_origins = os.getenv("EXTRA_CORS_ORIGINS", "").split(",")
_allowed_origins = [o.strip() for o in [_flutter_origin] + _extra_origins if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────

app.include_router(extract.router,  prefix="/extract",  tags=["extraction"])
app.include_router(validate.router, prefix="/validate", tags=["validation"])
app.include_router(classify.router, prefix="/classify", tags=["classification"])
app.include_router(analyse.router,  prefix="/analyse",  tags=["analysis"])
app.include_router(narrate.router,  prefix="/narrate",  tags=["narration"])

# ── Health ─────────────────────────────────────────────────────────────────

@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health() -> HealthResponse:
    """Always returns 200 OK. Used by the Flutter client on startup."""
    return HealthResponse()
