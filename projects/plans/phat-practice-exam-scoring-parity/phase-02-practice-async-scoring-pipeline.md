# Phase 2: Practice Async Scoring Pipeline

Dependencies: Phase 1. Blocks Phases 3, 4, 5.

## Requirements
After a student answers one question, AI types are queued and scored in the background and the client polls until SCORED or FAILED; objective types return their score in the submit response; a lost or failed job always ends in a terminal state.

## Files
Backend base: `d:\FPT\9thSemester\pte\pte-api\app\src\main\java\com\pte\practice\`.
- Add: Flyway migration V130 (scoring-state columns on the practice session item: status vocabulary, dispatch token, dispatched-at, failure code; reuse existing ai_* result columns) under `app\src\main\resources\db\migration\` (confirm folder with Glob before writing); practice scoring job record; practice scoring config (exchange, queue, DLQ, listener factory modeled on `internal/config/PracticeExplanationRabbitMqConfig.java` and `scoring/internal/config/ScoringRabbitMqConfig.java`); practice scoring dispatcher; practice scoring worker (mirror `scoring/internal/messaging/consumer/AiScoringWorker.java`); DLQ handler; payload canonicalizer covering every renderer; result DTO and poll endpoint.
- Change: `internal/service/PracticeSessionItemService.java` (answer path: canonicalize, objective sync, AI dispatch after commit, idempotent), `internal/domain/PracticeSessionItem.java`, `internal/service/PracticeSessionService.java`, `internal/controller/PracticeSessionController.java`, `internal/mapper/PracticeSessionResponseMapper.java`, `internal/dto/response/PracticeSessionResponse.java`, `internal/constant/PracticeConstants.java`, `internal/service/PracticeAnswerValidationService.java`, `PracticeMediaBindingService.java`, `app\src\main\resources\application.yml` (practice scoring settings).
- Replace: `PracticeSpeechScoringDispatcher` (speech-only, synchronous) and `PracticeSpeechScoringPersistenceService` (its result writer) with the new dispatcher and token-conditional result writer; remove their callers.
- Tests add/update: item service tests (sync objective, AI dispatch, double submit), worker tests (token mismatch, budget, provider error, DLQ), canonicalizer test per renderer, poll endpoint test (stale re-dispatch, max-age FAILED), migration smoke.

## Steps
0. Preconditions (resolve with the user before this phase starts): poll interval, max age and env-variable mapping (plan.md questions 5-7). Flyway applies migrations on every boot and on context-load tests, so "confirm before applying" cannot be enforced per migration: the user takes a local DB backup (or accepts a disposable `pte_postgres_data_localtest` volume) BEFORE the first run of this phase. V130 (additive) and V131 (destructive, Phase 3) stay separate files; never edit V130 after it has run anywhere (checksum failure).
1. Add the migration for scoring state on the practice item and align the domain model.
2. Build the canonicalizer that converts each renderer's stored answer into the exam payload shape and validates audio media ownership and readiness.
3. Rework the answer path: objective types score inline and return the score; AI types mark the item as scoring with a fresh dispatch token and publish after commit; repeated submissions stay idempotent.
4. Add the practice queue, listener factory, worker and DLQ handler mirroring the exam worker (one practice consumer, prefetch 1, no requeue, no container retry, budget check, token check, terminal FAILED on provider error or dead letter).
5. Expose the item result in the answer response and a poll endpoint that returns state plus score.
   - Authorization: `hasRole('STUDENT')`, resolved through `CurrentUserContext`, scoped by session owner and tenant exactly like the existing practice controller. Another user's or tenant's item returns 404 (not 403). The response carries only the caller's own score, sub-scores, feedback and transcript; never reference or correct answers.
   - Recovery: the stale/max-age check (re-dispatch a stale scoring item, FAILED past max age) runs in one shared service method used by the poll, the session read and the review read, so a student who closed the tab never leaves an item stuck in SCORING. Whether a small scheduled sweep is still wanted stays open question 6.
6. Spend control (Azure/Gemini credit is limited):
   - Define the retry/resubmit rules: a FAILED item may be retried through an explicit retry operation (new dispatch token, counts against an attempts-per-item cap); a SCORED item is final for that session item and cannot be re-answered; re-dispatch count is capped (stale re-dispatch at most N times, then FAILED).
   - Add a per-user rate limit on answer/retry for AI types.
   - Stale threshold must exceed the job budget plus expected queue wait, so a slow in-flight job is not re-dispatched while still running.
   - The result write is conditional on the dispatch token (token-conditional update, not only a token check at worker start); on optimistic-lock failure (`@Version`) the worker drops the write, never re-bills.
   - A GET that re-dispatches vendor-billed work is bounded by the caps above.
7. Remove the old synchronous speech dispatcher and persistence service and route all scoring through the facade from Phase 1, with no import of scoring internals.
8. Write the worker, dispatcher, canonicalizer and endpoint tests listed above, including the stale-token-does-not-bill case, the cross-user/cross-tenant poll 404, the re-submit-after-SCORED rejection, the retry cap and the overlap of an in-flight job with a re-dispatch.

## Success Criteria
- Practice module and scoring module tests pass.
- A test proves a stale token or already-terminal item never reaches the vendor scorer.
- A test proves a dead-lettered job leaves the item FAILED, and a poll past maximum age returns FAILED.
- Submitting an objective answer returns a 0-100 score in the same response; submitting an AI answer returns a scoring state immediately.
- Import grep for scoring internals inside practice returns nothing; module-structure test passes.

## Risks
- Broker down at publish leaves the item scoring forever: stale re-dispatch on poll plus maximum-age failure.
- Double billing: token check, budget, idempotent operation id; covered by tests.
- Memory in the 512m container: the practice listener adds consumers on top of the exam's 2. Use exactly 1 practice consumer (prefetch 1) so total audio normalizations stay at 3; Phase 6 verifies under concurrent exam plus practice load.
- Answer keys are read from the live question at scoring time; an unpublish/edit in between changes the key. Noted risk: either snapshot reference/correct answers on the item at answer time (preferred if cheap) or accept and document.
- Migration touches a table the explanation code still reads: keep both compiling until Phase 3, only adding columns here.
- Rollback: migration is additive in this phase; the worker can be disabled by removing the listener configuration while keeping the columns.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- Code review (PASS WITH FINDINGS) found real defects in the first worker design: a redelivered or re-dispatched job could be scored twice (double vendor spend); read-path recovery wrote through entities loaded without a lock; an objective-only SCORED item reported a null score; `PracticeAnswerCanonicalizer.normalize` used an un-precompiled regex.
- Self-inflicted while fixing: the precompiled pattern was first written `"\s+"`, which Java reads as a literal space escape (it would not match tabs or runs of whitespace). Caught on re-reading the file, corrected to `"\s+"`, and a regression test was added.
- Process slip: `git add -N` was used once to build a diff; it was undone immediately with `git reset -q -- app/src`. Nothing was committed.

### Root Cause
- The worker checked the dispatch token but never changed it, so two deliveries of the same job, or a job that started just before a re-dispatch, both passed the check.
- Recovery on session and review reads iterated items from a plain query, so its writes could race the worker or a retry.
- `resultOf` read only the AI score column.

### Resolution
- `PracticeScoringStateService.claim(itemPublicId, jobToken, now)` (REQUIRES_NEW) rotates the token and restarts the re-dispatch window; the worker claims first, then scores, then completes or fails with the claim token. A redelivered or stale job finds a different token and is skipped; a dead-lettered job with a stale token no-ops and the item ends as TIMED_OUT (retryable). `awaiting` is now private.
- `PracticeSessionItemRepository.findScoringForUpdate` (PESSIMISTIC_WRITE, SCORING items only); `PracticeSessionItemService.recoverScoring(session, now)` uses it, which also stops loading every item on each read.
- `resultOf` falls back to the objective score; canonicalizer uses a precompiled `WHITESPACE` pattern.
- Skipped on purpose: tenant id comes from the message payload (needs broker access to forge); the per-user rate limit is not serialized across sessions (overshoot of about 1-2 per minute); retry on a completed session is intended; altitude-level redesigns.
- TDD deviation, stated honestly: for the validation, Phase 1 facade-wiring, request factory, worker, item scoring, session scoring and review recovery tests there was no separate observed red run; tests were written before the implementation and went green on the first run after it (a compile failure was the only implicit red). The claim, locked-recovery, objective-fallback and whitespace tests were written first and one failed after implementation (`claim` returned the mock's null) before being fixed.
- Simplify pass (4 agents) applied the safe fixes: removed superseded evaluation code and dead constructors, one container factory, shared `readSubScores`.

### Test Results After Fix
- `./mvnw -pl app test` on `com.pte.practice.**`, `com.pte.scoring.**` and `ModuleStructureTest`: 767 tests, 0 failures, 0 errors, 16 skipped (counted from fresh surefire reports only).
- Not run: the full application suite, and any live Azure/Gemini call. Flyway V130 has not been applied to the local DB yet (backup exists at `D:\FPT\9thSemester\pte\db-backups\pte-localtest-before-phase2-20261024-084757.dump`).
