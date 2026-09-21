# Phase 3: Exam draft, audience sources and lifecycle

## Goal

Turn the current immediate session creation into an explicit host exam draft
that can gather audience sources and be safely published later.

## Data model

Add new Flyway migrations after the verified latest migration version. Exact
version numbers must be chosen from the branch at implementation time.

- Extend `exam_sessions` with lifecycle/generation configuration fields while
  preserving tenant, subscription, time window and policy data. Make the
  existing `snapshot_public_id` nullable for DRAFT/PREPARING rows, add a
  version column, lifecycle status, template public ID/version, form mode,
  reuse policy, series key and a safe generation-job reference. Backfill all
  existing non-null snapshots as READY/SCHEDULED compatibility rows before
  tightening any new constraints.
- Add `exam_audience_sources`: session ID, tenant ID, source type
  (`STUDENT`, `CLASS`, `PROGRAM`), source public ID, created-by, timestamps,
  and a unique `(session_id, source_type, source_public_id)` constraint.
- Add `exam_audience_members`: session ID, student public ID, source provenance,
  status (`CANDIDATE`, `ELIGIBLE`, `EXCLUDED`, `ENROLLED`), reason code,
  conflicting session/form references, and immutable publish timestamp.
- Keep existing class-assignment rows as a compatibility projection or migrate
  them through the canonical audience service; do not maintain two independent
  enrollment rule engines.

## Steps

1. Add `createDraft`, `getDraft`, `updateDraft`, source add/remove/list, and
   `previewAudience` application methods. All are tenant-scoped and draft-only.
2. Add source resolution through a public enrollment/roster facade. Resolve
   class and program membership in batch; do not issue one query per student.
3. Union all sources by student public ID and retain source provenance for UI
   explanation. Do not alter class/program membership.
4. Add the exam series/cycle key and form mode/reuse policy to the draft. Require
   a non-empty series key for official/mock exams because their default is
   `EXCLUDE_STARTED_IN_SERIES`; practice defaults to `ALLOW`.
5. Add state transitions and row locks. A draft cannot be edited after it enters
   `PREPARING`; publish cannot operate on a stale version.
6. Expose a safe summary: candidate count, duplicate count, eligible count,
   excluded count, capacity comparison, source labels, and readiness flags.
7. At publish, materialize the eligible audience into the existing enrollment
   aggregate in the same transaction as the immutable audience snapshot. This
   makes the existing `EnrollmentRepository.countBySessionId` the actual
   per-session capacity count; generation/form assignment can then be retried
   without creating a second enrollment set.
8. Keep existing manual enrollment endpoints as a compatibility path that calls
   the canonical audience/enrollment service and rejects mutations after publish.

## Backend locations

- `session/domain/ExamSession.java`
- `session/domain/SessionClassAssignment.java`
- `session/internal/service/SessionLifecycleService.java`
- `session/internal/service/EnrollmentService.java`
- `session/internal/service/SessionClassAssignmentService.java`
- `session/internal/controller/SessionController.java`
- `session/internal/controller/SessionClassAssignmentController.java`
- enrollment/class/program public service surfaces and their roster query DTOs.

## Canonical DTOs

The implementation should expose explicit records rather than overloading the
old skills-only request:

- `CreateExamDraftRequest`: name, template public ID, subscription public ID,
  opens/closes, mode/policy, requested capacity, form mode, reuse policy and
  optional series key.
- `PatchExamDraftRequest`: only mutable draft fields, with an expected version.
- `AudienceSourceRequest`: source type and source public ID.
- `AudiencePreviewResponse`: candidate/duplicate/eligible/excluded counts,
  paged safe members, reason codes, and readiness flags.
- `ExamPreflightResponse`: template shortages, package failures, overlap,
  capacity and audience issues in one structured response.

## Web/API-client locations

- `packages/api-client/src/types/scheduling/index.ts`
- `packages/api-client/src/requests/scheduling/sessions.ts`
- `packages/api-client/src/requests/scheduling/classAssignments.ts`
- new audience request/types modules under `packages/api-client/src/requests/scheduling/`
- `apps/tenant-web/features/exams/`
- `apps/tenant-web/features/classes/`
- `apps/tenant-web/features/programs/`

## Design Constraints

- Publish-time audience is an immutable snapshot; later roster changes affect
  only future exams.
- Preview is advisory. Publish must re-resolve and revalidate under a
  transaction; never trust a client-supplied student list as authoritative.
- All source IDs must be tenant-authorized. A source from another tenant is
  indistinguishable from not found to the caller.
- Deduplication occurs before capacity checks and generation counts.
- Keep `ExamSession` as the aggregate in this release; do not add a reusable
  `Exam` parent until a concrete multi-sitting requirement exists.
- Use optimistic version or pessimistic row lock consistently; do not combine
  stale client writes with last-write-wins behavior.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; draft,
  audience, lifecycle, optimistic-version and authorization behavior has
  focused unit/security coverage.
- Quality gate: mandatory and approved; report and receipt are stored under
  `quality/phase-03-exam-draft-audience-lifecycle-*`.
- Testing: passed; the final regression evidence is recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: backend compile, migration validation, API-client
  typecheck, manual class/program/student union walkthrough, tenant-isolation
  check, and concurrent draft-update review.

## Exit criteria

- Host can save a draft with any combination of student/class/program sources.
- Preview is deduplicated and explainable without exposing questions.
- Published audience snapshot is stable and legacy class/manual paths cannot
  bypass the lifecycle gate.
