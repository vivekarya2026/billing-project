---
document_type: tech-requirements
version: "2.0.0"
status: draft
created_by: product_manager_agent
date: 2026-09-17
project: home-utility-bill-intelligence
stack_pivot: v1-local-first → v2-cloud-multiplatform
---

# Tech Requirements: Home Utility Bill Intelligence — v2 Stack

> **Plain language first.** This doc is written at ~6th grade level.
> Long words are swapped for short ones. One idea per sentence.
> Jargon is defined on first use.

---

## The one-sentence product

Take a photo of your utility bill. The app tells you, in one sentence,
whether this month is normal and why it changed.

---

## What changed from v1 (the pivot)

The first version was "local-first." Everything lived on your phone.
No server. No account. No internet needed.

The new version uses a cloud server (Supabase) and lets you log in.
This makes it work on the web and on Android too, not just iOS.
It also makes it easier to build and test.

| Old decision | New decision | Why |
|---|---|---|
| Native iOS only | Flutter: Web + iOS + Android | Reach more users; test on web easily |
| No account, no server | Supabase + OAuth login | Needed for multi-device and web |
| Apple on-device models | Python FastAPI AI service | Easier to build, update, and test |
| Local-first (D7) | Cloud backend with RLS | Enables real user data storage |

> **What did NOT change:** the product vision, all four personas, every UX law,
> the full MoSCoW feature list, the design language, the copy rules,
> the anti-patterns, and the privacy guardrails.

---

## Repository shape

```
Billing Project/
├── Intial Document/          ← source product + design docs (do not edit)
├── context-graph/            ← knowledge graph (this folder)
├── frontend/                 ← Flutter app (web + iOS + Android)
├── backend/                  ← Supabase project (schema, RLS, migrations)
└── ai-service/               ← Python FastAPI (OCR + bill parsing + validation)
```

Frontend, backend, and AI service are in **separate folders**.
They talk to each other over HTTP. They do not share code directly.

---

## Part 1 — Frontend (Flutter)

### Why Flutter

Flutter runs on Web, iOS, and Android from one codebase.
One set of screens. One set of tests. One design system.
That is the only reason to use it.

### Folder structure

```
frontend/
├── lib/
│   ├── main.dart
│   ├── theme/
│   │   ├── tokens.dart        ← all design tokens in one place
│   │   ├── typography.dart    ← SF Pro stack, sizes, weights
│   │   ├── colours.dart       ← semantic colour tokens only
│   │   ├── spacing.dart       ← 8pt grid, named sizes
│   │   └── theme.dart         ← assembles ThemeData
│   ├── features/
│   │   ├── home/              ← unified due view (US-008)
│   │   ├── bill_capture/      ← camera + file picker (US-003)
│   │   ├── bill_detail/       ← answer + breakdown + source (US-004, US-009)
│   │   ├── onboarding/        ← batch drop + first run (US-001)
│   │   └── settings/          ← backup, language, reminders (4 items max)
│   ├── shared/
│   │   ├── components/        ← BillCard, PrimaryButton, ListRow …
│   │   └── services/
│   │       ├── supabase_client.dart
│   │       └── ai_service_client.dart
│   └── router.dart
├── web/
│   ├── index.html
│   └── styles/
│       └── globals.css        ← global CSS vars for web (mirrors tokens.dart)
├── pubspec.yaml
└── test/
```

### Global CSS (web)

All design tokens are declared in `web/styles/globals.css`.
Change a token once. Every screen updates.
No inline styles. No magic numbers.

