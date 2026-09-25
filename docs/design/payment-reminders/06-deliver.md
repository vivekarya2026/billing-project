# 06 Deliver: engineering handoff and design QA checklist

Skills: `handoff-spec`, `design-qa-checklist`.

Build from 04 (revised after Test). This file adds what engineering needs that the prototype does not: data shapes, algorithms, routes, file placement, tokens, copy, events, and platform constraints.

---

## Part 1: Handoff spec

### 1. Scope of v1

In: repeating payments (create, edit, pause, delete), computed occurrences with paid / snoozed / skipped overrides, Coming up section on the Bills tab, `/upcoming` screen, suggestions from bill history, ProviderLogo, bill-to-occurrence linking, Settings > Reminders rework, browser notifications while open, `.ics` calendar export.

Out: email, SMS, native push, paying in-app, shared households, amount prediction beyond last bill.

### 2. Data model

New files in `frontend/lib/shared/models/`:

```dart
// payee.dart
class Payee {
  final String id;
  final String name;          // "Netflix"
  final String? domain;       // "netflix.com", for ProviderLogo
  final String? serviceType;  // same vocabulary as Account.serviceType
  final String? accountId;    // set when derived from an Account
}

// schedule.dart
enum CadenceUnit { week, month, year }
enum MonthEndRule { clamp, lastDay }            // 04 form field 4b
enum AmountMode { fixed, lastBill, varies }
enum EndRule { never, onDate, afterCount }

class Schedule {
  final String id;
  final String payeeId;
  final CadenceUnit unit;
  final int interval;                 // 1..52; quarterly = month x 3
  final DateTime anchorDate;          // first due date as entered (may be past)
  final MonthEndRule monthEnd;        // only meaningful when anchor day >= 29
  final DateTime trackFrom;           // creation day; no occurrences before it (H2)
  final EndRule endRule;
  final DateTime? endDate;
  final int? endCount;
  final AmountMode amountMode;
  final double? amount;
  final int? leadDays;                // null = don't remind
  final bool paused;
  final DateTime createdAt;
}

// occurrence.dart
enum OccurrenceState { upcoming, dueSoon, dueToday, overdue, snoozed, paid, skipped }

class OccurrenceOverride {           // the only persisted occurrence data
  final String scheduleId;
  final DateTime dueDate;            // identity together with scheduleId
  final OccurrenceState state;       // paid | skipped | snoozed
  final DateTime? snoozedUntil;
  final DateTime? paidAt;
  final String? billId;
}

class Occurrence {                   // computed, never stored whole
  final Schedule schedule;
  final Payee payee;
  final DateTime dueDate;
  final DateTime? remindAt;          // null when leadDays == null
  final OccurrenceState state;
  final double? amount;              // from linked bill, else schedule
  final bool amountIsEstimate;       // true for lastBill mode (renders "about $142")
  final String? billId;
}
```

Supabase tables (for the non-demo path; mirrors the above): `payees`, `schedules`, `occurrence_overrides` with unique `(schedule_id, due_date)`. Row-level security by `user_id`, same as `accounts`. Migration file under `backend/` following existing conventions; not required for the demo.

### 3. Recurrence algorithm

Pure Dart, in `frontend/lib/shared/logic/recurrence.dart`, fully unit-tested. No package needed.

```text
nthDue(schedule, n):
  week:  anchorDate + 7 * interval * n days
  month: y/m = anchor month + interval * n
         day = monthEnd == lastDay ? lastDayOf(y, m)
                                   : min(anchor.day, lastDayOf(y, m))
  year:  y = anchor.year + interval * n
         day = (anchor is Feb 29 and y not leap) ? Feb 28 : anchor day

occurrences(schedule, from, to):
  start n at the smallest index whose due >= max(trackFrom, from)   // H2
  yield nthDue while due <= to and end rule not reached
  endCount counts from n = 0 of the anchor, so "after 12 payments" is stable
```

State derivation for an occurrence (overrides win, then by clock, device local time, H10):

```text
if override paid or skipped -> that state
if linked bill isPaid       -> paid
if override snoozed and now < snoozedUntil -> snoozed
if today > due   -> overdue
if today == due  -> dueToday
if remindAt != null and now >= remindAt -> dueSoon
else upcoming
```

`remindAt` = `dueDate - leadDays` at the Settings reminder time (default 09:00).

Weekly collapse: for one schedule, show only the most recent unresolved occurrence; if older unresolved ones exist, the row shows "N missed". The header badge counts schedules with any occurrence in dueSoon, dueToday, or overdue (H9).

### 4. Bill linking

