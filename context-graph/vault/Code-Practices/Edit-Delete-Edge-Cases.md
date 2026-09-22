---
type: CodePractice
description: "Edge-case catalog for editing and deleting bills, manual entries, group expenses, and settlements: inputs, boundaries, errors, concurrency, recovery paths, and test scenarios."
---

# Edit-Delete Edge Cases

Companion catalog to [[M15: Edit and delete entries]]. Enumerates the failure surface for correcting or
removing an entry so engineering handles each case intentionally and QA has a test map. Prioritised by
likelihood × impact.

## Feature overview

Scope: edit/delete of (a) captured bills, (b) manual bills, (c) group expenses, (d) settlements.
Out of scope: bulk edit, edit history UI beyond a single "edited" marker, cross-device merge (R2).

## Edge case categories

### 1. Input validation (edit form)

| # | Scenario | Expected behaviour | Priority |
|---|---|---|---|
| E1 | Amount cleared / empty on save | Block save, inline "Enter an amount" | High |
| E2 | Amount ≤ 0 or non-numeric | Block, "Enter a valid amount" | High |
| E3 | Amount with >2 decimals or huge (1e12) | Round to 2dp; cap + warn above sane max | Med |
| E4 | Provider/description emptied | Block, keep prior value focused | High |
| E5 | Due/period date in far future/past | Allow but soft-warn if >1yr out | Low |
| E6 | Period start after period end | Block, "End must be after start" | Med |
| E7 | Category re-detect vs manual override on name edit | Manual override wins; icon updates only if untouched | Med |

### 2. Boundary conditions

| # | Scenario | Expected behaviour | Priority |
|---|---|---|---|
| B1 | Edit the only expense that defines a balance | Recompute to zero, show "settled up" | High |
| B2 | Delete last entry in a group | Group persists, empty state shown | Med |
| B3 | Edit split from N members to 1 (self) | Others' owed → 0, notify them | High |
| B4 | Amount edit that flips who-owes-whom | Recompute direction, reflect in Friends | High |
| B5 | Edit a bill that is the basis of a trend/anomaly | Recompute dashboard + re-evaluate anomaly | Med |

### 3. Error / system states

| # | Scenario | Expected behaviour | Priority |
|---|---|---|---|
| S1 | Network drop mid-save | Optimistic apply, queue, rollback + retry toast on fail | High |
| S2 | Delete succeeds locally, server 500 | Restore row, "Couldn't delete — try again" | High |
| S3 | Edit an entry another user already deleted | "This entry no longer exists", refresh list | High |
| S4 | Permission denied (not creator/not in group) | Hide affordance; if raced, 403 → explain | High |
| S5 | Offline (Fake repo/demo) edit | Apply in-memory, note "resets on reload" | Med |
| S6 | Image-backed bill: edit amount but image unchanged | Keep image, mark field "edited", retain original | Med |

### 4. Concurrency / races

| # | Scenario | Expected behaviour | Priority |
|---|---|---|---|
| C1 | Two members edit same expense simultaneously | Last-write-wins + version check; loser sees "updated elsewhere" | High |
| C2 | Double-tap delete | Idempotent; second is a no-op | High |
| C3 | Edit while a settlement referencing it is being created | Block delete if referenced; warn on edit | Med |
| C4 | Undo after another action already ran | Undo window expires; disable stale Undo | Med |

### 5. Destructive-action safety

| # | Scenario | Expected behaviour | Priority |
|---|---|---|---|
| D1 | Delete a shared expense | Confirm once; state who is affected; Undo 5s | High |
| D2 | Delete a settled/paid settlement | Extra confirm; reversal is itself a recorded event | High |
| D3 | Delete captured bill with provenance | Soft-delete (recoverable), image retained 30d | Med |

## Error messages (canonical copy)

- Empty amount → "Enter an amount."
- Invalid amount → "Enter a valid amount."
- Deleted-elsewhere → "This entry no longer exists. We refreshed your list."
- Save failed → "Couldn't save your change. We put it back — try again."
- Delete failed → "Couldn't delete that. It's still here — try again."
- Shared delete confirm → "Delete this expense? Alice and Bob's balances will update."

## Recovery paths

- **Every delete → Undo** for 5 seconds (soft-delete under the hood); after that, recoverable from a
  30-day trash for captured bills only.
- **Every failed write → automatic rollback** of the optimistic change + non-blocking retry toast.
- **Every "changed elsewhere" → silent refresh** with a one-line explanation, never a dead-end.
- **Data preserved on edit:** original captured value retained behind an "edited" marker for provenance.

## Test scenarios (QA map)

1. Edit amount → dashboard trend + any anomaly recompute correctly.
2. Edit split N→1 → other members' balances zero and they are notified.
3. Delete + Undo within 5s → entry fully restored including split.
4. Delete + let Undo expire → captured bill recoverable from trash; manual bill gone.
5. Airplane-mode edit → optimistic apply, reconnect reconciles, conflict surfaces C1 copy.
6. Race: delete on device A while editing on device B → S3 copy, no crash.
7. Permission: non-member attempts edit via deep link → 403 handled gracefully.

## Related

- [[M15: Edit and delete entries]]
- [[Tesler's Law]]
- [[Postel's Law]]
- [[Optimistic UI with rollback]]
