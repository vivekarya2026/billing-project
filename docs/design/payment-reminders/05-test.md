# 05 Test: heuristic evaluation and cognitive load map

Skills: `heuristic-evaluation`, `assess-load` (cognitive-accessibility, chaining cognitive-load-assessment, memory-load-reduction, wayfinding-navigation).

Scope: the flows, form, states, and wireframes in 04. One evaluator (the heuristic skill recommends 3 to 5; this is a known limitation, and the follow-up usability study covers it). Walked through as a new user (first repeating payment, no history), as an existing BillSense user (six accounts with history), and per flow.

## Heuristic findings

Severity: 0 none, 1 cosmetic, 2 minor, 3 major, 4 catastrophe.

| ID | Heuristic | Where | Problem | Sev | Fix (applied in 04) |
| --- | --- | --- | --- | --- | --- |
| H1 | Visibility of system status; Match with the real world | Settings sheet, flow 1c | Browser notifications only fire from an open tab. Users will reasonably expect a "reminder" to reach them with the app closed; the one-line disclaimer in Settings does not change that expectation. This directly threatens J1, the core job. | 3 | Add **Add to calendar**: export an `.ics` event with the repeat rule and an alarm at the chosen lead time, so the phone's calendar reminds them with BillSense closed. Offered in the save SnackBar (first schedule only), on Schedule detail, and in Settings. Plus a one-time explainer the first time a schedule is saved: "Reminders show in BillSense and as browser notifications while it's open. Add to your calendar to be reminded anywhere." |
| H2 | Error prevention | Form field 3 | First due date may be up to 60 days in the past. Past occurrences would appear immediately as overdue and fire reminders for cycles already paid. | 3 | Tracking starts today. A past first due date only sets the anchor; the preview and all occurrences start from the next date on or after today. Helper text when a past date is picked: "We'll start from Oct 15, the next date after today." |
| H3 | Consistency and standards | Coming up rows, compact | Only the first row had Mark paid and Snooze buttons; other rows had to be opened. The same row type behaved differently depending on position. | 2 | Every Coming up row has one trailing 44pt "Mark paid" check button and an overflow menu (Snooze, Skip this one, Open). Same on Upcoming rows. |
| H4 | Recognition rather than recall; Aesthetic | Form field 4, compact | Five segmented options wrapped unpredictably onto two lines, and "Every 3 months" did not match the word people use. | 2 | Four chips (Weekly, Monthly, Quarterly, Yearly) fit one line at 320pt with the compact type scale; "Custom repeat" becomes a text button below the chips. |
| H5 | Match with the real world | Rows with estimated amounts | "~$142.00" relies on users reading the tilde as "about". | 2 | Write "about $142" for estimates (last bill amount), "Varies" when there is no amount; exact amounts keep cents. |
| H6 | Consistency; User control | Flow 1d plus state table | When an occurrence is linked to a bill, marking it paid in Coming up did not say whether the bill in the Bills list also became paid. Two sources of truth. | 2 | Marking a linked occurrence paid sets the bill's `isPaid`; marking the bill paid resolves the occurrence. Undo reverts both. |
| H7 | Aesthetic and minimalist design | Upcoming screen | Payments by date and the full list of repeating payments on one long scroll mixed "what's due" with "what I've set up". | 1 | Segmented control at the top: **Payments** (default, by date) / **Repeating** (all schedules A to Z). |
| H8 | Help users recognise and recover from errors | Suggestion cards | A wrong inference (irregular quarterly water bill) is accepted with one tap and nothing shows the user what was inferred. | 2 | Suggestion card states the inferred rule and the next date explicitly ("Monthly, next about Oct 12"); Confirm's SnackBar offers Edit alongside Undo. Inference requires 3 bills (not 2) when spacing varies by more than 4 days. |
| H9 | Flexibility and efficiency | Weekly payments ignored for weeks | Badge could grow indefinitely from ignored weekly occurrences. | 1 | Already collapsed per schedule ("2 missed") in 04; badge counts schedules needing attention, not occurrences. Clarified in 04. |
| H10 | Visibility of system status | Reminder time | Time zone behaviour unspecified; travellers could get reminders at odd hours. | 1 | Reminders use the device's current local time; documented in handoff, no UI. |

No severity 4 findings. Two severity 3 findings (H1, H2) must be fixed before build; both are fixed in 04.

## Cognitive load map: first repeating payment (new user, no account match)

Dimensions from `cognitive-load-assessment`: decisions, memory, concepts, steps, reading, visual. Rated L (low), M (medium), H (high).

| Step | User sees and does | Dec | Mem | Con | Steps | Read | Vis | Overall | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Bills tab, taps Add, picks "Repeating payment" | L | L | M | L | L | L | L | New concept "repeating payment" introduced by label alone; acceptable because the chooser subtitle explains it |
| 2 | Types payee; logo preview appears | L | L | L | L | L | L | L | |
| 3 | Logo wrong, opens "Change website" (minority path) | M | L | M | M | L | L | M | Why a website? Helper copy needed: "We use the website to find the logo." (added) |
| 4 | Amount, or Varies | M | L | L | L | L | L | L | |
| 5 | Picks first due date | M | M | L | L | L | L | M | **Memory bridge:** user must recall the payee's due date. Mitigation: prefill from bill when entering from a bill; nothing more possible for rent/insurance |
| 6 | Picks Repeats; sometimes month-end choice | H | L | M | L | M | M | **H (spike)** | Up to three decisions here (preset, custom interval, month-end rule) |
| 7 | Remind me | M | L | L | L | L | L | L to M | Defaults by cadence remove most decisions |
| 8 | Reads preview, taps Save | L | L | L | L | M | L | L | Preview removes the need to mentally compute dates |
| 9 | First-save explainer and Add to calendar (after H1) | M | L | M | L | M | L | M | New but one-time; dismissible |

Overall process score: **Low to Medium**, one spike at step 6 and one memory bridge at step 5.

Load reductions for the spike (applied in 04):
- Month-end choice appears only when the first due date is the 29th to 31st (already specified) and defaults to the safe option.
- Custom repeat moves out of the chip row (H4), so the common path is a single tap on a visible chip.
- The generated summary sentence ("Every month on the 15th") sits directly under the chips, so the effect of the decision is visible without scanning to the preview.

Wayfinding and memory checks:
- Back navigation: the form is a single screen; closing asks before discarding. Pass.
- Progress saved: not needed for a single-screen form under 30 seconds; the discard guard covers accidents. Pass.
- Context carried forward: bill-detail entry prefills payee, amount, date, and inferred cadence. Pass.
- Where am I: form title names the task; Save returns to the entry screen with a SnackBar naming the payee and next reminder. Pass.

## Stage check-in

Produced: 10 heuristic findings (two major, both fixed), a cognitive load map with one spike and one memory bridge, and reductions for both, all applied to 04 and marked "Revised after Test". Next: Deliver packages the revised prototype as an engineering handoff and QA checklist. The H1 fix (calendar export) adds one small capability to the handoff scope.
