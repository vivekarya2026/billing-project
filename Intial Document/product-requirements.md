---
document_type: requirements
version: "1.0.0"
status: draft
created_by: product_manager
project: "home-utility-bill-intelligence"
scope: MVP
date: 2026-09-17
---

# Product Requirements: Home Utility Bill Intelligence

## Executive Summary

### Elevator Pitch

Take a photo of your utility bill and the app tells you, in one sentence, whether this month is normal and why it changed. Everything stays on your phone.

### Problem Statement

A US household pays four to six utility providers on different cycles, in different formats, through different portals. When a bill jumps thirty dollars, finding out why means comparing this month's per-kWh rate, fixed charges, riders and usage against the same month last year, inside a document written in utility jargon. That work costs twenty to forty minutes per bill, so almost nobody does it, and rate increases, expired supply contracts, wrong plans and billing errors go undetected for years.

### Target Audience

Any capable adult managing household utility bills in the United States. Built to universal design, meaning one interface with no age-specific mode, tested against users at both extremes of capability and situational complexity.

### Unique Value Proposition

**We read the bill, not just the amount.** Every competitor shows what you spent. We show why it changed, whether it should have, and what specifically to say when you call. In language that needs no glossary, on a device that never uploads your data.

### Scope

- Type: MVP, shipped in two releases
- Market: United States only
- Platform: Native mobile, driven by the on-device model requirement
- Architecture: Local-first (L2, local processing with explicit per-bill cloud consent)
- Release 1: capture, extraction, validation, classification, unified view, provenance
- Release 2: change decomposition and anomaly detection

---

## Decisions Log

Decisions made by the product owner during discovery, recorded so downstream agents do not relitigate them.

| # | Decision | Rationale | Made by |
|---|---|---|---|
| D1 | Universal design, not an elderly-specific product | Designing for the hardest case produces a better product for everyone. An accessibility mode admits the default is bad. | Owner |
| D2 | Bills and consumption integrated, bills as the spine | Most US utility bills print usage and a 13-month comparison, so consumption comes free with extraction | Owner |
| D3 | MVP ingestion is manual entry plus photo/PDF capture | Green Button excludes bill line items, so utility API connection cannot answer the core question anyway | Owner, after analysis |
| D4 | Utility account connection deferred to COULD | Registration burden per utility is high, commercial aggregators are enterprise-priced | Owner |
| D5 | Ship Option B then A | Ship the spine first, add change decomposition once extraction accuracy is proven in the wild | Owner |
| D6 | Batch multi-file drop is a MUST, and is the onboarding | Solves the cold start problem: twelve months dropped at signup means a full baseline before first use | Owner |
| D7 | Local-first architecture | Privacy position, zero inference cost, no account required, works offline | Owner |
| D8 | L2 specifically: local by default, per-bill cloud consent on failure | Pure local degrades badly on poor photos. L2 keeps the promise honest and verifiable. | Delegated to PM |
| D9 | Household sharing and the caregiver use case are out for v1 | Direct cost of local-first. Accepted knowingly. | Owner |
| D10 | Anomaly flagging is a MUST, not a SHOULD | It is the reason anyone opens the app | Owner |

---

## User Personas

Four personas. Two are markets, two are design constraints. This is double the normal MVP count, justified because the constraint personas exist to break the design, not to be sold to.

```
  BARRIER                                              DEPTH
  |--------------------------------------------------------|
  Rafael          Marguerite        Dana            Wes
  (constraint)    (constraint)      (volume)        (constraint)
```

### Rafael Ocampo — Maximum-barrier case

**Demographics**
- Role: Warehouse night shift, 61. Rents a two-bedroom.
- Technical comfort: Low. Phone only, no computer, no printer, storage nearly full.
- Context: Electric and gas in his name. Water is in the landlord's name, billed as a flat share he has never seen evidence for. On a payment arrangement after falling behind last winter.

**Goals**
- Primary: Not get disconnected
- Secondary: Know whether the water charge the landlord passes on is real

**Frustrations**
- Was targeted by a shutoff scam call last year. Urgent notifications now read as threats, not help.
- Arrears roll into each bill, so the total never matches usage and nothing explains the gap
- No PDF exists. The bill is paper, and the paper is folded.

**Quote:** "Tell me the number I have to pay and the day. Everything else is noise until I know that."

**Usage pattern:** Twice a month, standing, cracked screen, 6am after a shift.

**What he breaks:** Language. Photo-only capture. Arrears versus usage. Split account ownership. The entire alert tone, because urgency reads as fraud to him.

### Marguerite Oyelaran — Trust and legibility case

**Demographics**
- Role: Retired school administrator, 74. Lives alone in the house she has owned since 1986.
- Technical comfort: Low to medium. iPad daily for messages and photos. Reading glasses. Does not trust anything that asks for a password.
- Context: Fixed income. A forty dollar swing is a decision about something else.

**Goals**
- Primary: Confirm nothing is wrong and nothing is overdue
- Secondary: Have an answer ready when her son asks if she is doing okay

**Frustrations**
- Portal text is too small and the important number is never the biggest one on the page
- Has been called by shutoff scammers, so urgency triggers suspicion not action
- Keeps paper copies because she does not believe the app will still have them next year

**Quote:** "I don't need a chart. I need someone to tell me if I'm alright."

**Usage pattern:** Once a month per utility, when the paper bill arrives. Reads the whole screen slowly, once.

**What she breaks:** Type size. Target size. Any sentence needing a glossary. Any flow requiring trust in something invisible.

### Dana Whitfield — The volume user, primary market

**Demographics**
- Role: Operations coordinator, 43, married, two kids, owns a 1,900 sq ft home outside Columbus
- Technical comfort: Medium. Confident with apps, not spreadsheets.
- Context: Electric, gas, water, internet, trash. Five accounts, five cycles, four portals.

**Goals**
- Primary: Know within ten seconds whether this month is normal
- Secondary: Stop feeling quietly overcharged with no way to check

