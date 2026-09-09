# Phase 6: Production migration — drain in-progress attempts and drop timer_states

## Requirements
Phase 5's code deploys only once in-flight attempts relying on the old server-enforced deadline are safely drained, per the spec's already-decided migration approach; the obsolete `timer_states` table is physically removed afterward, since Hibernate's `ddl-auto: update` never drops tables on its own.

## Steps
0. **(plan-reviewer finding, resolved — currently a checklist note, not a blocking gate)** No B2B tenant exists yet at planning time (product is still pre-production/dev-only) — this step does not block Phase 5/6 today. Keep it as a standing checklist item: **the first time this app is sold/deployed to a B2B tenant**, confirm and record explicit operational/contractual sign-off that that tenant's exam machines are genuinely OS-locked (kiosk mode) per `spec.md`'s NFR precondition, before that tenant's traffic runs on this codebase's deadline-free `AttemptService`. There is no feature flag to fall back on if that precondition turns out false for a given tenant, so this sign-off is the only safety net — don't let it get lost between now and whenever the first B2B deal actually happens.
1. Schedule the Phase 5 deploy outside any B2B proctored exam window, per the spec's decided approach (feasible because B2B sessions run on fixed schedules) — not yet applicable while there is no production deployment; apply once this ships to real users.
2. Before deploy, query for attempts still `IN_PROGRESS` and confirm the count is at or near zero for the scheduled window.
3. For any remaining `IN_PROGRESS` attempts, force-complete them through the existing idempotent `completeAttempt()`/submit path — no new mechanism, no compatibility shim keyed on `TimerState` row existence (explicitly rejected by the spec).
4. Deploy Phase 5's code once the drain is confirmed complete.
5. Take a schema/data backup, then run an explicit `DROP TABLE timer_states` migration/script after the deploy is confirmed healthy.
6. Confirm no stopgap "check if a TimerState row still exists" logic was introduced anywhere as part of this rollout.

## Success Criteria
- A pre-deploy query shows zero (or an explicitly accepted, force-completed near-zero) `IN_PROGRESS` attempts at deploy time.
- Post-deploy, a direct DB query confirms `timer_states` no longer exists in the schema, and the application starts/operates normally without it.
- Every force-completed attempt's student-visible history is intact (existing answers preserved, attempt shows as `SUBMITTED`), spot-checked against at least one force-completed record.

## Risks
- HIGH: force-completing a B2B proctored attempt mid-session, if the drain window is misjudged, would cut off a real actively-testing candidate. Mitigate by treating any non-zero in-progress count found outside the scheduled drain window as a stop-the-deploy condition, never forced through.
- MEDIUM: `DROP TABLE` is irreversible — mitigate with a schema/data backup taken immediately before running it.
- LOW: `ddl-auto: update` could attempt to recreate `timer_states` on a later deploy if any leftover `TimerState`-referencing entity/code wasn't fully deleted in Phase 5 — Phase 7's grep sweep is the explicit backstop for this.
