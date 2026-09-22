---
type: CodePractice
description: "A single deterministic keyword->icon resolver (lib/shared/components/category_icons.dart) categorises bills and expenses by name; used across bill cards, manual entry, and expense rows."
---

# Category Icon Auto-Detection

A single, deterministic keyword-to-icon resolver
(`lib/shared/components/category_icons.dart`, `CategoryIcons.iconFor`) maps any
free text (a provider name, a bill name, or an expense description) to a
Material icon, optionally biased by a structured `serviceType` from the data
model. It is intentionally keyword-based (no model), so it is deterministic
and works fully offline, consistent with [[No Model Arithmetic]].

## One source of truth, used everywhere

The same resolver backs every place an item icon appears:

- **Bill cards** on the [[M8: Unified due view]] (provider + service type)
- **Manual quick entry** ([[M14: Manual quick entry]]) — a live icon that
  updates as the user types the bill name
- **Expense rows** in the group/activity lists (`ActivityIcon` now delegates
  to `CategoryIcons`)

Because there is one table, adding a keyword (a new provider, a new category)
updates the icon everywhere at once. The badge styling (sky-tinted rounded
container) is shared via `CategoryIconBadge`, keeping the dark gradient theme
consistent.

## Related

- [[M14: Manual quick entry]]
- [[Flutter Global Theme]]