**Frustrations**
- Electric went up sixty dollars in March and she still does not know why. Assumed weather, moved on.
- Autopay means she often does not look at the bill until the annual total shocks her
- Every portal wants a different login and shows a different chart

**Quote:** "I pay them. I don't understand them. I've made peace with that and I hate it."

**Usage pattern:** Five times a month, under two minutes each, triggered by a bill notification. Never browses.

### Wes Tanaka — Depth and trust case

**Demographics**
- Role: Backend engineer, 38. Owns his house plus a rental unit across town.
- Technical comfort: High. Already runs Home Assistant with a smart meter integration.
- Context: Rooftop solar with net metering. Some months the electric bill is a credit. Annual true-up makes naive month-over-month comparison meaningless.

**Goals**
- Primary: One place that reconciles interval data against what the utility actually billed
- Secondary: Export everything, because he does not trust a startup to exist in three years

**Frustrations**
- Consumer apps round his numbers and hide the arithmetic
- Nothing handles net metering credits correctly
- Two properties means every app forces two accounts

**Quote:** "If I can't see how you got the number, I assume you got it wrong."

**Usage pattern:** Deep session once a quarter, then ignores it. Will evangelise or trash it in one sentence.

**What he breaks:** Solar and net metering. Multi-property. Data opacity. Export.

---

## Current Journey Analysis (As-Is)

The journey today, with no product. Eight stages.

| # | Stage | What actually happens | Feeling | The real cost |
|---|---|---|---|---|
| 1 | Bill arrives | Email among forty others, or paper in a stack. Five providers, five days. | Background static | Bills noticed late or not at all |
| 2 | Triage | Decide whether this needs attention now. The answer is almost always "later." | Mild avoidance | Due dates get close before anyone looks |
| 3 | Open it | Log in, reset the password, find the PDF. Or open the envelope. | Friction, resentment | A large share of attempts stop here |
| 4 | Look at the number | Eyes go to the total. Nothing else is read. | Relief or dread | Every line item is invisible |
| 5 | React | Number is higher. Form a theory instantly: "it was cold," "kids were home." | Rationalisation | The theory is never checked and is usually wrong |
| 6 | Decide to investigate | Compare to last year? Call the utility? Almost nobody does. Cost is 20 to 40 minutes, payoff unknown. | Resignation | Errors, expired contracts and wrong plans persist for years |
| 7 | Pay | Autopay, or click through the portal | Task closed | Paying removes the prompt to ever understand it |
| 8 | Forget | No unified record kept anywhere | Neutral | Next month starts from zero. No baseline, no pattern. |

### The three structural traps

**Stage 5 is where the product lives.** The user forms an explanation and it satisfies them enough to stop. They are not lazy. They are behaving correctly given that verification costs forty minutes with unknown payoff. Our job is to make verification cost zero, which flips the calculation.

**Stage 7 actively destroys stage 6.** Autopay is sold as convenience and is also why nobody catches anything. Any product that competes with autopay loses. Any product that sits before it and takes ten seconds wins.

**Stage 8 is why nothing compounds.** No baseline means every month is judged against vague memory. Cheapest problem to solve, and it unlocks stage 5.

### Pain points, sorted by what we can actually do

**Eliminated**
- No single view across providers
- No baseline or memory
- Line items invisible
- "Why did it go up" unanswerable

**Softened**
- Getting the bill in still requires user action. Photo capture makes it five seconds rather than a login, but not zero.
- Due date awareness improves, but we do not pay the bill in v1.

**Not addressable**
- The bill is genuinely complicated because US tariffs are genuinely complicated. Tesler's Law: that complexity moves, it does not vanish. We move it from user to system.
- Resolving an error still means calling the utility. We can hand over the exact sentence to say. We cannot make the call.

### Laws of UX applied to the diagnosis

| Law | Where it bites | Design constraint it produces |
|---|---|---|
| Peak-End Rule | Today the peak is dread at stage 4 and the end is "paid, stop thinking." Remembered as unpleasant, therefore avoided. | Move the peak to resolution: "you're fine" or "we found something." End on an answer, never on a dashboard. A chart is not an ending. |
| Hick's Law | Triage fails because portals present twenty things to do | Entry screen presents one. "Am I alright" is the only question on screen one. |
| Miller's Law | A utility bill has 30+ line items | Chunk to five or fewer: what you owe, what changed, why, when due, what to do |
| Fitts's Law | Marguerite's targets and Rafael's cracked screen | 60px minimum, above the 48px Material floor. Sized for the hardest case, everyone benefits. |
| Jakob's Law | People have thirty years of mental models about bills | Borrow the shape of a bank statement and a text message. Never a BI dashboard. |
| Tesler's Law | Wes needs the complexity Marguerite needs hidden | One engine, three registers. Underlying detail always reachable, never default. |
| Aesthetic-Usability | Trust is the product's currency under local-first | Visual polish is not decoration here. It is the trust signal that replaces a brand the user has never heard of. |

---

## Feature Prioritisation (MoSCoW)

### MUST have — Release 1

