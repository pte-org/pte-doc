# Phase 3: Template Approval Lifecycle and Readiness Validation

## Objective

Make template authoring safe for Platform Author and Platform Admin while
ensuring only a complete, renderer/scorer-compatible template can become the
active source for exam generation.

## Files

- `pte-api/app/src/main/java/com/pte/scoretemplate/domain/enums/ScoreTemplateStatus.java`
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java`
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/controller/ScoreTemplateController.java`
- `pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateActivationValidator.java`
- V41 approval metadata migration and scoretemplate service/controller tests
- `pte-web/apps/vendor-web/features/scoretemplate/` only for additive
  readiness/approval DTOs

## Implementation steps

1. Reconcile the current ScoreTemplate status and migration V41 approval
   metadata. Use one state model; do not add duplicate submitted/approval
   columns if V41 already provides the required timestamps and actor fields.
2. Implement the lifecycle using the existing enum/API state:
   DRAFT -> PENDING_APPROVAL -> ACTIVE -> RETIRED. Admin approval and rejection
   return the pending version to DRAFT according to the current service
   contract; do not add a new `SUBMITTED` enum or duplicate approval model.
   Keep pending, active and retired item lists immutable.
3. Enforce the role matrix:
   - Platform Author: create draft, edit draft, submit draft, view status.
   - Platform Admin: review, reject/return with reason, activate and retire.
   - Host/tenant roles: read only active templates that are usable for their
     tenant's exam flow.
4. Update activation validation to require all 22 current scored PTE task types,
   unique sequence/order, valid count/timing/weights and active allowlisted
   profiles. Preserve the existing rule that weights need not sum exactly to
   100 because the source table is rounded.
5. Treat retired/inactive catalog types as unavailable for new template items.
   Existing submitted/active versions containing a retired type remain readable
   according to the migration policy, but a new version must replace it.
6. Validate question-pool readiness separately from template structural
   validity. Activation should not silently promise a pool that cannot generate
   exams; expose a readiness report with task code, required range and
   available count to the authorized admin/author surface.
7. Preserve existing clone-to-new-draft behavior as the only way to change an
   active/retired plan. Return a friendly error when an old client attempts an
   in-place edit.
8. Add audit records for submit, reject, activate, retire, clone and validation
   failure with actor, version and reason, not question content.

## Design Constraints

- Preflight: Java 21/Spring Modulith conventions, the existing
  `ScoreTemplateStatus` lifecycle and V41 rejection metadata, method-level
  controller role annotations, `ScoreTemplateActivationValidator`, public
  `ScoreTemplateService` readiness facade, and shared `AuditLogService` were
  checked before implementation.
- One active template family/version at a time, enforced transactionally by the
  existing database uniqueness rule and service lock/flush ordering.
- Activation must pin runtime profiles and scoring versions before changing any
  status. Partial activation is not allowed.
- A Platform Author must never gain activation permission through a broad role
  annotation or controller fallback.
- A catalog retirement must not mutate old templates or snapshots. New drafts
  must use active catalog/profile entries only.
- Human-facing state and validation errors are defined in backend constants and
  mapped by web/app clients; raw exception names are not UI copy.
- No question content or random seed is exposed merely by inspecting template
  readiness.

## Acceptance criteria

- Author can create/edit/submit a draft (server state `PENDING_APPROVAL`); an
  author activation attempt is denied
  and audited.
- Admin can activate a valid submitted template; the prior active version is
  retired in the same transaction.
- Invalid templates identify every missing/duplicate/invalid task type or profile
  rather than failing on the first opaque enum error.
- Active/retired templates reject item mutation; clone produces an editable
  draft with copied but independent profile pins.
- A retired task type cannot be added to a new draft, while an old snapshot is
  not deleted or rewritten because of that retirement.
- Friendly API error text explains “this version cannot be edited; clone it to
  make changes” instead of displaying a machine code.

## Dependencies and handoff

- Depends on Phase 1 catalog lifecycle and Phase 2 runtime profiles.
- Must reconcile with the completed score-template/exam-generation plan before
  changing any existing endpoint or status.
- Unblocks snapshot generation with a fully resolved template contract.

## Quality and Testing State

Status: checks passed; awaiting the `--hard` completion confirmation before
marking this phase complete. Decision: unit tests=yes; quality gate=yes.

Test report: `tests/phase-03-template-lifecycle-and-readiness-test-report.json`
(37 passed, 0 failed, 0 skipped).

Quality gate: `APPROVED`; report
`quality/phase-03-template-lifecycle-and-readiness-quality-report.json` and
receipt
`quality/phase-03-template-lifecycle-and-readiness-receipt.json`.
One non-blocking note remains: live PostgreSQL migration verification is
deferred to Phase 8.

Required before phase completion:

- Backend unit tests for the complete state machine, role matrix, activation
  transaction, validation aggregation, clone behavior and friendly errors.
- Migration tests for V41 metadata reuse and the single-active invariant.
- Backend compile/test commands:
  .\mvnw.cmd -pl app -DskipTests compile and
  .\mvnw.cmd -pl app test.
- Mandatory ck:quality --gate receipt covering lifecycle integrity,
  authorization, transaction boundaries and compatibility with existing exam
  generation.
