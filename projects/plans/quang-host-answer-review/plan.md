# Plan: Host-Facing Raw Answer Review

Status: ✅ Completed
Date: 2026-09-08
Mode: Hard
Test: Default (no --tdd)
Created by: Plan Agent

## Overview

This plan delivers read-only answer review endpoints in the scoring service, enabling HOST_ADMIN and HOST_AUTHOR roles to inspect what a student actually answered (option selection, essay text, audio recording) alongside the AI-assigned score — and to record their own independent score for later AI-vs-teacher comparison statistics. Confirmed via direct codebase scan (2026-09-08, during e2e seed testing of the MC_LISTENING_SINGLE gap): no viewing capability exists anywhere today — exam-delivery's `AttemptController` is entirely `@PreAuthorize("hasRole('STUDENT')")`, reporting's `ReportController` returns only score summaries, and scoring's existing `ScoringReviewController` only had `POST /answers/{id}/review` (approve).

**Design pivot (2026-09-08, user decision):** the existing "host must approve an AI score before it counts" gate (`AI_SCORED_PENDING_REVIEW` status + `ScoringReviewService.approve()`) is being **removed**, not reused. User explicitly does not want an approval workflow. Instead: AI score always finalizes on its own (every task type behaves like `READ_ALOUD` does today — straight to `SCORED`, no human gate), and a host can independently submit their own score into a new, separate `teacherScore` column at any time, purely as parallel data for a future AI-vs-teacher comparison report. Which score (AI's or teacher's) counts as "official" for student-facing reports is explicitly **not decided yet** — out of scope for this plan, to be resolved later if/when the comparison feature is built.

## Phases

- [x] Phase 1: Media Client Integration [quality: approved, 1 LOW noted; testing: passed 2/2] — Add read-only MediaClient to scoring service with presign-GET capability for audio/image answers, mirroring exam-delivery's proven pattern.
- [x] Phase 2: Response DTOs and Payload Decoding [quality: approved, 1 LOW fixed; testing: skipped by user] — Implement task-type-aware answer payload decoders and response DTOs to make answer content human-readable (option text, essay body, audio URLs).
- [x] Phase 3: List Endpoint [quality: approved, 1 LOW fixed; testing: skipped by user] — Build tenant-scoped, filterable, paginated `GET /answers` endpoint with session and status filters for host review workflows.
- [x] Phase 4: Detail Endpoint and RBAC Enforcement [quality: approved, 0 findings; testing: skipped by user] — Implement `GET /answers/{answerPublicId}` with full playback URLs and enforce HOST_ADMIN/HOST_AUTHOR authorization + tenant isolation.
- [x] Phase 5: Remove Approve Gate, Add Independent Teacher Score [quality: approved, 0 findings; testing: skipped by user] — Delete the `AI_SCORED_PENDING_REVIEW`/approve workflow (WRITE_ESSAY finalizes like every other type); add a new `teacherScore` column + ungated `POST /answers/{id}/teacher-score` endpoint, stored independently of `rawScore` for future comparison stats.

**Plan status: COMPLETED — all 5 phases done.**

## Research Summary

Two parallel researchers investigated which service should own this feature (Primary: scoring; Alternative: exam-delivery, since it holds the true source-of-truth `attempt_answers.payload`). Adjudicated decision: **scoring owns it.** Deciding factor — the approve action already lives in scoring keyed by `ScoringAnswer.answerPublicId`; splitting "view" into a different service would force the host client to cross-service-join two data models for one review screen. The Alternative's staleness concern (scoring's `ScoringAnswer` is an event-sourced projection, not the source of truth) is not a new risk introduced by this feature — scoring already fully depends on that same outbox event to grade at all, so review inherits an already-accepted trust boundary, not a new one.

