# 03 Ideate: three concepts and a recommendation

Skills: `parallel-concepts`, `jakobs-law`, `teslers-law`.

## The question the set answers

Where does a repeating payment begin, and who decides its schedule: the user, filling a form, or the product, inferring it from what it already knows?

All three concepts use the Define model (Payee, Schedule, Occurrence) and the same visual language. They differ in entry point, division of labour, and unit of interaction, which is the behavioural test `parallel-concepts` requires.

## Concept A: Remind me from the bill

Entry point: a bill the user is already looking at. Unit: one bill at a time. Division of labour: user decides everything.

1. User opens a bill (`/bill/:id`) and taps "Remind me next time".
2. A bottom sheet asks: Repeats (Monthly preselected), Remind me (1 day before), Save.
3. The schedule is created for that account, anchored on this bill's due day.
4. Next cycle's reminder appears in the Bills list as a ghost row ("Expected Oct 15, Ohio Edison, about $142").

Tests: whether contextual setup from an existing bill is enough.
Strength: zero navigation, strong context, amount known.
Weakness: fails J3 for payments that never produce a bill (rent, insurance, gym) and has no forward overview (J2). Payments start only after the first bill is already in.

## Concept B: Upcoming hub with a form

Entry point: a dedicated Upcoming screen. Unit: a list of every upcoming payment. Division of labour: user fills a full form.

1. Bills tab header gets an Upcoming icon; the screen shows a 90-day list grouped by This week, Next week, Later this month, Later.
2. "Add repeating payment" opens a full form: Paid to (with logo), Amount, Repeats, First due date, Remind me, Ends.
3. Each row supports Mark paid, Snooze, Skip this one.

Tests: whether a single planning surface drives weekly use (J2).
Strength: covers every payment type, gives the forward view, conventional form.
Weakness: the user re-types what BillSense already knows about their six existing accounts; empty on day one, which weakens first impressions.

## Concept C: Suggested schedules

Entry point: the product proposes. Unit: a batch of suggestions. Division of labour: product infers, user confirms.

1. BillSense scans bill history per account. Two or more bills with regular spacing (for example 28 to 33 days apart) yield a suggestion: "Ohio Edison looks monthly, around the 15th. Remind you 3 days before?"
2. A Coming up section on the Bills tab shows suggestions as cards with Confirm and Not now.
3. Confirming creates the schedule with inferred cadence, anchor, and last amount. Editing opens the same form as B.
4. For payments without history, a manual path exists but is secondary.

Tests: whether inference plus one-tap confirm beats manual setup.
Strength: day-one value from existing data; lowest effort for J3 on known payees.
Weakness: inference can be wrong (quarterly water billed at irregular intervals); a pure suggestion model leaves no clear home for rent or insurance; suggestions can feel presumptuous if pushed too often.

## Conventions to follow and where to depart (`jakobs-law`)

Audit of recurrence pickers users already know: Google Calendar, Apple Reminders, Apple Calendar, Todoist, and bank "scheduled payments" screens.

| Convention | Follow or depart | Reason |
| --- | --- | --- |
| Repeat presets first, "Custom" last | Follow | Every audited product does this; a custom-only picker would impose learning cost on a once-per-payee task |
| Preset phrasing "Every month on the 15th" generated from the start date | Follow | Google Calendar's pattern; users check dates, not rule syntax |
| Presets Daily, Weekly, Monthly, Yearly | Depart: drop Daily; add Every 3 months | No bill is daily. Quarterly is common for water, insurance, and taxes and would otherwise force Custom |
| "Last day of the month" option | Follow (Google Calendar, banks) | Rent and card payments often anchor there; clamping the 31st silently is wrong |
| "Alert: 1 day before" dropdown | Follow the placement, depart on defaults | Defaults vary by cadence (below) instead of one global value |
| Ends: Never / On date / After N | Follow, but collapse under "Ends: Never" | Rarely changed; keeping it visible adds a decision to every setup |
| Swipe row to complete | Do not rely on it | Web on desktop has no swipe; buttons are primary, swipe is an accelerator on touch |

## Who carries the complexity (`teslers-law`)

Inherent complexity that cannot be removed: a payment's cadence, its anchor day, its lead time, and its end. Everything else is extraneous and should be absorbed by the product.

| Decision | Who carries it | How |
| --- | --- | --- |
| Payee name and category | Product, when an account exists; user otherwise | Autocomplete from accounts; category inferred from name (`CategoryIcons.kindFor` already does this) |
| Payee logo | Product | Domain guessed from the name, logo fetched automatically; user can correct the website only if the logo is wrong |
| Cadence | Product proposes, user confirms | Inferred from bill history (concept C); otherwise Monthly preselected (most common for household bills) |
| Anchor day | Product | Taken from the first due date the user picks; "last day" offered when they pick the 29th to 31st |
| Amount | Product when known | Last bill amount, or "Varies" toggle; never required |
| Lead time | Product default by cadence, user can change | Weekly: on the day. Monthly: 3 days before. Quarterly: 1 week. Yearly: 2 weeks |
| Reminder time of day | Product | 9:00 local; editable only in Settings, not in the form |
| End rule | Product defaults to Never | Available under a collapsed row |

The risk Tesler warns about, over-defaulting a critical decision, applies to the anchor date: a wrong due date silently breaks J1. So the date is the one field the user always sees and confirms, backed by the "next 3 payments" preview planned in Prototype.

## Recommendation: C inside B, with A as a shortcut

Adopt B's Upcoming hub as the home of all repeating payments and its form as the single editing surface. Seed it with C's suggestions so it is useful on day one. Keep A's "Make this recurring" row on the bill detail as a contextual shortcut into the same form, prefilled.

Scored against the job statements:

| Job | A | B | C | Recommended hybrid |
| --- | --- | --- | --- | --- |
| J1 Never miss a due date | Partial: only after a first bill | Yes | Yes for known payees | Yes |
| J2 See what is coming | No overview | Yes | Partial | Yes |
| J3 Capture once, fast | Fast for billed payees, impossible for others | Complete but slow | Fastest for known, weak for new | Fast for both |

What is cut: A's ghost rows in the main Bills list (they mix projected and real bills in one list, which risks the double-listing the IA rule forbids). Projected payments live in the Coming up section and Upcoming screen only.

Guardrails on suggestions: at most two suggestion cards at once; "Not now" hides a suggestion for 60 days; never suggest from fewer than two bills; never suggest for a payee that already has a schedule.

## Stage check-in

Produced: three concepts with distinct entry points and division of labour, a convention audit, a complexity allocation table, and a recommended hybrid. Next: Prototype specifies the hybrid in detail. The plan holds; the one addition is a small inference rule set for suggestions, which Prototype specifies in the flows and handoff.
