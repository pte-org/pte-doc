# Plan: Summarize Group Discussion speaking screen
Status: ✅ Complete
Date: 2026-08-23
Mode: Hard

## Overview
Add the `SUMMARIZE_GROUP_DISCUSSION` speaking-task screen as the 4th consumer of the shared `AudioPromptRecordBody` widget, wiring it into the task-type dispatcher and the dev preview fixture with poll-boundary-aligned mock timing.

## Phases
- [x] Phase 1: Screen + strings — add `SummarizeGroupDiscussionScreen` (mirrors `AnswerShortQuestionScreen`) and its fixed instruction-text constant.
- [x] Phase 2: Wiring — dispatcher switch arm, dev-preview fixture, and mixin doc-comment update.
- [x] Phase 3: Tests + regression gate — new screen/dispatcher tests plus full `flutter test` / `flutter analyze` / standards check.

## Research Summary
Verified directly against the codebase before planning:
- `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java:22` confirms `SUMMARIZE_GROUP_DISCUSSION(PteSection.SPEAKING, true, true, false, false, false, false, false)` — `scored=true`, `requiresAudioPrompt=true`, `requiresPromptText=false` — the exact same shape as `REPEAT_SENTENCE`, `RE_TELL_LECTURE`, `ANSWER_SHORT_QUESTION`.
- `AnswerShortQuestionScreen` (`lib/features/exam_attempt/speaking_writing/presentation/pages/answer_short_question_screen.dart`) is the cleanest, most current template: `StatefulWidget` with `task`/`attemptPublicId`/`recorder`/`mediaDao`/`coordinator`/`syncEngine` constructor params, a `State` using `AutoRecordTimerBridgeMixin` + an internally-constructed `AutoRecordCubit`, `ExamScaffold` with `AutoAdvanceOnUploadReady` as `bottomAction`, and a private `StatelessWidget` body that just instantiates `AudioPromptRecordBody` with fixed `preListenSeconds`/`preRecordSeconds` module constants and a fixed instruction-text string. `RepeatSentenceScreen` confirms the same shape.
- `AudioPromptRecordBody`'s doc comment (`.../widgets/audio_prompt_record_body.dart:18-35`) currently enumerates its 3 consumers as "`RepeatSentenceScreen`, `RetellLectureScreen`, and `AnswerShortQuestionScreen`" and separately notes fixed-vs-interpolated instruction text as "(Repeat Sentence, Answer Short Question)" vs "Retell Lecture" — both spots need a one-line addition for the new screen; no logic in this file changes.
- `SpeakingWritingStrings` (`lib/features/exam_attempt/speaking_writing/constants/speaking_writing_strings.dart`) already holds `repeatSentenceInstructionText` and `answerShortQuestionInstructionText` as single fixed constants — the exact pattern to follow for `summarizeGroupDiscussionInstructionText`.
- `TaskTypeDispatcher` (`lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`) has one `_taskTypeXxx` constant plus one switch arm per task type, in declaration order matching the switch; `_taskTypeAnswerShortQuestion`'s arm is the exact shape to copy (no `audioPlayerService`).
- `SpeakingWritingTaskFixtures` (`lib/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart`) already has a `retellLecture` fixture whose doc comment explains rounding 60s audio down to 57s so `prepSeconds` (70) and `prepSeconds+responseSeconds` (110) land on the dev-preview `ExamAttemptBloc`'s 10-second poll boundary — this is the exact rationale template to reuse for `summarizeGroupDiscussion` (200 and 320, both boundary-aligned).
- `AutoRecordTimerBridgeMixin`'s doc comment (`.../widgets/auto_record_timer_bridge_mixin.dart:11-13`) currently lists "Personal Introduction, Read Aloud, Repeat Sentence, Describe Image, Retell Lecture, Answer Short Question" — needs "Summarize Group Discussion" appended, doc-only.
- `answer_short_question_screen_test.dart` and `task_type_dispatcher_test.dart` (its `ANSWER_SHORT_QUESTION routing` group, lines ~465-494) are the exact structural templates for the new test file and the new dispatcher-routing test group, including the `_FakePathProviderPlatform` boilerplate and the `pinnedItemPublicId` identity-guard regression pattern.

