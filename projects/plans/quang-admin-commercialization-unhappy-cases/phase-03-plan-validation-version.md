# Phase 03 — Plan validation and expectedVersion stale-form protection

Status: unstarted. Story: US-02 [P1]. Primary IDs: PLN-01..08, PLN-11/12. Secondary preservation checks: PLN-09/10 (primary07). Depends on 01; precedes 04.

## Design Constraints

Retain current Plan lock, outstanding unexpired ISSUED guards, ACTIVE family immutability, ACTIVE-only archive, referenced-draft soft Delete, pending-modal protection and activation subscription snapshots. Add version only to Plan. Capacity Plans remain valid. New/edited Plans use VND, EXAM duration1..3650, caps/slots1..2000, decimal total precision19/scale2 (maximum17 integer digits); no bulk legacy rewrite or license snapshots.

## Detailed tasks and exact files

1. `pte-api/app/src/main/java/com/pte/billing/domain/Plan.java`: Plan-only nonnull long @Version; expand-first next migration adds version default0 to existing rows. `billing/internal/dto/response/PlanResponse.java` and `billing/internal/mapper/PlanMapper.java` expose version. Confirm migrations do not change catalog values or V77 protections.
2. `billing/internal/dto/request/PlanRequest.java`: retain create DTO with validation. New `PlanUpdateRequest.java` has editable fields plus required nonnegative expectedVersion; new `PlanTransitionRequest.java` has required expectedVersion. `billing/internal/controller/PlanController.java` binds PUT/activation/archive to these DTOs. `billing/internal/service/PlanService.java`: compare under existing write lock before applying updates/transition; stale409. Preserve service public boundary, stop old unguarded signatures being alternative writers, and flush before constructing response so returned version is current. Optimistic lock failures map to owning conflict code, no generic500.
3. Validate trim/nonblank and name/description255, price string -> BigDecimal unchanged, family-required/forbidden fields, currency exactly VND, duration bounds and integer caps. `billing/internal/constant/BillingConstants.java` owns new validation/conflict codes/messages. Validate activate as well: legacy invalid Plans cannot be newly activated unnoticed; show repair guidance. Existing untouched ACTIVE legacy values are not bulk-revalidated during reads; new issuance safety is handled in04.
4. `pte-web/packages/api-client/src/{types/billing/index.ts,requests/billing/plans.ts,requests/billing/plans.test.ts,index.ts}` update request/response types and transition functions. Trace tenant consumers; create remains distinct and tenant catalog reads tolerate added response field. Never substitute latest server version into stale payload automatically.
5. `pte-web/apps/vendor-web/features/commercialization/{api.ts,constants.ts,components/PlanCatalogView.tsx}` captures version at edit/confirmation. Keep input strings; remove silent Math.min clamp, validate integer/range without altering intent; currency fixed VND with explanation for manual legacy repair. Format decimal strings exactly without `Number(plan.price)` precision loss. Show field errors, fresh server values beside retained stale input on409, explicit reload/reapply choice, no automatic overwrite.
6. Preserve current pending modal and draft Delete paths; disable per-operation transitions, catch asynchronous handlers, reset current-action errors, guard record/operation identity. Regression pending Cancel/X/Escape/backdrop and route-away callbacks; use06 session generation without broad modal redesign.

## Proposed HTTP contract

POST `/api/v1/plans` uses create fields and existing success200. PUT `/api/v1/plans/{publicId}` uses same editable fields plus expectedVersion. POST activation/archive uses `{expectedVersion}`. GET/list adds `version` while retaining existing array shape. Missing/negative version400; stale409 `PLAN_VERSION_CONFLICT` (proposed owner constant); invalid DTO400, direct business422; lifecycle conflict409; deleted/missing404. Draft DELETE remains guarded/idempotent204 and cannot edit/reactivate/archive.

Mixed clients must fail closed on protected writes; deploy coordinated client support and backend enforcement only after authorization. No compatibility writer auto-fills current version. Manual repair of legacy non-VND/out-of-range Plans uses guarded edit; if outstanding codes prohibit entitlement repair, surface an operator blocker instead of bypassing guards.

## Verification planned after consent

Unit/HTTP: price17/18 integer digits,2/3 fractional digits, null/negative/zero, name255/256, mixed family, caps2000/2001, duration3650/3651/overflow, currencies123/ZZZ/non-VND. Assert DTO400 versus business422 intentionally; stale/missing version on all writers; returned version after flush; existing draft Delete and guards.

PostgreSQL: clean+legacy version migration; >=10 each update/update, update/archive, activation/activation, issue/archive and issue/entitlement-edit interleaving (04 completes issue coverage). Stale transaction loses409 without archived revival or overwritten fields. Verify no affected existing subscription expiry/cap. At valid duration max, activation persists expiry. Legacy invalid fixtures remain untouched until manual guarded repair; no silent migration changes.

Browser: native field validation and HTTP bypass separate;3000 not clamped, large decimal displays exact, 409 retains form and prompts comparison, close while pending still blocked, old delayed callback cannot close newly opened form. Transition failure caught; no unhandled rejection. PLN-09/10 report retained guards rather than snapshot behavior.

## Exit, rollback and dependencies

Exit: all write paths protected, exact returned version, boundary contracts, preserved lifecycle/modal receipts. Rollback retains version column and backend checks; if reverting to incompatible clients, disable protected writes and prompt update. Never roll back to unguarded old PUT. No automatic currency/duration repair or entitlement compensation.04 depends on these catalog safety rules;06 supplies final cache/operation isolation.

## Quality and Testing State

Quality: not evaluated; pending consent. Unit/PostgreSQL/browser: not started; pending consent. TDD recommended for stale form and race acceptance, not enabled. No new tests have run.
