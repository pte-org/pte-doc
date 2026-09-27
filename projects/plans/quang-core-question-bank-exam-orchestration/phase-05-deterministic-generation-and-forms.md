# Phase 5: Deterministic generation, jobs and immutable forms

## Goal

Replace the current active-template/skills/`java.util.Random` synchronous path
with deterministic, auditable generation that can support both one shared form
and one form per student.

## Steps

1. Extend the assessment generation facade to accept an explicit active template
   public ID, selected slot/policy configuration, form mode, base seed and an
   idempotency key. The session module must not call score-template internals.
2. Add immutable provenance fields to snapshots/forms: template public ID and
   version, generation algorithm version, seed, pool-policy fingerprint,
   question public IDs and revision numbers. Keep answer-bearing content in the
   trusted assessment/attempt boundary.
3. Add persistent `exam_generation_jobs` with states `QUEUED`, `RUNNING`,
   `SUCCEEDED`, `FAILED`, `CANCELLED`, attempts, progress counters, last safe
   error, idempotency key and timestamps. Add a unique key for one generation
   request per session/version.
4. Add `exam_forms` and form-item/provenance linkage. Each form references one
   immutable assessment snapshot. Add `form_assignments` to map an eligible
   student to exactly one form, with a unique `(session_id, student_id)` key.
5. Generate a deterministic base seed with a secure server source and derive a
   per-form seed from base seed + form sequence/student-independent form index.
   Persist algorithm version so a future algorithm change does not make old
   exams unreproducible.
6. Preflight every slot before writing. Aggregate missing counts by task type,
   section, required media and any configured pool filter. Reject duplicate
   question IDs within a form. Allow reuse across forms by default.
7. Run generation asynchronously for unique-form audiences or above a
   configured threshold. Official/mock always use the unique-form path; practice
   may use the shared-form path. Use the existing persistent work-queue conventions,
   but make PostgreSQL job/session state authoritative; Redis is not the source
   of truth for exam generation.
8. Make retries idempotent: lock the job/session, resume or discard only an
   incomplete form set, and never publish a partial audience/form set.
9. Publish only after all forms and assignments exist. Preserve the existing
   `snapshotPublicId` field for shared/legacy delivery while adding form-aware
   resolution for new attempts.
10. Ensure the delivery/attempt boundary receives a form/snapshot ID and never
    exposes seed, answer key, or unpublished source-question metadata.

## Backend locations

- `assessment/AssessmentService.java`
- `assessment/internal/service/ExamGenerationService.java`
- `assessment/internal/service/SnapshotPublishService.java`
- `assessment/domain/ExamSnapshot.java`, `ExamBlueprint.java`, snapshot items
- `session/domain/ExamSession.java`, `Enrollment.java`
- new assessment/session generation job, form and assignment entities/repos
- `session/internal/service/SessionLifecycleService.java`
- `attempt/internal/service/AttemptLifecycleService.java`
- `attempt/internal/service/SnapshotPinService.java`
- `attempt/internal/dto/request/StartAttemptRequest.java` and the session
  entitlement/form lookup used by attempt start.

The existing student start contract remains `POST /api/v1/attempts` with a
session public ID. The server resolves the student's immutable form assignment
inside the session entitlement lookup; the client does not choose a snapshot or
form ID. `SnapshotPinService` then pins the resolved form snapshot as it does
today, preserving the attempt module's local pinned-copy invariant.

## Design Constraints

- The generated snapshot/form is write-once after publish.
- The seed is persisted but not returned to host UI before the exam opens.
- Validation must happen before any published form is visible.
- Use a deterministic ordering/hash query or seeded selection; do not use
  database `RANDOM()` or an unseeded process-global random source.
- Question content is read through `ItembankService`/`QuestionFreezeView` and
  copied into immutable assessment content. No cross-module ORM joins.
- A generation job may fail and be retried, but a published session may never
  be silently regenerated with different questions.
- If a legacy skills-only request remains, it must go through the same generator
  and provenance contract.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; same-seed
  deterministic generation and orchestration defaults have focused tests.
- Quality gate: mandatory and approved; report and receipt are stored under
  `quality/phase-05-deterministic-generation-and-forms-*`.
- Testing: passed; the final regression evidence is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: backend compile, schema validation, manual
  same-seed reproducibility check, different-seed variation check, job retry and
  idempotency walkthrough, shared/unique form mapping check, and answer-leakage
  review of host/student response DTOs.

## Exit criteria

- A host can see generation progress and final form/audience counts without
  seeing question content before open.
- Re-running the same generation request cannot create a second form set.
- Same provenance reproduces the same ordered question IDs; changed seed creates
  a permitted variation.
- Existing attempt delivery can consume the assigned form without breaking
  legacy shared-snapshot sessions.

Implementation note: persistent job and idempotency state are in place, but
the current local release executes generation synchronously inside the request;
worker-backed asynchronous execution and durable FAILED-job retry processing
remain operational hardening items.
