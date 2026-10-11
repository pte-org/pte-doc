# Session lifecycle responsibility refactor

Date: 2026-10-10
Scope: Additional user-requested backend refactor, separate from Exam Staff Phase 02 quality receipt.
Status: Implemented; production and existing test-source compilation passed; independent scoped review APPROVED.

## Assessment and decision

`SessionLifecycleService` previously combined session creation, subscription rebinding, state transitions, policy mutation, read projections, reminder queries, cross-module operation locks and subscription revocation. Those responsibilities have different dependencies and invariants; splitting by use case is more useful than splitting by file length.

Keep the existing facade and method signatures so controllers, `SessionService`, enrollment, orchestration and preview consumers need no routing or API changes. The facade contains delegation only; focused services own the original business methods.

| Service | Responsibility |
| --- | --- |
| lifecycle/SessionCreationService | Subscription-gated assessment/session creation |
| lifecycle/SessionSubscriptionService | Scheduled-session subscription rebinding and enrollment license updates |
| lifecycle/SessionStateService | Open and close transitions |
| lifecycle/SessionPolicyService | Locked scheduled-session policy edits |
| lifecycle/SessionReadService | Session/detail/summary/retry-policy queries |
| lifecycle/SessionReminderService | Closing-soon candidates and locked schedule revalidation |
| lifecycle/SessionRevocationService | Revocation impact, scheduled cancellation and cancellation events |
| lifecycle/SessionAccess | Tenant context and owned-session lookup |
| lifecycle/SessionSubscriptionRules | Shared subscription window/capacity/overlap validation and constraint translation |
| SessionOperationGuardService | Attempt, scoring and publication transaction guards |

The operation guard remains in `internal/service/` alongside the existing package-private `SessionEntryGate`. This avoids making the entry gate public merely to move a file.

## Preserved boundaries

- Existing facade transactional and read-only annotations remain. Extracted command/read services use the original annotations and default REQUIRED propagation, not new transactions.
- Subscription locks precede session locks in creation/open/rebinding workflows; deterministic subscription lock order remains unchanged.
- Existing tenant checks, status conditions, exceptions, repository calls, explicit flushes and cancellation events retain their behavior.
- Entity state machines and policy resolver remain authoritative; no new domain state or migration.
- The existing unit-test setup only receives new constructor wiring. No test cases were added and no tests were executed.
- Unrelated Exam Staff outputs and web worktree changes remain untouched by this refactor.

## Verification

- Production compile: `mvnw.cmd -pl app -am -Dmaven.test.skip=true compile` — BUILD SUCCESS, 2026-10-10 18:57 +07:00.
- Existing test-source compile only: `mvnw.cmd -pl app -am -DskipTests=true test-compile` — BUILD SUCCESS, 219 test source files, 2026-10-10 18:59 +07:00. No tests executed.
- `git diff --check` — no whitespace errors; Git emits existing LF/CRLF normalization warnings.
- Facade: 172 lines; extracted lifecycle files: 43–96 lines.
- Independent scoped review: APPROVED, no blocking findings; see `quality/session-lifecycle-refactor-review.md`. Not an Exam Staff phase receipt or release approval.
- Not verified: live Spring runtime wiring, database lock contention, HTTP behavior or behavioral regression tests. Compile is not runtime/behavior proof.
