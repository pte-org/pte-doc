# Spec: PTE Practice Student Web

**Date:** 2026-10-07
**Status:** Planning-ready

---

## Problem Statement

Students need a dedicated web experience where they can sign in with email, browse the practice product, and complete practice when their organization has purchased an active plan. Students without an eligible organization should still understand the product through the normal UI, but must not be able to start practice.

The first scope is a Pearson PTE AI Practice-inspired student shell in `pte-practice` with four tabs: Home, Practice tests, Study-Pack, and Progress.

## User Stories

- **[P1]** As a student, I want to sign in with my verified email so that I can reach the student web without an organization-specific login flow.
  Accepted when: a verified email session can load the student shell and unauthenticated users cannot load protected student data.

- **[P1]** As an authenticated student without an eligible organization plan, I want to see the normal Home, Practice tests, Study-Pack, and Progress interfaces so that I can understand the available product.
  Accepted when: all four routes render their normal information architecture and no practice action starts an exercise.

- **[P1]** As an authenticated student without practice entitlement, I want practice-entry actions to be visibly locked so that unavailable features are clear without a separate error page.
  Accepted when: Practice tests, Study-Pack, and exercise-entry actions are non-actionable in the UI and direct deep links/API calls cannot start practice.

- **[P1]** As an imported active student in an organization with an active plan, I want practice to unlock automatically so that I can start available practice without a manual per-student activation step.
  Accepted when: after the canonical entitlement state is refreshed, the student's practice-entry action is enabled and the server permits the same operation.

- **[P1]** As a student, I want to view Progress even when I cannot currently practice so that my evaluation history is not hidden by current entitlement.
  Accepted when: Progress remains accessible read-only; students without history see an empty state rather than fabricated scores.

- **[P1]** As an organization administrator, I want student import to respect plan capacity so that an imported student is not unlocked beyond purchased seats.
  Accepted when: an import that exceeds the active plan capacity does not create an entitled student; a successful import under capacity can unlock the student.

- **[P1]** As an entitled student starting a practice test for the first time, I want to see a pre-session overview so that I understand the sections, item types, and time limits before answering.
  Accepted when: the session opens on an overview screen showing the test title, section/item-type/time information, a timer, `Save & exit`, and `Next`; no question, recording, or submission starts before `Next`.

- **[P1]** As an entitled student, I want each visible task type to open its appropriate first-question interaction so that practice is not reduced to a generic placeholder.
  Accepted when: the agreed first-runtime scope covers the selected task types with their correct interaction family (choice, dropdown, drag-and-drop, text entry, transcript marking, audio/video, or recording) and a task can be skipped or submitted through the session shell.

- **[P1]** As an entitled student, I want to rate my confidence for each response so that my progress analysis can distinguish knowledge confidence from correctness.
  Accepted when: after an answer is selected, Low/Medium/High confidence actions are available, the selected level is submitted with that response, and the first-use explanation can be dismissed without blocking the task indefinitely.

- **[P2]** As an entitled student, I want the four screens to preserve the reference product's visual hierarchy and responsive behavior so that the new app feels familiar across desktop and mobile widths.
  Accepted when: reviewed screenshots at 390x844, 1024x768, and 1440x900 preserve the agreed shell, card, lock, and progress patterns.

- **[P3]** _(out of scope for this first scope)_ As a student, I want Leaders, More, Redeem, and other future product areas so that the student web eventually covers the complete reference navigation.

## Functional Requirements

1. **FR-01:** The `pte-practice` app shall expose authenticated student routes for Home, Practice tests, Study-Pack, and Progress.
2. **FR-02:** The app shall support verified email sign-in using the project's canonical identity/authentication contract.
3. **FR-03:** The app shall derive an effective practice-access state from the canonical student membership/import status, student active status, organization plan status, and plan capacity rules.
4. **FR-04:** An authenticated student without effective practice access shall still be able to load the four basic screens.
5. **FR-05:** In the locked state, Practice tests, Study-Pack, and all practice-entry controls shall be visibly locked and shall not start an exercise or submit practice work.
6. **FR-06:** The backend shall enforce the same entitlement at practice start, task/content access, and answer submission boundaries; UI disabled state shall not be the only protection.
7. **FR-07:** A successful student import into an active-plan organization, subject to capacity, shall make the student eligible for practice without a separate manual activation flag.
8. **FR-08:** Plan expiry, plan suspension, student deactivation, or student removal shall revoke new practice access while preserving the student's historical Progress data.
9. **FR-09:** Progress shall be read-only in this scope and shall not display fabricated metrics when no practice history exists.
10. **FR-10:** The first scope shall not require lock explanation modals, upgrade flows, invite-code entry, or detailed lock error copy.
11. **FR-11:** Organization and student data shall be scoped so a student cannot view another organization's private practice or progress data.
12. **FR-12:** An entitled practice start shall open a pre-session overview before the first question, including test title, section/item-type/time information, a timer, `Save & exit`, and `Next`; a locked student shall not reach this session route.
13. **FR-13:** Home shall expose the agreed task catalog by skill group without making premium/reference availability appear as an implemented local runtime until the corresponding entitlement and content are available.
14. **FR-14:** Each task type included in the first runtime milestone shall use an interaction model appropriate to its content contract; the shared session shell shall support first-question loading, skip, answer submission, and early-exit states.
15. **FR-15:** An answer submission shall carry a confidence level of low, medium, or high when the task requires confidence capture; confidence shall not change the correctness score.
16. **FR-16:** Media-backed tasks shall expose an explicit media readiness state before playback or recording, including an actionable path for browser audio/microphone permission failure; the task must not silently submit an empty response.
17. **FR-17:** The product shall define unfinished-session semantics before implementation: resume, discard, or zero-result report. A browser close, media failure, or explicit early exit shall follow the same documented rule.