Investigation of the existing codebase (exam-delivery's AnswerSubmitted event flow, scoring's ScoringAnswer projection, reporting's tenant-scoping pattern, and media handling in SnapshotPinService) confirms that:

1. **ScoringAnswer already holds all required answer data** (payload, optionsJson, correctAnswerText, taskType, status, rawScore, sessionPublicId, tenantId, expired) — it is a read-optimized projection built transactionally from exam-delivery's AnswerSubmitted event via the transactional outbox (ADR-002). Using it for host review introduces no new staleness risk and avoids cross-service data model joins.

2. **Tenant scoping pattern exists in reporting** (ReportService.canView and CurrentUserContext) — the same pattern should be reused in ScoringReviewService to ensure a host cannot enumerate or fetch another tenant's answers by UUID guessing.

3. **Media presigning is proven in exam-delivery** — SnapshotPinService.resolveAudioUrl (line ~185) and MediaClient.java show the exact TTL and presign-GET pattern needed. Scoring service currently has no MediaClient; the feature adds a thin, read-only wrapper using the same logic.

4. **Answer payload structure is documented** — SubmitAnswerRequest (exam-delivery, lines 8-36) documents the taskType→payload encoding convention: decimal index for MC, comma-joined indices for multi-select/reorder, positional comma-join (with empty entries) for fill-blanks, raw text for essay/free-text.

5. **Pagination patterns exist** — InternalExportController uses keyset pagination; this feature will evaluate whether to reuse it for consistency or use simpler offset-page for a host-facing list.

**Chosen Approach:** Extend ScoringReviewController in scoring service only, using the existing ScoringAnswer projection and tenant-scoping pattern from reporting, with a new MediaClient modeled on exam-delivery's proven presign logic. This avoids cross-service joins, respects the existing trust boundary (ScoringAnswer + outbox), and scales to large answer sets via pagination.

6. **Current approve mechanism, for context (being removed in Phase 5)** — Today only `WRITE_ESSAY` is a "review-required" task type (`AiScoringWorker.REVIEW_REQUIRED_TASK_TYPES`); its AI score lands in `AI_SCORED_PENDING_REVIEW` and stays non-final until `ScoringReviewService.approve()` copies `rawScore` verbatim into `SCORED` (the host cannot currently enter a different number at all — "approve" is a rubber stamp, not real grading). Every other task type (MC via `ObjectiveScoringService`, `READ_ALOUD` via AI speech scoring) already finalizes straight to `SCORED` with zero host involvement. Phase 5 makes `WRITE_ESSAY` behave like those — always straight to `SCORED` — and adds `teacherScore` as an independent, non-blocking column any host can fill in whenever, for any task type.

## Dependencies

- Exam-delivery's AnswerSubmitted event must continue flowing to scoring's outbox (existing, not blocked).
- Authoring service must continue populating optionsJson in AnswerSubmitted event (existing, assumed functional).
- Media service (or storage backend presigned by MediaClient) must support GET presign requests (existing, used by exam-delivery).
- No new external service or data store required.

## Risks

- **HIGH: Payload decode bugs silently corrupt answer display** — Different task types have fragile encoding (e.g., fill-blanks with positional empty entries). Misalignment between what exam-delivery encodes and what scoring decodes will cause hosts to see garbled answers. Mitigation: Unit test every task-type decoder against fixtures from exam-delivery's test data; add property-based tests to verify symmetry between encoding and decoding.

- **HIGH: Tenant leak through UUID enumeration** — ScoringAnswer.answerPublicId is a UUID. If service layer does not enforce tenantId check before returning, a malicious host can iterate UUIDs from other tenants' answers. Mitigation: Never fetch ScoringAnswer by answerPublicId alone; always join on tenantId derived from CurrentUser. Add integration test that explicitly attempts cross-tenant fetch and verifies 403/404.

- **MEDIUM: Media presign TTL too short or URL expires mid-playback** — Audio answers are presigned URLs with TTL. If TTL is too short, host clicks audio player and gets a stale link; if too long, security exposure. Mitigation: Reuse exam-delivery's TTL value (already vetted); document TTL in API response so client can refresh.

- **MEDIUM: ScoringAnswer projection lag on high-volume days** — If exam-delivery's outbox processing stalls, hosts see stale or missing answers. Mitigation: this phase adds no new risk beyond what scoring already accepts for grading; document in the endpoint's eventual-consistency note.

- **LOW: optionsJson format unknown until verified against live data** — optionsJson might not be populated, or structure might differ from assumption. Mitigation: confirm shape and populate test fixtures early in Phase 2. If optionsJson is missing, detail endpoint will omit option text (fallback to option indices only) gracefully.

- **MEDIUM: Removing the approve gate changes WRITE_ESSAY's completion timing** — Today, an attempt containing a Write Essay task cannot show as fully scored until a host approves it; `AttemptCompletionService.checkAndEmitIfComplete` is only called from `approve()` for that type. After Phase 5, it finalizes automatically like every other type — attempts will complete faster (no host action required), which is the intended effect of removing the gate, but any downstream consumer that assumed "Write Essay always waits for a host" must be re-checked (searched: only `ScoringReviewService` and `AiScoringWorker` reference `AI_SCORED_PENDING_REVIEW`/`REVIEW_REQUIRED_TASK_TYPES` today — no other service depends on this delay).

- **LOW: Removing a live endpoint (`POST /answers/{id}/review`) is a breaking API change** — Confirm nothing outside this codebase (pte-app, external integrations) calls it before deleting; if anything does, it must be updated in the same phase, not left calling a 404.

## Cook Order Recommendation

Phases 1-2 are foundational (media client + decoders) and can be cooked in either order but both must land before Phase 3/4. Phase 5 is conditional — decide during that phase whether it's needed at all.

```
/ck:cook --hard pte-doc/projects/plans/quang-host-answer-review/phase-01-media-client.md
/ck:cook --hard pte-doc/projects/plans/quang-host-answer-review/phase-02-response-dtos.md
/ck:cook --hard pte-doc/projects/plans/quang-host-answer-review/phase-03-list-endpoint.md
/ck:cook --hard pte-doc/projects/plans/quang-host-answer-review/phase-04-detail-endpoint.md
/ck:cook --hard pte-doc/projects/plans/quang-host-answer-review/phase-05-approve-enrichment.md
```