Chosen approach: pure copy-and-adapt of the `AnswerShortQuestionScreen` template with no new shared-widget code — `AudioPromptRecordBody` already generalizes over `preListenSeconds`/`preRecordSeconds`/`instructionText`, so this feature requires zero changes to shared widget logic, only additive constants, one new screen file, one new test file, and small wiring/doc edits.

## Dependencies
None — pure Flutter app change, no backend or API changes required (the backend enum already exists and is verified).

## Risks
- MEDIUM: Hand-derived test-case second-values in the phase-03 test file (e.g. "elapsed 190s → remaining 10s") could be transcribed incorrectly from the prompt's pre-derived numbers. Mitigation: recompute each case's `remaining = prepSeconds - elapsed` and expected sub-stage label independently while writing the test, matching `answer_short_question_screen_test.dart`'s reasoning comments rather than copying numbers blind.
- LOW: Forgetting one of the two doc-comment edits in `audio_prompt_record_body.dart` (consumer list AND the fixed-vs-interpolated parenthetical) since both are easy to miss in a quick scan. Mitigation: grep the file for "Retell Lecture" and "Answer Short Question" before editing to find every mention.
- LOW: Instruction-text wording drifting from real PTE phrasing since this is a content judgment call, not a spec. Mitigation: keep the suggested fixed sentence unless implementation turns up a more canonical PTE wording; no functional risk either way since the string is opaque to the widget.

## Plan-Reviewer Findings (Hard mode, Step 3)
Verdict: **WARN** (1 ACCEPTED, fix applied before cook) — arithmetic (all Phase 3 test cases independently re-traced through the actual `_ListeningCard`/`_RecordCard` logic), `SUMMARIZE_GROUP_DISCUSSION` string consistency, dispatcher switch-arm shape, and `AudioPromptRecordBody`'s doc-comment scoping all verified correct against actual source.
- **ACCEPTED (HIGH)**: The plan's original Risks section cited "the suggested fixed sentence" as a mitigation, but no concrete draft sentence existed anywhere in the plan documents — phase-03's tests would have hardcoded whatever wording the implementer invented on the spot, with no review checkpoint, breaking the precedent set by the sibling `phat-speaking-retell-lecture-ui` plan (which resolved an analogous content ambiguity via explicit user Q&A before cook). **Fix applied**: phase-01 Step 3 now specifies the exact, literal instruction-text constant to use — pending final confirmation in Step 4 validation before cook (see below).
- NOTED: Research Summary line 16 claims `SUMMARIZE_GROUP_DISCUSSION` is "the exact same shape as `REPEAT_SENTENCE`, `RE_TELL_LECTURE`, `ANSWER_SHORT_QUESTION`" — true for the flags that matter to this UI screen (`scored`, `requiresAudioPrompt`, `requiresPromptText`), but `ANSWER_SHORT_QUESTION` actually differs on `requiresCorrectAnswer` (a backend-authoring-only flag, irrelevant to this plan's Flutter screen, which was verified directly against `answer_short_question_screen.dart`'s real source, not derived from this flag comparison). Documentation-accuracy note only, no implementation impact — not fixed.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-23 (cook session)
**Phase in progress:** All 3 phases implemented; proceeding to cook Step 3 (tester) / Step 4 (code-reviewer).
**Status:** All 3 phases complete. `flutter analyze`: 0 issues (whole project). Full `flutter test`: **311/311 passing** (302 baseline + 9 new: 8 in `summarize_group_discussion_screen_test.dart`, 1 new `SUMMARIZE_GROUP_DISCUSSION routing` group in `task_type_dispatcher_test.dart`). `check-standards.sh`: 0 new findings.

### Decisions made this session
- (none beyond plan's already-recorded post-review Q&A decisions)

### Next immediate action
Spawn `tester` (Step 3) and `code-reviewer` (Step 4) per the Standard-mode cook pipeline, then Step 5 finalize.