```css
/* web/styles/globals.css — generated from lib/theme/tokens.dart */
:root {
  /* Typography */
  --text-amount:      44pt;
  --text-title1:      28pt;
  --text-body:        19pt;   /* HIG Deviation D4: 19pt not 17pt */
  --text-subhead:     17pt;
  --text-caption:     13pt;   /* floor — nothing smaller */
  --font-system: -apple-system, BlinkMacSystemFont, 'SF Pro Display',
                 'SF Pro Text', 'Helvetica Neue', sans-serif;

  /* Colours — light mode */
  --label-primary:    #000000;
  --label-secondary:  rgba(60, 60, 67, 0.6);
  --bg-primary:       #FFFFFF;
  --bg-secondary:     #F2F2F7;
  --separator:        rgba(60, 60, 67, 0.29);
  --action:           #007AFF;   /* system blue = tappable ONLY */
  --destructive:      #FF3B30;   /* delete confirm ONLY, never bill status */

  /* Spacing (8pt grid) */
  --space-1: 4px;   --space-2: 8px;
  --space-3: 12px;  --space-4: 16px;
  --space-5: 20px;  --space-6: 24px;
  --space-8: 32px;  --space-10: 40px;
  --space-12: 48px; --space-16: 64px;

  /* Screen */
  --screen-edge: 20px;
  --card-pad:    20px;
  --card-gap:    12px;

  /* Radius */
  --radius-sm:   8px;
  --radius-md:   12px;
  --radius-lg:   16px;   /* bill cards */
  --radius-xl:   20px;   /* sheets, modals */
  --radius-full: 9999px; /* buttons */

  /* Motion */
  --dur-instant: 100ms;
  --dur-fast:    200ms;
  --dur-normal:  300ms;
  --ease-default: cubic-bezier(0.25, 0.1, 0.25, 1);
  --ease-out:     cubic-bezier(0, 0, 0.58, 1);

  /* Touch targets — HIG Deviation D1 */
  --target-min: 60px;   /* 44px is HIG floor; we use 60px for Rafael + Marguerite */
}

@media (prefers-color-scheme: dark) {
  :root {
    --label-primary:   #FFFFFF;
    --label-secondary: rgba(235, 235, 245, 0.6);
    --bg-primary:      #000000;
    --bg-secondary:    #1C1C1E;
    --separator:       rgba(84, 84, 88, 0.6);
    --action:          #0A84FF;
    --destructive:     #FF453A;
  }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

### shadcn token vocabulary (applied to Flutter)

We use shadcn's token *names* as our vocabulary.
We translate the values into Flutter `ThemeData`.
This makes it easy to switch themes later without rewriting every widget.

| shadcn token name | Flutter equivalent | Value |
|---|---|---|
| `--background` | `colorScheme.surface` | `--bg-primary` |
| `--foreground` | `colorScheme.onSurface` | `--label-primary` |
| `--primary` | `colorScheme.primary` | `--action` (#007AFF) |
| `--destructive` | `colorScheme.error` | `--destructive` |
| `--radius` | `cardTheme.shape` | `--radius-lg` (16px) |
| `--muted` | `colorScheme.surfaceVariant` | `--bg-secondary` |

### Apple HIG design rules (enforced in Flutter)

These are the rules that will not be broken.
Each one is there for a reason.

| Rule | Value | Reason |
|---|---|---|
| Min touch target | 60 × 60 px | HIG Deviation D1. Rafael's cracked screen. Marguerite's reading glasses. |
| Body text | 19 pt | HIG Deviation D4. Read once, slowly, by someone in glasses. |
| Status colour | Words only, never colour | HIG Deviation D2. Rafael was scammed. Red alarm = fraud to him. |
| Top-level navigation | No tab bar. Home + Add. | HIG Deviation D3. Hick's Law. Two choices, not five. |
| Dynamic Type | Mandatory on all text | Accessibility. No truncation at any font size. |
| The amount | Always the biggest element on screen | Deference pillar. Money is the content. |
| Items per screen | 5 maximum | Miller's Law. |
| Urgency signals | 0 | Anti-scam. No countdowns, no FOMO copy, no alarm colour. |

### Responsive breakpoints (web)

The web version uses the same Flutter widgets, rendered in a browser.
The layout adapts to screen width.

```
Mobile:   < 480px   — single column, full-width cards
Tablet:   480–1023px — same layout, slightly wider gutters
Desktop:  ≥ 1024px  — max-width 880px, centred, comfortable padding
```

All layouts use fluid CSS (`clamp()`, `min()`) not fixed breakpoints where possible.
Every primary action stays in the bottom third on mobile (Fitts's Law).

### v1 auth bypass

For testing without logging in, set this in `.env`:

```
BYPASS_AUTH=true
```

When `BYPASS_AUTH=true`, the app skips the OAuth flow and uses a
hardcoded test user ID. The rest of the app works exactly as it will
in production. Remove this flag before going live.

---

## Part 2 — Backend (Supabase)

### Why Supabase

Supabase gives us Postgres (the database), Auth (login), and Storage
(bill images) in one place. It has a free tier for development.
It scales when needed. It generates TypeScript types for free.

### Database schema

Every table has Row-Level Security (RLS) on.
A user only sees their own data.

```sql
-- Users come from Supabase Auth (OAuth). No separate users table needed.