| ID | Feature | User value | Complexity | Notes |
|---|---|---|---|---|
| M1 | Batch multi-file drop | Solves cold start. Drop twelve months, get a baseline before first use. | M | This is the onboarding, not a power feature |
| M2 | Per-file triage and classification | Identifies provider, service, period, account, duplicates, corrections. Sets aside non-bills. | M | Also catches scam letters dressed as shutoff notices |
| M3 | Guided capture UI | On-device extraction depends on image quality far more than cloud would | M | Edge detection, glare warning, retake prompt. Fix it at the lens. |
| M4 | Extraction with confidence and provenance | Turns an unreadable document into structured data | L | Per-field confidence score plus bounding region on the source image |
| M5 | Arithmetic self-validation | The only thing that makes batch viable without endless confirmation | M | Line items must sum to total, usage times rate must equal energy charge, balance forward must reconcile |
| M6 | Targeted confirmation | Ask only about fields that failed validation | S | Promoted from SHOULD. Without it, M5 has no resolution path. |
| M7 | Bill-type classification | Stops us being confidently wrong | M | Budget billing, estimated reads, arrears, one-time charges, solar credits, mid-cycle rate change |
| M8 | Unified due view | One screen, all providers, what is owed and when | S | Dana's five accounts. Marguerite's "am I alright." |
| M9 | Provenance and audit trail | Every number traceable to the pixel it came from | M | Wes's requirement, Marguerite's trust mechanism, our defence against false positives |
| M10 | Encrypted local backup and restore | No server means device loss is total loss | M | Forced by local-first |
| M11 | Per-bill cloud consent | The L2 promise only holds if the user genuinely controls it | S | Explicit, per bill, with the reason shown |

### MUST have — Release 2

| ID | Feature | User value | Complexity | Notes |
|---|---|---|---|---|
| M12 | Change decomposition | This is the product | L | Normalises per day, compares like period to like period, splits the delta into rate, usage, fixed charges, one-offs |
| M13 | Anomaly flagging | The reason anyone opens the app | M | Only fires when M5 validation passed cleanly on that bill |

### SHOULD have

| ID | Feature | User value | Complexity | Notes |
|---|---|---|---|---|
| S1 | Plan and contract change detection | Catches an expired supply contract, the most common silent cost increase | M | Read from the bill, not from a tariff database |
| S2 | Due date reminders | Prevents the late fee | S | Tone rules apply hard. No urgency styling. |
| S3 | Export, CSV and JSON | Wes will not commit without it | S | Also the honest answer to "what if you shut down" |
| S4 | Output language setting | Rafael | S | Extraction is language-agnostic. This is presentation only. |
| S5 | Assistance programme surfacing | Triggered by arrears or a disconnection notice. Roughly one in six US households entered 2026 behind on utility bills. | M | High moral weight, low frequency. Doing it badly is worse than not doing it. |
| S6 | Corrected bill versioning | A re-issued bill must supersede, not duplicate | S | |
| S7 | Grounded conversation | Wes's escape hatch | M | Not the front door. Strictly grounded in extracted data, refuses to speculate. |
| S8 | Report generation and export | Wes's artifact | S | Not the default view for anyone |
| S9 | Register switching | One engine, three levels of detail | M | Setting or adaptive. Design decision for Agent 2. |

### COULD have

| ID | Feature | Complexity | Notes |
|---|---|---|---|
| C1 | Utility account connect | L | Green Button proof of concept, one or two utilities. Supplements capture, cannot replace it, since Green Button excludes line items. |
| C2 | Smart meter ingest | M | Reconciles interval data against what was billed. Wes already runs Home Assistant. |
| C3 | Voice input and output | M | Universal design payoff, helps everyone |
| C4 | Household sharing and sync | L | Explicitly deferred by D9. Requires a sync layer that local-first does not have. |
| C5 | Full solar and net metering support | L | MVP detects and flags. Full support is its own project. |

### WON'T have, this release

| Feature | Reason for exclusion | Reconsider when |
|---|---|---|
| Bill payment | Money movement brings licensing, PCI and liability. Also autopay is where understanding goes to die. We sit before payment deliberately. | Probably never. This is a position, not a backlog item. |
| Generic efficiency tips | "Lower your thermostat" is not insight. Every competitor has it, nobody values it. | Only if personalised by actual extracted data |
| Full tariff marketplace comparison | Requires a maintained database of thousands of US rate plans. This is a company, not a feature. | After 10k+ users, as a partnership |
| Bank account sync | Six incumbents do it better, and it shows the amount, not the bill. Wrong layer. | Never |
| Roommate bill splitting | Different product, different social dynamics | If demand appears |
| Prepaid utility accounts | No bill, no cycle, no comparison. The model does not apply. | If a market appears |
| Web application | Local-first requires on-device models. The web has no equivalent. | If browser-based local inference matures |

---

## Edge Case Register

### Threats to the core thesis

**Budget billing (levelized / equal payment plans).** The utility averages annual cost and bills a flat amount, truing up once a year. For these users the bill does not change with usage by design, so the entire "why did it change" proposition is void. We must detect it and switch modes: track the deferred balance, warn about the true-up, compare actual usage against the levelized amount. Missing this gives a meaningful slice of users a broken experience they will never explain to us.

**Estimated meter reads.** Utilities estimate when they cannot read the meter, then correct on the next actual read. A spike is often a correction for months of underestimation, not a usage change. Saying "your usage jumped 40%" when the truth is "they guessed low for three months" is confidently wrong on our headline feature. Bills mark estimated reads. We read that flag and refuse to conclude across an estimate boundary.

**Variable billing periods.** Cycles run 28 to 35 days. Comparing raw totals without normalising per day manufactures a fake 25% swing. Trivial to fix, catastrophic if missed.

### Bill structure

| Case | Why it breaks us | MVP handling |
|---|---|---|
| Rate change mid-cycle | Two rate blocks on one bill, a single average is wrong | Extract both. MUST. |
| Solar / net metering | Credits, negative bills, annual true-up | Detect and flag. Full support deferred. |
| Arrears carried forward | Total decouples from usage entirely | Separate current charges from balance. MUST. |
| One-time charges (late fee, reconnection, deposit) | Look identical to a usage spike | Classify separately. MUST. |
| Prepaid accounts | No bill, no cycle | Out of scope, flagged clearly |
| Seasonal or vacant property | Zero-usage months break the baseline | Tolerate, do not alarm |

### Capture and extraction

