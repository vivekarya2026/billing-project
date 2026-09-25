# 01 Empathize: jobs to be done

Skill: `jobs-to-be-done`. Input: the existing BillSense product (utility and subscription bills, due dates, overdue alarms on the Bills list, a single global reminder preference) and the feature request. No new research; these statements are hypotheses to validate in the follow-up usability study.

## Core job

Keep every recurring payment on time without having to hold the schedule in my head.

The user does not want "a reminder". They want the late fee, the service cut-off, and the 11pm "did I pay the water bill?" moment to stop happening. A reminder is one tool they hire for that job; a calendar entry, a bank autopay, and a sticky note are its competitors.

## Job statements

**J1. Never miss a due date.**
When a bill I pay regularly is coming due, I want to be told early enough to act, so I can pay on time and avoid late fees or a service cut-off.

- Functional: the right nudge, at the right lead time, for the right payee and amount.
- Emotional: relief; not carrying a background worry.
- Social: being the reliable one in the household; never the person who let the internet get cut off.

**J2. See what is coming out soon.**
When I plan my week or month, I want to see which payments are due and roughly how much, so I can make sure the money is there.

- Functional: an ordered list of upcoming payments with amounts (known or estimated) and dates.
- Emotional: control; no surprises.
- Social: able to answer "what do we owe this month?" instantly.

**J3. Capture a new recurring cost once.**
When I sign up for something that bills on a cycle (insurance yearly, a gym weekly, rent monthly), I want to record it once in a few seconds, so I can forget about it until it matters.

- Functional: set payee, cadence, and lead time with minimal typing; recognise the payee visually later.
- Emotional: confidence that it is captured correctly (the dates are right).
- Social: none significant.

## Job lifecycle, and where BillSense stands today

| Job stage | What the user does | Today in BillSense | Gap |
| --- | --- | --- | --- |
| Define | Decide a payment needs tracking | Adds a bill manually or by scan | No notion of "this repeats" |
| Locate | Find payee, amount, date | Extracted from the bill | Non-bill payments (rent, insurance) have no home |
| Prepare | Decide when to be reminded | One global Off / Day before / Day of | No per-payment lead time; a yearly insurance bill needs weeks, not a day |
| Confirm | Check the schedule is right | Nothing to check | No preview of future dates |
| Execute | Pay | Outside the app | Fine; out of scope |
| Monitor | Watch what is coming | Bills list with overdue alarm, month grouping | Only bills already entered; nothing projected forward |
| Modify | Change cadence, pause, stop | Not possible | Needs edit, pause, end |
| Conclude | Mark paid, move on | `isPaid` exists on Bill | Not connected to any reminder |

## Current alternatives users hire

- Phone calendar repeating event: good cadence control, no amount, no paid state, noisy.
- Bank autopay: solves execution, not visibility; users still get surprised by amounts.
- Payee's own emails: arrive at the payee's chosen time, mixed with marketing.
- Memory: the default, and the thing that fails.

## Design implications (acceptance criteria for later stages)

1. A reminder must carry payee, amount (or "varies"), and date; a bare "Pay bill" nudge fails J1 and J2.
2. Lead time is per payment, with sensible defaults by cadence (a weekly payment and a yearly one need different notice).
3. The upcoming view is the primary surface, not the settings form (J2 is used weekly; J3 once per payee).
4. Setup must be fast and must show future dates back to the user before saving (J3 emotional job: confidence).
5. Marking paid must close the loop in one tap from the reminder (J1 conclude stage).
6. The payee must be recognisable at a glance, which is where the company logo earns its place (J2 scanning, J3 confidence).

## Stage check-in

Produced: core job, three job statements, lifecycle gap table, six acceptance criteria. Next: Define turns these into a brief, an object model, and where reminders live. Nothing here changes the plan.
