# Plan: Personal Introduction Speaking Screen
Status: ✅ Complete
Date: 2026-08-23
Mode: Hard

## Overview
Add a new Speaking-task screen for the `PERSONAL_INTRODUCTION` task type (verified backend enum, `scored=false`, `requiresAudioPrompt=false`), structurally cloned from `ReadAloudScreen` — a single-card, no-sub-stage, fully-auto-advancing prep(25s)/response(30s) recording flow — and wire it through the dispatcher, dev fixtures, and tests.

## Phases
- [x] Phase 1: Strings + PersonalIntroductionScreen — add the 3 instruction-string constants and the new screen mirroring `ReadAloudScreen` exactly.
- [x] Phase 2: Dispatcher + dev fixture wiring — route `PERSONAL_INTRODUCTION` through `TaskTypeDispatcher`, add a dev-preview fixture, and check/update the timer-bridge mixin doc comment.
- [x] Phase 3: Tests + full regression gate — new screen test, new dispatcher routing test group, full `flutter test`/`flutter analyze`/`check-standards.sh` pass.

## Research Summary
Direct codebase inspection (no separate researcher agents dispatched — architecture was pre-confirmed by the user via AskUserQuestion) confirmed:
- `PteTaskType.java:15`: `PERSONAL_INTRODUCTION(PteSection.SPEAKING, false, false, false, true, false, false, false)` — only `scored=false` Speaking task; `requiresAudioPrompt=false` (5th positional flag), confirming no audio-listening sub-stage is needed.
- `ReadAloudScreen` (`lib/features/exam_attempt/speaking_writing/presentation/pages/read_aloud_screen.dart`) is the exact structural template: `StatefulWidget` + `State` with `AutoRecordTimerBridgeMixin`, `AutoRecordCubit` built in `initState`/closed in `dispose`, `ExamScaffold` with `AutoAdvanceOnUploadReady<AutoRecordCubit, AutoRecordState>` as `bottomAction`, body = `InstructionText` + `AutoRecordStatusCard` (single card, unchanged, reused as-is) + scrollable prompt text.
- `SpeakingWritingStrings` follows a `xInstructionPrefix/Middle/Suffix` 3-constant pattern per screen (see `readAloudInstructionPrefix/Middle/Suffix`, `describeImageInstructionPrefix/Middle/Suffix`) — the new strings follow this exactly.
- `TaskTypeDispatcher` (`lib/features/exam_attempt/presentation/widgets/task_type_dispatcher.dart`) switches on a private `const String _taskTypeX` per task type; each auto-record Speaking arm passes `task, attemptPublicId, recorder: audioRecorderService, mediaDao, coordinator: mediaUploadCoordinator, syncEngine` (no `audioPlayerService` — that's Listening-only).
- `SpeakingWritingTaskFixtures` (`lib/features/exam_attempt/reading/dev/speaking_writing_task_fixtures.dart`) has an established doc-comment precedent (`describeImage`'s fixture) for literal, non-poll-boundary-aligned prep/response values with an explicit "accepted lag" note — the same pattern applies here since there is no sub-stage to redistribute seconds within.
- `AutoRecordTimerBridgeMixin`'s doc comment (`auto_record_timer_bridge_mixin.dart:11-13`) already enumerates screens by name ("Read Aloud, Repeat Sentence, Describe Image, Retell Lecture, Answer Short Question") — this list needs a new entry for Personal Introduction.
- `read_aloud_screen_test.dart` is a complete, directly-portable test template (mock bloc/recorder/mediaDao/coordinator/syncEngine, `_FakePathProviderPlatform`, `stubBlocState` helper, 5 test cases covering exactly the coverage this task requires).
- `task_type_dispatcher_test.dart` has an established per-task-type `group('TaskTypeDispatcher — X routing', ...)` pattern (see `REPEAT_SENTENCE`/`DESCRIBE_IMAGE`/`RE_TELL_LECTURE`/`ANSWER_SHORT_QUESTION` groups) with a matching `_xTask({required pinnedItemPublicId})` helper — directly portable.

## Dependencies
None — all consumed types/widgets (`AutoRecordCubit`, `AutoRecordStatusCard`, `AutoAdvanceOnUploadReady`, `ExamScaffold`, `InstructionText`, `AutoRecordTimerBridgeMixin`) already exist and are unchanged.

## Risks
- HIGH: Accidentally reaching for `AudioPromptRecordBody`/manual advance button (matching the screenshot literally instead of the confirmed architecture) — mitigated by treating `ReadAloudScreen` as the mandatory template and explicitly not touching `TaskAdvanceButton`/`FlushableAnswerCubit`.
- MEDIUM: Dev-preview fixture's 25s/30s prep/response values don't land on the `ExamAttemptBloc`'s 10s poll boundary, causing a small dev-preview-only UI lag at phase transitions — mitigated by keeping the literal values (per explicit user requirement) and documenting the lag inline, mirroring `describeImage`'s precedent exactly.
- LOW: Baseline test count assumed stale from a prior session — mitigated by measuring the actual pre-Phase-1 `flutter test` count fresh in Phase 3 rather than trusting the prior 295 snapshot.

## Plan-Reviewer Findings (Hard mode, Step 3)
Verdict: **WARN** (1 ACCEPTED, fix applied before cook) — architecture cloning, rejected-manual-button path, `PERSONAL_INTRODUCTION` string consistency, fixture placement, and test-template existence all independently verified correct against actual source.
- **ACCEPTED (HIGH)**: The plan's own Research Summary line 17/Phase 1 originally instructed cloning `ReadAloudScreen`'s `_instructionText(int responseSeconds)` shape — but that function takes ONE parameter and interpolates `task.responseSeconds` into both slots (Read Aloud has no separate prep-seconds mention). Personal Introduction's target string needs `task.prepSeconds` (25) in the first slot and `task.responseSeconds` (30) in the second — that's `DescribeImageScreen._instructionText(int prepSeconds, int responseSeconds)`'s 2-parameter shape, not Read Aloud's. Literally following the original plan text would have silently produced "In 30 seconds..." instead of "In 25 seconds...". **Fix applied**: phase-01 now explicitly calls out this correction and references `describe_image_screen.dart` as the co-template for the instruction-text function specifically (while `ReadAloudScreen` remains the template for everything else — lifecycle, scaffold, single-card body).
- NOTED: Research Summary mislabeled `requiresAudioPrompt` as "the 5th positional flag" (it's actually the 3rd constructor arg / 2nd boolean) — the cited value (`false`) is correct, only the position label is wrong; no code reads flags positionally, so no implementation risk. Not fixed (documentation-only slip, not worth a plan edit).
- NOTED: `PERSONAL_INTRODUCTION`'s `requiresPromptText=true` flag (confirming the screen legitimately needs `task.promptText`) wasn't explicitly cited in the Research Summary, though Phase 1 already includes the prompt-text display correctly — incomplete justification trail only, not an implementation gap.
- NOTED: `TaskTypeDispatcher`'s `_ => _UnsupportedTaskTypePlaceholder(...)` fallback arm already provides a safe degrade path if Phase 2 is skipped/fails after Phase 1 lands — pre-existing safety net, no plan change needed.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-23 (cook session)
**Phase in progress:** All 3 phases implemented; proceeding to cook Step 3 (tester) / Step 4 (code-reviewer).
**Status:** All 3 phases complete. `flutter analyze`: 0 issues (whole project). Full `flutter test`: **302/302 passing** (295 baseline + 7 new: 6 in `personal_introduction_screen_test.dart`, 1 new `PERSONAL_INTRODUCTION routing` group in `task_type_dispatcher_test.dart`). `check-standards.sh`: 0 new findings (all listed warnings pre-existing).

### Decisions made this session
- (none beyond plan's already-recorded post-review Q&A decisions)

### Next immediate action
Spawn `tester` (Step 3) and `code-reviewer` (Step 4) per the Standard-mode cook pipeline, then Step 5 finalize.
