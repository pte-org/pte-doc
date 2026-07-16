# Team Assignments: PTE Pivot (4 people, full-stack)

**Date:** 2026-07-16
**Basis:** plan.md's 9 phases, each phase owned wholly by one person (not split into backend/frontend slices). 8 substantive phases ÷ 4 people = 2 phases each; Phase 9 is shared by all four at the end.

Placeholder names below (Dev 1–4) — swap in real names.

---

## Assignment table

| Dev | Phase 1 (first) | Phase 2 (second) |
|---|---|---|
| **Dev 1** | Phase 1 — Domain Model Redesign | Phase 6 — Objective Task Scoring |
| **Dev 2** | Phase 3 — AI Scoring Research & Architecture | Phase 4 — Speaking Response Scoring |
| **Dev 3** | Phase 2 — Exam Delivery Timing | Phase 7 — Score Aggregation & PTE 10–90 Reporting |
| **Dev 4** | Phase 5 — Writing Response Scoring | Phase 8 — Frontend Implementation |

**Phase 9 — Integration Testing & Documentation:** shared by all 4 at the end (see below).

---

## Why this pairing (not just phase-number order)

- **Dev 1 (1 → 6):** whoever designs the `Question`/`Exam` schema (Phase 1) is best placed to implement objective scoring (Phase 6), since it reads directly off the `correct_answer` fields that Phase 1 defines.
- **Dev 2 (3 → 4):** AI vendor research flows directly into building the Speaking scoring pipeline — same person carries the vendor-selection context forward instead of handing off.
- **Dev 3 (2 → 7):** both are "exam attempt lifecycle" concerns (timing state machine, then final score-state aggregation) — same mental model of `ExamAttempt`/`AttemptAnswer`.
- **Dev 4 (5 → 8):** Writing scoring is the lightest of the four AI/domain phases, freeing Dev 4 up soonest to take on Phase 8 (frontend), which is the single largest phase (20 task types × 2 platforms — flagged HIGH complexity in plan.md Risks) and needs the most runway.

---

## Dependency-aware sequencing

Only **Phase 1** and **Phase 3** have no upstream dependency — everything else waits on one or both of them. This means Dev 1 and Dev 2 start immediately; Dev 3 and Dev 4 have a startup gap.

```
Day 1:         Dev1: Phase 1 (domain model)     Dev2: Phase 3 (AI vendor research)
               Dev3: waiting on Phase 1          Dev4: waiting on Phase 1 + Phase 3
```

**Fill the startup gap instead of sitting idle:**
- **Dev 3**, while waiting for Phase 1: start Phase 2's Step 1 now — it's pure research (sourcing official Pearson PTE timing values), no code/schema dependency. Have the timing-config table ready so Phase 2 implementation starts the moment Phase 1 lands.
- **Dev 4**, while waiting for Phase 1 + Phase 3: pair with Dev 2 on the essay-scoring half of Phase 3 research (Phase 3 covers both speech and essay vendor evaluation — splitting it between Dev 2 and Dev 4 speeds it up AND gets Dev 4 the context they'll need later for Phase 5). Alternatively, start scaffolding the shared frontend shell (project structure, task-navigation component, timer-display component) that Phase 8 will need regardless of which task-type screens come first.

```
After Phase 1 lands:   Dev1 → Phase 6     Dev3 → Phase 2 (research already done, starts coding immediately)
After Phase 1 + 3:     Dev2 → Phase 4     Dev4 → Phase 5
After Phase 2 lands:   Dev4 → can start Phase 8 in parallel with Phase 4/5/6 (Phase 8 mainly needs Phase 1+2's API contract, not full scoring data)
After Phase 4+5+6:     Dev3 → Phase 7 (the last phase to unblock — flag if Phase 4 or 5 slips, since Phase 7 can't start without both)
```

**Critical path:** Phase 1 → {Phase 4, Phase 5, Phase 6} → Phase 7. Phase 7 (Dev 3's second phase) is the tightest dependency in the whole plan — it needs three other phases done first, so it's the most likely phase to start late. Dev 3 should expect a longer wait after finishing Phase 2 and use it to help test/review Phase 4/5/6 as they land, rather than sitting idle.

---

## Phase 9 (Integration Testing & Documentation) — shared

Not owned by one person. Split by what each dev already knows best:
- **Dev 1:** regression tests for `examdelivery`/`iam`/`tenancy` + objective-scoring tests; owns final schema-consistency doc pass.
- **Dev 2:** Speaking scoring integration tests (mock vendor + real sandbox if available).
- **Dev 3:** Exam timing tests + score-aggregation tests + security/authorization audit (Phase 7's report-endpoint auth checks).
- **Dev 4:** Writing scoring integration tests + full frontend manual QA pass (pte-app + pte-web) across all 20 task types.

All 4 converge for the joint end-to-end pass (one full mock exam attempt, every task type) before declaring Phase 9 — and the whole pivot — done.
