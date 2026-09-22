---
type: Feature
id: "M16"
priority: "MUST"
name: "Billing-only interface"
user_value: "A focused billing app — filter bills by type, track each expense on its own graph, and add or remove a bill in seconds."
complexity: "M"
release: "Release 1"
---

# M16: Billing-only interface

**Priority:** MUST | **Complexity:** M | **Release:** Release 1

*The redesign that turns the hybrid app into a focused **billing** experience.
SplitWise features are hidden from navigation (code retained, unlinked) so the
product reads as a single-purpose bill tracker. Built on the **daisyUI 5 design
system** — its semantic tokens (`primary`/`secondary`/`accent`,
`base-100/200/300`, `base-content`, `success`/`warning`/`error`/`info`), shape
tokens (`radius-selector`/`field`/`box`), size scale (xs–xl) and breakpoints
(640/768/1024/1536) — realised in Flutter, and its component anatomy (Filter/
Tabs, Stat, Card, List/`list-row`, Dock/Menu, Modal, Skeleton, Badge/`badge-
soft`). Applies [[Hick's Law]], [[Fitts's Law]], [[Miller's Law]] and the
Serial-Position effect.*

## Why this matters

The app had grown to six tabs spanning two domains (bill intelligence +
expense splitting). That split the product's story and buried the core value —
"is this month normal, and where does my money go?" Collapsing to three
billing tabs restores a single, legible purpose ([[Hick's Law]]).

## What it covers

- **Three tabs** (Dock/Menu semantics): **Bills**, **Insights**, **Settings**.
  Bottom `NavigationBar` on mobile, left `NavigationRail` on desktop (Jakob).
- **Bill-type filter** (Filter/Tabs): a horizontally scrollable chip row —
  `All` first (Serial-Position) plus one chip per service type actually present
  (Electric, Gas, Water, Internet, Phone, Streaming…), each carrying its
  category colour + glyph (Law of Similarity). Filters the list client-side.
- **Easy add / remove**:
  - Add via an edge-anchored FAB → add-bill chooser (scan or manual) ([[Fitts's Law]]).
  - Remove via **swipe-to-delete** on the list **and** a **Delete** action in
    bill detail — both confirm once and offer a **5-second Undo** (see [[M15: Edit and delete entries]]).
- **Per-type tracking graphs** (Insights): a KPI **Stat** row (total spend,
  bills tracked, biggest type), a **By bill type** ranked-bar card where tapping
  a type reveals that type's own monthly trend line, plus the existing
  spend-over-time, by-provider and where-it-goes charts. Colours unified with
  the category taxonomy.
- **Responsive** (three classes): content capped at 880px on wide screens,
  stats grid 3-up → 1-up on mobile, ≥60px touch targets, reduced-motion fades.

## Non-negotiable behaviours

- **daisyUI design system** — colours, radii, typography (Inter) and component
  anatomy come from `daisyui-context-graph`; dark is the default theme with a
  matching light theme, both built from daisyUI's `base-*` + semantic tokens.
  The previous gradient/glow + Newsreader treatment was replaced by daisyUI's
  clean flat surfaces.
- **Skeletons, not spinners**, while bills/insights load.
- **Optimistic delete with visible Undo**; deletes are reversible for 5s.
- **Words carry meaning, not colour** (D2) — every chart mark has a word+value label.
- **SplitWise stays compiled** — routes remain (`/groups`, `/friends`, `/activity`,
  `/profile`), just unlinked from any tab, so the feature is trivially restorable.

## Personas served

- [[Rafael Ocampo]] — filters to Electric and watches its own trend.
- [[Marguerite Oyelaran]] — adds a bill in seconds, deletes a duplicate with Undo.
- [[Wes Tanaka]] — reads the per-type breakdown to see where money goes.

## UX laws behind this

- [[Hick's Law]]
- [[Fitts's Law]]
- [[Miller's Law]]
- [[Jakob's Law]]

## Related

- [[M15: Edit and delete entries]]
- [[M14: Manual quick entry]]
- [[M8: Unified due view]]
- [[Edit-Delete Edge Cases]]
