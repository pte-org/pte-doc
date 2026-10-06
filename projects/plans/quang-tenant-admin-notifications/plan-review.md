# Independent plan review

Date: 2026-10-03. Scope: documentation only; no feature tests or production changes.

## Initial review and adjudication

| ID | Severity | Finding | Decision and required correction |
| --- | --- | --- | --- |
| R1 | HIGH | A direct business-to-notification append API can introduce reverse module dependencies. | ACCEPTED: use synchronous originating-transaction events and notification-owned BEFORE_COMMIT listeners; verify module graph. |
| R2 | HIGH | CLOSED sessions cannot resolve unfinished attempts through the existing OPEN-only force-submit path. | ACCEPTED: explicit authorized, audited cohort finalization with reasoned dispositions; no silent exclusion, force-submit, or exclusion of submitted papers. |
| R3 | HIGH | Composite uniqueness with a nullable tenant can duplicate platform-admin inbox items. | ACCEPTED: non-null event/recipient uniqueness or documented platform/tenant partial indexes, with PostgreSQL concurrent null-tenant tests. |
| R4 | MEDIUM | Delivering to every snapshotted host contradicts suppressing accounts deactivated before delivery. | ACCEPTED: retain audience history; specify terminal suppression, count conservation and no automatic backfill after reactivation. |

## Phase review and adjudication

| ID | Severity | Finding | Decision and required correction |
| --- | --- | --- | --- |
| R5 | HIGH | Assignment commands can add manual requirements after an AI-only cohort has been finalized. | ACCEPTED: enforce frozen-mode compatibility under the same session lock; allow supplemental allocations only to fulfil existing manual requirements; test assignment/finalization races. |
| R6 | HIGH | An admin can publish a draft changed after their preview. | ACCEPTED: require the reviewed draft version for first publish; return 409 on mismatch without intents; replay successful publication returns the immutable existing result. |
| R7 | MEDIUM | An upper sequence watermark does not stabilize mutable Unread offset pagination. | ACCEPTED: document live-filter semantics and reset pagination after relevant read changes, or use compatible cursor continuation; verify cross-tab/read-all cases. |

## Final re-review

Verdict: ACCEPT for documented design readiness on 2026-10-03. The independent reviewer re-read the master, spec and actual R1–R7 corrections; no blocking finding remained in the reviewed scope.

Verified corrections cover synchronous transaction-safe listeners, explicit cohort finalization, non-null uniqueness, terminal audience suppression/count conservation, assignment/finalization serialization, reviewed-version publication, and live Unread membership with read revisions. Common-first requirements remain mandatory in all seven phases. User-confirmed rules are separated from proposed engineering mechanisms.

Parent verification checked seven phase structures, required headings, common-first requirements, relative Markdown links and whitespace across the bundle. This is documentation verification, not an implementation quality receipt.

## Validation boundary

All implementation phases, unit/integration/E2E tests, and runtime quality gates remain not started. Documentation review cannot prove notification delivery, PostgreSQL behavior, authorization or browser interaction.
