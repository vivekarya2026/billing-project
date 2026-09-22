---
type: Feature
id: "M15"
priority: "MUST"
name: "Edit and delete entries"
user_value: "Fix a wrong amount, provider, date, or split — or remove an entry entirely — without starting over."
complexity: "M"
release: "Release 1"
---

# M15: Edit and delete entries

**Priority:** MUST | **Complexity:** M | **Release:** Release 1

*Realises the correction path implied by [[D3: MVP ingestion is manual entry plus photo/PDF capture]] and
[[M4: Extraction with confidence and provenance]] — capture and manual entry both produce imperfect data, so
every entry must be correctable. Recovery from a wrong entry is a [[Tesler's Law]] obligation: the complexity
of "what did I get wrong and how do I undo it" belongs to the system, not the user.*

## Why this matters

Both ingestion paths create wrong entries routinely:

- **Capture / OCR** ([[M4: Extraction with confidence and provenance]]) misreads a digit, a date, or a provider.
- **Manual quick entry** ([[M14: Manual quick entry]]) invites typos ($176.40 vs $17.640) and mis-detected categories.
- **Group expenses** get logged against the wrong payer, the wrong split, or the wrong group.

Without edit/delete, the only "fix" is to delete-and-recreate, which loses provenance and, for split expenses,
silently changes what other people owe. This is the single most common support/abandonment trigger in ledger apps.

## What it covers

| Entry type | Edit fields | Delete semantics |
|---|---|---|
| Bill (captured) | amount, due date, provider, service type, period | soft-delete, keep image + provenance |
| Bill (manual) | amount, due date, provider/name, category | hard-delete allowed (no provenance) |
| Group expense | description, amount, paid-by, split members | soft-delete, recompute balances |
| Settlement | amount, direction | reversible; never silently drop a paid record |

## Non-negotiable behaviours

- **Confirm destructive actions** ([[Postel's Law]] / [[Peak-End Rule]]): delete asks once, offers Undo.
- **Never silently change someone else's balance.** Editing a shared expense notifies affected members.
- **Preserve provenance on edit.** An edited captured bill is marked "edited" with the original value retained.
- **Optimistic UI with rollback.** Edits/deletes apply instantly and roll back visibly on failure.
- **Idempotent deletes.** Deleting an already-deleted entry is a no-op, not an error.

## Personas served

- [[Rafael Ocampo]] — fixes a misread electric amount before it skews his trend.
- [[Dana Whitfield]] — corrects who paid on a group trip expense.
- [[Marguerite Oyelaran]] — removes a duplicate she accidentally captured twice.

## UX laws behind this

- [[Tesler's Law]]
- [[Postel's Law]]
- [[Peak-End Rule]]
- [[Fitts's Law]]

## Shipped (Release 1 — billing-only)

The billing-interface redesign shipped the **bill** edit/delete path end-to-end, offline:

- **Delete — two entry points, both reversible.** Swipe-to-delete on the Bills
  list (`endToStart` `Dismissible`, red trash affordance, confirm dialog) and a
  **Delete** action in the bill detail overflow menu. Both remove the bill
  optimistically and show a **5-second Undo** SnackBar. Undo restores the exact
  bill at its original position. Backed by `BillRepository.deleteBill` +
  `FakeBillRepository`'s soft-delete `_deletedIds` set (`restoreBill` clears it).
- **Edit.** The bill detail overflow menu opens the manual-entry form in **edit
  mode** (`/manual-bill?id=:id`), prefilled from the bill; saving applies
  `BillRepository.updateBill` (shallow field overrides in the fake repo).
- **Confirm + Fitts.** The destructive button is visually separated from
  "Keep"/"Cancel"; the swipe gesture is far from the row tap target.

**Deferred (SplitWise hidden):** group-expense and settlement edit/delete are
not surfaced while the app is billing-only — the SplitWise screens remain in the
tree, unlinked from navigation, so this can be restored without new work.

*See also: the Bills tab now shows the full bill list with a bill-type filter,
and Insights adds per-type tracking graphs — see [[Billing-only interface]].*

## Related

- [[Billing-only interface]]
- [[Edit-Delete Edge Cases]]
- [[M14: Manual quick entry]]
- [[M4: Extraction with confidence and provenance]]
- [[M8: Unified due view]]
- [[D3: MVP ingestion is manual entry plus photo/PDF capture]]