-- A property is a home or building. One user can have many properties.
-- Wes has two: his home and a rental.
create table properties (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users not null,
  name        text not null,          -- "Home", "Rental on Oak St"
  address     text,
  created_at  timestamptz default now()
);

-- An account is one utility provider for one property.
-- e.g. "Ohio Edison — electric — Home"
create table accounts (
  id           uuid primary key default gen_random_uuid(),
  property_id  uuid references properties not null,
  user_id      uuid references auth.users not null,
  provider     text not null,         -- "Ohio Edison"
  service_type text not null,         -- "electric" / "gas" / "water" / "internet"
  account_ref  text,                  -- account number printed on bill
  created_at   timestamptz default now()
);

-- A bill is one statement from one provider for one period.
create table bills (
  id              uuid primary key default gen_random_uuid(),
  account_id      uuid references accounts not null,
  user_id         uuid references auth.users not null,
  period_start    date not null,
  period_end      date not null,
  period_days     int generated always as (period_end - period_start) stored,
  amount_due      numeric(10,2),
  previous_balance numeric(10,2),
  current_charges numeric(10,2),
  due_date        date,
  bill_type       text,               -- "standard" / "budget" / "estimated" / "solar" / "arrears"
  validation_passed boolean,
  cloud_consent   boolean default false,
  source_image_path text,             -- Supabase Storage path
  is_corrected_version boolean default false,
  supersedes_bill_id uuid references bills(id),
  created_at      timestamptz default now(),
  extraction_status text default 'pending'  -- pending / complete / partial / failed
);

-- One row per extracted field per bill. Every figure is traceable.
create table extraction_fields (
  id              uuid primary key default gen_random_uuid(),
  bill_id         uuid references bills not null,
  user_id         uuid references auth.users not null,
  field_name      text not null,      -- "amount_due", "usage_kwh", "rate_per_kwh" …
  raw_value       text,               -- exactly what OCR read
  parsed_value    numeric,
  confidence      float check (confidence between 0 and 1),
  bounding_box    jsonb,              -- {x, y, w, h, page} — source region on image
  user_corrected  boolean default false,
  corrected_value numeric,
  created_at      timestamptz default now()
);

-- Line items: each charge line on the bill.
create table line_items (
  id          uuid primary key default gen_random_uuid(),
  bill_id     uuid references bills not null,
  user_id     uuid references auth.users not null,
  label       text not null,          -- "Distribution charge", "Supply charge", "Rider A"
  amount      numeric(10,2),
  category    text,                   -- "distribution" / "supply" / "tax" / "rider" / "one-time"
  confidence  float,
  bounding_box jsonb
);

-- Classification results (bill type flags per bill)
create table bill_classifications (
  id          uuid primary key default gen_random_uuid(),
  bill_id     uuid references bills not null,
  flag        text not null,          -- "budget_billing", "estimated_read", "arrears", "solar", "mid_cycle_rate_change"
  confidence  float,
  notes       text
);

-- Anomalies flagged by the analysis engine
create table anomalies (
  id              uuid primary key default gen_random_uuid(),
  bill_id         uuid references bills not null,
  user_id         uuid references auth.users not null,
  component       text,               -- "rate" / "usage" / "fixed" / "rider"
  description     text,               -- plain language, ~6th grade
  phone_script    text,               -- exactly what to say when calling
  user_dismissed  boolean default false,
  user_confirmed_wrong boolean default false,
  created_at      timestamptz default now()
);
```

### Row-Level Security policies

```sql
-- Example for bills table (same pattern for all tables):
alter table bills enable row level security;

create policy "users see own bills"
  on bills for all
  using (auth.uid() = user_id);

-- During BYPASS_AUTH testing:
-- The test user ID is hardcoded in the app and RLS still applies.
-- All test data belongs to that test user. No special bypass on the DB.
```

### Storage bucket

```
bill-images/
  {user_id}/
    {bill_id}/
      original.{jpg|pdf}
      page_1.jpg
      page_2.jpg   (if multi-page)