| Case | Why it breaks us | MVP handling |
|---|---|---|
| Bad photo: glare, fold, crop, shadow | Silent partial extraction | Confidence scoring plus targeted confirm. MUST. |
| Paper only, no PDF | Rafael's default | Photo path is a MUST, not an alternative |
| Utility changes bill format | Extraction degrades silently, no error thrown | Confidence floor plus flag for review |
| Duplicate upload | Double counts the month | Dedupe on account plus period. MUST. |
| Corrected or re-issued bill | Supersedes an earlier one | Versioning. SHOULD. |
| Non-English or bilingual bill | Rafael | Extraction language-agnostic, output language a setting. SHOULD. |

### Account and identity

| Case | Why it breaks us | MVP handling |
|---|---|---|
| Bill in someone else's name | Renter, adult child, landlord pass-through | Allow. Never verify ownership. MUST. |
| Multi-property | Wes | Property is a first-class object in the data model. MUST, even where the UI hides it. |
| Shared or split bills | Roommates | Out of scope for MVP |
| Death of account holder | Real, handled badly everywhere | Out of scope, but build nothing that makes it harder |

### Tone and safety

| Case | Why it matters | MVP handling |
|---|---|---|
| Disconnection notice detected | Highest-stakes moment in the product | Calm, specific. Surface assistance programmes. Never amplify anxiety. |
| Our alert looks like a scam | Rafael's lived experience | No urgency styling, no countdowns, no "act now." Ever. |
| We claim an error that isn't one | Destroys trust permanently, costs a wasted phone call | Always "this looks unusual, worth checking." Never "you were overcharged." Always show the evidence. |
| Bad month for a stretched household | Marguerite and Rafael | Do not lecture. "You used more" is not help when there was a heatwave. |

---

## The Agentic Layer

### Architectural principle

**The model is used for perception and expression. Never for computation.**

Reading a crumpled bill photo is perception. Writing one clear sentence at the right reading level is expression. Both are what language models are good at. Calculating that a forty dollar increase is twenty six from a rate change, eleven from usage and three from a new rider is arithmetic, and language models do arithmetic with invisible errors. Deterministic code does it correctly or fails loudly.

### Pipeline

| Stage | What it does | Engine |
|---|---|---|
| 0. Triage | Per file: is this a bill, which provider, which service, which period, which account, duplicate, correction, or not a bill at all | On-device model |
| 1. Extraction | Structured line items, per-field confidence, bounding region on source image | Vision OCR plus on-device model |
| 2. Self-validation | Does the arithmetic close? Line items sum to total, usage times rate equals energy charge, balance forward reconciles, period days match stated dates | Deterministic code |
| 3. Classification | Budget billing, estimated read, solar, arrears, mid-cycle rate change | On-device model plus rules |
| 4. Reconciliation | Dedupe, order into a per-account timeline, stitch account identity across format variations, mark invalid comparison windows | Deterministic code |
| 5. Analysis | Normalise per day, compare like to like, decompose delta into rate, usage, fixed, one-offs | Deterministic code, no model |
| 6. Narration | State the computed result once, clearly, at the right register and in the right language | On-device model |
| 7. Conversation | Answer questions strictly grounded in extracted data, refuse to speculate beyond it | On-device model |

### Why self-validation is load-bearing

A fourteen-bill batch cannot ask for fourteen times twenty field confirmations. Nobody completes 280 confirmations. Batch capture is only viable if the system checks its own work.

It can, because a utility bill is arithmetic that has to close. If the math reconciles, extraction was correct and no human is needed. If it does not, extraction failed and we know exactly which field to ask about. Confirmation drops from every field to the two or three that did not add up.

This is what converts a probabilistic extractor into something trustworthy with money. Under the L2 architecture it does double duty: it is both the quality gate and the privacy router, because it identifies exactly which bills need the cloud fallback.

### One engine, three registers

Same computation, three presentations. Tesler's Law paid off properly.

**Marguerite** gets one sentence and nothing else on screen.

> Your electric bill is $148, due the 22nd. That's normal for this time of year. Nothing looks unusual.

**Dana** gets the sentence plus the reason.

> Electric is up $41 from last March. About $26 of that is a rate increase that took effect January 1. The rest is usage, and March was colder than last year.

**Wes** gets the table, the arithmetic, and the source regions. Every figure tappable back to the pixel it was read from, plus export.

### Guardrails, non-negotiable

The model must never:

1. Assert a number not traceable to a source document
2. Perform arithmetic that determines an outcome
3. State that a charge is an error. Always "this looks unusual, worth calling them about," with evidence shown.
4. Use urgent language, countdowns or alarm styling. Our urgency is indistinguishable from fraud to a user who has been scammed.
5. Answer questions outside the extracted data. "I don't have that" is a correct answer.

Product rule: every anomaly surfaced must come with the specific thing to say on the phone. Flagging a problem the user cannot act on is anxiety delivery.

### Local-first architecture (L2)

Local by default. When validation fails and the arithmetic does not close, the app asks the user whether to send that single page to the cloud for a second look. Most bills never leave the device. The hard ten to fifteen percent do, only with explicit consent.

**What this buys**

- No account required, which removes Marguerite's single biggest objection and takes signup friction to zero
- Works with no signal
- Near-zero per-user inference cost, which neutralises the batch onboarding cost problem
- Trivial export, and almost nothing server-side to delete

**What it costs**

- Household sharing and the caregiver use case, deferred entirely
- Multi-device sync
- Device loss equals data loss without encrypted backup
- Weaker accuracy on poor photographs, which is exactly where Rafael lives, mitigated by guided capture

---

## User Stories

### MUST — Release 1

#### US-001: Batch onboarding drop

**As a** new user,
**I want to** drop a stack of bills from the last year in one action,
**So that** the app has a real baseline before I have used it once.

**Acceptance criteria**

Happy path:
- Given I have 12 bill files on my device, when I select them all and drop them in, then each is triaged, extracted and validated without further input except where validation fails
- Given the batch completes, when I reach the end, then I see a timeline per account and a single summary of what was understood

