# Plan: PTE web UI system refactor

**Date:** 2026-10-07
**Status:** Ready for phased implementation
**Repository scope:** `pte-web` implementation; planning artifacts in `pte-doc`
**Mode:** Hard
**Source spec:** `spec.md`

## Scope Challenge

- **Exists?** Partially. `@pte/ui` already owns many presentational primitives
  and a dashboard shell, but theme, locale, and visual ownership are not yet
  complete across both apps.
- **Minimum?** Build the shared semantic foundation first, then migrate each
  app in controlled waves. The first useful delivery is common light/dark and
  vi/en infrastructure plus the vendor/admin pilot.
- **Complexity?** Hard: two Next.js apps, a shared package, many role-specific
  flows, existing behavior that must not change, and a large visual/token
  migration.
- **Scope split:** do not cook this as one change. Each phase is independently
  reviewable and should be completed with its own typecheck/build/browser
  evidence before the next migration wave.

## Architecture Decisions

1. `@pte/ui` owns semantic visual tokens, theme runtime contract, generic
   locale contract, shell/header/sidebar presentation, controls, surfaces,
   feedback, data display, and motion.
2. `vendor-web` and `tenant-web` retain role navigation definitions, auth gates,
   domain dictionaries, API/query hooks, validation, mutation ownership, and
   business state.
3. Adapt `nextjs-admin-dashboard` source patterns into PTE. Do not link,
   iframe, import, or run the reference app at runtime.
4. Keep light mode as the continuity default. Add explicit dark mode with
   browser persistence and semantic tokens; the vendor/admin pilot is the first
   dark-mode acceptance gate.
5. Make Vietnamese (`vi`) the clean-profile default and English (`en`) the
   switchable second locale. Persist locale per browser and keep `html[lang]`
   synchronized.
6. Preserve current routes for the first pass. Use tabs, stepper stages,
   drawers, collapsible sections, and contextual panels for density reduction.
   Route-level splits are backlog proposals requiring a separate decision.
7. Do not add a new dependency merely to implement theme or locale. If a
   dependency becomes necessary, stop at that phase and request approval first.
8. Theme/locale/tab state is presentation state only. No API, auth, role,
   validation, business-state, or domain data behavior changes are allowed.

## Research Inputs

- **Primary architecture review:** common-first semantic tokens, theme runtime,
  locale contract, and shared shell ownership fit the existing `@pte/ui`
  boundary; keep app/domain dictionaries outside the shared package.
- **Alternative UX review:** a hybrid strategy is safer than either a big-bang
  rewrite or immediate route splitting. Keep existing routes, use tabs,
  steppers, and drawers by default, and reserve route splits for independently
  navigable workflows that already have or later receive an approved route.
- **Concrete route baseline:** the scan found approximately 29 vendor pages and
  27 tenant pages; route files are generally thin wrappers while feature views
  own the density and state.

## Required Evidence Artifacts

Phase 01 must create and maintain these artifacts under this plan directory:

- `route-matrix.md`: route, actor, role gate, feature owner, shared primitives,
  locale/theme coverage, responsive status, and density classification.
- `actor-permission-matrix.md`: navigation visibility, route access, protected
  actions, and current redirect/forbidden behavior for each actor.
- `behavior-preservation-manifest.md`: URL state, hooks/queries, mutations,
  payloads, validation, callbacks, modal entry points, and state ownership for
  every migrated surface.
- `density-audit.md`: reproducible counts, classification, priority, evidence,
  and approved route-preserving treatment for every route.
- `failure-state-matrix.md`: failure/recovery cases, owner, expected UI,
  action, and verification scenario.
- `visual-consumer-inventory.md`: chart, overlay, status, navigation, and
  other semantic-token consumers assigned to a phase.

Each later phase adds its own verification report and updates these artifacts;
it may not replace an unverified row with an assumption.

## Phase Map

| Phase | Outcome | Depends on |
|---|---|---|
| 01 | Route inventory, visual baseline, and density audit | None |
| 02 | Semantic light/dark token and theme foundation | 01 |
| 03 | Vietnamese-first `vi`/`en` locale foundation | 01, 02 |
| 04 | Shared NextAdmin-inspired shell, primitives, motion, and accessibility baseline | 02, 03 |
| 05 | Vendor/admin core pilot migration | 04 |
| 06 | Vendor commercial/content/support migration and dense-screen treatment | 05 |
| 07 | Tenant host operations migration | 04 |
| 08 | Tenant exam, examiner, student, public, and auth migration | 07 |
| 09 | Cross-app regression, visual matrix, handoff, and route-split backlog | 05, 06, 07, 08 |

## Screen Density Audit and Decisions

The following list is the initial source-grounded backlog. “Function-heavy”
means the screen combines at least three independent user jobs or multiple
mutation/modal workflows. These are proposals, not permission to change
behavior automatically.

