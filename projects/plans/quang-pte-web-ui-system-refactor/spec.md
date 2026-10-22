# Spec: PTE web UI system refactor

**Date:** 2026-10-07
**Status:** Ready

---

## Problem Statement

The two `pte-web` applications have a growing set of reusable components, but
their shell, tokens, copy, theme behavior, and screen density are not yet
consistent. The product needs a common NextAdmin-inspired visual system with a
Vietnamese-first bilingual UI and light/dark modes, while preserving existing
PTE branding, routes, API behavior, authentication, roles, and business logic.

The refactor also needs an explicit inventory of screens that are too dense or
combine too many jobs, so those screens can be decomposed deliberately instead
of receiving more local components and styling.

## Actor and Permission Boundary

The route and behavior evidence must cover these actors without recording
credentials or tokens:

| Actor | Existing role boundary to observe |
|---|---|
| Platform administrator | `PLATFORM_ADMIN` vendor/admin navigation and protected actions |
| Host administrator | `HOST_ADMIN` tenant/host navigation and protected actions |
| Examiner | `EXAMINER` examiner work, assignment, and scoring visibility |
| Proctor | `PROCTOR` proctor/session visibility and action restrictions |
| Student | `STUDENT` student routes, results, and student-only actions |
| Anonymous user | Public and authentication routes; authenticated routes must retain their current denied/redirect behavior |

Phase 01 records, for every route and protected action, navigation visibility,
route access, current redirect or forbidden behavior, and the owning role
check. Later phases must verify this matrix rather than infer permission
preservation from a successful render.

---

## User Stories

- **[P1]** As a PTE web user, I want vendor and tenant dashboards to share one
  visual system so that navigation, forms, tables, cards, dialogs, feedback,
  and responsive behavior feel consistent across roles.
  Accepted when: changed screens compose common `@pte/ui` primitives and do
  not add page-local copies of shell, card, table, modal, theme, or locale
  infrastructure.

- **[P1]** As a Vietnamese user, I want Vietnamese to be the default UI
  language and English to be selectable so that I can operate the platform in
  my preferred language.
  Accepted when: a clean browser profile renders `vi` by default, the switcher
  changes all refactored UI labels and accessibility text to `en`/`vi`, the
  selected locale persists after reload, and the root `html[lang]` matches it.

- **[P1]** As a dashboard user, I want a light/dark theme toggle so that I can
  work comfortably in different environments without losing readability.
  Accepted when: the shared shell and all components in the first pilot render
  in both themes, the selected theme persists after reload, focus/disabled/
  status states remain readable, and the PTE logo is unchanged.

- **[P1]** As a user working on a dense screen, I want related actions grouped
  into clear sections or steps so that I can understand the workflow without
  scrolling through unrelated controls.
  Accepted when: every P1 overloaded-screen candidate has a recorded
  decomposition proposal and the approved pilot uses tabs, steps, drawers, or
  panels without changing its route or action contracts.

- **[P1]** As a product owner, I want visual refactoring to preserve behavior
  so that UI work does not silently change data, permissions, or workflows.
  Accepted when: no API endpoint, auth boundary, role restriction, validation
  rule, mutation payload, business-state transition, or existing route target
  changes as part of this UI plan.

- **[P2]** As a keyboard or reduced-motion user, I want the refreshed UI to
  remain operable and calm so that animation does not block access.
  Accepted when: changed common components retain keyboard/focus semantics,
  new motion is CSS-based and short, and `prefers-reduced-motion: reduce`
  disables non-essential motion.

- **[P2]** As a user on a small viewport, I want dense tables and forms to stay
  usable without page-level horizontal scrolling.
  Accepted when: visual checks at 320px, 390px, and desktop widths show no
  page-level overflow; only intentionally scrollable data regions may
  overflow.

- **[P3]** As a product owner, I want future route-level decomposition options
  documented so that screens that remain overloaded after the first pass have a
  deliberate next step.
  Accepted when: route-level splits are recorded separately and are not
  introduced without an explicit follow-up decision.

---

## Functional Requirements

1. **FR-01: Repository and route inventory.** Create a maintained matrix for
   both `apps/vendor-web` and `apps/tenant-web` that records route, role,
   feature owner, shared components used, locale coverage, theme coverage,
   responsive status, and density/decomposition status.

2. **FR-02: Semantic theme tokens.** Extend the existing `@pte/ui` token
   stylesheet with semantic light and dark values for page/shell/card surfaces,
   text, borders, controls, focus rings, status tones, overlays, charts, and
   navigation. Do not create a second palette or use feature-specific hex
   values in migrated screens.

3. **FR-03: Theme runtime.** Add a shared theme contract/provider and a
   header-accessible theme toggle supporting `light` and `dark`, with light as
   the continuity default. Persist the user's choice per browser and apply the
   theme before the dashboard becomes visually interactive to avoid a visible
   flash where practical.