Edge cases:
- Given the batch contains a non-bill file, when triage runs, then it is set aside with a plain-language reason and the batch continues
- Given the batch contains two copies of the same bill, when reconciliation runs, then one is kept and the duplicate is reported, not silently dropped
- Given the batch contains a corrected re-issue, when reconciliation runs, then it supersedes the original and both are retained
- Given processing is interrupted, when the app reopens, then completed bills are kept and processing resumes

**Out of scope:** cloud batch processing. Batch runs on device.

**Technical notes:** processing must be resumable and must not block the UI. Progress is per file, not a single indeterminate spinner.

**Security considerations:** files never leave the device during batch unless US-011 consent is given per file.

**Priority:** MUST | **Complexity:** M | **Dependencies:** US-002, US-004, US-005

---

#### US-002: Per-file triage

**As a** user dropping mixed files,
**I want to** have the app work out what each file is,
**So that** I do not sort or label anything.

**Acceptance criteria**

Happy path:
- Given a file, when triage runs, then the app determines: is this a utility bill, which provider, which service type, which billing period, which account
- Given a determination, when confidence is below threshold, then the file is queued for confirmation rather than assumed

Edge cases:
- Given a file that is a receipt, a letter, or a photo of something else, when triage runs, then it is set aside with a reason the user can read
- Given a file that appears to be a shutoff notice or a solicitation impersonating a utility, when triage runs, then it is flagged separately and never processed as a bill
- Given a multi-page PDF containing several bills, when triage runs, then each is separated

**Out of scope:** verifying that the account belongs to the user. We never do this.

**Security considerations:** SEC-PM-004. Triage must not become a mechanism for identifying whose account a bill belongs to beyond what is printed on it.

**Priority:** MUST | **Complexity:** M | **Dependencies:** none

---

#### US-003: Guided capture

Rafael can photograph a folded paper bill and get a usable image on the first or second attempt.

**Done when:**
- Camera shows edge detection and a fit guide
- Glare, blur and partial-crop are detected before capture completes and prompt a retake with a specific reason
- A capture that fails quality checks never silently proceeds to extraction
- Works one-handed, standing, in poor light

**Priority:** MUST | **Complexity:** M

---

#### US-004: Extraction with confidence and provenance

**As a** user,
**I want** every figure the app shows me to be traceable to the bill it came from,
**So that** I can check it rather than trust it blindly.

**Acceptance criteria**

Happy path:
- Given a validated capture, when extraction runs, then the app produces structured fields: account, service address, period start and end, usage quantity and unit, rate blocks, each line item with label and amount, subtotal, taxes, previous balance, payments, amount due, due date
- Given each extracted field, when it is stored, then it carries a confidence score and a bounding region referencing the source image
- Given any displayed figure, when the user taps it, then the source region is shown

Edge cases:
- Given a bill format the extractor has not seen, when extraction runs, then confidence drops and the bill routes to confirmation rather than producing a confident guess
- Given a field genuinely absent from the bill, when extraction runs, then it is recorded as absent, not zero

**Technical notes:** on-device vision OCR plus a small local model for structuring. Bounding regions are required, not optional, because they are the substrate for US-009.

**Security considerations:** SEC-PM-001, SEC-PM-002. Bill images and extracted fields are PII with identity-theft value.

**Priority:** MUST | **Complexity:** L | **Dependencies:** US-003

---

#### US-005: Arithmetic self-validation

**As a** user,
**I want** the app to check its own reading of my bill,
**So that** I am not asked to verify twenty fields per bill.

**Acceptance criteria**

Happy path:
- Given an extracted bill, when validation runs, then the app checks that line items sum to the subtotal, subtotal plus taxes equals current charges, previous balance plus current charges minus payments equals amount due, usage times rate equals the energy charge, and period end minus period start matches any stated day count
- Given all checks pass, when validation completes, then the bill is accepted with no user confirmation required

Edge cases:
- Given one check fails, when validation completes, then the specific failing fields are identified and only those go to confirmation
- Given the bill type makes a check inapplicable, for example budget billing or a solar credit, when validation runs, then that check is skipped rather than failed
- Given rounding differences under one cent, when validation runs, then they are tolerated

**Out of scope:** validating that the utility's own arithmetic is correct. That is US-013, and it is a different question.

**Technical notes:** deterministic code only. No model involvement at this stage, ever.

**Priority:** MUST | **Complexity:** M | **Dependencies:** US-004

---

#### US-006: Targeted confirmation

Dana confirms only the two or three fields that failed validation, not the whole bill.

**Done when:**
- Confirmation shows the source region alongside the field in question
- The user can correct the value directly
- A correction re-runs validation
- No bill that passed validation ever asks for confirmation

**Priority:** MUST | **Complexity:** S | **Dependencies:** US-005

---

#### US-007: Bill-type classification

**As a** user on a budget billing plan,
**I want** the app to know that my bill does not vary with usage,
**So that** it does not tell me nothing changed as though that were an insight.

**Acceptance criteria**

Happy path:
- Given a bill, when classification runs, then the app identifies whether it is budget billing, contains an estimated read, contains arrears, contains solar or net metering credits, contains a mid-cycle rate change, or contains one-time charges
- Given budget billing is detected, when the bill is displayed, then the app tracks the deferred balance and the true-up date rather than comparing month to month
- Given an estimated read is detected, when comparison would cross that boundary, then no conclusion about usage change is drawn and the reason is stated

Edge cases:
- Given a bill with both arrears and a one-time late fee, when classification runs, then both are identified and separated from current usage charges
- Given a solar credit producing a negative bill, when classification runs, then it is handled without error and flagged as outside full support

**Technical notes:** classification must run before any analysis stage. The system must know what kind of bill it is looking at before it says anything about what changed.

**Priority:** MUST | **Complexity:** M | **Dependencies:** US-004

---

#### US-008: Unified due view

Marguerite opens the app and sees, on one screen, whether anything is owed and whether anything looks wrong.

