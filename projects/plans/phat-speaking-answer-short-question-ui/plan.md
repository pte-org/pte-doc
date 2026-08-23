# Plan: Answer Short Question Speaking Screen (+ DRY extraction)
Status: ✅ Complete
Date: 2026-08-23
Mode: Hard

## Overview
Add a new `ANSWER_SHORT_QUESTION` speaking-task screen with fixed 3s/8s/3s/10s timing and a fixed instruction string, and — as the required first step — extract the near-identical "listening + record" body shared by `RepeatSentenceScreen` and `RetellLectureScreen` into a single reusable widget (`AudioPromptRecordBody`) before the third screen consumes it, per the user's explicit choice to extract now rather than duplicate a third time.

## Phases
- [x] Phase 1: Extract `AudioPromptRecordBody` — pure code move, refactor `RepeatSentenceScreen`/`RetellLectureScreen` to consume it, prove zero behavior change via their existing tests passing unchanged.
- [x] Phase 2: New `AnswerShortQuestionScreen` — fixed instruction string, dispatcher wiring, dev fixture, mixin doc update.
- [x] Phase 3: New screen's tests, dispatcher routing test, and full-suite/analyze/standards regression gate.

## Research Summary
Two researchers independently investigated how to add the `ANSWER_SHORT_QUESTION` screen given this is the 3rd occurrence of the same "listening + record" card shape (after Repeat Sentence and Retell Lecture). Researcher A proposed extracting the shared body (`_ListeningCard`, `_RecordCard`, `_elapsedPrepSeconds`) into one reusable `AudioPromptRecordBody` widget, parameterized by `task`, `preListenSeconds`, `preRecordSeconds`, and `instructionText`, leaving each screen's own sub-stage constants, instruction-text construction, and State/lifecycle/AutoRecordCubit boilerplate in place (that boilerplate is identical across *all* speaking screens, including ones that don't share this card layout, so extracting it is a separate, out-of-scope concern). Researcher B, tasked with finding an alternative (e.g. a mixin, a configurable single card, or continued duplication), concluded no alternative shape fit this codebase's established patterns (`ReadAloudScreen`/`DescribeImageScreen`'s prior unification precedent for `AutoRecordCubit`/`AutoRecordTimerBridgeMixin` was cited as the direct analogue) and conceded Researcher A's plain-`StatelessWidget`-with-constructor-params approach was the better fit. This plan implements Researcher A's design verbatim, confirmed via direct reading of both existing screen files during plan-writing: `_elapsedPrepSeconds`, `_ListeningCard`, and `_RecordCard` are structurally identical between `repeat_sentence_screen.dart` and `retell_lecture_screen.dart` (only `_preRecordSeconds`'s value and the `_instructionText` construction differ, both of which stay screen-local).

Chosen approach: create `lib/features/exam_attempt/speaking_writing/presentation/widgets/audio_prompt_record_body.dart` housing the public `AudioPromptRecordBody` plus the three moved private members; refactor both existing screens to a one-line `build()` delegating to it; add the new screen as a third, equally-thin consumer.

## Dependencies
None — all backend contracts (`ANSWER_SHORT_QUESTION` enum, `TaskView.prepSeconds`/`responseSeconds`) already exist and are consumed identically to the two existing speaking screens.

## Risks
- HIGH: The extraction accidentally changes rendered output, widget-tree shape, or progress-bar/countdown values — mitigation: treat it as a pure code move, diff old vs. new `build()` structure line-by-line, and require `repeat_sentence_screen_test.dart`/`retell_lecture_screen_test.dart` to pass **unmodified** as the correctness gate (Phase 1 and re-verified in Phase 3).
- MEDIUM: `ANSWER_SHORT_QUESTION` enum name or the 14/24-second poll-boundary timing could drift or be miscopied — mitigation: re-grep `PteTaskType.java` at implementation time (not just trusting this document), and state the non-boundary-aligned fixture timing explicitly in its doc comment, mirroring `describeImage`'s precedent.
- LOW: `prepSeconds: 14`/total `24` don't land on the dev-preview `ExamAttemptBloc`'s 10s poll boundary, causing a small dev-preview-only UI lag at phase transitions — mitigation: none needed, this is cosmetic, never a production concern (production timing comes from real server-pushed deadlines), and is an explicit, accepted user tradeoff (same as `describeImage`'s fixture).

## Plan-Reviewer Findings (Hard mode, Step 3)
Verdict: **APPROVED** — no CRITICAL/HIGH findings. Independently re-diffed `repeat_sentence_screen.dart`/`retell_lecture_screen.dart` (structurally identical, confirming the extraction is safe), independently recomputed all Phase 3 test arithmetic against `prepSeconds=14/preListen=3/preRecord=3/audio=8` (all plan-stated numbers correct), re-verified `ANSWER_SHORT_QUESTION` against `PteTaskType.java`, and confirmed the existing-test protection gate cannot be gamed (tests assert only on public widgets/rendered text, never private class identities).
- NOTED: `SpeakingWritingTaskFixtures` lives at `lib/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart` (nested under `reading/`, despite being Speaking/Writing-only content) — phase-02 referred to it by filename only, risking an implementer creating a duplicate file under `speaking_writing/dev/` instead. Fix applied: phase-02 now states the full existing path explicitly.
- NOTED: The plan's "286-test baseline" is a snapshot, not a live value — if other work merges before Phase 3 runs, treat the baseline as "the `flutter test` count measured immediately before Phase 1 starts," not the literal 286.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-23 (cook session)
**Phase in progress:** All 3 phases implemented; proceeding to cook Step 3 (tester) / Step 4 (code-reviewer).
**Status:** All 3 phases complete. `flutter analyze`: 0 issues (whole project). Full `flutter test`: **294/294 passing** (286 baseline + 8 new: 7 in `answer_short_question_screen_test.dart`, 1 new `ANSWER_SHORT_QUESTION routing` group in `task_type_dispatcher_test.dart`). `repeat_sentence_screen_test.dart`/`retell_lecture_screen_test.dart` re-verified passing **unmodified** after all Phase 2/3 additions — final proof the `AudioPromptRecordBody` extraction stayed behavior-neutral end-to-end. `check-standards.sh`: 0 new findings (all listed warnings pre-existing).

### Decisions made this session
- (none beyond plan's already-recorded decisions)

### Next immediate action
Spawn `tester` (Step 3) and `code-reviewer` (Step 4) per the Standard-mode cook pipeline, then Step 5 finalize.
