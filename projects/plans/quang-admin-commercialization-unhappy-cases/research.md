# Research and design adjudication

Ngày2026-10-05. Two read-only researchers (Primary and Alternative) inspected current repo; main agent verified material contracts. Planning HEADs: API f070e38, web eafe3c8, both clean at check. No runtime tests, network writes or implementation performed in this planning turn. Previous lifecycle test evidence belonged to an earlier HEAD, not fresh gates for these commits.

## Primary approach

Reuse current modular-monolith services, owning Constants/DomainException and @pte/ui/query patterns. Target application PESSIMISTIC_WRITE review, field/schema validation, existing authorized host reset, Plan expectedVersion, guarded license issuance idempotency and effective expiry. Unit tests for branches; PostgreSQL committed race/fault tests before deciding hypotheses need fixes.

Primary proposed four workgroups; main plan expands to seven execution phases solely to isolate contract, revoke transaction and regression gates. No additional product features implied.

## Alternative approach and tradeoffs

- Refetch-before-save is smaller than Plan expectedVersion but cannot reliably detect stale payloads. Select client-carried expectedVersion plus existing lock.
- Expected state + subscription identity is smaller than storing a generic preview-token framework. Select resource-specific revoke preview and server-checked state/scope; no generic lifecycle platform.
- AFTER_COMMIT + REQUIRES_NEW cancellation can be recoverable but cannot provide atomic billing/session completion alone. Select BEFORE_COMMIT owning session listener/public facade after consistent lock protocol; stop if commit/rollback proof or module boundaries fail rather than quietly switch to eventual success.
- Manual lookup after issuance timeout is smaller than idempotency but cannot guarantee original intent. Select durable actor/operation/key/payload-digest/result-reference committed with code; token generation collision retry must retry whole transaction.
- Replacing legacy list array with page envelope breaks callers. Select additive admin namespace with masked bounded PagedResult; existing routes have explicit deprecation/rollout safety.
- Snapshots, capacity compensation and durable mail/invitation are larger alternatives rejected/deferred by approved policies.

## Verified current source

| Area | Source | Observed contract / implication |
|---|---|---|
| Application | pte-api/app/src/main/java/com/pte/billing/internal/service/TenantApplicationService.java; internal/repository/TenantApplicationRepository.java | findPending ordinary read, approval is one transaction spanning tenant/identity/decision; keep this atomicity and add targeted lock. |
| Application DTO/read | billing/internal/dto/request/SubmitApplicationRequest.java, RejectApplicationRequest.java; dto/response/TenantApplicationResponse.java | Existing reason/reviewer/time fields can be rendered; missing schema length validation needs targeted additions. |
| Application UI/client | pte-web/apps/vendor-web/features/commercialization/components/AdminApplicationDetailView.tsx; packages/api-client/src/requests/billing/applications.ts | Detail searches whole list; independent existing GET detail not wired. Approve/reject don't share pending guard. |
| Plan | billing/internal/service/PlanService.java; domain/Plan.java; PlanCatalogView.tsx | Current write lock + outstanding guard + immutable ACTIVE family implemented; no version/precondition yet; numeric clamp and Number(price) remain. |
| Issue | billing/internal/service/LicenseCodePersistenceService.java | REQUIRES_NEW insert already locks/rechecks Plan; don't reintroduce outer Plan lock. Add family eligibility and intent/result in this same persistence transaction. |
| Redeem | billing/internal/service/LicenseCodeService.java; internal/repository/LicenseCodeRepository.java | Conditional update/activation/linkage in one transaction already exists; prove real concurrency/rollback rather than gratuitous replacement. |
| License HTTP | billing/internal/controller/LicenseCodeController.java; LicenseCodeResponse.java; web billing/licenseCodes.ts | Current GET array top100, bearer string path revoke, no issue key. Use additive UUID admin namespace to avoid UUID/String path ambiguity. |
| Revoke/session | session/internal/listener/SubscriptionRevokedSessionListener.java; SessionLifecycleService.java; internal/repository/ExamSessionRepository.java | Default transactional listener AFTER_COMMIT; cancellation REQUIRED. Current findBySubscriptionIdAndStatus already has PESSIMISTIC_WRITE, contrary to the initial plain-query hypothesis. Reuse it, review deterministic order/recheck and commit boundary; atomic durable effect is not established by source inspection. |
| Session lock order | SessionLifecycleService.changeSubscription/open/publish | changeSubscription locks session before old/new subscriptions; opposite proposed revoke order creates deadlock risk. Need inspect every subscription↔session writer, not just listener annotation. |
| Email | notification/internal/listener/TenantApplicationNotificationListener.java | Approval AFTER_COMMIT dispatch carries generated password transiently; no delivery guarantee inferred from API200 or inbox state. |
| Recovery | identity/internal/controller/UserController.java; UserService.java; UserProvisioningHelper.java; vendor features/tenancy/components/TenantDetailView.tsx | Existing GET users/by-tenant, POST users/id/reset-password and credentials/send-email; PLATFORM_ADMIN can manage HOST_ADMIN with scope checks. Prefer existing Tenant detail manual reset; rotation not resend of original. |
| Cache | vendor features/notifications/api.ts; features/auth/api.ts; packages/api-client/src/client/client.ts | protectedCache helper handles unauthorized clear, not comprehensive session-generation fencing. Reuse actual auth lifecycle where possible, don't assume helper proves late-result isolation. |
| Pagination | shared/web/PagedResult.java, PageMeta.java | Reuse project data/meta shape and page/size conventions, not new envelope. |

Paths are workspace-relative; hypotheses remain hypotheses until tests run. Original matrix source line numbers can drift.

## Preflight risks (must enter plan)

1. Opposite lock order + billing/session dependency cycle: event/public facade must not create reverse internals imports, and source session references must be reread after acquiring coherent locks.
2. Token remains exposed if only UI masking is done: new page DTO must exclude raw token; legacy routes, issue result caches, access logs and body traces require explicit treatment.
3. Idempotency key/result stored outside insert transaction can acknowledge an orphan key or duplicate code. Broad DataIntegrityViolation retry hides non-token failures; restrict collision classification.
4. Plan @Version alone doesn't protect stale forms, and JPQL/native bulk writers can bypass version increment. Client precondition plus all-writer inventory is required.
5. Reset recovery needs exact host target + scope + explicit confirmation + audit, not arbitrary contact-email match or automatic password rotation.
6. Legacy VND/duration/capacity handling must not rewrite active entitlements or silently classify grants as reverted.
7. Prior lifecycle full-suite11 failures reproduced on clean HEAD906345c require fresh baseline comparison on currentHEAD; don't mark this plan validated by prior tests or expand fixes without approval.
