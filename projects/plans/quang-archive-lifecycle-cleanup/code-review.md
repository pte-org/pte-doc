# Code review and verification boundaries

Date: 2026-10-05. Review performed inline using ck:quality and code-review; no independent reviewer agent was available. Five quality reports have source-fingerprinted receipts. APPROVED applies to reviewed changes, not deployment or release readiness.

## Reviewed decisions

- Billing reference guard includes orders/subscriptions/licenses in every historical state; list capabilities use two batched queries, not per-row lookups.
- Delete/activate/archive/edit and license issuance/order reservation share a Plan write-lock contract. Lock lives inside REQUIRES_NEW persistence transactions, avoiding an outer lock waiting on itself. Remote payment calls are not inside the reservation lock.
- Questions reuse existing optimistic version and guard only original never-published drafts. Platform identity and shared/null-tenant scope are checked before idempotent tombstone handling. Native generation queries exclude deleted rows.
- Audit joins the deletion transaction. Actual PostgreSQL fault injection proves no half-committed tombstone when audit fails.
- Migration keeps unknown legacy data protected and publication history monotonic. No reverse itembank-to-assessment dependency, hard delete, media cleanup, restore UI or license snapshot system was introduced.
- API client preserves archive POST and accepts empty DELETE 204. UI uses server capabilities, pending guards and controlled mutation errors. Plan edit conflicts also refetch capabilities after review remediation.
- Shared Modal optional dismissal guard defaults false, preserving existing nonpending callers. ConfirmDialog uses it during confirmation.

## Findings / limits

No unresolved blocking finding was identified in the reviewed lifecycle changes. Full regression is nevertheless FAILED: 11 cases also reproduce on clean HEAD. They were not weakened, deleted or silently waived. See [test report](test-report.md).

Authenticated JWT/filter/method-security E2E is not proven by standalone MVC or mocked browser sessions. Publish/revision races are not claimed as tested. Snapshot retention fixture uses synthetic scalar template/blueprint IDs; it proves persisted content retention, not full publishing/scoring delivery.

ui-ux influenced wording and confirmation behavior only; no layout/style redesign. Its unauthenticated probe redirected to login. Probe P1 placeholder contrast (2.83:1), P2 Forgot password target and P3 password-toggle target are pre-existing login issues outside lifecycle scope, not fixed in this change. Focus rings were preserved for accessibility. Mobile tables retain existing horizontal scrolling rather than a new mobile layout.