## Non-Functional Requirements

- **Performance:** The effective entitlement state should be available to the student shell within p95 < 500 ms after the required API responses are available; practice authorization must not depend on a client-only cache.
- **Security:** Every practice mutation and protected practice read must be rejected server-side when the effective entitlement is absent; authorization tests must cover UI bypass/deep-link/API attempts.
- **Availability:** If entitlement lookup fails, the shell may remain visible but practice actions must fail closed rather than default to unlocked.
- **Accessibility:** Locked controls must be perceivable in keyboard and assistive-technology flows and must not appear actionable when access is absent.
- **Responsive behavior:** The four MVP routes must be reviewed at 390x844, 1024x768, and 1440x900 in addition to the 1920x911 reference capture.
- **Runtime accessibility:** Choice controls, confidence controls, drag-and-drop alternatives, text entry, media controls, and locked states must expose keyboard/focus/assistive labels appropriate to their interaction.

## Success Criteria

- [ ] 100% of the four MVP routes render for an authenticated student session.
- [ ] 100% of locked-state test cases prevent practice start through both UI interaction and direct protected API/deep-link attempts.
- [ ] 100% of successful in-capacity imports into an active-plan organization produce an entitled student after the agreed entitlement refresh boundary.
- [ ] 100% of plan-expiry, plan-suspension, student-deactivation, and student-removal cases block new practice while retaining Progress history.
- [ ] 0 fabricated Progress metrics are rendered for students with no practice history.
- [ ] All four routes pass visual review at the three agreed viewport sizes without losing the locked-state affordance.
- [ ] For every task type included in the selected runtime milestone, the first-question acceptance test records the intended interaction family and a no-answer/skip path.
- [ ] Confidence capture tests cover all three levels and verify that confidence does not alter correctness scoring.

## Out of Scope

- Leaders, More, Redeem, and other navigation outside the four MVP tabs.
- Payment, plan purchase, checkout, or organization self-service upgrade flows.
- Lock explanation copy, modal dialogs, upgrade CTAs, and invite-code onboarding.
- A new administrator import experience if the canonical import capability already exists elsewhere in the platform.
- Full parity with every third-party reference interaction or private asset.
- Task types that remain outside the selected runtime milestone after the task-coverage decision.
- Full scoring/AI evaluation parity with the reference product; this scope covers the response contract and session UX until scoring ownership is confirmed.

## Assumptions

- `pte-api` remains the canonical source for identity, student import/membership, organization plan status, capacity, practice authorization, and Progress data.
- A successful import means the student row is valid, active, organization-scoped, and accepted under plan capacity.
- Current Progress belongs to the student and remains read-only even when current practice entitlement is revoked.
- The first UI can use a simple locked visual state without user-facing reason text; detailed messaging can be added later.
- The reference site is used for product inspiration and layout inspection, not as a source of private credentials, tokens, or proprietary runtime code.
- The inspected reference account may expose only free task types; premium-locked task types are coverage gaps until an authorized entitlement or local content fixture is available.

## Planning Decisions

- The first product target includes the actual exercise runtime and answer submission for the visible task catalog, delivered in phases by interaction family rather than as one undifferentiated release. The initial implementation may use local task fixtures for task types whose premium reference content cannot be inspected from the available account; it must preserve the same task contract so canonical content can replace fixtures.
- The canonical authentication, import, membership, plan, capacity, and Progress contracts are not re-created in `pte-practice`. Phase 01 must map and validate the existing contracts. If one email has multiple memberships, the app must use the platform's explicit organization context; it must never merge private data across organizations or unlock from an ambiguous membership.
- Entitlement is server-authoritative at protected route/session start/content/answer boundaries. The shell refreshes entitlement on initial load and app focus/session start; real-time propagation is not required for the first release. Any entitlement lookup failure fails closed for practice.
- A non-empty unfinished session is resumable. An untouched/empty early exit is discarded without a score report. Browser close and media readiness failure follow the same draft/exit policy; no fabricated response is submitted.
- Confidence is required for an answered item before submission/advance and is recorded as low, medium, or high. Skipped items do not require a confidence value. The onboarding explanation is dismissible and is separate from the per-answer control.
