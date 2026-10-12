# Phase 03 — Publication barrier and bounded legacy alignment

Status: completed. Dependencies: Phase01 schema and Phase02 session coordination.
Stories: P1 Host publishes final human decisions; existing results remain stable.
Requirements: FR08–10.

## Inputs and output paths

Relative to `pte-api/app/src/main/java/com/pte/`:

- `scoring/internal/service/{GradingCompletionEvaluator,GradingCohortService,ScoringReviewReadQueryService,ScorePublicationLockService}.java`.
- `scoring/ScoringService.java` and public scoring DTO/read model for manual publication inventory/readiness.
- `scoring/dto/response/{HostScoreReviewResponse,HostScoreReviewView,GradingCohortResponse}.java` as required for authoritative mode/capability/counts.
- `reporting/internal/service/ReportPublishService.java` and `reporting/internal/dto/response/ReportPublicationReadinessResponse.java`.
- New immutable Flyway data migration after Phase01 schema; `pte-api/scripts/diagnose-examiner-finalization-legacy.sql` for read-only diagnostic inventory.
- Delivery/remediation notes in this plan folder; no migration version reuse.

## Design Constraints

- Frozen nonexcluded cohort inventory is authoritative for manual publication; never use live all-submitted membership there.
- Revalidate pinned expected coverage, assignment actor, decision provenance and selected score pointer inside publish transaction; do not trust stored COMPLETED alone.
- Objective/UNSCORED aggregation and readiness outside manual policy keep current contracts. Published snapshots and AI_ONLY are not rewritten.
- Reporting uses public ScoringService facade; no imports of scoring internal repositories.
- SQL-only bounded legacy annotation/alignment; no runtime repair, automatic cohort creation, fabricated AI history or JPA immutable-row updates.

## Implementation steps

1. Expose manual inventory/readiness via scoring facade DTOs: mode, frozen member identities/version and concrete blockers/counts. Reuse existing grading reads where sufficient; add only missing safe fields.
2. Extend manual evaluator to require every frozen pinned subjective item has actual answer, assigned actor-owned publishable immutable score and matching selected EXAMINER pointer. Existing objective requirements remain in the manual cohort barrier.
3. Readiness and publication consume identical frozen nonexcluded membership. Fetch matching submitted attempts through AttemptService; reject missing/unsubmitted required members and ignore excluded attempts that submitted after freeze.
4. Under session mutex, re-evaluate actual coverage and selected pointers before snapshot creation. Add manual policy checks to report input projection: selected AI/unselected/teacher fallback cannot satisfy manual subjective readiness.
5. Keep actual POST preflight and bodyless POST publish contracts; publish revalidates readiness under the mutex and returns concrete blockers. No publication expectedVersion protocol currently exists. Do not conflate grading-cohort/source-selection preview versions with publication, or trust stale preflight/COMPLETED.
6. Add authoritative Host review mode/capabilities and actual assignment/decision readiness counts; avoid UI guesses from a single page or fabricated new stats.
7. Recheck next unused migration version. SQL classifies only unpublished explicit MANUAL cohorts with nonexcluded members and valid score→answer→assignment ownership.
8. Set those existing human rows LEGACY_IMPORTED with null reviewed AI metadata and align EXAMINER source/pointer/selection actor-time from original score. Respect both published session state and existing published report snapshots defensively.
9. Leave AI_ONLY, published, excluded, cohort-less and inconsistent records untouched. Diagnostics list counts and bounded identifiers for each class without student PII or signed URLs.
10. Fail closed when manual legacy row lacks required provenance/alignment. Cohort-less rows later explicitly frozen require operator-reviewed follow-up versioned SQL/remediation before finalization/publication; no freeze-time runtime repair.
11. Document migration row counts, operator preflight and forward recovery. Rolling old manual mutation UI back after schema/policy activation is unsafe; keep writes unavailable until coordinated recovery.

## Planned verification

From pte-api: `.\mvnw.cmd -pl app -am -DskipTests compile`.
If selected: `.\mvnw.cmd -pl app -am '-Dtest=GradingCompletionEvaluatorTest,GradingCompletionEvaluatorAssignmentCoverageTest,ReportPublishServiceTest,ScoreSourceSelectionServiceTest,ScoringReviewServiceTest,ScoringReviewReadQueryServiceTest' -Dsurefire.failIfNoSpecifiedTests=false test`.

- AI ready but one subjective decision absent blocks manual publication; correct full decisions publish exact human scores.
- Missing pinned answer, wrong assignment owner, wrong selected pointer or objective pending blocks manual publication.
- Excluded later-submitted attempt is absent from manual report inventory; required frozen submitted member is present.
- AI_ONLY/no-cohort existing publication remains unchanged; published snapshots are byte/semantic stable.
- PostgreSQL migration fixture: valid manual legacy aligns, ambiguous/excluded/cohort-less stays untouched, published/AI_ONLY untouched, no invented viewed AI.
- Direct API publish with stale preview rechecks under mutex; concurrent final decision cannot produce partial snapshot.

## Acceptance and handoff

Manual final authority is enforced beyond UI. Migration is deterministic and diagnostics/remediation boundary is explicit. Phase05 can render real readiness and frozen workflow without inventing backend state.

## Quality and Testing State

- Quality: not evaluated; user choice pending.
- Testing: not started; user choice pending; no --tdd selected.
- Compile/test/SQL fixture steps are planned only; record actual database engine and executed evidence later.