4. **FR-04: Common component migration.** Make the common shell, header,
   sidebar, buttons, inputs, selects, cards, badges, tables, pagination,
   dropdowns, action menus, modals, alerts, empty/loading/error states, and
   motion primitives consume semantic tokens and render correctly in both
   themes. Adapt the reusable visual boundaries from `nextjs-admin-dashboard`
   into `@pte/ui`; do not link the reference app at runtime.

5. **FR-05: Locale runtime.** Add a shared locale contract/provider and a
   language switcher for `vi` and `en`. Vietnamese is the default on a clean
   browser. Persist the selected locale per browser and keep `html[lang]` in
   sync with the active locale.

6. **FR-06: Message ownership.** Keep generic component labels and messages in
   the shared locale layer, and keep vendor/tenant/domain messages in the
   owning app or feature dictionary. New or migrated UI must not introduce raw
   user-facing strings directly in JSX. Existing API data, user names, plan
   names, question text, and other domain content remain data unless separately
   translated by product decision.

7. **FR-07: Locale-aware formatting.** Route dates, times, numbers, and
   currency display in migrated surfaces through locale-aware formatters so
   Vietnamese and English do not show inconsistent hard-coded formats.

8. **FR-08: Shared shell ownership.** Consolidate presentation ownership of
   the duplicated dashboard shell/header/sidebar/theme/language controls in
   `@pte/ui`, while leaving role filtering, navigation definitions, auth gates,
   and app-specific labels in the respective apps.

9. **FR-09: Motion and accessibility.** Define shared motion durations/easing
   and use CSS transitions/keyframes for reveal, dropdown, modal, hover, and
   state feedback. Preserve semantics, focus-visible behavior, keyboard
   interaction, dialog/menu/table labels, and reduced-motion behavior.

10. **FR-10: Common state presentation.** Standardize presentational loading,
    empty, error, success, stale, conflict, and forbidden states in `@pte/ui`
    where the existing feature/auth boundary already provides the state. This
    requirement does not change redirect behavior, authorization decisions,
    retry semantics, or API error ownership.

11. **FR-11: Density audit.** Classify every route as normal, content-heavy, or
    function-heavy using visible section count, independent user jobs, form or
    table density, and modal/action count. Record the evidence and a proposed
    treatment before changing a function-heavy screen.

12. **FR-12: Route-preserving decomposition.** For approved function-heavy
    screens, use tabs, stepper stages, drawers, collapsible sections, or
    contextual panels inside the existing route. Keep current callbacks,
    hooks, query/mutation ownership, validation, API payloads, permissions,
    and action entry points unchanged.

13. **FR-13: Incremental migration waves.** Migrate in this order unless a
    verified dependency requires adjustment: common foundation; vendor/admin
    pilot; remaining vendor commercial/content/support; tenant host core;
    tenant exam workflows; examiner/student/public/auth surfaces; regression
    and handoff.

14. **FR-14: Visual verification.** For each migration wave, verify at least
   one representative route at desktop, 390px, and 320px widths in light and
   dark themes, and verify Vietnamese/English labels for the changed surface.

15. **FR-15: Behavior boundary.** This work may add presentation state for
   theme, locale, tabs, steps, and drawers, but must not change backend code,
   API clients/contracts, auth/session semantics, route permissions, domain
   state, or business logic.

16. **FR-16: Concurrency and recovery preservation.** Visual decomposition
   must retain existing version-conflict handling, license-code idempotency/
   recovery, assignment preview staleness checks, and student placeholder-data
   behavior in their current feature owners.

17. **FR-17: Browser-navigation semantics.** In-route tabs, steps, drawers,
    and mobile detail panels must preserve existing pathname, query, and hash
    contracts. If presentation state intentionally uses query/hash state, the
    plan must record refresh, deep-link, browser back/forward, Escape, close,
    and focus-return behavior before implementation.

18. **FR-18: Actor and permission evidence.** The route matrix must cover
    platform administrator, host administrator, examiner, proctor, student,
    and anonymous behavior, including visible navigation, route access,
    protected actions, and current redirect/forbidden outcomes.

19. **FR-19: Behavior-preservation evidence.** Every migrated route or dense
    surface must have a pre/post manifest covering URL state, role gate,
    queries, mutations, payloads, validation, callbacks, modal/action entry
    points, and presentation-state ownership.

20. **FR-20: Failure-state evidence.** The plan must map loading, empty,
    validation, unauthorized, forbidden, not-found, network/timeout,
    conflict, stale-preview, duplicate-request/idempotency, and placeholder-data
    cases to their current feature owner, expected presentation, user action,
    and verification scenario.

---

## Non-Functional Requirements

- **Maintainability:** shared visual decisions belong in `@pte/ui`; feature
  screens compose common primitives instead of duplicating them.
