# Phase 1 — Contract Freeze and Coverage Matrix

## Objective

Freeze the cross-repository decisions that affect security, persistence and runtime scope before implementation. Produce a canonical API/domain/coverage matrix without changing production behavior.

## Story mapping

- P1: email identity, active-plan entitlement, locked access and imported-student unlock.
- P2: shell/runtime capability and responsive contract.
- P3: explicitly deferred navigation remains out of scope.

## Scope

- Resolve email authentication semantics, organization context and non-enumeration behavior.
- Define eligible-plan/capacity policy and active student/membership state.
- Define `PRACTICE` session source, empty-discard/non-empty-resume lifecycle, server deadline and concurrency model.
- Produce an ADR/schema decision for the boundary between a student-facing
  `PracticeSession` aggregate and any reused execution/attempt record; official
  exam attempt/report semantics must remain unchanged.
- Map all 23 canonical task types to existing runtime profiles and interaction families.
- Mark `WRITE_EMAIL`, explicit video and premium-reference fixture rows as gaps.
- Define the per-row `canonical-contract`, `renderer-status`, `content-status`
  and `release-status` vocabulary from the coverage matrix; mark
  `PERSONAL_INTRODUCTION` explicitly as unscored.
- Decide whether `pte-practice` consumes an extracted/shared API client or owns a typed local adapter.
- Freeze isolated-app auth transport, CORS/CSRF boundary, feature-flag owner,
  browser/media support matrix, media retention and test framework/commands.
- Define Progress ownership, historical retention and scoring boundary.

## Exact files/areas likely changed

- `pte-doc/projects/plans/quang-pte-practice-student-web/spec.md` — only if a confirmed decision changes the planning-ready contract.
- `pte-doc/projects/plans/quang-pte-practice-student-web/` — API matrix, task coverage matrix, ADR/decision notes and fixtures/provenance documentation.
- Phase outputs: `phase-01-contract-matrix.md`, `phase-01-task-coverage-matrix.md` and `phase-01-adr-practice-boundary.md`.
- Read-only inputs to map: `pte-api/app/src/main/java/com/pte/identity/internal/controller/AuthController.java`, `AuthService.java`, `LoginRequest.java`, `StudentRosterImportController.java`, `StudentRosterImportService.java`, `pte-api/app/src/main/java/com/pte/tenancy/TenancyService.java`, billing `Subscription.java`, `pte-api/app/src/main/java/com/pte/session/internal/service/EntitlementService.java`, `pte-api/app/src/main/java/com/pte/attempt/internal/controller/AttemptController.java`, `TaskView.java`, `SubmitAnswerRequest.java`, `pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileRegistry.java`, and `pte-api/app/src/main/java/com/pte/reporting/internal/controller/ReportController.java`.
- Existing precedent to reuse: `pte-doc/projects/plans/quang-task-type-catalog-template-runtime-contract/`, `quang-dynamic-task-type-screen-contract/`, `phat-device-check-test-mic-and-sound-ui/`, `phat-exam-prefetch-all-tasks/`, and `quang-practice-finish-submit-lockdown/`.

## Dependencies

- Research findings in `reports/261007-quang-pte-practice-student-web-brainstorm.md`.
- Existing runtime registry/template/snapshot contracts; no reimplementation.
- User confirmation of the recommendations in the parent plan before Phase 02 migrations.

## Implementation steps

1. Inventory current request/response/status/error contracts and write a compatibility matrix.
2. Write the organization-context decision and ambiguous-email behavior.
3. Write the entitlement truth table for imported/active/inactive students, active/expired/suspended plans, capacity failure, removed membership and unknown organization.
4. Write the session state machine: overview → in progress → draft/exit or submitted; empty exit discarded; non-empty draft resumable; no fabricated report.
5. Define empty/non-empty precisely: an answer-bearing payload or completed
   recording makes a draft non-empty; untouched/skip-only exit is discarded and
   creates no report. Record browser-close, pending-autosave and media-failure
   transitions.
6. Write idempotency/version rules: scoped key + request hash + replayed response
   with a recommended 24-hour TTL; `409 IDEMPOTENCY_KEY_REUSED` and
   `409 STALE_SESSION_VERSION`; use optimistic versioning rather than an
   unbounded multi-tab lease.
7. Create the 23-row runtime coverage matrix with canonical profile, renderer family, media capability, release status and unresolved gaps.
8. Decide the `PracticeSession`/attempt schema, auth transport, media format,
   API error matrix, feature-flag/runbook ownership and test commands; record
   migration/rollback order.
9. Obtain user decisions on the five parent-plan recommendations before Phase 02 migrations.

## Acceptance criteria

- No unresolved contract is silently assumed in later phase files.
- The eligibility truth table explicitly distinguishes `EXAM_PACKAGE` from `STUDENT_CAPACITY`.
- Multiple memberships never merge private data or unlock ambiguously.
- Every canonical enum value has one existing profile/family mapping; `WRITE_EMAIL` and video appear as explicit gaps.
- Every canonical row has exactly one release status and no fixture/blocked row
  is presented as runnable production content.
- Session, confidence, media and Progress semantics are written as testable rules.
- The package/module owner table, session schema ADR, transport/CSRF decision,
  media format decision, error matrix, flag owner and test commands are present.
- API compatibility and rollout order are approved before implementation.

## Design Constraints

- Documentation and read-only inspection only.
- Do not add a second runtime registry, question type enum or official report semantics.
- Do not use the reference site's private content/assets as a contract.
- New API names remain conceptual until existing controller/module conventions are verified in the implementation phase.
- Preflight: backend follows package-owned `internal/controller`, `internal/service`,
  `internal/dto`, `internal/constant/*Constants.java` and migration-per-version
  conventions; user-facing validation text is owned by the module constants.
  `pte-practice` must use feature folders, shared UI/API primitives and
  `constants.ts` per owning feature rather than a monolithic page. Tests mirror
  source ownership: Maven/JUnit for `pte-api`, Vitest/RTL for pure web behavior,
  and Playwright for cross-route/browser behavior. These are the applicable
  conventions for this documentation phase.

## Quality and Testing State

- Quality: **APPROVED** — see `quality/phase-01-contract-freeze-and-coverage-quality-report.json` and the valid receipt beside it.
- Testing: **PASSED** — see `tests/phase-01-contract-freeze-and-coverage-test-report.json`.
- Evidence: API matrix, identity/entitlement truth table, decision record, 23-row coverage matrix and scope-challenge sign-off.
