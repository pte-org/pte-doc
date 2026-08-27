# Plan: Writing Tasks API Support

Status: ⏳ In progress — design approved (2026-08-25), awaiting implementation
Date: 2026-08-25
Mode: Soft (small, well-scoped, additive — no architectural decisions)

## Overview

Enable the existing Flutter writing task screens (`SummarizeWrittenTextScreen`, `WriteEssayV2Screen`) to be exercised end-to-end against the API. Today the writing task types are partially wired:

- `TaskView` already carries `promptText`, `minWordCount`, `maxWordCount` ✓
- `SubmitAnswerRequest.payload` accepts text for `WRITE_ESSAY` and `SUMMARIZE_WRITTEN_TEXT` ✓
- `task-skill-mapping.json` has both writing types ✓

…but two blockers prevent the flow from running:

1. `TimerService` fails fast on `SUMMARIZE_WRITTEN_TEXT` because the task is missing from `task-timing.json`.
2. No sample `Question` rows exist for either writing type, so authoring blueprints cannot include them, so `/next-task` cannot return one.

This plan fixes only those blockers. Scoring pipeline (Phase 5 of `quang-pte-pivot`), human review, and Flutter UI changes are out of scope — confirmed with user before drafting this plan.

## Related UI (already shipped in `pte-app`)

These Flutter screens were built by the user prior to this plan; this plan adds the API support they need to render against a real backend. No UI changes are made here, but the IT and smoke checks must verify each UI's `TaskView` consumption path:

| UI file (pte-app) | Reads from `TaskView` | Persists via |
|---|---|---|
| `lib/features/exam_attempt/speaking_writing/presentation/pages/summarize_written_text_screen.dart` (wrapper, 23 lines) → `widgets/summarize_written_text_body.dart` (logic) | `promptText` (with dev-fixture fallback `kSummarizeWrittenTextPassage`), `minWordCount` (fallback `kSummarizeWrittenTextMinWords = "5"`), `maxWordCount` (fallback `kSummarizeWrittenTextMaxWords = "75"`) | `WriteEssayCubit` → `AnswerOutboxDao.upsertAnswer` (local SQLite) → `SyncEngine` flushes `POST /attempts/{id}/answers` |
| `lib/features/exam_attempt/speaking_writing/presentation/pages/write_essay_v2_screen.dart` (wrapper, 23 lines) → `widgets/write_essay_v2_body.dart` (logic) | `promptText` (fallback `kWriteEssayPrompt`), `minWordCount` (fallback `kWriteEssayMinWords = "200"`), `maxWordCount` (fallback `kWriteEssayMaxWords = "300"`) | Same — `WriteEssayCubit` reused for both writing tasks |

Notes for implementers / testers:
- The body widgets use the `WriteEssayCubit` for both screens (no separate `SummarizeWrittenTextCubit` exists in `pte-app` today) — out of scope here, but worth knowing so we don't accidentally break the cubit contract.
- `WritingTaskHeader` reads `totalSeconds` from the constant `kSummarizeWrittenTextDurationSeconds = 600` / `kWriteEssayDurationSeconds = 1200`, NOT from `TaskView.prepSeconds` / `responseSeconds`. The dev-fixture path bypasses server timer values entirely. The real-backend path uses `TaskView.responseSeconds` only for the shared `ExamAppBar` countdown; the writing-task-local `WritingTaskHeader` always uses the hard-coded constant. This is a known UI behavior, not something this plan changes.
- Word-count validation is purely client-side (`_WordCountFooter` flips color on out-of-range when time expired). Server accepts any text — no `minWordCount`/`maxWordCount` validation in `SubmitAnswerRequest`.

## Phases

- [x] Phase 1: Timing config — add `SUMMARIZE_WRITTEN_TEXT` entry to `task-timing.json` (0 prep / 600 response). `WRITE_ESSAY` already present at 0 / 1200. ✅ Done.
- [ ] Phase 2: Seed via REST API + unit test + smoke — `curl` commands to create `Question` rows via `POST /api/authoring/questions`, one `AttemptMapper` unit test covering writing task field mapping, manual smoke instructions.

## Research Summary

The full attempt flow is already wired through generic, task-type-agnostic endpoints (`POST /attempts`, `GET /attempts/{id}/next-task`, `POST /attempts/{id}/answers`, `POST /attempts/{id}/submit`). The `AttemptMapper.toTaskResponse` method already maps every relevant `PinnedItemView` field into `TaskView` — including `promptText`, `minWordCount`, `maxWordCount`, `prepSeconds`, `responseSeconds`. The Flutter screens consume this `TaskView` directly via `ExamAttemptBloc` and submit `payload` as raw text. No client-side changes are needed; the only backend work is to give the timer config a missing entry and give the seed loader something to seed.

Authoring's existing seed pattern (`ReadingTaskSeedRunner` under `services/authoring/src/main/java/com/pte/authoring/seed/`, profile-activated by `spring.profiles.active=seed-reading-tasks`) is the convention to follow — `WritingTaskSeedLoader` mirrors it: `@Component` gated on `@ConditionalOnProperty(name = "app.seed.writing-tasks", havingValue = "true")` with a fixed `publicId` per row, so the loader is idempotent across reboots.

## Dependencies

None new. All collaborators already exist and are unmodified in their public surface:
- `TimerService` (consumes `task-timing.json`)
- `AttemptMapper` / `TaskView` / `PinnedItemView` (carry prompt + word counts)
- `AttemptController` / `AttemptService` (generic task-type-agnostic endpoints)
- `SubmitAnswerRequest` (`@NotBlank String payload` for text-input tasks)
- `QuestionRepository.findByPublicId(...)` for idempotent seeding