On `createBill` and `updateBill` in the repository: find a schedule whose payee has the bill's `accountId`, then the occurrence whose due date is within 5 days of the bill's due date; upsert an override with `billId`. The Bills list shows the bill; Coming up shows the occurrence with a "Bill received" tag and the bill's amount. Mark paid on either side updates both (H6): `occurrence paid` sets `is_paid` on the bill; `bill isPaid` resolves the occurrence.

### 5. Suggestions

In `frontend/lib/shared/logic/schedule_suggestions.dart`:
- Per account with no schedule, take bill due dates sorted.
- Monthly candidate if consecutive gaps are 26 to 35 days; quarterly if 85 to 97; yearly if 355 to 375; weekly if 6 to 8.
- Require 2 bills when all gaps are within 4 days of each other, else 3 (H8).
- Anchor day = median day-of-month (or weekday for weekly). Amount mode `lastBill`.
- Show at most 2; dismissed suggestions stored in `shared_preferences` as `accountId -> dismissedAt`, hidden 60 days.

### 6. Repository additions

Add to `BillRepository` in `frontend/lib/shared/data/bill_repository.dart` (both the Supabase and Fake implementations):

```dart
Future<List<Payee>> getPayees();
Future<Payee> upsertPayee(Payee payee);
Future<List<Schedule>> getSchedules();
Future<Schedule> createSchedule(Schedule s);
Future<void> updateSchedule(String id, Map<String, dynamic> changes);
Future<void> deleteSchedule(String id);          // soft, for Undo
Future<void> restoreSchedule(String id);
Future<List<OccurrenceOverride>> getOverrides({DateTime? from, DateTime? to});
Future<void> upsertOverride(OccurrenceOverride o);
Future<void> deleteOverride(String scheduleId, DateTime dueDate);  // Undo
```

`FakeBillRepository`: keep everything in memory, call the existing `_bump()` so `FakeBillRepository.revision` refreshes the Bills tab and Upcoming. Seed data: derive payees from the six seeded accounts; create two schedules (Netflix monthly on the seeded due day, lead 3 days; a free-standing "Car insurance" yearly, $640, lead 14 days) so Coming up and Upcoming are populated in the demo; leave Spectrum unscheduled so a suggestion appears.

### 7. Routes and screens

Add to `frontend/lib/router.dart` as stacked routes (outside the shell, like `/bill/:id`):

| Route | Screen file | Notes |
| --- | --- | --- |
| `/upcoming` | `features/reminders/upcoming_screen.dart` | Segments Payments / Repeating (H7) |
| `/schedule/new` | `features/reminders/schedule_form_screen.dart` | Query params for prefill: `?billId=` or `?accountId=` |
| `/schedule/:id` | `features/reminders/schedule_detail_screen.dart` | |
| `/schedule/:id/edit` | same form screen, edit mode | |

Changes to existing screens:
- `features/home/home_screen.dart`: Coming up section above `BillTypeFilter`; header Upcoming icon with badge. Listen to `FakeBillRepository.revision` as the list already does.
- `features/bill_capture/add_bill_screen.dart`: third option "Repeating payment", subtitle "Rent, insurance, subscriptions. We'll remind you."
- `features/bill_detail/bill_detail_screen.dart`: Repeats row (04 section 4e).
- `features/settings/settings_screen.dart` and `state/settings_state.dart`: replace the 3-option picker with the Reminders sheet (04 section 4f). New keys: `reminder_default_lead` (int or null), `reminder_time` ("09:00"), `browser_notifications` (bool). Migration on first load: `off` to null, `day_before` to 1, `day_of` to 0; keep reading the old `reminders` key once, then remove it.

Post-save navigation follows the pattern already used for manual bills: `context.pop()` back to the entry screen (not `go`), then a floating SnackBar with Undo, 4 seconds.

### 8. Components

| Component | File | Spec |
| --- | --- | --- |
| `ProviderLogo` | `shared/components/provider_logo.dart` | 04 section 6 |
| `PaymentRow` | `shared/components/payment_row.dart` | Logo, name, due phrase, amount, Mark paid button, overflow. Reuse `BillListRow`'s compact metrics: tile 40 / 46, vertical padding `space3` / `space4` |
| `ComingUpSection` | `features/reminders/widgets/coming_up_section.dart` | Header "Coming up" + "See all", up to 3 rows + 2 suggestion cards |
| `SuggestionCard` | `features/reminders/widgets/suggestion_card.dart` | Confirm (primary), Edit, Not now (text) |
| `RepeatPicker` | `features/reminders/widgets/repeat_picker.dart` | Four chips + Custom repeat + summary sentence |
| `NextPaymentsPreview` | `features/reminders/widgets/next_payments_preview.dart` | 3 dates, first reminder, weekend tag |

