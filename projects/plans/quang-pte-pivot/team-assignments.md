# Team Assignments: PTE Pivot (2 senior + 2 mid-level, full-stack)

**Date:** 2026-07-16
**Basis:** plan.md's 9 phases, each phase owned wholly by one person. Split by phase complexity/risk, not just phase order: phases with concurrency, cross-cutting architecture, or security decisions go to seniors; phases with well-specified deterministic logic or repetitive-but-mechanical volume go to mid-level devs.

Placeholder names below — swap in real names.

---

## Complexity read on each phase (why the split is what it is)

| Phase | Complexity driver | Level needed |
|---|---|---|
| 1 — Domain Model | Foundational schema decisions block the whole team; mistakes here ripple everywhere | **Senior** |
| 2 — Exam Delivery Timing | Optimistic locking on concurrent timer writes, WebSocket real-time state, auto-timeout transitions | **Senior** |
| 3 — AI Vendor Research | Exploratory/evaluative, steps are well laid out in the plan, low blast radius if imperfect | Mid |
| 4 — Speaking Scoring | First-of-its-kind async poller with row-locking (`SELECT FOR UPDATE SKIP LOCKED`), retry/circuit-breaker, vendor integration — sets the pattern Phase 5 will copy | **Senior** |
| 5 — Writing Scoring | Same shape as Phase 4 but the hard pattern is already proven — largely "follow the recipe" | Mid |
| 6 — Objective Scoring | Deterministic rule-based logic, no concurrency, no vendor, thoroughly spec'd acceptance criteria | Mid |
| 7 — Score Aggregation & Reporting | Ties Phase 4+5+6 together, enforces authorization on report endpoints, cache-invalidation correctness, partial-aggregation edge cases | **Senior** |
| 8 — Frontend (20 task types × 2 platforms) | High *volume*, but each task-type screen reuses a handful of component patterns (audio recorder, MC, drag-reorder, text input) once scaffolded | Mid (high-volume, needs help — see note below) |

---

## Assignment table

| Person | Phase A (first) | Phase B (second) |
|---|---|---|
| **Senior 1** | Phase 1 — Domain Model Redesign | Phase 7 — Score Aggregation & PTE 10–90 Reporting |
| **Senior 2** | Phase 2 — Exam Delivery Timing | Phase 4 — Speaking Response Scoring |
| **Mid 1** | Phase 3 — AI Scoring Research & Architecture | Phase 5 — Writing Response Scoring |
| **Mid 2** | Phase 6 — Objective Task Scoring | Phase 8 — Frontend Implementation |

**Phase 9 — Integration Testing & Documentation:** shared by all 4 at the end.

**Senior 1 bookends the project** — architects the schema everyone depends on (Phase 1), then owns the final integration/authorization-sensitive phase (Phase 7) that ties everyone else's work together.
**Senior 2 owns both concurrency-heavy phases** (Phase 2's timer-locking, Phase 4's poller row-locking) — same mental model (optimistic/pessimistic locking, race-condition reasoning) applies to both.
**Mid 1** starts with research (Phase 3, low-risk if the initial vendor picks aren't perfect — Phase 3's own risk section already plans for re-evaluation), then implements Writing scoring by mirroring the pattern Senior 2 establishes in Phase 4.
**Mid 2** starts with the most self-contained, deterministic phase (Phase 6 — good ramp-up task, hard to get subtly wrong since it's pure rule logic with unit tests), then takes on the frontend.

---

## Dependency-aware sequencing

Only **Phase 1** and **Phase 3** have no upstream dependency.

```
Day 1:   Senior1: Phase 1         Mid1: Phase 3
         Senior2: waiting on Phase 1     Mid2: waiting on Phase 1
```

- **Senior 2**, while waiting: do Phase 2 Step 1 now (pure research — sourcing official Pearson PTE timing values, no schema dependency). Timing-config table is ready the moment Phase 1 lands.
- **Mid 2**, while waiting: scaffold the shared frontend shell (project structure, shared component skeletons: audio-recorder, MC-select, drag-reorder, text-input) that Phase 8 will need regardless of task order — doesn't need Phase 1 to start.

```
After Phase 1 lands:      Senior2 → Phase 2 (research already done)     Mid2 → Phase 6
After Phase 1 + 3:        Senior2 → Phase 4 (after Phase 2)             Mid1 → Phase 5
                                                                          (coordinate with Senior2: Mid1 should see
                                                                           Phase 4's poller pattern before replicating
                                                                           it in Phase 5 — a short pairing session
                                                                           when Senior2 lands the SpeechScoringPoller
                                                                           skeleton saves Mid1 from reinventing it)
After Phase 1 + 2:        Mid2 → Phase 8 (needs Phase 1+2's API contract, not full scoring data — can run in
                                            parallel with Phase 4/5/6/7)
After Phase 4 + 5 + 6:    Senior1 → Phase 7 (last phase to unblock)
```

**Critical path:** Phase 1 → {Phase 2, Phase 4 (Senior 2), Phase 5 (Mid 1), Phase 6 (Mid 2)} → Phase 7 (Senior 1). Senior 1 finishes Phase 1 early and then has the longest wait before Phase 7 can start — use that time productively: reviewing Phase 4/5/6 as they land (Senior 1 designed the schema they all build on, so they're well-placed to review), and pre-designing Phase 7's aggregation config/rubric mapping (Phase 7 Steps 1–2 are research/design, don't need 4/5/6's code to exist yet, only the *shape* of what they'll produce).

**Phase 8 volume risk:** even with reusable components, 20 task types across 2 platforms is large (flagged HIGH in plan.md Risks). Once Mid 1 finishes Phase 5 or Senior 2 finishes Phase 4, whoever frees up first should pull frontend task-type screens off Mid 2's plate rather than going idle — treat Phase 8 as elastic capacity for whoever's done with their own two phases first.

---

## Phase 9 (Integration Testing & Documentation) — shared

- **Senior 1:** regression tests for `examdelivery`/`iam`/`tenancy`, security/authorization audit (Phase 7's report-endpoint checks), final schema-consistency doc pass.
- **Senior 2:** timer/concurrency edge-case tests (race conditions in Phase 2, poller idempotency in Phase 4), operations runbook for the scoring-outage alert/recovery procedure.
- **Mid 1:** Writing + Speaking scoring integration tests (mock vendor + sandbox if available), vendor research report finalization.
- **Mid 2:** full frontend manual QA pass (pte-app + pte-web) across all 20 task types, objective-scoring unit test coverage review.

All 4 converge for the joint end-to-end pass (one full mock exam attempt, every task type) before declaring Phase 9 — and the whole pivot — done.
