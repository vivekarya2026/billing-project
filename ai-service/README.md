# ai-service/

Python FastAPI microservice for bill extraction, deterministic validation,
spend analysis, and narration.

## Quick start

```bash
cd ai-service

python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt

cp .env.example .env      # fill in Supabase service role key

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Open the auto-docs: [http://localhost:8000/docs](http://localhost:8000/docs)

## Endpoints

| Method | Path | Status | Description |
|--------|------|--------|-------------|
| GET | `/health` | ✅ Real | Always returns `{status: ok}` |
| POST | `/validate` | ✅ Real | Deterministic arithmetic checks |
| POST | `/analyse` | ✅ Real | Spend decomposition (with prior bill) |
| POST | `/extract` | 🔶 Stub | Returns sample bill until OCR wired (Phase 2) |
| POST | `/classify` | 🔶 Stub | Returns sample tags (Phase 4) |
| POST | `/narrate` | 🔶 Stub | Returns template sentence (Phase 6) |

## Pipeline stages

```
Stage 0: Ingest      — download image from Supabase Storage (Phase 2)
Stage 1: OCR         — PaddleOCR → words + bounding boxes (Phase 2)
Stage 2: Validation  — ✅ deterministic arithmetic (REAL)
Stage 3: Parse       — OCR text → structured fields (Phase 2)
Stage 4: Classify    — tag detection (Phase 4)
Stage 5: Analysis    — ✅ spend decomposition (REAL)
Stage 6: Narration   — ⚠️ ONLY LLM stage (Phase 6)
Stage 7: Persist     — write to Supabase (Phase 3)
```

## Deterministic math rule

**Stages 2 and 5 do ALL arithmetic.** The LLM in Stage 6 receives only
`AnalysisResult` structured data and is constrained to produce exactly one
sentence. It never touches numbers. This prevents hallucinated calculations.

## Run tests

```bash
pytest tests/test_validation.py -v
```

All tests run without a server, database, or network connection.

## Dashboard

```bash
streamlit run dashboard/app.py
```

Phase 1 shows sample data. Phase 7: connects to Supabase for real history.

## Environment variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key — **never expose to client** |
| `FLUTTER_WEB_ORIGIN` | CORS allowed origin (Flutter web URL) |
| `AI_SERVICE_HOST` | Bind host (default `0.0.0.0`) |
| `AI_SERVICE_PORT` | Bind port (default `8000`) |

OCR and LLM keys are documented in `.env.example` under Phase 2 / Phase 6.