**Done when:**
- All providers appear in one list ordered by due date
- No more than five items are on the primary screen
- The screen answers "am I alright" without scrolling
- All targets are at least 60px
- No urgency styling, countdowns or alarm colours are used anywhere on this screen

**Priority:** MUST | **Complexity:** S | **Dependencies:** US-004

---

#### US-009: Provenance and audit trail

Wes taps any number and sees the region of the source bill it was read from.

**Done when:**
- Every displayed figure links to its source region
- The source image is retained for as long as the bill record exists
- Corrections made by the user are recorded alongside the original extraction, not overwriting it

**Priority:** MUST | **Complexity:** M | **Dependencies:** US-004

---

#### US-010: Encrypted local backup and restore

A user who loses or replaces their phone can restore their bill history.

**Done when:**
- Backup is encrypted and the user controls where it goes
- Restore reproduces the full history including source images and provenance
- The backup mechanism does not require an account
- The user is told clearly, at first run, that no server copy exists

**Priority:** MUST | **Complexity:** M

---

#### US-011: Per-bill cloud consent

**As a** privacy-conscious user,
**I want to** decide bill by bill whether anything leaves my device,
**So that** the local-first promise is mine to enforce, not a claim I have to take on faith.

**Acceptance criteria**

Happy path:
- Given a bill fails validation and local re-extraction does not resolve it, when the app cannot proceed, then it asks whether to send that single page to the cloud, stating what will be sent and why
- Given the user declines, when they decline, then the bill is retained with the fields that were readable and marked incomplete, and the app continues to function

Edge cases:
- Given a batch with four failing bills, when consent is requested, then the user may answer once for the batch or individually, and the choice is not remembered as a standing permission by default
- Given the user has never granted consent, when they use the app, then no network call carrying bill content is ever made

**Out of scope:** automatic cloud fallback without asking. This never happens.

**Security considerations:** SEC-PM-002, SEC-PM-003. What is sent, where it goes, and what is retained must be stated in the consent prompt in plain language, not in a policy document.

**Priority:** MUST | **Complexity:** S | **Dependencies:** US-005

---

### MUST — Release 2

#### US-012: Change decomposition

**As a** user seeing a higher bill,
**I want to** know how much of the increase is rate, usage, fixed charges and one-offs,
**So that** I know whether this is something I did, something they did, or something wrong.

**Acceptance criteria**

Happy path:
- Given two comparable bills for the same account, when decomposition runs, then the delta is split into: rate change, usage change, fixed charge change, one-time charges, and stated in dollars
- Given billing periods of different lengths, when decomposition runs, then values are normalised per day before comparison
- Given the comparison, when it is presented, then it compares the same period last year by default, not the previous month

Edge cases:
- Given either bill contains an estimated read, when decomposition runs, then no usage conclusion is drawn and the reason is stated plainly
- Given the account is on budget billing, when decomposition runs, then it compares actual usage against the levelized amount and tracks the deferred balance instead
- Given fewer than two comparable bills exist, when the user opens the bill, then the app says what it does not yet know rather than guessing
- Given a mid-cycle rate change, when decomposition runs, then both rate blocks are used

**Technical notes:** deterministic arithmetic. The model narrates the result and does not compute it. Every component of the decomposition must be independently displayable for US-009.

**Priority:** MUST, Release 2 | **Complexity:** L | **Dependencies:** US-005, US-007

---

#### US-013: Anomaly flagging

**As a** user,
**I want to** be told when something on my bill looks wrong,
**So that** I can call the utility with a specific question instead of a vague suspicion.

**Acceptance criteria**

Happy path:
- Given a decomposed bill, when a component falls outside expected bounds, then the app surfaces it as something worth checking, shows the evidence, and provides the specific sentence to say when calling
- Given an anomaly is surfaced, when it is displayed, then the language is "this looks unusual, worth checking" and never "you were overcharged"

Edge cases:
- Given the bill did not pass validation cleanly, when anomaly detection would run, then it does not run and nothing is flagged. Silence is preferred to a guess.
- Given an anomaly is explained by a classified bill type, for example arrears or a one-time fee, when detection runs, then it is not flagged as an anomaly
- Given the user marks a flag as wrong, when they do so, then it is recorded and that pattern is not re-flagged for that account

**Out of scope:** contacting the utility, disputing a charge, or asserting a legal position.

**Security considerations:** false positives carry real cost to the user. The false-positive rate is a tracked metric with a hard target.

**Priority:** MUST, Release 2 | **Complexity:** M | **Dependencies:** US-012

---

### SHOULD

#### US-014: Plan and contract change detection

The app detects from the bill that a supply contract expired or a rate plan changed.

**Done when:** a plan or contract change visible on the bill is surfaced with the date it took effect and its dollar impact.
**Priority:** SHOULD | **Complexity:** M

#### US-015: Due date reminders

The user is reminded before a bill is due.

**Done when:** reminders are timed to the user's choice, use no urgency styling, no countdown and no alarm colour, and can be turned off entirely.
**Priority:** SHOULD | **Complexity:** S

#### US-016: Export

Wes exports everything as CSV and JSON.

**Done when:** export includes all extracted fields, corrections, provenance references and bill type classifications, and is readable without the app.
**Priority:** SHOULD | **Complexity:** S

#### US-017: Output language

Rafael reads the app in Spanish while his bills stay in English.

**Done when:** output language is a setting independent of bill language, and extraction quality is unaffected by it.
**Priority:** SHOULD | **Complexity:** S

#### US-018: Assistance programme surfacing

A user with arrears or a disconnection notice is shown the assistance programmes available in their state.

**Done when:** programmes are surfaced calmly and specifically, with eligibility stated plainly and no judgement in the copy.
**Priority:** SHOULD | **Complexity:** M

#### US-019: Corrected bill versioning

A re-issued bill supersedes the original without losing it.

**Done when:** both versions are retained, the current one is used for analysis, and the change between them is visible.
**Priority:** SHOULD | **Complexity:** S