```

Bucket policy: private. Only the owning user can read/write their files.

### OAuth setup

Supabase Auth handles Google and Apple sign-in out of the box.

```
Providers to enable in Supabase dashboard:
  ✓ Google (OAuth 2.0)
  ✓ Apple (Sign in with Apple)

Redirect URLs:
  http://localhost:3000/auth/callback   (web dev)
  https://your-domain.com/auth/callback  (web prod)
  com.yourapp://auth/callback           (mobile deep link)
```

For v1 testing, set `BYPASS_AUTH=true` in the Flutter `.env` file.
This skips OAuth. The backend still enforces RLS with a test user ID.

---

## Part 3 — AI Service (Python FastAPI)

### Why a separate Python service

The AI/OCR work is Python-native (PaddleOCR, PyTorch, NumPy).
Keeping it separate means:
- Flutter does not care how OCR works
- You can update the AI model without touching the app
- You can run the AI service on a bigger machine if needed
- The deterministic validation code is easier to test in Python

### Folder structure

```
ai-service/
├── main.py               ← FastAPI app entry point
├── routers/
│   ├── extract.py        ← POST /extract  (image → structured bill data)
│   ├── validate.py       ← POST /validate (does the arithmetic close?)
│   ├── classify.py       ← POST /classify (budget billing? estimated read?)
│   ├── analyse.py        ← POST /analyse  (change decomposition)
│   └── narrate.py        ← POST /narrate  (structured data → one sentence)
├── pipeline/
│   ├── stage_0_triage.py
│   ├── stage_1_extraction.py
│   ├── stage_2_validation.py   ← DETERMINISTIC CODE ONLY — no model
│   ├── stage_3_classification.py
│   ├── stage_4_reconciliation.py
│   ├── stage_5_analysis.py     ← DETERMINISTIC CODE ONLY — no model
│   ├── stage_6_narration.py
│   └── stage_7_conversation.py
├── models/               ← model loading + inference wrappers
│   ├── ocr.py            ← PaddleOCR wrapper
│   └── llm.py            ← narration + conversation model
├── dashboard/
│   ├── app.py            ← Streamlit / Plotly dashboard
│   └── charts.py         ← spend decomposition + usage trend charts
├── requirements.txt
├── .env.example
└── tests/
    ├── test_validation.py   ← most critical test file
    └── test_extraction.py
```

### The eight pipeline stages

The pipeline mirrors the spec exactly.

```
Stage 0  Triage       → Is this a bill? Which provider? Which period?
Stage 1  Extraction   → Structured line items + bounding boxes per field
Stage 2  Validation   → Does the arithmetic close? (CODE ONLY, never a model)
Stage 3  Classification → Budget billing? Estimated read? Arrears? Solar?
Stage 4  Reconciliation → Dedupe, build timeline, find invalid comparison windows
Stage 5  Analysis     → Normalise per day, compare same month last year (CODE ONLY)
Stage 6  Narration    → Write one sentence at the right reading level
Stage 7  Conversation → Answer questions grounded in extracted data only
```

### The most important rule

**Models read images and write sentences. Code does arithmetic.**

Stage 2 (validation) and Stage 5 (analysis) are pure Python math.
No language model is involved. If a calculation is wrong, it fails loud
and fast — it does not hallucinate a plausible-looking number.

```python
# stage_2_validation.py — example
def validate(bill: ExtractedBill) -> ValidationResult:
    failures = []

    # Check 1: line items sum to subtotal
    items_total = sum(item.amount for item in bill.line_items)
    if not approx_equal(items_total, bill.subtotal, tolerance=0.02):
        failures.append(FailedCheck(
            field="subtotal",
            expected=items_total,
            actual=bill.subtotal,
            message="Line items do not add up to the subtotal."
        ))

    # Check 2: usage × rate = energy charge
    if bill.usage_kwh and bill.rate_per_kwh and bill.energy_charge:
        calc = bill.usage_kwh * bill.rate_per_kwh
        if not approx_equal(calc, bill.energy_charge, tolerance=0.05):
            failures.append(FailedCheck(
                field="energy_charge",
                expected=calc,
                actual=bill.energy_charge,
                message="Usage × rate does not match the energy charge."
            ))

    # Check 3: balance forward reconciles
    if bill.previous_balance is not None and bill.payments is not None:
        expected_due = bill.previous_balance + bill.current_charges - bill.payments
        if not approx_equal(expected_due, bill.amount_due, tolerance=0.02):
            failures.append(FailedCheck(
                field="amount_due",
                expected=expected_due,
                actual=bill.amount_due,
                message="Balance forward does not reconcile."
            ))

    return ValidationResult(passed=len(failures) == 0, failures=failures)
