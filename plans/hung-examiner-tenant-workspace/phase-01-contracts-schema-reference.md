# Phase 01 — Contracts, schema and AI reference

Status: not started. Dependency: approved spec and validation answers.
Stories: P1 assigned AI reference and reliable decisions; P2 only actual available reference fields.
Requirements: FR01–03,05–07,10. Output does not yet enable human finalization.

## Inputs and output paths

API root: `pte-api/app/src/main/java/com/pte/`.

- Existing `scoring/domain/{ExaminerAnswerScore,ScoringAnswer}.java` and `scoring/domain/enums/`.
- Extend `scoring/dto/request/SubmitExaminerScoreRequest.java` and response `{ExaminerAttemptDetailResponse,ExaminerAnswerDetailResponse,ExaminerScoreSubmissionResponse}.java`.
- New public response `ExaminerAiReferenceResponse.java`, `ExaminerDecisionResponse.java` and enums for availability/decision kind under existing scoring packages.
- New internal `ExaminerReviewVersionService.java`; extend existing `ExaminerAnswerScoreRepository.java` for tenant/actor/request lookup. No separate receipt domain/repository/table. Scoped read policy helper only if existing services cannot own it cleanly.
- Existing `scoring/internal/service/{ExaminerScoringService,ExaminerWorkQueryService}.java`.
- New migrations in `pte-api/app/src/main/resources/db/migration/`; recheck latest V91 and select unused versions. Do not modify applied migrations.

## Design Constraints

- Extend creation-only immutable score metadata; do not introduce another final-score aggregate or policy table.
- DTOs retain old read aliases while updated decision fields become authoritative. New mutation contract is explicit, not optional blind MANUAL interpretation.
- Tenant/active role/owned assignment precedes AI projection and authorized media signing. Keep student identity, answer keys, Host scores, provider secrets and other examiners hidden.
- LEGACY_IMPORTED is server/migration-only. Nullable old metadata is recognized as legacy, not accepted for new modern decisions.
- No media/provider/network calls while holding mutation locks; hash excludes signed URLs.

## Implementation steps

1. Re-read actual DTO/entity/migration constraints and pick exact next migration numbers before edits.
2. Add decision kind, reviewed AI score/version, expected review version and request identity to immutable score creation. Keep existing PreUpdate/PreRemove protection.
3. Embed request receipt on the immutable score row: key, canonical fingerprint and expected/viewed versions stored at creation; partial unique `(tenant_id, examiner_public_id, request_public_id)` WHERE request_public_id IS NOT NULL. Scoped lookup before new writes detects cross-answer reuse. Fingerprint includes answer, score, kind, expectedReviewVersion and nullable reviewedAiVersion.
4. Add constraints for integer0..100, allowed kinds and complete modern metadata. Existing rows must remain safely representable pending Phase03 bounded legacy annotation. Do not annotate published/AI_ONLY rows as if newly finalized.
5. Canonicalize AI version from persisted status/result/provenance/scoredAt; AVAILABLE only when existing hasPublishableAiScore is true. PENDING/AI_SCORING→PENDING, SCORING_FAILED→FAILED, invalid/STUB/unknown SCORED→UNAVAILABLE.
6. Compute reviewVersion per answer using pinned frozen content identity, assignment owner, policy/cohort identity/member disposition, AI reference, decision and publication. Do not reuse whole-session review hash or treat answer lockVersion alone as complete.
7. Add safe detail fields for cohort mode, publication state, finalization capability/blocking reason, aiReference, decision and reviewVersion. Pre-cohort owned work stays readable but cannot finalize.
8. Expose one's own committed request identity in decision projection so timeout reconciliation can distinguish exact intent, not only equal scores. Never expose another actor's receipt.
9. Keep old status/myScore/submittedAt aliases derived consistently. Queue progress counts human decisions, not AI readiness.
10. Document specific error codes for old payload, missing manual cohort, stale review, conflicting receipt and unavailable work; preserve existing HTTP conventions.

## Planned verification

From pte-api: `.\mvnw.cmd -pl app -am -DskipTests compile`.
If tests selected: `.\mvnw.cmd -pl app -am '-Dtest=ExaminerScoringServiceTest' -Dsurefire.failIfNoSpecifiedTests=false test` plus new focused version/DTO cases.

- Assigned active Examiner sees real AI; other role/tenant/assignment is denied before media access.
- REAL valid0/100 is AVAILABLE; raw null is not falsely FAILED; STUB/out-of-range is UNAVAILABLE.
- Media URL refresh leaves versions unchanged; AI/content/policy change updates the relevant version; unrelated answer changes do not.
- Serialization preserves aliases and hides PII/teacherScore/answer keys. No invented rubric/transcript.
- PostgreSQL schema accepts valid modern/legacy shape and rejects malformed modern metadata/key reuse.

## Acceptance and handoff

Shared contract is fully defined and safe read projection compiles. Persisted decision is still existing immutable score. Phase02 consumes exact enum/hash/receipt definitions. Phase03 owns SQL data alignment and migration diagnostics.

## Quality and Testing State

- Quality: not evaluated; user choice pending.
- Testing: not started; user choice pending; no --tdd selected.
- Commands above are proposed, not executed; record evidence and limitations after implementation.
