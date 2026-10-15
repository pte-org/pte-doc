# Brainstorm: PTE web UI system refactor

**Date:** 2026-10-07  
**Status:** Direction selected; ready for structured planning

## Challenge

`pte-web` contains two Next.js applications (`vendor-web` and `tenant-web`)
that share `@pte/ui`, but the visual language is only partially centralized.
The requested refactor should carry the visual language of
`nextjs-admin-dashboard` into PTE, add light/dark modes, make Vietnamese the
default language with English as the second language, and reduce density on
screens that currently combine too many jobs. The existing logo, routes,
business logic, API contracts, authentication, and role boundaries must stay
intact.

## Ideas Explored

1. **Common-first design system.** Selected. Build semantic tokens, theme and
   locale infrastructure, shell/layout primitives, controls, surfaces, data
   display, feedback, and motion in `@pte/ui` before migrating feature screens.

2. **Big-bang visual rewrite.** Rejected. The two apps have many role-specific
   flows and shared-package consumers; a single rewrite would make behavior
   regressions difficult to isolate.

3. **Global CSS overlay.** Rejected. It would leave hard-coded feature colors,
   duplicate shell markup, and screen-specific exceptions underneath the new
   appearance. It also would not provide a maintainable translation boundary.

4. **Pilot then expand.** Selected. Use the already-started vendor/admin
   surface as the first migration wave, prove both themes and both locales on
   real PTE screens, then move through tenant/host and role-specific surfaces.

5. **Theme strategy.** Selected: keep a light default for continuity, add a
   user-controlled dark mode backed by semantic tokens, and make every shared
   component theme-safe before feature migration. The common phase owns the
   infrastructure; the vendor/admin pilot is the first dark-mode acceptance
   gate.

6. **Locale strategy.** Selected: Vietnamese (`vi`) is the default UI locale;
   English (`en`) is switchable and persisted per browser. Shared UI owns the
   locale contract and generic labels, while each app owns domain dictionaries.
   API data and user-created names are not translated by the UI layer.

7. **Screen decomposition.** Selected: preserve current routes first and split
   overloaded screens with tabs, stepper sections, drawers, or nested panels.
   New route-level decomposition is a later proposal and requires a separate
   product decision.

## User's Direction

- Build the common visual foundation before changing individual screens.
- Use the `nextjs-admin-dashboard` style and component boundaries as a source
  reference, adapting code patterns into `pte-web` rather than linking the
  reference app at runtime.
- Keep the PTE logo unchanged.
- Default the UI to Vietnamese and provide English as the second language.
- Add dark mode in the common foundation, then verify it on the first
  vendor/admin pilot.
- Keep the current route and business behavior while reducing overloaded page
  density; report the proposed decompositions for later approval.

## Current Evidence From the Repositories

- `pte-web` is a pnpm/Turborepo workspace with `apps/vendor-web`,
  `apps/tenant-web`, `packages/ui`, and `packages/api-client`.
- The route scan is approximately 29 vendor pages and 27 tenant pages; most
  route files are thin wrappers and the real density lives in feature views.
- `@pte/ui` already owns a dashboard shell, cards, forms, tables, modals,
  menus, status components, motion tokens, and the PTE-adapted light palette.
- The token stylesheet currently declares `color-scheme: light`; neither app
  has a real `ThemeProvider` or locale provider, and both root layouts still
  declare `html lang="en"`.
- Vendor and tenant apps duplicate `DashboardChrome` presentation while
  keeping app-specific role and navigation logic.
- A static scan found broad use of literal Tailwind color utilities across the
  workspace (for example `bg-white`, `text-gray-*`, `border-gray-*`, and
  `text-slate-*`), so a dark-mode toggle alone would be insufficient.
- The reference dashboard has explicit `default.css` and `dark.css` semantic
  palettes plus common header/sidebar/theme-toggle/card/table boundaries. These
  are visual references only; PTE will preserve its own brand and contracts.

## Overloaded Screen Candidates

These are planning candidates, not approved implementation changes. The
recommended first treatment keeps the existing route.

