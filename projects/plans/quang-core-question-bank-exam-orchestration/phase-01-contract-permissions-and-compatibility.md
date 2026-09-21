# Phase 1: Contract, permissions and compatibility boundary

## Goal

Freeze the target vocabulary and permission matrix before adding tables or
changing the current session create behavior. Produce an explicit API contract
for draft, preflight, generation and publish while retaining a safe migration
path for current clients.

## Current evidence

- `pte-api/app/src/main/java/com/pte/session/internal/dto/request/CreateSessionRequest.java`
  currently requires skills, subscription, time window and capacity.
- `SessionLifecycleService.create()` immediately calls
  `AssessmentService.generateAndPublish()`.
- `ScoreTemplateController` is admin-only; question authoring/type controllers
  already distinguish platform author and admin actions.
- Current frontend request types mirror the skills-based request.

## Steps

1. Document the canonical nouns and IDs: `ScoreTemplate` (the current global
   template), `ExamSession` (the first-release exam aggregate),
   `AudienceSource`, `AudienceMember`, `GenerationJob`, `ExamForm`, and
   `FormAssignment`.
2. Define lifecycle enums and legal transition table. Reject mutations after
   `SCHEDULED` except explicit operational actions already supported by policy.
3. Define the permission matrix in backend security constants and an API
   contract table. Platform Author saves `DRAFT` templates and submits them;
   Platform Admin approves/activates them. The implementation may use a
   `PENDING_APPROVAL` state, but it must not grant author activation rights.
4. Specify the error envelope for all new validation failures: stable machine
   code, safe friendly default message, field/slot/student details, and a
   correlation/request ID where available.
5. Add a compatibility document and deprecation behavior for skills-only
   session creation. It must either require an explicit compatibility feature
   flag or translate the request to the active template without silently
   overriding a selected template.
6. Map the existing public facades and define new facade methods before any
   internal repository is called from another module.

## Files and contracts to settle

- Backend: `session/domain/enums/SessionStatus.java`,
  `session/internal/dto/request/CreateSessionRequest.java`,
  `session/internal/controller/SessionController.java`,
  `assessment/AssessmentService.java`,
  `itembank/ItembankService.java`, `billing/BillingService.java`.
- Security: existing shared role/permission constants and controller
  `@PreAuthorize` declarations.
- Web client: `packages/api-client/src/types/scheduling/index.ts`,
  `packages/api-client/src/requests/scheduling/sessions.ts`.
- Documentation: add an API/state matrix to this plan's implementation notes;
  do not change the older commercialization plan.

## Design Constraints

- Preflight: current contract conventions are `ApiResponse` plus `DomainException`
  with module-owned constants; `SessionStatus` is a persisted VARCHAR enum and
  can accept additive lifecycle values without rewriting existing migrations.
  Frontend status labels are exhaustive constants consumed by the shared Badge.
- Do not introduce a second exam aggregate in this phase.
- Do not remove the old endpoint until tenant-web is migrated and a compatibility
  smoke path proves no stale client can publish an unvalidated exam.
- The legacy skills-only endpoint is a temporary adapter only; new official/mock
  exams must still receive the series/reuse/form defaults from the canonical
  service and may not silently fall back to an unsafe shared form.
- Method security must enforce author/admin differences server-side; UI hiding
  is not authorization.
- Error codes remain stable for clients, but raw codes are never a product UI
  message.
- New public facade methods must return DTO/read contracts, not ORM entities.
- Preserve tenant isolation and the current global-content read-only boundary.

## Quality and Testing State

- Unit-test expansion: enabled per the latest user instruction; focused
  permission/contract tests and regression coverage were executed.
- Quality gate: mandatory and refreshed after the complete implementation;
  report:
  `quality/phase-01-contract-permissions-and-compatibility-quality-report.json`;
  receipt:
  `quality/phase-01-contract-permissions-and-compatibility-receipt.json`.
- Testing: passed; exact commands and counts are recorded in
  `tests/phase-08-verification-test-report.json`.
- Required checks during cook: inspect controller authorization, compile the
  app, typecheck `@pte/api-client`, verify request/response examples, and run
  manual unauthorized/authorized role checks against a local stack if available.

## Session Notes

- Added additive `DRAFT`, `PREPARING`, and `READY` session status vocabulary.
- Updated the shared scheduling status contract and tenant status labels.
- Canonical creation is now `POST /sessions/drafts`; the old skills-only
  `POST /sessions` fails closed with a friendly migration response.
- Build gate passed: Maven app compile, `@pte/api-client` typecheck, and
  tenant-web TypeScript check.
- Phase completion is recorded after the explicit test and quality gates in the
  current worktrees; no commit or push was performed.

## Exit criteria

- Lifecycle, role matrix, compatibility rule and error envelope are unambiguous.
- No phase after this one needs to invent a status, role, or endpoint shape.
- `ck:quality` finds no blocker/high issue for the contract boundary.