Reuse, do not re-create: `CategoryIcons.kindFor` / `colorForKind` for monogram colour, `DateFormat('MMM d')` phrasing consistent with `_fmtDue` in `home_screen.dart`, `PrimaryButton`, `BillTypeFilter` untouched.

### 9. Visual tokens

All from `theme/tokens.dart` and the theme `TextTheme`; no raw values.

| Element | Token |
| --- | --- |
| Screen edge padding | `AppTokens.screenEdge` |
| Row vertical padding | `space3` compact, `space4` default |
| Gap logo to text | `space2` compact, `space3` default |
| Section header gap above | `space6` |
| Card and sheet radius | `radiusLg` (12) |
| Chip radius | `radiusFull` |
| Field radius | `radiusField` (6) |
| ProviderLogo radius | 0.22 x size (matches `CategoryTile`) |
| Logo inset tile | `colorScheme.surface` of the light scheme on both themes, 1px `outlineVariant` border |
| Overdue accent | `colorScheme.error` plus the word "overdue" (never colour alone) |
| Due today accent | the same accent the home sentence uses for "today" |
| Section header | `labelMedium`, uppercase as existing month headers do |
| Payee name | `titleMedium` |
| Due phrase, helper text | `bodySmall` |
| Amount | `titleMedium`, tabular figures |
| Minimum target | 44 x 44 for Mark paid, overflow, chips |

Compact (< 400pt) uses the compact type scale automatically through the theme; no per-widget font sizes.

### 10. Copy strings

| Key | String |
| --- | --- |
| `comingUp.title` | Coming up |
| `comingUp.seeAll` | See all |
| `row.dueIn` | Due {weekday}, {MMM d}, in {n} days |
| `row.dueToday` | Due today |
| `row.overdue` | Overdue by {n} day(s) |
| `row.missed` | {n} missed |
| `row.billReceived` | Bill received |
| `amount.estimate` | about {amount} |
| `amount.varies` | Varies |
| `action.markPaid` | Mark paid |
| `action.snooze` | Snooze |
| `action.skip` | Skip this one |
| `snooze.options` | Tomorrow / In 3 days / Pick a day |
| `form.title.new` | Add repeating payment |
| `form.title.edit` | Edit repeating payment |
| `form.paidTo.error` | Add who you pay, for example Netflix or Landlord. |
| `form.website.helper` | We use the website to find the logo. |
| `form.website.error` | Enter a website like netflix.com. |
| `form.amount.helper` | Leave empty if it changes each time. |
| `form.firstDue.error` | Pick the next date this payment is due. |
| `form.firstDue.past` | We'll start from {MMM d}, the next date after today. |
| `form.lead.error` | For a weekly payment, pick up to 3 days before. |
| `form.discard` | Discard this repeating payment? / Keep editing / Discard |
| `form.duplicate` | {payee} already repeats {cadence}. Edit that one instead? / Edit existing / Keep both |
| `save.snackbar` | {payee} repeats {cadence}. Next reminder {MMM d}. / Undo |
| `firstSave.explainer` | Reminders show in BillSense and as browser notifications while it's open. Add to your calendar to be reminded anywhere. / Add to calendar / Not now |
| `suggestion.body` | {payee} looks {cadence}. Next about {MMM d}. Remind you {lead}? |
| `upcoming.total` | {amount} due in the next 30 days |
| `upcoming.totalVaries` | + {n} that vary |
| `upcoming.empty` | No repeating payments yet. Add rent, insurance, or subscriptions and we'll remind you before they're due. |
| `upcoming.error` | Couldn't load your payments. / Try again |
| `delete.confirm` | Delete {payee}? Reminders stop. Past bills are kept. / Delete / Cancel |
| `paused.banner` | Reminders are paused for {payee}. / Resume |
| `notif.title` | {payee}, {amount} |
| `notif.body` | Due {weekday} {MMM d}. Tap to mark paid. |
| `settings.notif.note` | Only while BillSense is open in a tab. We'll show anything you missed when you come back. |
| `settings.calendar.note` | To be reminded when BillSense is closed. |

### 11. Notifications on Flutter web