## Risks

- **MEDIUM: Seeded questions are platform-owned (SHARED visibility) and will appear in any tenant's question bank.** `Question.status = PUBLISHED` means any tenant that queries the bank can see and reuse them. Mitigation: (1) these are dev-only seed publicIds that should never appear in a real blueprint; (2) the authoring service requires `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` role for `POST /questions` — local dev auth is configured with those roles; prod auth config must not give those roles to regular users.
- **LOW: Seed via REST API is not idempotent by default.** Re-running the `curl` commands inserts duplicate `Question` rows (different `publicId`). Mitigation: the commands use fixed `publicId` values; the authoring `POST /questions` endpoint should reject duplicates with 409 Conflict — verify this before using the commands.
- **LOW: `task-timing.json` reload semantics.** Timer config is static at `TaskTimingConfig` construction; if a future change makes it hot-reloadable, the `SUMMARIZE_WRITTEN_TEXT` entry's behavior could shift unexpectedly. Out of scope here — current reload strategy is static at startup, verified by reading `TaskTimingConfig`.
- **NOTED (not blocking)**: full live end-to-end verification (Flutter app pointed at a running backend) was not performed — the plan targets backend-only. Manual smoke test steps are documented in Phase 2. Live e2e can be picked up by the Frontend member once Phase 2 is complete.

## Files Touched

```
pte-api/services/exam-delivery/src/main/resources/config/task-timing.json          (modify, ✅ Phase 1 done — +1 entry)
pte-doc/projects/plans/hung-writing-tasks-api/plan.md                              (modify, Phase 2 revised, Session Notes updated)
pte-doc/projects/plans/hung-writing-tasks-api/phase-01-timing-config.md            (no-op, timing done inline)
pte-doc/projects/plans/hung-writing-tasks-api/phase-02-seed-and-test.md            (rewrite, REST API seed + unit test + smoke)
```

## Plan Review (Step 3 red-team)

Not run yet — plan is small enough (≤4 file changes) that a separate red-team pass would be overhead. If the implementation reveals ambiguity (e.g., existing `Question` JSON shape differs from the spec, or the `seed-reading-tasks` profile convention has a hidden detail), the relevant phase file will be updated and re-reviewed inline.

## Session Notes

<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-25 00:00
**Phase in progress:** Phase 1 (timing config) — smallest, lowest-risk change first

### Decisions made this session

- Spec location: moved from `docs/superpowers/specs/2026-08-25-writing-tasks-api-design.md` to `projects/plans/hung-writing-tasks-api/plan.md` per user's explicit instruction ("làm ở đâu viết plan ở đó").
- Plan format: `plan.md` at folder root (matches `phat-speaking-read-aloud-ui/`, `phat-docker-compose-services/` convention) rather than `spec.md` at root (matches `phat-jackson3-objectmapper-migration/`, `ninh-student-exam-flow/`) — picked because the user's chosen parent folder `projects/plans/` matches the `plan.md` style more directly.
- Phase split: 2 phases (timing, seed+test) — matches "minimal" scope confirmed by user (3 file changes total before test, kept that way).
- Validation: word-count validation on the server stays OFF — UI shows warnings but server accepts whatever the student submits, matching the rest of the codebase's "trust the student at submit time" posture for free-text answers.
- Out of scope confirmed by user: scoring pipeline, vendor adapter, Flutter UI, admin authoring UI.
- **Added "Related UI (already shipped in pte-app)" section** per user's follow-up instruction ("thiếu 2 cái planUI tôi đã làm nữa") — explicitly cross-references the 4 files in `pte-app` (`SummarizeWrittenTextScreen` + body, `WriteEssayV2Screen` + body) and notes that the IT/smoke checks must verify the real-backend `TaskView` shape those UIs consume. Implementation does NOT modify any of those UI files.
- **Phase 1 executed (2026-08-26)**: Added `SUMMARIZE_WRITTEN_TEXT: { "prepSeconds": 0, "responseSeconds": 600 }` to `task-timing.json`. Verified `mvn -pl services/exam-delivery compile` passes. `WRITE_ESSAY` entry (0 / 1200) unchanged.
- **Phase 2 revised**: Codebase audit revealed (1) `ReadingTaskSeedRunner` does NOT exist — all authoring is via REST API (`POST /api/authoring/questions`, requires `PLATFORM_ADMIN`/`PLATFORM_AUTHOR` role). Phase 2 now seeds via `curl`/`http` commands against the running `authoring` service. (2) No `@SpringBootTest` or Testcontainers exist anywhere in `pte-api` — only Mockito unit tests. Phase 2 test now is a `AttemptMapper` unit test (covers `toTaskResponse` field mapping for writing task types) plus manual smoke instructions.

### Pre-existing, unrelated context noted

- `pte-doc/projects/plans/quang-pte-pivot/phase-05-writing-response-scoring.md` describes the eventual scoring pipeline (4 sub-scores, async poller, vendor wrapper). This plan does **not** touch any of that — the scoring poller will pick up our `Question` rows naturally once it ships, since `PteTaskType` is already mapped.
- `pte-app/lib/features/exam_attempt/speaking_writing/dev/writing_task_fixtures.dart` has its own Flutter-side dev fixtures (`kSummarizeWrittenTextDurationSeconds = 600`, `kWriteEssayDurationSeconds = 1200`). The 600/1200 durations in this plan intentionally match those constants — frontend and backend stay in lockstep.
