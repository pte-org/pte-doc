# Hard plan review — staff workspace overview

Date: 2026-10-12 (Asia/Saigon). Read-only plan review; no product edits or execution checks.

## Verdict

READY WITH CLARIFICATIONS. No confirmed BLOCKER/HIGH security or product contradiction after applying the user-validated decisions and the master plan's precedence over research alternatives. Resolve PR01–PR02 in the plan before implementation so the client and server do not make incompatible contract/time choices.

## Findings

### PR01 — MEDIUM: Proctor list response context is still an implementation alternative

Phase01's contract says list timezone/asOf may use “additive page context or a companion list metadata field” and “if chosen”. Phase03 requires validated response timezone to render the active list. The existing `AssignedProctorSessionResponse` contains no timezone/asOf, and an ALL/ACCESSIBLE/UPCOMING list currently does not require a timezone. An implementer can satisfy the optional Phase01 wording while leaving Phase03 dependent on unavailable overview data. This also conflicts with independent list/overview error handling if list rendering gets its timezone from a failed overview.

Action: freeze one backward-compatible response shape now, or explicitly state that list display uses the client-resolved zone and list predicates use server Clock, without depending on overview success. If context is selected, specify its exact field name/type and which scopes accept/require timezone; retain existing `data/meta`. Treat overview/list `asOf` as independent observations, as already agreed.

### PR02 — MEDIUM: Date rollover and timezone re-evaluation are not scheduled in phase steps

The spec requires next local midnight (not +24 hours) and re-evaluation of timezone on focus. Phase02 only schedules focus/manual refetch and finite staleTime; staleTime does not trigger a request when it expires. Phase03 has no date-boundary step. A page left active across midnight can continue showing yesterday's TODAY count/list; a focus refetch can also reuse the earlier resolved timezone unless resolution explicitly runs again before selecting the query key.

Action: add a single reschedulable date-boundary invalidation based on response `dayEnd` and server `asOf`, with local-time clock drift handling, invalidating overview and active TODAY list together. Re-resolve browser timezone on focus/visibility return before refetch/key selection; clear old timer on zone/identity change and unmount. This is a boundary refresh, not continuous polling. If a boundary timer is intentionally deferred, remove that promise from the spec and explicitly document that TODAY updates only on focus/manual refresh.

## Confirmed plan safeguards

- Principal-derived tenant/actor, role guard, active Examiner check and exact assignment scope are explicit; no foreign-owner parameter is accepted.
- Browser IANA timezone is validated; TODAY uses opensAt in half-open local-day bounds, excludes yesterday's start even for ongoing work, and does not synthesize OPEN.
- Exactly three cards per role; Examiner completion remains own unpublished queue scope. Research's four-card/fixed-zone suggestions are superseded, not implementation choices.
- Server-side aggregates/limited priority, stable DB ordering and actor-scoped cache prefixes are specified. Readiness is separate from saved progress and AI availability.
- Queue count semantics must remain consistent across SELECT/filter/count/overview. Ownership/deletion assumptions require source verification; anomalies are not silently repaired in this read-only feature.
- No rollout, writes, receipt changes, new routes, speculative indexes, tests or quality runs are scheduled. Compile/typecheck cannot prove SQL/runtime/security behavior; limitations are explicit.

## Review scope and limits

Read spec, master plan, all four phase plans and both research notes; checked existing Examiner queue/detail source and Proctor row contract to validate the contract/readiness concerns. No production data inspection, runtime queries, benchmarks or tests. Findings describe plan clarity, not defects reproduced in an implementation.
