# Phase 6 Runbook: Drain in-progress attempts & drop `timer_states`

**Status: NOT YET EXECUTED — ready and reviewed, held pending an actual production deployment.**
Per `plan.md`'s Overview status note, the product has no production traffic and no B2B tenant yet
(confirmed with user, 2026-09-08). This document is the concrete procedure to run **the first time
Phase 5's code is deployed to a real, in-use environment** — it is not something to execute against
today's dev-only stack. Nothing in this file has been run for real; every command below has only
been checked for correctness (query syntax, table/column names against the current schema) — not
executed against production data, because none exists yet.

This runbook implements `phase-06-production-drain-and-db-migration.md`'s Steps 1-6. Read that file
first for the *why*; this file is the *how*.

---

## 0. Standing pre-condition (checklist item, not a gate today)

Before this runbook is ever run against a **B2B** tenant specifically (B2C/home-practice traffic has
no kiosk precondition to check): confirm and record explicit operational/contractual sign-off that
tenant's exam machines are genuinely OS-locked (kiosk mode), per `spec.md`'s NFR. There is no feature
flag to fall back on if this turns out false — this sign-off is the only safety net. Do not let this
get lost between now and whenever the first B2B deal actually happens.

## 1. Schedule the deploy window

Confirm the deploy window falls outside any currently-scheduled B2B proctored exam session. B2B
sessions run on fixed schedules (per `spec.md`), so this is a calendar check against the scheduling
service's session table, not a guess:

```sql
-- Run against the scheduling service's database (com.pte.scheduling.domain.ExamSession,
-- table exam_sessions — verified against the schema as of client-side-exam-timer Phase 6
-- planning, 2026-09-08; re-check if the scheduling schema has since changed).
SELECT public_id, tenant_id, opens_at, closes_at
FROM exam_sessions
WHERE opens_at  <= :deployWindowEnd
  AND closes_at >= :deployWindowStart;
```

If this returns any B2B session, do not deploy in that window — reschedule.

## 2. Pre-deploy drain check

Run against `exam-delivery`'s database:

```sql
SELECT id, public_id, session_public_id, student_public_id, tenant_id, started_at
FROM exam_attempts
WHERE status = 'IN_PROGRESS'
ORDER BY started_at;
```

- **Zero rows**: proceed straight to Step 4 (deploy).
- **A handful of rows, all well outside any B2B session window** (i.e. abandoned/stale B2C attempts —
  the common case for a home-practice product): proceed to Step 3 to force-complete them.
- **Any row whose `tenant_id` matches an active, in-window B2B session**: **STOP.** Do not deploy in
  this window — this is a real candidate actively testing right now (Phase 6 Risk, HIGH). Reschedule
  the whole deploy to a later drain window instead.

## 3. Force-complete remaining IN_PROGRESS attempts

**Do not hand-write a `SQL UPDATE exam_attempts SET status = 'SUBMITTED'` for this.** `AttemptService`'s
own `completeAttempt()` (and `ProctorCommandService.forceSubmit()`, which does the same thing for a
proctor-issued command) atomically writes the `AttemptSubmitted` outbox event in the SAME transaction
as the status change (ADR-002 Transactional Outbox — see `AbstractOutboxWriter`'s own doc comment). A
raw SQL update would leave the attempt looking `SUBMITTED` with **no** `AttemptSubmitted` event ever
published, silently breaking every downstream consumer that reacts to it (at minimum, `scoring`'s
`AnswerIngestConsumer` pipeline, per this refactor's own Phase 5 review — the attempt would never get
scored).

The plan's Step 3 explicitly requires reusing the existing path, no new mechanism. Two options, in
order of preference:

**Option A (preferred) — one attempt at a time, via the existing proctor command flow.** For each
`public_id` from Step 2's query, issue a `FORCE_SUBMIT` proctor command through the normal
`proctor-service` flow (`ProctorCommandService.issueCommand` / the existing STOMP-driven invigilator
UI, or a direct authenticated call to whatever REST entry point fronts `IssueCommandRequest`) with
that attempt's id and its owning tenant. This is zero new code — it is the exact same mechanism a
real invigilator's "Force submit" button already uses, just triggered by an ops engineer instead.
Slower for a large batch, but touches nothing that hasn't already been reviewed and tested.

**Option B (for a larger batch) — a throwaway, one-off `CommandLineRunner`.** If the straggler count
from Step 2 is too large for Option A to be practical, write a temporary Spring Boot
`CommandLineRunner` (gated behind a dedicated profile so it never runs on a normal boot, e.g.
`--spring.profiles.active=drain-once`) that, for each `public_id` from Step 2, calls
`ProctorCommandService.forceSubmit(attemptPublicId, tenantId)` directly in-process. This is still
"the existing mechanism," just invoked from a temporary entry point instead of over the network —
write it, run it once, delete it. Do not merge it into the main branch as permanent code (it has no
purpose once the drain is done, and leaving unused ops tooling around is its own maintenance cost).

Either way: re-run Step 2's query afterward and confirm zero `IN_PROGRESS` rows remain.

## 4. Deploy Phase 5's code

Once Step 2 confirms zero (or explicitly-handled) `IN_PROGRESS` attempts, deploy the `exam-delivery`
build containing Phase 5's changes (no more `TimerState`/`TimerController`/deadline enforcement).

## 5. Backup, then drop `timer_states`

**Only after the deploy is confirmed healthy** (application started, a real `startAttempt`/
`submitAnswer` round-trip verified against the deployed build):

```sql
-- 1. Take a full schema+data backup first (DROP TABLE is irreversible — Phase 6 Risk, MEDIUM).
--    Use whatever this environment's standard backup mechanism is (pg_dump, managed-DB snapshot,
--    etc.) — not specified here since it depends on the actual production infrastructure, which
--    doesn't exist yet.

-- 2. Confirm nothing still references the table before dropping it.
SELECT count(*) FROM timer_states;

-- 3. Drop it.
DROP TABLE timer_states;
```

## 6. Post-deploy verification

```sql
-- Confirms the table is gone.
SELECT to_regclass('public.timer_states');  -- expect NULL

-- Confirms application-level correctness on at least one force-completed attempt from Step 3:
-- status is SUBMITTED, existing answers are untouched.
SELECT a.public_id, a.status, a.submitted_at, count(ans.id) AS answer_count
FROM exam_attempts a
LEFT JOIN attempt_answers ans ON ans.attempt_id = a.id
WHERE a.public_id = :oneOfTheForceCompletedAttemptPublicIds
GROUP BY a.public_id, a.status, a.submitted_at;
```

Expect `status = 'SUBMITTED'`, a non-null `submitted_at`, and `answer_count` unchanged from before the
force-complete (Phase 6 Success Criteria: "every force-completed attempt's student-visible history is
intact").

## 7. Confirm no stopgap logic was introduced

Before closing out this rollout, grep the deployed codebase for anything that special-cased a
`TimerState` row's presence/absence as a compatibility check — the plan (and Phase 5's implementation)
deliberately rejected any such shim. There should be zero hits outside historical doc comments:

```bash
grep -rn "TimerState" --include="*.java" services/exam-delivery/src/main
```
