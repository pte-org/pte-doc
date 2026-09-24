# Phase 02 — Scoped readiness and deterministic generation

## Goal

Make Practice preflight and generation use the exact same persisted skill set, producing an immutable snapshot that contains no tasks from unselected sections.

## Requirements

- Extend the public assessment-module contract with scope-aware template feasibility and deterministic generation. Session orchestration must call the public module facade rather than assessment internals.
- Use one shared requirement resolver for template items, section selection, task-type normalization, and template-policy-specific implicit items.
- Preflight only requirements and question-bank stock in selected sections. Unselected-section shortages do not block Practice.
- Generation creates exactly the selected sections, retains deterministic seed/idempotency behavior, and includes a policy-injected Speaking item only when Speaking is selected and the pinned template policy requires it.
- Keep one source of truth for question counts, task timing, scoring metadata, media references, and task runtime contract.
- Ensure generated form assignments and snapshots stay immutable after generation; retrying the same idempotency key does not produce duplicate forms.
- Preserve current full-template behavior for Mock Test and Official Exam and for older clients whose drafts resolve to full scope.
- Keep the existing rule that a READY exam does not become unpublishable due to later question-bank changes.

## Likely files

- `pte-api/app/src/main/java/com/pte/assessment/AssessmentService.java`
- `pte-api/app/src/main/java/com/pte/assessment/internal/service/ExamGenerationService.java`
- Assessment feasibility DTO/service/repository methods as needed.
- `pte-api/app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
- `pte-api/app/src/test/java/com/pte/assessment/internal/service/ExamGenerationServiceTest.java`
- `pte-api/app/src/test/java/com/pte/session/internal/service/ExamOrchestrationServiceTest.java`
- Assessment/question-bank repository tests for scoped stock queries where needed.

## Steps

1. Add one assessment-side operation that resolves requirements for `(pinned template version, selectedSkills)` and returns scoped feasibility.
2. Route draft preflight through that operation and map shortage details to existing friendly host-facing issue/message patterns.
3. Pass the session's persisted scope into deterministic generation; use the identical resolver as feasibility.
4. Verify form creation, task ordering, snapshot item count, version/fingerprint metadata, and transaction/idempotency behavior for shared and unique forms.
5. Keep reporting and attempt code unchanged unless regression tests reveal a real incompatibility; the generated snapshot, not the selected scope field, remains delivery/scoring truth.

## Tests and exit criteria

- Full scope yields the same template sections and requirements as before the change.
- A one-skill Practice with enough selected stock succeeds even when an unselected section has zero stock.
- A shortage in a selected skill blocks preflight and reports the affected task requirement.
- A selected skill with no template items is rejected rather than creating an empty section.
- A Reading-only snapshot contains no Speaking/Writing/Listening item; multi-skill scope contains exactly the selected sections.
- Template policy-injected Speaking content appears only for selected Speaking and when existing policy calls for it.
- Repeated generation with the same idempotency key returns the same job/forms; no partial READY exam is created on failure.
- Attempt totals, score aggregation, and subset report behavior match generated snapshot content; overall score remains absent for partial skills.

## Design Constraints

- Do not duplicate section-to-requirement filtering in `session` and `assessment`.
- Never filter tasks in `pte-app` or pin a broader snapshot and hide items in the UI.
- Preserve template timing and scoring. Zero seconds must not be repurposed to mean untimed.
- Practice `UNLIMITED` continues to mean audio replay only; it does not change attempt lifecycle.
- Avoid schema or endpoint changes to reports if existing partial-skill aggregation passes.
- Preflight: scope filtering belongs in assessment behind `AssessmentService`; preserve `ExamGenerationService`'s deterministic seed, shared template requirement builder, template policy handling, and existing answer-free feasibility DTO. Session must not import assessment internals. User selected no unit tests and no quality gate; run the backend compile gate only.

## Quality and Testing State

- Quality: skipped_by_user; decision: user_confirmed_skip.
- Testing: not_started; skipped_by_user per user request. No unit tests created or run.
- Build Gate: passed — `mvnw -pl app -DskipTests clean compile`.
