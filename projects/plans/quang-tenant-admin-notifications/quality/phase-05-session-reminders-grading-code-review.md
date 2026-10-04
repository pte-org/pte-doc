# Phase 05 code review

Date: 2026-10-04
Mode: hard
Result: APPROVED_WITH_NOTES

## Reviewed areas

- Session reminder schedule query, row-lock revalidation, stale pending suppression, recipient eligibility, and event-key idempotency.
- Closed-session grading cohort preview/finalize, immutable membership, outstanding-attempt dispositions, pinned-item coverage, objective/manual/AI-only predicates, and completion transition.
- Scoring progress wake-up plus periodic reconciliation and the BEFORE_COMMIT notification listener.
- Host-only routes, tenant scoping, shared `ApiResponse`/`DomainException`, parameterized SQL, additive migration, configuration defaults, and module dependency direction.

## Review result

- No BLOCKER or HIGH finding introduced by Phase 05.
- Host operations are guarded by `HOST_ADMIN` and revalidated against the caller tenant.
- Submitted attempts are included by construction; only non-submitted attempts may carry an audited cohort-only exclusion, without changing attempt status.
- Manual completion checks assignment coverage and submitted examiner scores per pinned subjective item; assignment presence alone is not treated as completion.
- AI-only completion requires a publishable REAL AI score; objective items require a valid scored result; UNSCORED is explicit.
- Session and cohort locks, database uniqueness, immutable cohort status, inbox event keys, and BEFORE_COMMIT listeners provide replay/concurrency protection within the implemented boundary.
- New display/error text is centralized in module constants; unexpected diagnostic detail is not added to the public response contract.

## Non-blocking notes

- PostgreSQL migration and lock/barrier behavior still need live database evidence; Docker Desktop was unavailable in this run.
- Browser/HTTP authorization and host UI wiring are not release evidence for this backend phase and remain in the planned validation phases.
- Scheduled reconciliation and session scoring reads are intentionally bounded by the current service contract but have not been benchmarked at the stated 40-paper/host-scale targets.
- The migration is additive and forward-only; rollback means disabling the new workers and retaining the cohort/history tables until an explicit retention policy exists.
- The evaluator prepared-test byte hash was reconciled after extracting a supplemental assertion; the assertion-preservation note is recorded in the TDD artifact and test report.