| Area | Current surface | Evidence | Proposed in-route decomposition | Priority |
|---|---|---|---|---|
| Vendor commercial | `LicenseCodesView` | ~650 lines; issue/retry recovery, lookup, filters/list, reveal, revoke preview/confirmation | Tabs or stacked work areas: Issue, Lookup, Issued codes; reveal/revoke stay contextual drawers/dialogs | P1 |
| Vendor commercial | `PlanCatalogView` | ~660 lines; catalog metrics/list, create/edit form, lifecycle transitions, delete/archive and version conflict | Catalog list as the default view; create/edit in a drawer or dedicated step panel; lifecycle actions remain row-level | P1 |
| Vendor authoring | `ScoreTemplateListView` + `ScoreTemplateEditorView` | list combines create/clone/approval actions; editor combines metadata, policy, ordering, diagnostics, activation | List and editor keep routes; editor uses Basics, Task types/order, Review/activation tabs | P1 |
| Vendor content | Question bank/editor flows | list/filter/table and media/question editing are dense and have long forms | Keep list/detail routes; use editor sections or tabs for prompt, options/media, scoring/validation, preview | P2 |
| Vendor tenancy | `TenantDetailView` | detail view owns identity, organization/access details and tenant actions | Summary, organizations/access, branding/settings sections with a compact action rail | P2 |
| Tenant learner management | `StudentSearchView` | ~575 lines; contextual filters, roster, add/import, suspend/reactivate, credential generation, details | Keep roster route; separate filter context, roster table, and management drawer/modal flows | P1 |
| Tenant exam delivery | `SessionDetailView` | lifecycle/configuration plus participants, staff assignment, grading, answers and publication sections | Overview, participants, staff/scoring, answers/publication tabs; keep mutation ownership in feature code | P1 |
| Tenant exam creation | `CreateExamWizard` | ~610 lines; source selection, classes/students/programs, exam mode and policy review | Preserve wizard route/modal; split into Setup, Audience, Policy, Review steps where existing validation permits | P1 |
| Tenant exam staffing | `ExaminerAssignmentSection` / `HostScoreReviewPanel` | large assignment/review blocks with independent search, selection, scoring and publication concerns | Use sub-panels or tabs inside session detail; do not move API/state ownership into common UI | P2 |
| Tenant class/program operations | `ClassDetailView`, `ProgramDetailView`, roster/import flows | detail pages combine summary, membership, lecturer assignment and import/transfer operations | Summary, members, teaching staff, imports/actions sections; retain modal entry points | P2 |
| Tenant examiner | `ExaminerWorkView` | queue, attempt detail, and scoring in one role surface | Master-detail layout; mobile detail drawer while keeping `/examiner/work` | P2 |
| Public/auth content | `HomeView`, login/register | `HomeView` is content-heavy (~450 lines) but is a public narrative rather than a multi-job admin screen | Improve section hierarchy and anchors; do not split solely because the file is long | P3 |

## Open Questions

None blocking for the master plan. The current decisions are: `vi` default,
`en` second locale, light default with user-controlled dark mode, and
route-preserving tabs/steps/drawers for the first decomposition pass.

## Risks

- A shared token migration can alter dozens of screens at once. Each wave must
  have a route matrix, visual smoke checks, and a clear diff boundary.
- Translation work can accidentally become business logic or change API/error
  semantics. Locale dictionaries must map UI keys to existing states and error
  codes without changing contracts.
- Dark mode can be incomplete if feature components retain literal light-only
  utility classes. The plan must migrate common primitives first and track
  remaining literals per wave.
- Existing concurrency guards (plan version conflict, license-code
  idempotency/recovery, assignment preview staleness, and student placeholder
  data) must survive any visual decomposition.
- Splitting an overloaded screen can accidentally change action ordering,
  keyboard reachability, or modal entry points. Decomposition is presentation
  only until separately approved.
- The reference dashboard contains dependencies and product-specific markup
  that do not belong in PTE. Only the visual system and reusable boundaries
  should be adapted.