| Priority | Surface | Initial diagnosis | First treatment while preserving route |
|---|---|---|---|
| P1 | `vendor-web` `LicenseCodesView` | Issue/retry recovery, lookup, filters/list, reveal, revoke preview/confirm | Tabs or stacked work areas: Issue, Lookup, Issued codes; contextual reveal/revoke drawer/dialog |
| P1 | `vendor-web` `PlanCatalogView` | Catalog list, create/edit, lifecycle transitions, delete/archive, version conflict | Default catalog view plus create/edit drawer or step panel; row-level lifecycle actions |
| P1 | Score template list/editor | CRUD, clone, approval, ordering, policy, diagnostics, activation | Keep routes; editor tabs: Basics, Task types/order, Review/activation |
| P1 | `tenant-web` `StudentSearchView` | Context filters, roster, add/import, suspend/reactivate, credentials, details | Separate filter context, roster surface, and management/details drawers |
| P1 | `tenant-web` `SessionDetailView` | Lifecycle/configuration, participants, staff, grading, answers, publication | Tabs: Overview, Participants, Staff/scoring, Answers/publication |
| P1 | `tenant-web` `CreateExamWizard` | Source selection, audience, mode, policy, review | Explicit Setup, Audience, Policy, Review steps within the existing flow |
| P2 | Vendor question bank/editor | Table/filter plus long question/media/scoring form | List/detail remains; editor sections or tabs and a preview panel |
| P2 | `tenant-web` `ExaminerAssignmentSection` and `HostScoreReviewPanel` | Independent assignment/review responsibilities embedded in exam flow | Sub-panels/tabs owned by the exam feature; no common business logic |
| P2 | Tenant class/program detail and roster/import flows | Summary, membership, lecturer, transfer/merge/split/import actions | Summary, Members, Staff, Imports/Actions sections |
| P2 | `tenant-web` `ExaminerWorkView` | Queue, attempt detail, and scoring in one role surface | Master-detail layout; mobile detail drawer while keeping `/examiner/work` |
| P2 | `vendor-web` `TenantDetailView` | Identity, organization/access, branding and tenant actions | Summary, Organizations/access, Branding/settings sections |
| P3 | `tenant-web` `HomeView` | Content-heavy public narrative, not function-heavy | Improve hierarchy and anchors; do not split only because the file is long |

### Reproducible density rubric

Phase 01 records these counts from the rendered route and its owning view:

- `J`: independent user jobs with a distinct outcome.
- `S`: visible top-level sections/cards/panels.
- `I`: independent form, table, wizard, or editor clusters.
- `M`: independent mutation groups (create, update, delete, lifecycle, or
  assignment/review action families).
- `A`: modal, drawer, action-menu, or other secondary action entry points.
- `C`: content/instruction/report blocks that primarily communicate information
  rather than collect input.

Classify a route as **function-heavy** when `J >= 3`, `I >= 3`, `M >= 2 and
A >= 2`, or it has at least four workflow stages. Classify it as
**content-heavy** when `C >= 4`, or `C >= 3` with one block containing at least
120 words of continuous narrative/instruction/report copy. Otherwise classify
it as **normal**. If both rules apply, record both signals and treat
function-heavy as the implementation-risk classification. Priority is P1 for
core admin/exam workflows with function-heavy risk, P2 for secondary workflows
or lower-risk function-heavy surfaces, and P3 for content-heavy hierarchy work.

Every route row must include the exact counts and a short evidence note; file
line count alone is never a classification signal.

## Phase ownership and execution order

| Phase | Owns | Explicitly does not own | Execution |
|---|---|---|---|
| 05 | Vendor overview, tenancy, applications, settings, notifications, and vendor dashboard shell composition | Commercial/content/support feature migration | After 04 |
| 06 | Vendor commercialization, licensing, score/question authoring, platform content, and support tickets | Phase 05 pilot routes and shared providers | After 05 |
| 07 | Tenant host operations, organization/program/class/student/staff surfaces, notifications, audit, and support; only shared tenant dashboard shell composition | Tenant public/login/register auth surfaces and exam-specific workflows | After 04; may run beside 05 only on isolated branches with the shared package frozen |
| 08 | Tenant exam workflows, examiner/proctor/student role surfaces, public home, login, and registration | The host operations feature files owned by 07 and the shared shell owned by 04 | After 07 |

The default cook order is sequential in the shared working tree. Parallel work
between 05 and 07 is optional and requires isolated branches plus a frozen
`@pte/ui` contract; merge conflicts are resolved before either phase advances.

## Red-Team Review