#### US-020: Grounded conversation

Wes asks a question about his bills and gets an answer drawn only from extracted data.

**Done when:** answers cite the bills they come from, questions outside the data return an explicit "I don't have that," and no figure appears in an answer that is not traceable.
**Priority:** SHOULD | **Complexity:** M

---

## Key User Flows

### Flow 1: First run, batch onboarding

Flow: Open app → Explain in one screen → Drop files → Processing → Confirm failures only → Timeline

```
+---------------------------------------------------+
|                                                   |
|   Add your bills.                                 |
|                                                   |
|   Photos or PDFs. As many as you have.            |
|   Everything stays on this phone.                 |
|                                                   |
|   +-------------------------------------------+   |
|   |          Choose files                     |   |
|   +-------------------------------------------+   |
|                                                   |
|   +-------------------------------------------+   |
|   |          Take a photo                     |   |
|   +-------------------------------------------+   |
|                                                   |
|   No account. No sign up.                         |
|                                                   |
+---------------------------------------------------+
```

Walkthrough:
1. No account creation. The app is usable in one tap. This is the single largest differentiator at the front door and it exists only because of the local-first decision.
2. The user selects any number of files. The copy invites a stack, not a single bill, because cold start is the enemy.
3. Processing shows per-file progress with the provider name as it is identified, so the user watches it work rather than watching a spinner.
4. Only bills that failed validation request confirmation. In a clean batch of twelve, the user confirms nothing.
5. The flow ends on the timeline with a plain summary. Peak-End: the end state is an answer, not a dashboard.

Decision points:
- Files versus camera at entry
- Per-batch versus per-bill consent if any bill fails and needs the cloud
- Skip confirmation and accept incomplete data, always available

### Flow 2: Monthly single bill

Flow: Notification or open → Capture → Extract and validate → Answer

```
+---------------------------------------------------+
|                                                   |
|   Ohio Edison                                     |
|                                                   |
|   $148.20                                         |
|   Due March 22                                    |
|                                                   |
|   -------------------------------------------     |
|                                                   |
|   Normal for this time of year.                   |
|   Nothing looks unusual.                          |
|                                                   |
|   -------------------------------------------     |
|                                                   |
|   +-------------------------------------------+   |
|   |          See the details                  |   |
|   +-------------------------------------------+   |
|                                                   |
+---------------------------------------------------+
```

Walkthrough:
1. The amount and the date are the two largest things on screen. Everything Rafael needs is above the fold.
2. One sentence of interpretation. This is Marguerite's entire product.
3. Detail is one tap away and never the default. Tesler's Law.
4. Five items maximum on this screen. Miller's Law.
5. No colour is used to signal alarm. A normal bill and an unusual one differ in words, not in red.

### Flow 3: Something looks wrong

Flow: Answer screen → Anomaly → Evidence → What to say

```
+---------------------------------------------------+
|                                                   |
|   Ohio Edison                                     |
|                                                   |
|   $189.40                                         |
|   Due March 22                                    |
|                                                   |
|   -------------------------------------------     |
|                                                   |
|   Up $41 from last March.                         |
|                                                   |
|   $26  Rate increase, effective Jan 1             |
|   $11  You used more                              |
|   $ 4  New distribution rider                     |
|                                                   |
|   -------------------------------------------     |
|                                                   |
|   The rider is new this month and is not          |
|   listed on your plan. Worth checking.            |
|                                                   |
|   +-------------------------------------------+   |
|   |     What to say when you call             |   |
|   +-------------------------------------------+   |
|                                                   |
+---------------------------------------------------+
```

Walkthrough:
1. The decomposition is the answer. Three numbers, not a chart.
2. Each line is tappable to its source region on the bill. Provenance is a tap, not a menu.
3. The anomaly is phrased as worth checking. Never as a verdict.
4. The flow ends on an action the user can actually take. Peak-End: the memorable end is empowerment, not alarm.
5. No urgency styling despite this being the highest-stakes screen in the product.

---

## Success Metrics

### Primary (North Star)

| Metric | Target | How we measure |
|---|---|---|
| Explained bills per household per month | 3 or more within 60 days of first use | Count of bills captured that produced an explanation the user did not dispute or correct |

Three matters because it means the user has moved past one utility and made this the place they look.

### Secondary (health indicators)

| Metric | Target | Why it matters |
|---|---|---|
| Capture completion rate | 85%+ | Started captures reaching a confirmed bill. Below this the photo flow is broken and nothing downstream matters. |
| Batch completion rate | 90%+ of files in a batch reaching a usable record | Onboarding is the batch. If it fails, there is no product. |
| Validation pass rate without confirmation | 80%+ | The proportion of bills where arithmetic closes on first pass. This is the number that makes batch viable. |
| Cloud fallback rate | Under 15% of bills | Measures how well the local-first promise holds in practice |
| Time from capture to answer | Median under 30 seconds | Doherty Threshold. Longer and the user context-switches away. |
| Extraction field accuracy | 95%+ across the top 20 US utility formats | Measured at the confirmation step, which supplies free ground truth |
| Anomaly false positive rate | Under 5% | The most dangerous number in the product. One wrong flag costs a pointless phone call and permanent trust. |
| Month 2 retention | 40%+ | Monthly product, so month 2 is the real signal, not day 7 |

### Not optimising for

| Metric | Reason |
|---|---|
| Daily active users | This is a monthly product. Chasing DAU means manufacturing reasons to open it, which is how good tools become annoying. |
| Session length | Longer sessions mean confusion, not engagement. Two minutes and out is the goal. |
| Feature breadth | Six incumbents beat us on breadth. We win on depth of one thing. |
| Conversation volume | Chat is the escape hatch, not the product. High usage would mean the main flow failed. |

---

## Open Questions

