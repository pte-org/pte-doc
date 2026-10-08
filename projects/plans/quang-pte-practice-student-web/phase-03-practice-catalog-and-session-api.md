# Phase 3 — Practice Catalog and Standalone Session Facade

## Objective

Create a student-facing practice catalog and standalone practice-session boundary that reuses existing pinning/runtime/timing/media infrastructure without pretending a host-created exam session is self-practice.

## Story mapping

- P1: entitled student can see the pre-session overview and start only when authorized; locked student cannot start.
- P2: catalog capability/readiness metadata supports familiar cards and responsive states.
- P3: no official exam administration surfaces.

## Scope

- Catalog grouped by section/task type with visible-vs-runnable availability.
- Pre-session overview containing title, sections, item types, time information, timer, `Save & exit` and `Next`.
- Explicit practice source/session type and facade over existing attempt infrastructure.
- Server-side content readiness, runtime profile allowlist and capability/preflight check.
- Session start/resume/overview/task delivery/heartbeat/media/answer boundary contracts.
- Confidence enum and answered-item validation are part of this boundary before
  any runtime phase is enabled; Phase 07 only adds projection/Progress behavior.

## Exact files/areas likely changed

- Existing attempt areas: `pte-api/app/src/main/java/com/pte/attempt/internal/controller/AttemptController.java`, `AttemptLifecycleService.java`, `HeartbeatController.java`, `pte-api/app/src/main/java/com/pte/attempt/internal/dto/response/TaskView.java`, `SubmitAnswerRequest.java`, `pte-api/app/src/main/java/com/pte/attempt/domain/enums/AttemptStatus.java`.
- Existing session areas: `pte-api/app/src/main/java/com/pte/session/internal/controller/StudentSessionController.java`, `pte-api/app/src/main/java/com/pte/session/internal/service/EntitlementService.java` — adapt only through public boundaries; do not force host enrollment semantics onto practice.
- Existing runtime areas: `pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileRegistry.java` and task contract services.
- New practice facade/controller/application/domain/DTO files under a verified `com.pte.practice` or existing owning module boundary; exact package is a Phase 01 architecture decision.
- Additive migration files under `pte-api/app/src/main/resources/db/migration/` for practice source/session/draft/idempotency/version fields where existing tables cannot express the contract.

## Dependencies

- Phase 01 coverage matrix.
- Phase 02 entitlement service and auth context.
- Existing snapshot/pinning/runtime contract plans and current attempt/media services.

## Implementation steps

1. Define catalog DTO: task code, section, label, availability, profile/renderer key, schema version, required capabilities and fixture/provenance status.
2. Resolve catalog entries from the canonical registry; reject unknown renderer/profile keys and do not expose answer keys.
3. Define practice session aggregate/source and idempotent start operation. Preflight entitlement, content readiness, client capability and deadline before creating a session.
4. Reuse existing pinning/task delivery, adding safe saved-answer state needed for resume without leaking reference answers.
5. Define server state transitions, deadline enforcement, heartbeat and optimistic version/lease behavior.
6. Add protected catalog/session/task/media/answer routes through the approved controller boundary.
7. Add migration and repair/rollback notes; preserve official exam attempt/report behavior.

The session state machine must name the aggregate and execution record chosen in
Phase 01, return resumable drafts, and expose a stable error matrix for
`401/403/404/409/410/422/429/5xx`. New practice mutations must require an
idempotency key; safe retries replay the first result and stale versions return
`STALE_SESSION_VERSION` without overwriting another tab.

## Acceptance criteria

- Locked students can read safe catalog metadata but cannot create or reach a practice session.
- Entitled start is idempotent and opens an overview before question/recording/submission.
- A missing/retired/unsupported profile blocks before delivery with a stable machine code; no silent next-task.
- Server deadline and entitlement are enforced after reload, expiry, revoke and direct API calls.
- A practice session is distinguishable from host-created official sessions and does not require an exam-session code/enrollment.
- Task responses contain safe runtime metadata and saved state sufficient for resume.
- Existing official exam routes remain compatible.

## Design Constraints

- Reuse `TaskRuntimeProfileRegistry`, pinning, answer validation, heartbeat and media seams; do not fork them.
- Runtime keys are allowlisted identifiers, never class names/scripts from storage.
- Keep public IDs and ownership checks; do not expose database IDs or correct answers.
- Idempotency and conflict semantics must be explicit before frontend calls are added.

## Quality and Testing State

- Quality: **APPROVED**. Report: `quality/phase-03-practice-catalog-and-session-api-quality-report.json`; receipt: `quality/phase-03-practice-catalog-and-session-api-receipt.json`.
- Testing: **PASSED**. Report: `tests/phase-03-practice-catalog-and-session-api-test-report.json`.
- Evidence: safe catalog/readiness projection, runtime allowlist and capability preflight, locked-versus-entitled start, durable start/mutation idempotency, student ownership, optimistic version checks, server deadline expiry, live entitlement re-check, additive practice/session schema and optional confidence persistence.
- Review boundary: task delivery, media authorization, answer mutation routes and Progress projection remain intentionally deferred to Phases 05–07; no live PostgreSQL, email/RabbitMQ or production API smoke test was claimed.