| Finding | Decision | Mitigation | Owner / target / evidence | Residual risk |
|---|---|---|---|---|
| Full dark-mode migration can break existing light utility classes | ACCEPTED | Migrate tokens/common primitives first; track literal color usage per wave and verify both themes | Phase 02/04; `theme-contract.md`, verification report | Feature-local literals may remain until their wave |
| Putting all domain translations in `@pte/ui` would couple the apps | ACCEPTED | Shared package owns locale contract/generic messages; each app owns domain dictionaries | Phase 03; `locale-contract.md`, raw-string audit | Domain copy may need product translation decisions |
| A common provider can accidentally affect auth/session behavior | ACCEPTED | Providers handle only theme/locale presentation state; auth/query providers remain unchanged | Phase 02/03; behavior manifest and provider diff | Hydration integration can still regress if not browser-tested |
| Standardizing forbidden or recovery states could accidentally change auth/error behavior | ACCEPTED | Common layer owns presentation only; existing auth redirects, retry/recovery semantics, and API error ownership remain in current features | Phase 04/06/07/08; failure-state matrix and browser scenarios | Some API failure paths may be unavailable locally |
| Route splits would expand behavior and navigation scope | ACCEPTED | Use in-route tabs/steps/drawers first; record route splits as future proposals | Phase 01/09; density audit and split backlog | Product may later approve route changes |
| The reference app has dependencies PTE does not need | ACCEPTED | Adapt component boundaries and styles; do not copy unrelated dependencies or mock data | Phase 04; visual checklist and dependency diff | Visual parity is intentionally approximate |
| The migration is too broad for one cook run | ACCEPTED | Nine phases, explicit checkpoints, and no phase advance without evidence | All phases; phase verification reports and status gates | Worktree conflicts can still pause a phase |
| Existing concurrency guards could be lost during visual decomposition | ACCEPTED | Preserve version-conflict, idempotency/recovery, stale-preview, and placeholder-data guards in feature owners | Phase 01/06/07/08; behavior and failure matrices | Runtime proof depends on local API/data availability |

## Quality and Testing State

- Quality: not evaluated for this new master plan.
- Testing: not started for this new master plan.
- Existing repository evidence from the earlier tenant-management pilot is
  historical context only; each new phase must record fresh evidence.

## Gate Policy

- `PASS` means all mandatory artifacts and checks for that phase are complete;
  an unavailable check may not be silently counted as passing.
- `UNVERIFIED` means evidence is missing or infrastructure/data prevented the
  check. It blocks every dependent phase and blocks release-readiness.
- `BLOCKED` means a scope, behavior, permission, or quality failure prevents
  safe continuation. It also blocks every dependent phase and
  release-readiness.
- A deliberate exception requires a written waiver in the phase verification
  report with owner, exact scope, reason, expiry/next review date, and the
  dependent phase it permits. A waiver makes the state visible; it does not
  convert `UNVERIFIED` into evidence-backed `PASS`.
- For implementation phases 02 through 09, `@pte/ui` typecheck plus the
  affected app lint/typecheck/build checks are mandatory. `ck:quality` is
  mandatory before the phase gate, and relevant unit/integration/browser
  checks are mandatory for changed behavior or interaction surfaces. Phase 01
  is artifact/static-review only but must still pass its completeness gate.

## Handoff Rules

- Before each phase, confirm the exact test scope and `ck:quality` command;
  this confirms execution details only and cannot waive the mandatory gate
  policy above.
- Before implementing a P1 function-heavy screen, record its mini-plan:
  current jobs, proposed tabs/steps/drawers, preserved action contracts,
  responsive treatment, and the states that must remain reachable. A screen
  does not enter implementation solely because it appears in the backlog.
- Every phase must publish `Inputs`, `Outputs`, and a `Blocking Gate` with a
  status of `PASS`, `UNVERIFIED`, or `BLOCKED` in its phase file or verification
  report.
- A phase is not complete because static code compiles; report browser,
  authenticated API, and production limitations separately.
- If a proposed density split requires a route, API, auth, or business-state
  change, stop and report it instead of silently expanding scope.
- Keep the existing PTE logo and supplied local account behavior unchanged.

## Cook Session 2026-10-07

- A fast sequential sweep executed all nine planned phases in the shared
  `pte-web` worktree; common foundation work preceded app/feature pilots.
- Phase 01 evidence artifacts were added: route matrix, actor/permission
  matrix, behavior-preservation manifest, density audit, failure-state matrix,
  and visual-consumer inventory.
- Phases 02-04 delivered the shared semantic theme, locale runtime, shell,
  accessibility-oriented common controls, and tokenized common surfaces.
- Phase 05 added the vendor/tenant shell integration and a route-preserving
  vendor tenant-detail tab pilot. Phases 06-08 apply the common system across
  vendor commercial/content/support consumers and tenant host/exam/auth/public
  consumers, with a tenant exam-wizard stepper pilot.
- Phase 09 static evidence is recorded in
  `cook-run-2026-10-07.md`: `@pte/ui` and both app typechecks, lint, builds,
  and `git diff --check` passed. Existing warnings are listed there.
- `ck:test` and `ck:quality` were skipped at the user's request. Authenticated
  browser, local API/data, responsive, theme/locale persistence, role, and
  full regression evidence remain `UNVERIFIED`; this is not a release-ready
  claim.
