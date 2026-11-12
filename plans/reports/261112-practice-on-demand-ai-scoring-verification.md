# Practice on-demand AI scoring: verification

Date: 2026-11-12
Plan: `pte-doc/projects/plans/quang-practice-on-demand-ai-scoring/`

## What changed

| Area | Change |
|---|---|
| Practice speaking scoring | The scoring model (the Capstone gateway) listens to the recording itself, with the task's Pearson rubric in the prompt. This replaces Azure for practice; exams keep Azure. Switch: `SCORING_AI_PRACTICE_SPEECH_VENDOR` (`gateway`, the default, or `azure`). |
| When AI scores | Objective tasks are scored on submit, as before. Speech and writing answers are saved unscored (`NONE`) until the student presses **Chấm điểm**: per answer in TASK/SKILL sessions, or once for the whole test after a mock test is submitted. |
| Re-scoring | An answer is scored once. `SCORED` is final; `FAILED` follows the existing retry rules. |
| Feedback | The same model call returns a reason per trait, a transcript and 1–2 tips, written in Vietnamese. For Read Aloud and Repeat Sentence, code also adds word marks (omitted and inserted words). |
| Worker | `PRACTICE_SCORING_CONCURRENCY` (default 3). Each queued mock-test answer has its recovery clock start at its expected turn, so the end of a long queue is not failed while it is still waiting. |

New endpoints (student, session owner only):

- `POST /api/v1/student/practice/sessions/{id}/items/{itemId}/scoring`: score one answer (TASK/SKILL).
- `POST /api/v1/student/practice/sessions/{id}/scoring`: score every unscored AI answer of a submitted mock test.

API additions:

- `PracticeItemResultResponse.feedbackDetail`
- `PracticeReviewResponse.kind`
- `PracticeReviewResponse.Item.result`

## Traits by source

| Task | Judged by the model from the audio | Counted by code from the model's transcript |
|---|---|---|
| RA | Pronunciation, Oral Fluency | Content (passage words minus errors) |
| RS | Pronunciation, Oral Fluency | Content 0–3 (words in sequence) |
| ASQ | none | Vocabulary 0/1 (accepted answers) |
| DI, RL, RTS, SGD | Content, Pronunciation, Oral Fluency | none |

The item score always comes from `RubricScorer`, so the `RubricScoreSingleSourceTest` ratchet still passes.

## Checks run

| Check | Result |
|---|---|
| `pte-api` focused tests (practice, scoring, generation, architecture, API inventory) | 1,491 + 391 tests, 0 failures |
| `pte-api` full `app` suite (before the last two fixes) | 5,237 tests, 0 failures, 82 skipped |
| `pte-api` full `app` suite (after all fixes) | 5,238 tests, 0 failures, 82 skipped |
| Local `app` container rebuilt | healthy |
| Live scorer against the real gateway: Read Aloud recording from Kokoro with a filler, a repetition and a substituted word | Passed in 7.8 s. Model `gemini-3.8-flash-n` behind Capstone. Transcript verbatim, including "um" and the repetition. Content 10/12, Oral Fluency 2, Pronunciation 5, item score 77. Reasons and tips in Vietnamese and correct. |
| `pte-practice`: `tsc --noEmit`, eslint, vitest | clean, clean, 812 tests passed |

## Issues found and fixed during verification

1. **The gateway streams server-sent events unless the request says `stream: false`.** The live call first failed with `PROVIDER_RESPONSE_INVALID`. `OpenAiCompatibleStructuredClient` now sends `"stream": false`. This client also carries gateway text scoring (`SCORING_AI_TEXT_VENDOR=gateway`), so that path may have had the same failure before.
2. **The app failed to start after the first rebuild.** The new request service depended on `PracticeSessionStateGuard`, which is not a Spring bean. The service now locks the session through `PracticeSessionRepository`. Unit tests with mocks could not catch this; the container start did.
3. **`DraftParser.java` measured 310 lines**, over the 300-line limit, after the earlier HIW fix. The word diff moved to `HiwWordDiff`. Its schema messages, and those of `PictureDrafts`, moved to `QuestionGenerationConstants`.

## Not verified / limitations

- No end-to-end run through the student HTTP API. There is no local student account, and no token was forged. The scorer, the request service and the UI were each checked separately.
- Only Read Aloud was scored live. DI, RL, RTS, SGD, RS and ASQ were covered only by unit tests with a fake model.
- Capstone's pronunciation and fluency bands are perceptual and not calibrated against human raters. The same answer can differ by about one band between runs.
- Word marks show a substitution as one omitted word plus one inserted word.
- The validators under `itembank/internal/generation/validate/` still have about 15 inline messages from before this work. They were not touched.
- No browser check. The user tests the UI.
