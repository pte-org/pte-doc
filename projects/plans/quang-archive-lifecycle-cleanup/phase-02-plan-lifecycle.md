# Phase 02: Plan Delete draft và retirement guard

Status: completed (scoped implementation and quality/unit gates); integration evidence in phase05. Stories: P1 safe deletion/history. Depends on: phase01.

## Tasks

- [x] Add DELETE Plan controller/platform-admin-only + service transaction + known error codes.
- [x] Load authorized target with lock; require DRAFT, nondeleted, no order/subscription/license references in any state. Set deleted=true and audit; do not touch dependent rows.
- [x] Repeat delete checks role first; same tombstone no-op; missing404. Read/get/list/update/activate/archive reject deleted targets or exclude deleted explicitly.
- [x] Update PlanRepository filters for admin list/active list/get; audit internal historical lookups separately so order/subscription display is not lost.
- [x] Narrow archive to ACTIVE; DRAFT gets conflict directing Delete draft if eligible, ARCHIVED retains existing rule; preserve old rows and error texts where unchanged.
- [x] Under minimal guard policy, block archive and entitlement edit when ISSUED code expiry>null-now or no expiry. Expired timestamp is effective expiry even before cron; redeemed code does not count as outstanding. All references still block DELETE.
- [x] Guard ACTIVE family switch: reject and require new plan, or restrict only per approved policy; document exact selected invariant rather than sneak broader edit rules.
- [x] Serialize issue/check/snapshot-or-live-plan/save against archive/edit through common Plan locking transaction. Refactor outer eligibility + REQUIRES_NEW insertion if it defeats guard; collision retries outside failed transaction, bounded attempts.
- [x] Check order creation can only reference ACTIVE+nondeleted under same lifecycle rule; existing order activation remains historical flow, not generic delete-filter breakage.
- [x] Expose capabilities + blocked reason; batched reference counts for list, exact check again on mutation.

## Files / surfaces

Billing `PlanController`, `PlanService`, `PlanRepository`, `PlanResponse`, `BillingConstants`; Order/Subscription/License repositories for existence/batch queries; `LicenseCodeService` and persistence transaction boundary; audit public service.

## Design Constraints

Preflight: Plan lock is acquired inside each persistence transaction (license/order reservation) and lifecycle write, not outside REQUIRES_NEW. Billing native reference union preserves all historical states; list capabilities are batched. DomainException owns 409 mapping; AuditLogService joins deletion transaction. Tests/quality consent=yes for all phases.

- Plan DRAFT not in customer catalog; deleted Plan not purchasable/issuable; history must remain resolvable through trusted paths.
- No license snapshot architecture in this phase unless validation explicitly changes scope; guard is interim product limitation, not promised final policy.
- Hold lock and dependency check through write. Do not hold Plan lock outside REQUIRES_NEW which reacquires same resource and self-blocks.
- No silent amount/currency changes, quota reversal, cancellation of existing subscriptions.

## Tests to Write First (đề xuất TDD)

- Delete unusedDRAFT → persisted tombstone + one audit; second delete no duplicate audit.
- ACTIVE/ARCHIVED/past reference/missing/forbidden cases; no mutation when conflict.
- Deleted missing from admin/active lists; GET/mutation404; historical order still resolves enough receipt information.
- Archive DRAFT409, ACTIVE no outstanding code succeeds, ISSUED valid/no-expiry blocks, ISSUED elapsed does not block retirement.
- Entitlement edit with outstanding code conflict; metadata edit follows exact approved contract.
- Concurrent issue/archive or issue/edit has serializable valid outcome; no usable code tied to retired live plan under guard policy.
- Token uniqueness collision retry creates one result, transaction stays recoverable.

## Verification / exit

Targeted `PlanServiceTest`, `LicenseCodeServiceTest`, relevant Order/activation tests plus new PostgreSQL lifecycle integration. Assert DB after commit in separate transaction; unit mocks alone not sufficient. Phase02 complete only after receipts show required behavior.

## Quality and Testing State

- User test choice: yes, all phases; Standard, not TDD.
- Quality: APPROVED; [report](quality/phase-02-plan-lifecycle-quality-report.json), [receipt](quality/phase-02-plan-lifecycle-receipt.json).
- Testing: 29 original targeted tests passed; additional HTTP/PostgreSQL/history/race evidence in [test report](test-report.md). ACTIVE type immutable; metadata/price changes remain allowed, entitlement changes blocked with outstanding codes.
