# Phase 4: Collapsible statistics overview

## Shared component

Added and exported `@pte/ui`'s `CollapsibleSection`:

- Expanded by default.
- Accessible toggle button with `aria-expanded` and `aria-controls`.
- Reusable title, subtitle, wrapper class, and content class.
- Uses a unique React-generated content id.

File:

- `pte-web/packages/ui/src/components/CollapsibleSection.tsx`

## Screens updated

### Vendor web

- Admin Overview
- Tenant management
- License management
- Tenant applications
- Plan catalog
- Question Bank overview

### Tenant web

- Billing plan overview
- Quota/capacity overview
- Program overview metrics

All current `StatCard` groups are now inside the shared collapsible section.

## Question Bank layout

The question overview was reorganized into a compact 3-column/2-row grid:

- Column 1: Total questions above Draft.
- Columns 2 and 3: Listening, Reading, Writing, and Speaking distributed as
  compact skill cards.
- Desktop content is narrowed with approximately 40px horizontal space on
  each side (`lg:mx-10`).
- The section can be collapsed to reduce vertical space.

Main file:

- `pte-web/apps/vendor-web/features/questionbank/components/_QuestionStatGrid.tsx`