- Use the browser Notification API through `package:web` (add `web: ^1.1.0` to `pubspec.yaml`). Request permission only from the Settings "Allow" button or the first-save explainer, never on app load.
- A `ReminderTicker` service starts with the app shell: on start and every 60 minutes, compute occurrences whose `remindAt` has passed since `last_notified_at` (persisted), fire one notification per schedule (not per occurrence), then store the new `last_notified_at`. On app open after time away, fire nothing for more than 3 missed items; instead show the badge and let Coming up carry them (avoids a notification burst).
- Fire a browser notification only when `document.visibilityState == 'hidden'`; when visible, the in-app row highlight is enough.
- Clicking the notification focuses the tab and navigates to `/schedule/:id`.
- No service worker in v1, so nothing fires with the tab closed. That limitation is stated in copy and mitigated by `.ics` export.

### 12. Calendar export (`.ics`)

In `frontend/lib/shared/logic/ics_export.dart`; download via a Blob and anchor element (`package:web`). One VEVENT per schedule, all-day on the due date:

| Schedule | RRULE |
| --- | --- |
| Weekly, every N | `FREQ=WEEKLY;INTERVAL=N;BYDAY=FR` |
| Monthly, anchor day 1 to 28 | `FREQ=MONTHLY;INTERVAL=N;BYMONTHDAY=15` |
| Monthly, anchor 29 to 31, clamp | `FREQ=MONTHLY;INTERVAL=N;BYMONTHDAY=28,29,30,31;BYSETPOS=-1` trimmed to days up to the anchor (for 30: `28,29,30`) |
| Monthly, last day | `FREQ=MONTHLY;INTERVAL=N;BYMONTHDAY=-1` |
| Yearly | `FREQ=YEARLY;INTERVAL=N;BYMONTH=3;BYMONTHDAY=1`; Feb 29 anchor uses `BYMONTH=2;BYMONTHDAY=28,29;BYSETPOS=-1` |
| End rules | `UNTIL=YYYYMMDD` or `COUNT=N` |

`DTSTART` is the first occurrence on or after today (H2). `VALARM` fires at the reminder time on the lead day. All-day events start at 00:00, so for reminder hour h: `TRIGGER:-P{leadDays-1}DT{24-h}H` when leadDays is 1 or more (09:00, 3 days before: `-P2DT15H`), and `TRIGGER:PT{h}H` for on the day (09:00: `PT9H`). `SUMMARY`: "Pay {payee}"; `DESCRIPTION`: amount phrase; `UID`: `{scheduleId}@billsense`. Edits do not sync; the Schedule detail note says "Re-download after editing."

### 13. ProviderLogo implementation notes

- URL order: Logo.dev (`https://img.logo.dev/{domain}?token={LOGO_DEV_TOKEN}&size=128&format=png`) only when `const String.fromEnvironment('LOGO_DEV_TOKEN')` is non-empty; else `https://unavatar.io/{domain}?fallback=false`.
- `Image.network` with `errorBuilder` returning the monogram and `frameBuilder` for the 150 ms fade. Paint the monogram underneath from the first frame.
- Build flag for the Vercel deploy: add `--dart-define=LOGO_DEV_TOKEN=...` only if you sign up; the publishable token is designed to be public.
- Curated domains live in `shared/components/provider_logo.dart` as a `const Map<String, String>`, keyed by lowercased provider name.
- Cache as specified in 04 section 6; key `logo_miss_{domain}` in `shared_preferences`.
- `BillListRow` keeps `CategoryTile` in v1. Swapping it for `ProviderLogo` is a separate, reversible change once logo quality is confirmed on real data.

### 14. Analytics events

`schedule_form_opened {entry}`, `schedule_saved {entry, unit, interval, leadDays, prefilled}`, `schedule_deleted`, `schedule_paused`, `suggestion_shown`, `suggestion_confirmed`, `suggestion_dismissed`, `reminder_fired {channel}`, `occurrence_paid {from}`, `occurrence_snoozed {option}`, `occurrence_skipped`, `ics_downloaded {scope}`, `notifications_permission {result}`. These feed the metrics in 02.

### 15. Edge cases to implement and test

- Anchor on the 31st across Feb, Apr, Jun, Sep, Nov in both month-end modes.
- Feb 29 yearly across a non-leap year.
- Past anchor date (60 days ago) creates no overdue occurrences.
- Lead time equal to or longer than a weekly cadence is not selectable.
- Bill arrives 6 days from occurrence: not linked; 5 days: linked.
- Two bills in one cycle for one account: link the closer one only.
- DST change between remind day and due day: reminder still at 09:00 local.
- Offline: logos fall back to monograms, everything else works from the fake repository.
- 0 schedules and 0 suggestions: Coming up hidden, Upcoming shows empty state.
- Payee name of 60 characters: truncates to one line with ellipsis in rows, two lines in the detail header.
- Browser notifications denied: Settings shows "Blocked in browser settings"; the Allow button is replaced by a help link.

