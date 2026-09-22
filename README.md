# Billing Project — Home Utility Bill Intelligence

A focused **billing** app: track your utility bills, filter by type, see per-type
spend graphs, and add/remove bills in seconds. Built with **Flutter (web)** on
the **daisyUI 5** design system (dark-first), with a Supabase backend and a
Python AI/OCR service (both optional in the offline demo).

> The app runs in **offline demo mode** by default (`BYPASS_AUTH=true`): it
> auto-logs in and uses seeded demo bills, so no backend is required to try it.

---

## Repository layout

| Folder | What it is |
|---|---|
| `frontend/` | Flutter app (web + mobile). The deployable web build lives in `frontend/build/web`. |
| `backend/` | Supabase schema / backend assets. |
| `ai-service/` | Python FastAPI service for image→text bill extraction (OCR/AI). |
| `context-graph/` | Product knowledge graph (Obsidian vault + Mermaid). |
| `Intial Document/` | Original product requirements. |

---

## Run locally

The simplest way (build if needed, then serve):

```bash
./run.sh            # serve on http://localhost:3012
./run.sh --rebuild  # force a clean rebuild, then serve
```

Or manually:

```bash
cd frontend
flutter build web --dart-define=BYPASS_AUTH=true
cd build/web && python3 -m http.server 3012
```

Then open <http://localhost:3012>.

---

## Deploy (Vercel — static)

Vercel has no Flutter build image, so this repo commits the built web output
(`frontend/build/web`) and Vercel serves it **statically** — no build step runs
on Vercel. Configuration lives in [`vercel.json`](./vercel.json):

- `outputDirectory: frontend/build/web`
- `buildCommand: null` (nothing to build on Vercel)
- SPA rewrites so deep links fall back to `index.html`

### Update the deployed app

Because Vercel serves the committed build, you must rebuild locally and commit
the output before pushing:

```bash
cd frontend && flutter build web --dart-define=BYPASS_AUTH=true && cd ..
git add -A && git commit -m "chore: rebuild web" && git push
```

Vercel auto-deploys on every push to the connected branch.

---

## Tech stack

- **Frontend:** Flutter (web / iOS / Android), daisyUI 5 design tokens, Inter type.
- **Backend:** Supabase (Postgres, Auth, Storage).
- **AI service:** Python FastAPI (bill OCR / narration).
- **Hosting:** Vercel (static web).
