# Spec: Practice Exam Anti-Cheat Policy Flag

**Date:** 2026-09-27
**Status:** Ready

---

## Problem Statement

Practice exams currently resolve to `LockdownMode.NONE`, so the Windows desktop app intentionally does not enter fullscreen or activate desktop restrictions. Hosts need an opt-in Practice setting for a controlled test environment without changing the stronger `STRICT` policy used by Official exams.

The feature must reuse the existing session-scoped `ExamPolicy.lockdownMode` contract so the backend pins one authoritative policy into the student attempt.

## User Stories

- **[P1]** As a host, I want to enable anti-cheat restrictions while creating a Practice exam so that I can run a controlled local/demo test.
  Accepted when: the Create Exam workflow exposes a Practice-only setting and submits the selected policy with the draft creation request.

- **[P1]** As a student, I want an anti-cheat-enabled Practice attempt to enter fullscreen before the first task appears so that the Practice session behaves like a controlled desktop session.
  Accepted when: a Windows attempt whose pinned policy is `STANDARD` activates fullscreen and existing standard lockdown hooks before `TaskTypeDispatcher` renders the task; activation failure prevents the task from opening.

- **[P1]** As a student, I want a detected violation to be visible and recorded without losing my Practice attempt so that I can continue testing the exam flow.
  Accepted when: the app shows the existing warning UI, persists the violation locally, and submits it through a verified authenticated audit path; no pause or force-submit occurs.

- **[P1]** As a host, I want Official exams to retain strict enforcement independently of the Practice checkbox so that a permissive Practice choice cannot weaken Official policy.
  Accepted when: Official sessions resolve to `STRICT` and the Practice setting cannot change that value.

- **[P2]** As a host, I want the selected anti-cheat policy visible in the exam review/detail UI so that I can verify the session before sharing its session ID.
  Accepted when: exam detail distinguishes Practice unrestricted, Practice controlled, and Official strict policy.

- **[P3]** _(out of scope — future)_ Pause, force-submit, or automatically invalidate a Practice attempt after a violation.

## Functional Requirements

1. **FR-01:** Reuse the existing `lockdown_mode` persistence and wire it through the draft create/update contract. Do not add a second boolean column as a competing source of truth.
2. **FR-02:** For `PRACTICE`, the host UI shall expose a boolean setting:
   - disabled → `lockdownMode = NONE`;
   - enabled → `lockdownMode = STANDARD`.
3. **FR-03:** `STRICT` shall remain reserved for `OFFICIAL_EXAM` in this feature. A Practice checkbox shall not expose or produce `STRICT`.
4. **FR-04:** The policy shall be stored on the session before publication/opening and copied into the pinned attempt snapshot. The student app shall use the pinned `lockdownMode`, not infer security from `examMode`.
5. **FR-05:** A `STANDARD` attempt shall activate the existing Windows fullscreen, shortcut, clipboard, and violation-monitoring stack before the first task is displayed. Existing activation-failure behavior remains fail-closed for the initial controlled session.
6. **FR-06:** A `STANDARD` violation shall produce the existing in-app warning and an audit event. It shall not pause, force-submit, invalidate, or terminate the Practice attempt in this release.
7. **FR-07:** Audit delivery shall use an authenticated backend contract that exists in the current monolith. The implementation shall not rely on a stale or unimplemented `/api/proctor/violations` REST path.
8. **FR-08:** The host review/detail response shall expose enough policy information to distinguish `NONE`, `STANDARD`, and `STRICT` without requiring the host to inspect the student app.
9. **FR-09:** The release verification path shall exercise a Windows release binary with both Practice policy values and record the observed `lockdownMode`, fullscreen state, and activation result.
10. **FR-10:** The setting shall not change Practice skill selection, retry count, timer behavior, task navigation, question generation, scoring, or report publication behavior.

## Non-Functional Requirements

- **Security:** The backend policy is authoritative and pinned per attempt. A missing or invalid non-legacy policy must not silently enable a weaker mode for a newly created controlled session.
- **Compatibility:** Existing sessions and existing API consumers remain readable. Legacy sessions with no explicit policy retain their documented compatibility default until migrated.
- **Platform:** The initial acceptance target is Windows desktop. macOS, Linux, mobile, and browser enforcement are out of scope.
- **Audit reliability:** Every detected violation is persisted locally before network delivery; delivery failures remain retryable and observable. The final transport must be covered by an API contract test.
- **UX:** Enabling the Practice setting must not add a pause or force-submit path. The student can continue after a warning.

## Success Criteria

- [ ] Practice unchecked creates/updates a session whose returned policy is `NONE`; the Windows student app remains windowed.
- [ ] Practice checked creates/updates a session whose returned policy is `STANDARD`; the Windows release app enters fullscreen before displaying task 1.
- [ ] In a controlled Windows release test, an activation failure prevents the task screen from opening and gives a retryable error.
- [ ] At least four controlled violation cases (fullscreen exit attempt, blocked shortcut, external clipboard change, forbidden-app detection where configured) create local audit rows with the correct attempt ID and severity.
- [ ] At least one online and one offline/reconnect audit-delivery test demonstrate that the host-side audit receives the event through the verified backend contract.
- [ ] Official exam creation and start remain `STRICT` regardless of the Practice-only setting.

## Out of Scope

- Pausing, force-submitting, invalidating, or terminating a Practice attempt after a violation.
- Allowing `STRICT` for Practice.
- Replacing the existing Windows native lockdown implementation.
- Server-authoritative timer/deadline enforcement; this remains a separate high-priority security gap and must not be implied as solved by this flag.
- Continuous process monitoring, screen-recording detection, VM detection, multi-monitor blocking, macOS/Linux enforcement, and mobile enforcement.
- Proctor/host workflow redesign beyond exposing the policy and receiving the audit event.

## Assumptions

- The existing `ExamPolicy.lockdownMode` column and DTO path are the canonical policy mechanism.
- `STANDARD` means fullscreen plus the current standard desktop hooks, with warning/audit-only response after a detected violation.
- The host may change the policy only while the session is still editable/scheduled; once an attempt is pinned, the policy is immutable for that attempt.
- The current release binary is rebuilt after the native plugin and Dart service changes; an older installed binary is not considered evidence of the current code behavior.

## [NEEDS CLARIFICATION]

None for the agreed MVP direction. The audit transport and release verification details are implementation acceptance gates, not product-choice blockers.