---

## Part 2: Design QA checklist

Check against 04 and this file, with the demo data, at 360pt (compact) and 1280pt.

### Visual accuracy
- [ ] All spacing, radii, and type use the tokens in section 9; no hard-coded font sizes in new widgets.
- [ ] ProviderLogo and CategoryTile align on size and corner radius in the same list.
- [ ] Logos sit on the light inset tile in dark mode; no dark glyph on dark background.
- [ ] Amounts use tabular figures and right-align in Upcoming.

### Layout
- [ ] Repeat chips fit one line at 320pt and 360pt.
- [ ] Coming up hides entirely when empty; no empty card on the Bills tab.
- [ ] Form Save button is sticky and not covered by the on-screen keyboard.
- [ ] Upcoming max width 720 on wide screens; no stretched rows.

### Interaction
- [ ] Every Coming up and Upcoming row has Mark paid and overflow at 44 x 44 (H3).
- [ ] Mark paid, Skip, and Delete each show a SnackBar with a working Undo for 10 seconds.
- [ ] Marking a linked occurrence paid marks the bill paid, and Undo reverts both (H6).
- [ ] Snooze cannot pick a date later than due date + 7.
- [ ] Closing a dirty form asks before discarding; Keep editing is the default.
- [ ] Save returns to the screen the form was opened from; the back button works afterwards.
- [ ] Browser permission is requested only from Settings or the first-save explainer.

### Content
- [ ] Preview shows the right next 3 dates for: monthly on the 31st (both modes), quarterly, yearly Feb 29, every 2 weeks.
- [ ] A past first due date shows the "We'll start from" helper and no overdue items (H2).
- [ ] Estimated amounts read "about $142", unknown read "Varies" (H5).
- [ ] No internal words in UI: occurrence, recurrence, RRULE, payee.
- [ ] All copy matches section 10.
- [ ] City Water Dept shows a monogram; the five other demo providers show logos.

### Accessibility
- [ ] Screen reader reads a row as "Ohio Edison, about 142 dollars, due Friday October 15, in 3 days" followed by the actions.
- [ ] ProviderLogo is excluded from semantics when the name is beside it.
- [ ] Overdue is conveyed by text as well as colour.
- [ ] Form errors are announced and focus moves to the first invalid field on Save.
- [ ] Text at 200% browser zoom does not clip in rows or the form.
- [ ] Contrast: monogram glyphs and all text at least 4.5:1 in both themes.

### Cross-platform
- [ ] Chrome, Safari (iOS and macOS), Firefox: logos load (CORS) and notifications work where supported. Safari iOS only supports web notifications for installed home-screen web apps; confirm the Settings copy handles "not supported" gracefully.
- [ ] Downloaded `.ics` imports into Apple Calendar and Google Calendar with the right repeat and alarm.
- [ ] Offline demo: no broken images, no hangs, no network errors surfaced to the user.

---

## Close

**Delivered.** Six documents in `docs/design/payment-reminders/`: jobs to be done (01), brief, content model, sitemap, and metrics (02), three concepts and a recommendation (03), flows, form, state machines, wireframes, and the ProviderLogo spec (04, revised after Test), heuristic and cognitive-load evaluation (05), and this handoff with QA checklist (06).

**Decisions made along the way.**
- Reminders are in-app plus browser notifications while open; `.ics` export covers the closed-app case. Email and push wait for a backend.
- Schedules belong to a payee (an account or a free-standing payee), not to individual bills; occurrences are computed, only user actions are stored.
- Upcoming hub plus suggestions from bill history, with "Make this recurring" on bills. No fourth tab.
- Four repeat presets (Weekly, Monthly, Quarterly, Yearly) plus Custom; lead time defaults by cadence.
- Logos from unavatar.io (keyless, CORS-enabled, verified live), optional Logo.dev token; Clearbit is dead; Google and DuckDuckGo favicon endpoints fail CORS in CanvasKit.

**Skipped, and whether to revisit.**
- Empathize research: revisit. The job statements are hypotheses; the recurrence picker and suggestion cards are the riskiest assumptions.
- Test with users: revisit before or right after build.
- Multiple evaluators for the heuristic pass: one evaluator only.

**Next two skills.**
1. `usability-test-plan`: five sessions on the built feature, tasks around adding a quarterly payment, confirming a suggestion, and resolving an overdue payment.
2. `a-b-test-design`: once live, test whether cadence-based lead-time defaults beat a single global default on the on-time payment rate.