- **Accessibility:** changed controls retain accessible names and keyboard
  paths; use WCAG 2.2 AA targets where applicable (4.5:1 normal text,
  3:1 large text and non-text UI/focus indicators), and do not convey status
  by color alone. Review both themes manually.
- **Performance:** do not add an animation library or repeated render loop;
  theme/locale initialization must not introduce data fetching or blocking
  business requests.
- **Responsive behavior:** at 320px and 390px, no page-level horizontal
  overflow is allowed; table overflow remains scoped to its table container.
- **Consistency:** no new arbitrary color utilities or feature-local palette;
  follow `pte-web/docs/CODING_STANDARDS_WEB.md`.
- **Safety:** do not persist credentials, tokens, or domain data as part of
  theme/locale preferences; do not put secrets in plan artifacts or tests.
- **Verification:** each wave records applicable `@pte/ui` typecheck, app
  typecheck/lint/build, diff checks, and browser evidence with limitations
  stated separately.
- **State safety:** existing recovery, stale-preview, conflict, and
  placeholder-data guards remain reachable from the same user workflows.
- **Runtime contracts:** valid stored theme values are `light`/`dark` under
  `pte-web.theme`; valid stored locale values are `vi`/`en` under
  `pte-web.locale`. Missing or invalid values fall back to light and `vi`,
  respectively. Theme/locale initialization must not issue business requests.
- **Evidence status:** every phase gate is recorded as `PASS`, `UNVERIFIED`,
  or `BLOCKED`; unavailable authenticated data or browser infrastructure is
  reported as a limitation rather than silently treated as passing.

---

## Success Criteria

- [ ] **Inventory coverage:** 100% of current `vendor-web` and `tenant-web`
  routes are present in the route/density/theme/locale matrix before the final
  migration wave.
- [ ] **Common foundation:** one shared theme contract, one shared locale
  contract, and one shared visual shell are used by both apps; no new
  app-local copies are introduced.
- [ ] **Theme coverage:** all common components and the vendor/admin pilot pass
  visual checks in light and dark at desktop, 390px, and 320px widths.
- [ ] **Locale coverage:** clean browser defaults to Vietnamese; switching to
  English updates all changed UI labels, accessibility labels, and
  locale-sensitive formatting; reload preserves the choice.
- [ ] **Behavior preservation:** changed routes retain their existing URLs,
  role gates, API calls, action callbacks, validation, and modal entry points;
  no backend or business-logic diff is part of the refactor.
- [ ] **Actor and state evidence:** the actor/permission matrix,
  behavior-preservation manifest, density audit, and failure-state matrix cover
  every route or migrated surface.
- [ ] **Navigation semantics:** changed in-route presentation preserves
  pathname/query/hash, refresh/deep-link, back/forward, Escape, close, and
  focus-return behavior as applicable.
- [ ] **Density decisions:** 100% of P1 function-heavy candidates have an
  evidence-backed decomposition proposal before implementation; no route-level
  split is made without separate approval.
- [ ] **Common states and motion/accessibility:** standardized state surfaces
  remain presentation-only, new non-essential motion is disabled under
  `prefers-reduced-motion: reduce`, and changed common controls remain
  keyboard/focus operable.
- [ ] **Quality gates:** `@pte/ui` typecheck, both app lint/typecheck/build
  checks, `git diff --check`, and applicable browser smoke checks pass or their
  exact pre-existing limitations are documented.

---

## Out of Scope

- Backend/API/domain model changes, new business capabilities, or data-model
  migrations.
- Changes to authentication, authorization, role boundaries, session storage,
  API payloads, validation rules, or business-state transitions.
- Replacing the existing PTE logo or changing the PTE brand identity.
- Runtime linking, iframe reuse, or importing the reference app as a
  dependency; the reference is a source/style reference only.
- Route-level decomposition in the first UI plan; route proposals are tracked
  for a later product decision.
- Translating user-generated/domain data, question content, plan names, or API
  error semantics without a separate product/content decision.
- Refactoring the Flutter `pte-app`; this plan covers the web workspace
  (`pte-web/apps/*` and `pte-web/packages/ui`).
- Introducing a new charting, animation, or component library unless a later
  plan explicitly approves it.

---

## Assumptions

- Vietnamese (`vi`) is the product default and English (`en`) is the only
  additional locale in this plan.
- Light mode remains the continuity default; the user can explicitly select
  dark mode and the selection is persisted per browser.
- The existing PTE logo asset and visible brand copy remain unchanged.
- Existing routes remain the primary navigation contract; tabs, steps, drawers,
  and panels are acceptable presentation changes inside those routes.
- `@pte/ui` is the ownership boundary for reusable visual, theme, locale
  contract, and motion infrastructure; apps retain domain labels and role
  navigation definitions.
- Existing API/client behavior is already the source of truth and is not
  redesigned by this UI plan.