```

### API endpoints

```
POST /extract
  Body: { image_base64: str, bill_id: str }
  Returns: ExtractedBill (fields + confidence + bounding boxes)

POST /validate
  Body: ExtractedBill
  Returns: ValidationResult (passed: bool, failures: list)

POST /classify
  Body: ExtractedBill
  Returns: ClassificationResult (bill_type flags + confidence)

POST /analyse
  Body: { current_bill: ExtractedBill, comparison_bill: ExtractedBill }
  Returns: ChangeDecomposition (delta split by rate/usage/fixed/one-offs)

POST /narrate
  Body: { analysis: ChangeDecomposition, register: "brief"|"explained"|"full" }
  Returns: { sentence: str }

POST /converse
  Body: { question: str, extracted_bills: list[ExtractedBill] }
  Returns: { answer: str, citations: list[BillReference] }
```

### Python dashboard

`ai-service/dashboard/app.py` runs separately from the API.
It is for you (the developer) and for Wes (the depth user).

```bash
cd ai-service
streamlit run dashboard/app.py
```

Charts included:
- Monthly spend per provider (bar chart, normalised per day)
- Year-over-year comparison (same month, different year)
- Change decomposition waterfall (rate vs usage vs fixed vs one-offs)
- Anomaly timeline (which months had flags)
- Provider comparison (electric vs gas vs water cost per month)

All charts pull from Supabase via the service role key.
They are read-only. No bill data is modified from the dashboard.

---

## Part 4 — How the three parts talk

```
Flutter app
  │
  ├── Supabase (data + auth + storage)
  │     POST /bills         → write bill metadata
  │     POST /storage       → upload bill image
  │     GET  /bills         → read bill history
  │     REALTIME            → live status updates during extraction
  │
  └── Python FastAPI (AI + OCR)
        POST /extract       → send image, get structured bill back
        POST /validate      → check the math
        POST /classify      → identify bill type
        POST /analyse       → compute change decomposition
        POST /narrate       → get the one sentence
```

Flow for a single bill capture:
1. User takes photo → Flutter saves image to Supabase Storage
2. Flutter sends image URL to FastAPI `/extract`
3. FastAPI runs OCR + extraction → returns fields + confidence
4. Flutter shows targeted confirmation if validation failed
5. User confirms or corrects
6. Flutter writes final data to Supabase `bills` + `extraction_fields`
7. Flutter calls FastAPI `/narrate` → gets the one sentence
8. Flutter displays the answer screen

---

## Part 5 — Environment and configuration

### Flutter `.env`

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
AI_SERVICE_URL=http://localhost:8000   # local dev
BYPASS_AUTH=true                       # v1 testing only — remove before launch
```

