# Plan: Practice Exam-Scoring Parity
Status: 🟡 In Progress
Date: 2026-10-23
Mode: Hard

## Overview
Make pte-practice score every answer through the same scoring module the exam app uses (AI speech, AI text and objective scorers for all 23 task types), one question at a time, and drop the rubric-based practice grading and the AI explanation feature entirely. Scoring is asynchronous with polling for AI types; objective types return their score in the submit response.

Base paths: backend `d:\FPT\9thSemester\pte\pte-api\app\src\main\java\com\pte\` (written as `api:`), practice frontend `d:\FPT\9thSemester\pte\pte-practice` (`web-practice:`), admin frontend `d:\FPT\9thSemester\pte\pte-web` (`web:`).

## Phases
| # | Phase | Status | Depends on |
|---|-------|--------|-----------|
| 1 | [Scoring facade for all task types](phase-01-scoring-facade-all-task-types.md) | [x] Complete (awaiting review gate) | none |
| 2 | [Practice async scoring pipeline](phase-02-practice-async-scoring-pipeline.md) | [x] Complete (awaiting review gate) | 1 |
| 3 | [Remove rubric and explanation](phase-03-remove-rubric-and-explanation.md) | [x] Complete (awaiting review gate) | 2 |
| 4 | [Catalog and content readiness](phase-04-catalog-and-content-readiness.md) | [x] Complete (awaiting review gate) | 2 (3 recommended first) |
| 5 | [pte-practice renderers and score view](phase-05-practice-web-renderers-and-score-view.md) | [x] Complete (awaiting review gate) | 2, 3, 4 |
| 6 | [Verification](phase-06-verification.md) | [~] Steps 1-5 done; step 6 (full UI walkthrough) partial, see phase file | 1-5 |

- [x] Phase 1: Scoring facade — one public entry in the scoring module that scores any of the 23 types with a public failure enum
- [x] Phase 2: Async pipeline — practice-owned migration, queue, worker, DLQ, dispatch token, polling endpoint, sync objective path
- [x] Phase 3: Removal — delete rubric module, explanation feature, vendor-web practice-rubrics, config and env leftovers
- [x] Phase 4: Catalog — 22 visible types runnable when content exists, Write Email and Personal Introduction hidden, presigned prompt media, content readiness
- [x] Phase 5: Frontend — renderers for all types, scoring/poll/score view, explanation UI removed
- [ ] Phase 6: Verification — full test run, module-boundary check, cost-gated live check, manual UI hand-off

## Key Decisions
- Parity target is the exam path: same scorer beans (Azure and Gemini AI scorers plus the objective scoring service), same 0-100 score scale, same fallback marking. Practice does not persist exam entities; it keeps its own result snapshot on the practice session item.
- Rubric grading is dropped entirely (module, admin UI, binding, columns). Explanation feature is dropped entirely, including its queue, worker, outbox and generator.
- AI types are async plus polling, with a practice-owned queue and worker mirroring the exam worker: dispatch token, AI job budget, DLQ leading to terminal FAILED, no container retry, retry only per HTTP call in the vendor guard. Objective types score synchronously inside the answer call.
- Practice talks to scoring only through public facades (scoring facade, media facade, practice-question facade). No import of scoring internals.
- 23 task types = exam runtime profiles: 1 UNSCORED (Personal Introduction), 7 AI speech, 3 AI text (SWT, Write Essay, SST), 12 objective. Write Email is not an exam type and is removed.
- Prompt audio and image are presigned by the backend into the task content, because students cannot resolve prompt refs themselves.
- The review endpoint survives and moves out of the explanation controller.
- No production data exists (as of 2026-10-08), so the destructive migration (next number after V129, i.e. V130) is acceptable, but any real DB write still needs user confirmation.
- No commit steps anywhere; the user commits manually.
- User decisions (2026-10-23): Personal Introduction is HIDDEN from practice (22 visible/runnable types; the facade still classifies it as unscored). A SCORED item is final; only FAILED items can be retried, max 2 retries per item, plus a per-user rate limit. Seed/content script is deferred (user publishes PRACTICE-pool questions via vendor-web). Cook with `--hard --tdd`.

## Research Summary
Codebase-verified (no external research). Findings that shaped the plan:
- Exam AI flow: dispatcher marks the answer with a fresh token and sends after commit; worker checks token, spends job budget, writes the result; provider errors go to a failed state; DLQ handler writes an internal-error terminal state; two consumers, prefetch 1, no requeue. If the broker is down at send time the row stays "scoring" and only a later request re-sends it once stale.
- Current practice speech adapter in the scoring module is synchronous, speech-only, has no persistence and swallows every error into an empty result; it is the piece to replace.
- The scorer request carries payload, prompt text, reference answer, correct answer, image ref, word limits and tenant; the result carries 0-100 score, sub-scores, feedback, transcript, detail and a fallback flag.
- Exam payload shapes: audio = media id string, text = raw text, objective = comma-separated. Practice stores per-renderer JSON, so a canonicalizer from every renderer to the exam shape is required.
- The session response exposes only the first pending item, so an answered item's score needs its own response field and poll endpoint.
- The review endpoint lives inside the explanation controller; deleting it blindly breaks review.
- The module-structure test lists the rubric module; it must change with the deletion.
- Question selection always returns the first published question (no rotation), and no PRACTICE-pool seed exists for a fresh local DB.
- Unrelated "rubric" wording in scoring scorers and examiner UI must be preserved.

## Dependencies
- RabbitMQ and the existing scoring vendor configuration (Azure Speech, Gemini) for live checks; keys stay in the user's local env file and are never read by this plan.
- Docker arm64 deployment (512m app container): no host-run fallback.
- `docker-compose.services.yml` has uncommitted user edits; Phase 3 config cleanup must edit around them, not overwrite.
- Separate git repo for pte-practice (Next.js 16): read the bundled Next docs before frontend work, per its AGENTS.md.

## Risks
- HIGH: Double billing of Azure/Gemini on redelivery, stale re-dispatch or double submit — dispatch token plus job budget plus idempotent answer operation; test that a stale token never calls the vendor.
- HIGH: Modulith leak (practice importing scoring internals, or scoring depending back on practice) — only public facades with public DTO/enums; module-structure test and an import grep in Phase 6.
- HIGH: Destructive migration drops tables and columns while code still references them — sequence code removal before or with the migration inside Phase 3; build green between phases.
- MEDIUM: Polling forever (lost message, DLQ not terminal, broker down at publish) — stale re-dispatch on poll, terminal FAILED after a max age, client poll timeout with retry affordance.
- MEDIUM: 512m container memory with two audio-scoring consumers — keep consumers at the exam values, one practice worker pool, size check during live verification.
- MEDIUM: Drift from the exam worker over time — mirror its structure, document the pairing in code comments, add a parity test over all 23 types.
- MEDIUM: Prompt media unreachable for students for 14 renderers — backend presign in Phase 4, checked manually in Phase 6.
- HIGH (red-team): AI spend control — attempts-per-item cap, per-user rate limit, SCORED items final, capped stale re-dispatch with threshold above job budget, token-conditional result write (Phase 2 step 6).
- HIGH (red-team): Poll authorization and answer-key leakage — STUDENT role, owner+tenant scoped, 404 for others; presign only an allowlist of prompt-media fields, test that reference/correct answers never reach students (Phase 2 step 5, Phase 4 step 3).
- HIGH (red-team): Flyway applies on boot, so backup must precede the first run of Phase 2 (Phase 2 step 0); V130 and V131 stay separate.
- MEDIUM (red-team): practice worker uses exactly 1 consumer; Phase 6 checks memory under concurrent exam+practice scoring.
- NOTED: answer keys read live at scoring time (can change mid-scoring); orphan old queues/WRITE_EMAIL sessions; frontend broken between Phases 2-5; seed script and question rotation deferred unless confirmed.
- LOW: Unrelated "rubric" strings removed by an over-eager search — delete by module/file lists only; grep review in Phase 3.
- LOW: i18n keys left orphaned in vendor-web — cleaned in Phase 3.

## Unresolved questions
1. RESOLVED: Personal Introduction hidden from practice.
2. RESOLVED: no seed script in this plan; content published by the user via vendor-web.
3. Question rotation: deferred (serves the first published question); out of scope unless confirmed.
4. RESOLVED (2026-10-24): no fallback notice in the UI. Only Describe Image sets the flag (scored against the reference text when the image is missing), and the user treats the reference text as a trusted source. The score is shown like any other.
5. RESOLVED (2026-10-24): poll 2 s with backoff up to 5 s; client gives up after 120 s with a retry affordance; server turns a stuck SCORING item FAILED after 180 s (must stay above the 90 s job budget).
6. RESOLVED: no scheduled sweeper; stale re-dispatch / max-age FAILED runs on poll, session read and review read.
7. RESOLVED: delete the old rubric/explanation env variables; add new ones for the practice worker (queue, per-user rate limit, retry cap 2) and update the compose files.
8. RESOLVED: keep the existing review URL and response; only move the code out of the explanation controller.
9. RESOLVED: remove only the practice-rubrics keys; do not audit shared keys.
10. RESOLVED (2026-10-24): user approved the estimate: about 1 Azure call (~30 s audio, ~$0.01) and 1 Gemini call (<$0.001), worst case +1 Azure call if dedup fails, under $0.05 total. The concurrent exam+practice memory check was dropped by the user, so that risk stays unverified.

## Session Notes
- Phase 1 done 2026-10-23, `--hard --tdd`. Stopped at the review gate: user must approve before Phase 2.
- Added to `com.pte.scoring`: `PracticeScoringRequest/Route/Failure/Exception`, `PracticeAiEvaluation.feedback`, `ScoringService.scorePracticeAnswer` and `practiceScoringRoute`. Practice has no new `scoring.internal` imports.
- Scoring suite 646 tests, 0 fail, 16 skip. Nothing committed.
- Phase 2 code done 2026-10-24, `--hard --tdd`. Practice-owned RabbitMQ worker with claim-by-token-rotation, locked read-path recovery, polling and retry endpoints, inline objective scoring. Practice + scoring suites and `ModuleStructureTest`: 767 tests, 0 fail, 16 skip. Nothing committed. Flyway V130 is not applied to the local DB yet (backup taken first); no live Azure/Gemini run. Review gate: user approves before Phase 3 (V131 is destructive, take a fresh backup first).
- (Done) Before Phase 2: resolve open questions (poll interval and client timeout, max age before FAILED, sweeper or not, `PRACTICE_AI_*` env mapping, review endpoint path, i18n scope) and back up the local DB (Flyway V130 runs on first boot).
- Phase 5 done 2026-10-24, `--hard --tdd`, pte-practice only. 22 task renderers, canonical answer payloads, scoring poll (2 s backoff to 5 s, gives up after 120 s), ScoreView with retry, review page scores per answered item. Typecheck clean, 59 vitest tests, lint 0 errors (6 pre-existing warnings), build passes. Nothing committed. Review gate: user approves before Phase 6.
- Phase 6 steps 1-4 done 2026-10-24: backend 2735 tests, 0 fail, 77 skip (ModuleStructureTest included); no scoring-internal imports in practice, no removed class names or PRACTICE_AI_ settings; pte-practice and vendor-web green; api-client has 1 pre-existing failure (dashboard/contract.test.ts, 4 unmapped overview Student* records, committed 2026-10-18, not touched by this plan). Live run waits for the user to rebuild and start the stack.
- Phase 6 live run done 2026-10-24: three routes scored (objective, Gemini, Azure), duplicate submit/F5 billed once, failure path checked (non-retryable and retryable, retries capped at 2). Details and leftovers are in the phase 6 file. Nothing committed.
