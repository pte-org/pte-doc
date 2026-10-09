# Spec: Tenant Exam Questions tab and Overview lifecycle actions

**Date:** 2026-10-08
**Status:** Approved direction; ready for phased planning
**Related plan:** `../quang-tenant-exam-ui-decomposition/`

---

## Problem Statement

The tenant Exam detail header currently combines identity, status, preview, and lifecycle
buttons in one crowded action row. The generated questions are a core part of an Exam but
are not exposed as a dedicated task-oriented tab. This refinement separates context from
actions and gives Hosts a clear read-only Questions surface without changing business logic.

---

## User Stories

- **[P1]** As a Host, I want to see Exam status, schedule, capacity, and valid lifecycle
  actions together in Overview so that I can understand and operate the Exam without
  scanning a crowded header.
  Accepted when: status is rendered in the Overview status card and Open/Close/Cancel are
  rendered only in the Overview lifecycle area according to the existing status guards.

- **[P1]** As a Host, I want a dedicated Questions tab so that I can inspect the generated
  Exam content without opening an unrelated action or scrolling through other workflows.
  Accepted when: Questions is a separate tab and renders the existing immutable snapshot
  preview grouped by section/task type with loading, empty, error, and content states.

- **[P1]** As a Host, I want the detail header to show only Exam identity and navigation
  context so that the page is easier to scan.
  Accepted when: the header has no duplicated lifecycle action rail or standalone View Exam
  action; those concerns are reachable from Overview and Questions.

- **[P2]** As a Host, I want seven tabs to remain usable on narrow screens so that I can
  reach Questions and operational tabs without page-level horizontal overflow.
  Accepted when: tab navigation supports keyboard focus, horizontal tab scrolling, and one
  visible panel at a time at the supported mobile viewport.

- **[P3]** _(out of scope)_ As an author, I want to edit or reorder generated Exam questions
  from the tenant detail screen. Authoring remains in the Vendor workflow.

---

## Functional Requirements

1. **FR-01:** The Exam detail route exposes these seven tabs in this order: Overview,
   Questions, Exam settings, Participants & proctors, Submissions, Examiner, and
   Results & publication.
2. **FR-02:** Overview renders the current status, schedule, capacity, policy, Exam code,
   and existing compact metrics without duplicating the full settings or result workflows.
3. **FR-03:** Overview renders only lifecycle actions valid for the current Exam status;
   Open, Close, and Cancel retain their existing disabled-state, confirmation, mutation,
   invalidation, and authorization behavior.
4. **FR-04:** The header retains identity/back navigation and may expose a compact overflow
   menu, but does not render a duplicate lifecycle action rail or standalone View Exam
   action.
5. **FR-05:** Questions renders the existing generated Exam snapshot/preview contract,
   grouped by section or task type, and preserves answer-key hiding and existing preview
   data transformations.
6. **FR-06:** Questions is read-only. No question editing, reordering, answer-key editing,
   question-bank mutation, or new tenant Exam mutation is introduced.
7. **FR-07:** All seven tab labels and the Questions content have Vietnamese default and
   English translations through the existing locale contract.
8. **FR-08:** Tab switching retains the existing visited-tab state strategy, local filters,
   pagination, selected detail state, and modal reachability; inactive panels may lazy-load
   on first visit without blanking the global shell.
9. **FR-09:** Existing API hooks, query keys, status guards, role boundaries, routes, and
   mutation ownership remain unchanged.

---

## Non-Functional Requirements

- **Performance:** Switching tabs must not trigger a full-page route loading state; first
  visit may show a local tab skeleton, and subsequent visits keep retained content visible
  while data revalidates.
- **Accessibility:** Tabs must expose correct tab/tabpanel semantics, keyboard navigation,
  visible focus, and accessible labels for the Questions preview and lifecycle actions.
- **Responsive behavior:** At a 390px viewport, the tab strip may scroll horizontally but
  the document must not gain horizontal overflow; action groups must wrap or stack without
  clipping.
- **Theme:** New or moved presentation uses existing semantic light/dark tokens; no
  light-only or white-only text/background assumptions are introduced.
- **Safety:** No backend, database, API-client, authentication, scoring, or Exam lifecycle
  contract change is part of this refinement.

---

## Success Criteria

- [ ] The detail screen exposes exactly 7 approved task tabs in Vietnamese and English.
- [ ] The header contains 0 duplicated lifecycle buttons and no standalone View Exam button.
- [ ] Overview contains 1 state-aware lifecycle action area and the status card.
- [ ] Questions displays the existing generated snapshot preview in read-only mode without
  exposing answer keys or adding question mutations.
- [ ] Switching through all 7 tabs preserves the global shell and produces no full-page
  loading flash.
- [ ] Desktop and 390px browser smoke pass in light/dark mode with Vietnamese default and
  English switch, including keyboard tab navigation and no page-level horizontal overflow.
- [ ] Existing lifecycle, submission, Examiner, result/publication, and modal behaviors
  remain reachable and no API/backend files are changed.

---

## Out of Scope

- Editing, reordering, importing, deleting, or scoring Questions from the tenant detail tab.
- Changing question-bank authoring, Vendor Exam Builder behavior, snapshot generation, or
  answer-key rules.
- Changing Open/Close/Cancel backend contracts, status transitions, permissions, or routes.
- Moving the Examiner work queue from `/examiner/work`.
- Adding analytics, audit APIs, new scoring rules, or result calculation behavior.

---

## Assumptions

- The existing Exam preview/snapshot query and answer-key-hiding behavior are the source of
  truth for the new Questions tab.
- Published/generated question snapshots remain immutable; the tenant detail surface only
  presents them.
- The existing shared Tabs, skeleton, modal, semantic theme, locale, and collapsible-section
  primitives are sufficient unless a focused gap is found during planning.

---

## [NEEDS CLARIFICATION]

None. The user approved the read-only Questions tab and Overview-owned lifecycle actions.
