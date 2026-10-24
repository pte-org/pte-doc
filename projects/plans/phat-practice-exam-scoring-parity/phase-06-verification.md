# Phase 6: Verification

Dependencies: Phases 1-5.

## Requirements
The whole change is proven by automated tests, a module-boundary check, a cost-approved live scoring run and a manual UI walkthrough by the user.

## Files
No new production files. Reads and runs against:
- Backend: `d:\FPT\9thSemester\pte\pte-api` (full test suite, `app\src\test\java\com\pte\ModuleStructureTest.java`).
- Compose: 3-file compose plus the user's env file (never read the env file; the user runs or approves it). Docker arm64 only, no host-run fallback.
- Frontends: `d:\FPT\9thSemester\pte\pte-practice`, `d:\FPT\9thSemester\pte\pte-web`.
- Update after run: the Execution Log sections of phases 1-5 and the status table in `plan.md`.

## Steps
1. Run the complete backend test suite and the module-structure check; record counts and any failures.
2. Search practice code for scoring-internal imports and for removed class names, rubric and explanation settings; confirm none remain.
3. Run web type check, lint and build for pte-practice and pte-web.
4. Report an Azure/Gemini cost estimate (number of calls, audio minutes, dollars) and wait for the user's approval before any real vendor call.
5. After approval, run the stack through compose and submit one answer per route (speech, text, objective) and a duplicate submit; confirm one vendor call each, correct states, a forced DLQ failure ends FAILED, a SCORED item cannot be re-answered, and container memory stays within the 512m limit while an exam audio scoring and a practice audio scoring run concurrently.
6. Give the user a short manual UI checklist (all 23 types open, prompt media plays, polling to score, failure retry, review page) and record their result.
7. Update execution logs and plan status, and list leftover unresolved questions.

## Success Criteria
- Backend suite is green with zero new failures versus the pre-change baseline; module-structure test passes.
- Greps for scoring-internal imports in practice, removed class names and PRACTICE_AI settings return nothing.
- Web type check, lint and builds pass.
- Live run (only after approval): each route reaches SCORED with a 0-100 score, a duplicate submit does not bill twice, a dead-lettered job reaches FAILED, no container restart or out-of-memory event.
- User confirms the manual UI checklist.

## Risks
- Live run costs credit: gated by an approved estimate; use the smallest audio samples.
- No Windows or host fallback: failures must be reproduced through compose.
- Flaky local broker state: purge practice queues before the run.
- Rollback: if verification fails, fix forward within the owning phase; the destructive migration cannot be undone without restoring local data. The backup is taken BEFORE the first run of Phase 2/3 (see Phase 2 step 0), not here, because Flyway applies migrations on boot and in context-load tests.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- api-client test `dashboard/contract.test.ts` fails: 4 overview records (StudentAttemptHistoryResponse, StudentDetailResponse, StudentPerformanceResponse, StudentSkillPerformanceResponse) not covered by fixtures.

### Root Cause
- Pre-existing: those records were committed 2026-10-18 and this plan does not touch the overview module. Not re-run against a clean baseline.

### Resolution
- Left as is, out of scope. Concurrent exam+practice memory check dropped by the user (risk stays unverified).

### Live run (step 5, 2026-10-24, local compose)
- Routes: MCS-R objective 100/100 (attempts 0); SWT 100 via GEMINI (attempts 1, sub-scores + feedback); Read Aloud 85 via AZURE_SPEECH (attempts 1, 5 sub-scores + transcript). Provider calls: AZURE_SPEECH 1, GEMINI 2 (two SWT sessions), objective 1; cost inside the approved limit.
- Duplicate submit / F5 right after submit: one `POST /answer`, `scoring_attempts` stays 1, no second vendor call. After F5 the completed session shows the finish screen without the score; the score is only visible on the review page.
- Failure path: wrong Gemini key gives `PROVIDER_REJECTED` (not retryable): no retry button, "cannot be re-scored" text. Gemini timeout 1 ms (temporary override, restored) gives `BUDGET_EXCEEDED`/`PROVIDER_UNAVAILABLE` (retryable): "Chấm lại" shown, two retries run (`scoring_attempts` 3), then the button disappears.
- A SCORED item is final per `PracticeScoringStateService`; restarting from the catalog creates a new session and item (each one scored and billed separately). A third retry through the API and a literal DLQ dead-letter were not exercised live (unit tests only).
- Local-only findings fixed or noted: `PRACTICE_STRICT_ENTITLEMENT_ENABLED=true` is now in `docker-compose.local-test.yml` (403 PRACTICE_NOT_ENTITLED otherwise); per-task start idempotency key (409 when the key was reused across tasks); duplicated passage text in read-aloud/SWT/blank/highlight views; stale score from the previous task shown in the next session. All three UI fixes are in `PracticeSessionView.tsx`.

### Test Results After Fix
- Backend 2735 tests, 0 failures, 77 skipped. pte-practice typecheck, 59 tests, lint, build green (build re-run after the live-run fixes; first attempt hit Next 16.4.0's intermittent SecurityFatalError, retry passed). vendor-web lint 0 errors, build green. api-client 686 pass, 1 pre-existing fail.

### Leftovers (not done)
- Step 6 is only partly done: the user opened MCS-R, SWT and Read Aloud live (and the failure screens); the other 19 visible types, prompt media playback and the review page were not walked through.
- Concurrent exam+practice memory check dropped by the user (unverified).
- Question rotation (open question 3) out of scope.
- Next 16.4.0 reports a security advisory at build; whether to upgrade is the user's decision (not run).
- api-client `dashboard/contract.test.ts` failure is pre-existing.
- Review page makes N requests (one per answered item) and shows raw saved-payload JSON; its "Practice review" button label is English.
- Missing confidence level replaces the whole page with an error (pre-existing); an inline reminder was offered, not built.
- Practice sign-in can sit on "Đang xác minh…" after redirect (minor, not diagnosed).
- `ai_score_status` is UNVALIDATED for every scored item (nothing validates it yet).
- No limit on how many new sessions a student can start per day; each costs a vendor call.