| Question | Impact | Owner | Status |
|---|---|---|---|
| iOS first, Android first, or both? | Determines timeline and which on-device stack | Owner | Open |
| What happens on the very first screen before any bill exists? | Onboarding quality | Designer | Open, raised at MoSCoW gate, not yet answered |
| Account recovery with no account | Backup and restore UX | Designer | Open |
| Which 20 utility formats define the accuracy target? | Test corpus scope | Owner | Open |
| Does register switching adapt automatically or is it a setting? | Core interaction model | Designer | Open |
| Cloud fallback provider and its retention policy | Determines whether the L2 promise is defensible | Architect | Open |
| Is there a path back to household sharing in v2? | Reopens the caregiver market closed by D9 | Owner | Open |

---

## Security Considerations Summary

Identified, not solved. Passed to the Architect.

| ID | Category | Consideration | Owner |
|---|---|---|---|
| SEC-PM-001 | data_protection | Utility bills contain full name, service address, account number and payment history. PII with identity-theft value, not merely financial data. | architect |
| SEC-PM-002 | data_protection | The cloud fallback path sends bill imagery to a third party. Where it runs, what it retains, and how that is disclosed is product-defining, not a vendor choice. | architect |
| SEC-PM-003 | data_protection | Local-first is the architecture. Every design decision must preserve it, and any server-side component requires explicit re-approval. | architect |
| SEC-PM-004 | authorization | Users may add bills in another person's name, legitimate for renters and family. We must never verify ownership, and must never allow this to become a surveillance mechanism. | architect |
| SEC-PM-005 | compliance | US only. State privacy laws apply, notably CCPA/CPRA. Utility account data may carry additional state protections. Legal review before launch. | architect |
| SEC-PM-006 | data_protection | Export and deletion must be real and complete. Largely simplified by local-first, but the encrypted backup is now the surface that matters. | architect |
| SEC-PM-007 | data_protection | Encrypted local backup becomes the single point of data loss and the single most valuable artifact to steal. Key handling is critical. | architect |

---

## Appendix A: Competitive Analysis

### Open source

| Product | What it does well | Where it falls short | Target user |
|---|---|---|---|
| ericg1840/Billtracker | Client-only, no backend, localStorage. Month-over-month trend, category breakdown, due-soon widget at five days, PDF extraction with human review. | Zero stars, six commits, default branch is an AI-generated branch name. Unmaintained. No savings analysis. | Self-hosters |
| Billzzz | MIT, self-hosted. Recurring expenses by category, flexible frequencies, payment history. | No trend analysis, no savings insight | Self-hosters |
| MoneyMatter | Docker self-hosting, auto-categorisation that learns, bring-your-own OpenAI-compatible endpoint including local models | General budgeting, not utility-specific. No bill reading. | Privacy-focused technical users |
| Home Assistant Energy Dashboard, emoncms | Genuine consumption monitoring, identifies energy-hungry appliances, detects abnormal usage | Kilowatt hours, not dollars. No bills, no due dates. | Home automation enthusiasts |

### Commercial

| Product | What it does well | Where it falls short | Pricing | Target user |
|---|---|---|---|---|
| Copilot Money | Detects recurring bills, AI learns spending behaviour, monthly view | Sees the total, never the line items. Cannot explain why. | Subscription | Financially engaged consumers |
| WalletHub | All recurring bills in one place, category totals, six-month average | Bank-sync layer. Never reads the bill. | Free | Mainstream consumers |
| TimelyBills | AI-predicted alerts before due dates, covers utilities, subscriptions, rent, loans | Reminder product, not an explanation product | Freemium | Bill-payers |
| EverSafe | Monitors accounts for irregular activity and missed payments, alerts family members | Not a bill product. Fraud monitoring for seniors. | ~$8/month | Seniors and families |

### Positioning statement

> **We read the bill, not just the amount.** Every other tool tells you what you spent. We tell you why it changed, whether it should have, and what specifically to do about it, in language that does not require a utility glossary, on a device that never uploads your data.

### The structural gap

Every existing tool either pays the bill or categorises the amount. Not one of them reads the bill.

This is defensible because the industry data standard cannot close it. Green Button, the open standard for utility data access, explicitly excludes bill PDFs, demand, line item detail, time-of-use breakdowns and third-party supplier charges. Incumbents with bank and utility integrations structurally cannot see what a photograph reveals. The hard thing here is not something the big players have and we lack. It is something the standard itself does not carry.

---

## Appendix B: Why Now

Three changes, and they compound.

**The money got serious.** The US average residential electricity rate reached 18.34 cents per kWh as of June 2026, up 38.7% in six years per EIA data, and rose 7.3% between April 2025 and April 2026 alone. Utilities requested a record 31 billion dollars in rate hikes across 2025, more than double the 15 billion sought in 2024, and nearly half of those 2025 requests remained unapproved as of early 2026, meaning a further wave is still reaching consumer bills. Roughly one in six US households entered 2026 already behind on utility payments.

**Extraction became tractable.** Vision-capable models can now pull structured line items from an arbitrary utility bill without a per-utility template. Five years ago this required OCR pipelines that broke on every format change.

**On-device made it private.** Apple's Foundation Models framework gives developers a roughly 3B parameter on-device model free of cost, with OCR tooling backed by the Vision framework for extracting structured text from images, and guidance that on-device models suit focused extraction and classification tasks with bounded outputs. That is exactly this workload. Local-first extraction was not viable eighteen months ago. It is now.

---

## Handoff

**Product Requirements complete.**

- 13 MUST features defined across two releases
- 9 SHOULD features defined
- 20 user stories written
- 4 personas documented, 2 as markets and 2 as design constraints
- 3 key flows wireframed
- 8 metrics defined with targets
- 7 security items identified and passed to the Architect
- 8 competitors analysed across open source and commercial

**Ready for:**
- Agent 2, UX/UI Designer: design brief, information architecture, flows, component inventory, design tokens
- Agent 3, System Architect: on-device model selection, data model with property as a first-class object, validation engine, encrypted backup, cloud fallback contract

These can proceed in parallel.
