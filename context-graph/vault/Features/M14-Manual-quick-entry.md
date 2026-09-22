---
type: Feature
id: "M14"
priority: "MUST"
name: "Manual quick entry"
user_value: "Add a bill in seconds when you only have the amount, no photo needed."
complexity: "S"
release: "Release 1"
---

# M14: Manual quick entry

**Priority:** MUST | **Complexity:** S | **Release:** Release 1

*Realises the manual-entry half of [[D3: MVP ingestion is manual entry plus photo/PDF capture]], which was documented but not shipped in the first build.*

## Why this matters

Not every bill arrives as a clean photo or PDF. Sometimes the user just knows
the provider and the amount (a text reminder, a glance at a portal, a paper
bill already thrown away). Forcing a scan in that moment is friction that
stops the bill ever being tracked. Manual quick entry keeps the cold-start
promise: any bill can enter the system in seconds.

## How it works

The Add Bill entry point offers exactly two choices (Hick's Law):

- **Scan or upload** -> the existing guided capture + extraction flow ([[M3: Guided capture UI]], [[M4: Extraction with confidence and provenance]])
- **Enter manually** -> a quick form: bill name / provider, amount, optional due date

The category is **auto-detected from the name** and shown as a live icon that
updates as the user types (see [[Category Icon Auto-Detection]]). The user
never has to pick a category. On save, the bill flows into the same
[[M8: Unified due view]] as scanned bills.

## Personas served

- [[Dana Whitfield]]
- [[Rafael Ocampo]]

## UX law behind this

- [[Hick's Law]]

## Related

- [[D3: MVP ingestion is manual entry plus photo/PDF capture]]
- [[M8: Unified due view]]
- [[Category Icon Auto-Detection]]
