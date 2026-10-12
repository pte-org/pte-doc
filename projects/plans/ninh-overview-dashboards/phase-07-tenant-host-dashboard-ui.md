# Phase 7: Tenant Host Dashboard UI

## Requirements
`/host/dashboard` becomes a thin route rendering a host dashboard view built from the single host aggregate; every backend host section has a widget (see the Section -> Widget map in plan.md) and the existing LearnersOverview stays as the last full-width section. Priority: P1 KPI row, seat/subscription usage, attempts trend, upcoming sessions, needs-attention, quick actions, LearnersOverview; P2 recent activity, session-status donut, learner assignment split, grading pipeline; P3 compact staff coverage, academic structure, own support tickets and pending orders cards.

## Design Constraints
- The route file has no inline text and no client directive; the client boundary lives in the view.
- Exactly one request to the dashboard endpoint per page load (LearnersOverview's own roster request is excluded from that count); one TanStack Query hook with a dashboard query key and non-zero stale time; errors shown only via the user-facing error helper.
- Because host core counts are uncached server-side, mutations elsewhere (import learners, create class, create session) invalidate the dashboard key and get fresh counts.
- Pending orders card shows a count and links to the existing billing page; no payment link exists in the data.
- All copy in typed feature message files (en and vi) using the exam-staff detail pattern; every displayed enum/status has both keys; do not grow the shared locale provider.
- Widgets are dumb panels; failed section shows its own error state, forbidden section hidden; zero shows 0, null change a dash; no Branch column.
- Reuse @pte/ui as shipped; no inline styles, raw colors or hand-styled headings; component <= 150 lines, file <= 300. Tests are `.test.ts` files under `features/` (the only pattern the tenant-web vitest config matches).
- LearnersOverview is untouched; deferring its mount until near the viewport is allowed only through a wrapper.

## Steps
1. Read the Next.js 16 docs in the bundled docs folder, then create the feature folder (api hook, constants incl. query key, types, utils, messages, components barrel) and reduce the route page to a thin render of the view.
2. Build pure mappers/formatters (section to view model, delta direction/tone, locale number/date formatting) with `.test.ts` unit tests.
3. Build P1 widgets: KPI row in a collapsible section, seat/subscription usage with near-limit warning and expiry, 12-month attempts trend, upcoming sessions table with row links, needs-attention list derived from section counts (grading, unpublished reports, expiry, tickets, orders), quick actions in the page header.
4. Build P2 widgets: recent activity timeline, session-status donut, learner assignment split, grading pipeline progress.
5. Build the P3 compact cards: staff coverage, academic structure, own support tickets, pending orders.
6. Compose the responsive grid (mobile single column with attention first, tablet two columns, desktop twelve-column) with LearnersOverview last at full width (optionally lazily mounted through a wrapper); add dashboard-key invalidation to the roster import, class and session creation mutations.
7. Run lint, typecheck, tests and build for tenant-web, one command at a time, and fix issues.

## Success Criteria
- `pnpm --filter tenant-web lint`, `pnpm --filter tenant-web typecheck`, `pnpm --filter tenant-web test` (includes new mapper tests) and `pnpm --filter tenant-web build` each pass.
- Grep: `host/dashboard/page.tsx` has no inline text and no `use client`; new components contain no hardcoded user-facing strings, inline style attributes or raw hex colors.
- Every host section in the plan's Section -> Widget map has a rendered consumer (checklist in handoff).
- In the running app as HOST_ADMIN, the network panel shows exactly one request to the host dashboard endpoint per load (roster request excluded); LearnersOverview is the last section; a mocked failing section shows only its own error state.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- Query-key invalidation can be forgotten in other features: centralize the key and cover the three known mutations.
- Needs-attention depends on counts that may be absent: hide items whose source section is unavailable.
- Large bilingual copy: typed message files make missing keys fail at typecheck.