### Python `.env`

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key   # NOT the anon key
OCR_MODEL=paddleocr                          # or "tesseract"
LLM_PROVIDER=openai                          # or "local" for on-device
OPENAI_API_KEY=sk-...                        # only if LLM_PROVIDER=openai
```

### Supabase local dev

```bash
npx supabase init
npx supabase start        # starts local Postgres + Auth on Docker
npx supabase db push      # applies schema migrations
```

---

## Part 6 — Build order (after plan approval)

This is the sequence to build in. Each phase is testable before the next.

### Phase 0 — Project scaffold (1 day)
- Create `frontend/`, `backend/`, `ai-service/` folders
- Init Flutter project, Supabase project, FastAPI project
- Wire up global CSS tokens in Flutter and web
- Get the three parts running locally

### Phase 1 — Auth + bypass (1 day)
- Supabase OAuth (Google + Apple)
- `BYPASS_AUTH` flag in Flutter
- Create all DB tables + RLS policies
- Test: can log in, can read/write own data, cannot read other users' data

### Phase 2 — Capture + upload (2 days)
- Camera capture (guided: edge detection, glare warning)
- File picker (single + batch)
- Upload to Supabase Storage
- Test: photos land in the right bucket folder

### Phase 3 — OCR + extraction (3 days)
- FastAPI `/extract` endpoint
- PaddleOCR wrapper
- Field extractor (returns confidence + bounding boxes)
- Test: run against 5 real bill images, check field accuracy

### Phase 4 — Validation engine (2 days)
- Stage 2: arithmetic self-validation (the most critical code)
- Stage 3: bill type classification
- Targeted confirmation UI in Flutter
- Test: run against bills that should fail validation; confirm only failing fields appear

### Phase 5 — Home screen + bill detail (2 days)
- Unified due view (US-008)
- Bill card component (signature component)
- Bill detail: answer screen in three registers (brief / explained / full)
- Provenance: tap any number, see source region
- Test: Dana's two-minute flow end-to-end

### Phase 6 — Analysis + narration (3 days)
- Stage 5: change decomposition (Release 2 feature M12)
- Stage 6: narration (one sentence per register)
- Anomaly flagging (M13) + phone script
- Test: run against 12 months of bills, check decomposition arithmetic

### Phase 7 — Settings + backup (1 day)
- 4-item settings screen (backup, language, reminders, detail level)
- Encrypted backup + restore
- Test: restore on a fresh install

### Phase 8 — Polish + responsive (2 days)
- Responsive layout for all three breakpoints
- Dynamic Type / font scaling
- VoiceOver / screen reader labels
- Reduced motion support
- Test: Marguerite's and Rafael's use cases specifically

---

## Part 7 — Design rules (pinned)

These apply to every screen. No exceptions.

| Rule | Value |
|---|---|
| Min touch target | 60 × 60 px (HIG Deviation D1) |
| Body text | 19 pt (HIG Deviation D4) |
| Smallest text | 13 pt (never smaller) |
| Items per screen | 5 max (Miller's Law) |
| Top-level choices | 2 (Hick's Law + HIG Deviation D3) |
| Status colour | Words only. Never red/amber for bill status. (HIG Deviation D2) |
| Urgency signals | 0 — no countdowns, no alarm colour |
| Primary buttons per screen | 1 |
| Flow endings | Always an answer. Never a dashboard. (Peak-End Rule) |
| Amount on screen | Always the biggest text element (Deference pillar) |
| Reading level | 6th grade for all copy |
| Auth in v1 | Bypassable with `BYPASS_AUTH=true` |
| RLS | Always on. Every table. No exceptions. |
| Model arithmetic | Never. Code does math. Models write sentences. |
| Colour independence | No information carried by colour alone |
| Provenance | Every number links to its source on the bill |

---

## Part 8 — Security checklist

These items are from the PRD security register (SEC-PM-001 to SEC-PM-007).
They are identified, not solved. The architect owns the solution.

| ID | What to watch out for | Phase |
|---|---|---|
| SEC-PM-001 | Bill images contain full name, address, account number — PII with identity-theft value | Phase 2 |
| SEC-PM-002 | FastAPI receives bill images — what it retains must be stated in the UI | Phase 3 |
| SEC-PM-003 | Any new server component needs re-approval (this whole pivot IS that re-approval) | Phase 0 |
| SEC-PM-004 | Never verify bill ownership — users can add bills in another person's name (valid for renters) | Phase 2 |
| SEC-PM-005 | US state privacy laws apply (CCPA/CPRA). Legal review before launch. | Before Phase 8 |
| SEC-PM-006 | Export and delete must be real and complete | Phase 7 |
| SEC-PM-007 | Encrypted backup is the most valuable artifact to steal — key handling is critical | Phase 7 |

---

## Open questions (carry forward from PRD)

| Question | Impact | Owner |
|---|---|---|
| Which OCR model: PaddleOCR, Tesseract, or a vision API? | Extraction accuracy and cost | Architect |
| Cloud fallback (FastAPI) — what does it retain? Stated in the UI? | SEC-PM-002, trust | Architect |
| Does register switching (brief / explained / full) adapt automatically or is it a user setting? | Core interaction model | Designer |
| Which 20 US utility formats define the accuracy target? | Test corpus scope | Owner |
| Flutter web hosting: Vercel, Supabase Hosting, or other? | Deployment | Architect |
| Is there a path to household sharing in v3? | Product direction | Owner |

---

*Generated by product_manager_agent v2.0.0 · 2026-09-17*
*Companion vault: open `context-graph/vault/` in Obsidian*
*Regenerate vault: `python3 context-graph/build.py`*
