# Plan: Retell Lecture Speaking Task
Status: ✅ Complete
Date: 2026-08-23
Mode: Hard

## Overview
Add the `RE_TELL_LECTURE` speaking task screen by structurally mirroring `RepeatSentenceScreen` exactly (same `AutoRecordCubit`/`AutoRecordTimerBridgeMixin`/two-card layout), differing only in its sub-stage timing (3s pre-listen, 57s audio, 10s pre-record prep, 40s response) and its 2-variable instruction template.

## Phases
- [x] Phase 1: Strings + `RetellLectureScreen` — new instruction strings, new screen mirroring `RepeatSentenceScreen`'s structure with `_preListenSeconds = 3`/`_preRecordSeconds = 10`.
- [x] Phase 2: Dispatcher wiring + dev fixture + mixin doc update — route `RE_TELL_LECTURE`, add the `retellLecture` fixture (`prepSeconds: 70`, `responseSeconds: 40`), update the timer-bridge mixin's doc comment.
- [x] Phase 3: Tests + final regression — new screen test file, dispatcher routing test, full suite/analyze/standards gate.

## Research Summary
This is a pure "clone an existing screen with different constants" feature — no new architecture, no cubit/state changes, no shared-widget extraction (this is only the 2nd consumer of `AudioListeningStatusCard`, so per this codebase's 3-occurrence DRY threshold, no base class is warranted yet). All reused pieces (`AutoRecordCubit`, `AutoRecordState`, `RecordingPhase`, `AutoRecordTimerBridgeMixin`, `AudioListeningStatusCard`, `RecordedAnswerStatusCard`, `ExamScaffold`, `AutoAdvanceOnUploadReady`) are consumed exactly as-is, with zero logic changes — confirmed by reading each file in full before planning. Key decisions:

1. **Backend enum confirmed as `RE_TELL_LECTURE`** (verified via direct grep of `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java:19`: `RE_TELL_LECTURE(PteSection.SPEAKING, true, true, false, false, false, false, false),`) — not `RETELL_LECTURE`. Phase 2 re-verifies this at implementation time rather than trusting this document alone, per this plan's own instruction.

2. **Sub-stage constants differ from `RepeatSentenceScreen`'s only in the pre-record duration.** `RepeatSentenceScreen` uses `_preListenSeconds = 3`/`_preRecordSeconds = 3`. `RetellLectureScreen` uses `_preListenSeconds = 3` (same "Beginning in 3 seconds" delay before the lecture audio starts — confirmed explicitly by the user: "trước khi phát audio, cho chuẩn bị 3 giây") and `_preRecordSeconds = 10` (the "10s chuẩn bị" stage before recording). Audio-playing duration is `task.prepSeconds - _preListenSeconds - _preRecordSeconds`, which is 57 when `prepSeconds = 70` (the user's literal "~60s" audio is therefore 57s in the fixture, to keep the approved boundary-aligned `prepSeconds = 70` total — see Research Summary item 5 for why 70 was kept over a literal 73).

3. **The Listening card's "Beginning in" sub-stage is reachable exactly like `RepeatSentenceScreen`'s — no special-casing needed.** With `_preListenSeconds = 3` (not 0), `_ListeningCard`'s existing `if (elapsed < _preListenSeconds)` branch behaves identically to `RepeatSentenceScreen`'s: "Beginning in 3/2/1 seconds" for `elapsed` 0/1/2, then "Playing 57...1 seconds left" for `elapsed` 3–59. This makes the port to `RetellLectureScreen` a pure constant swap with zero branch-logic annotation required.

4. **Instruction template interpolates the sub-stage constant, not `task.prepSeconds`.** The mockup text says "in 10 seconds" — the prep-before-record duration alone (`_preRecordSeconds`), not the combined 70-second `task.prepSeconds` (audio + prep). The template is `retellLectureInstructionPrefix + _preRecordSeconds + retellLectureInstructionMiddle + task.responseSeconds + retellLectureInstructionSuffix`, following Describe Image's 2-variable template pattern but with `_preRecordSeconds` (a screen-local constant) as the first variable instead of `task.prepSeconds`. This is flagged explicitly in phase-01 as the easiest mistake to make.

5. **Dev fixture (`prepSeconds: 70`, `responseSeconds: 40`) lands on the dev-preview `ExamAttemptBloc`'s 10-second poll boundary** at both transitions (prep→response at 70s, response→recorded at 70+40=110s) — both multiples of 10. This avoids the "Beginning in 0 seconds" stuck-UI dev-preview-only lag documented on `repeatSentence`'s fixture (whose `prepSeconds: 10`/`responseSeconds: 15` also happens to align), unlike `describeImage`'s fixture, which deliberately keeps its literal 25/40 values and accepts up to ~5s of dev-preview-only lag. User confirmed keeping `70` (over the literal `3 + 60 + 10 = 73`) explicitly when asked — the ~3s of audio duration absorbed into staying boundary-aligned is an acceptable rounding, same spirit as `readAloud`'s/`repeatSentence`'s existing boundary-aligned fixtures. Phase 2's fixture doc comment states this explicitly, matching the existing precedent set by both prior fixtures' doc comments.

6. **No shared-base-widget extraction.** `AudioListeningStatusCard`'s own doc comment already anticipated Retell Lecture as a "future audio-prompt task type" consumer — this plan is that 2nd consumer, and per this codebase's established convention, extraction only happens at the 3rd occurrence. Not revisited here.

## Dependencies
None. `RE_TELL_LECTURE` as a `TaskView.taskType` string value requires no domain-model or backend-contract change — `TaskView.prepSeconds`/`responseSeconds` already exist and are sufficient. No new pubspec dependency.

## Risks
- HIGH: Interpolating `task.prepSeconds` (70) instead of `_preRecordSeconds` (10) into the instruction template would silently produce wrong, non-mockup-matching text ("in 70 seconds..." instead of "in 10 seconds...") — Mitigation: phase-01 states this explicitly as the primary implementation hazard; phase-03's instruction-text test asserts the literal expected string with 10 and 40, not 70.
- MEDIUM: Backend enum name confusion (`RE_TELL_LECTURE` vs. `RETELL_LECTURE`) — a routing string typo means the task silently falls through to `TaskTypeDispatcher`'s unsupported-task-type placeholder instead of erroring loudly — Mitigation: phase-02 re-greps `PteTaskType.java` at implementation time before wiring the dispatcher string constant, and phase-03's dispatcher routing test asserts the exact string routes to `RetellLectureScreen`.
- LOW: Forgetting the `_FakePathProviderPlatform` test setup (required by `AutoRecordCubit`'s `resolveRecordingFilePath` calling `path_provider`) causes a `MissingPluginException` in the new screen test — Mitigation: phase-03 copies the exact `setUpAll`/`_FakePathProviderPlatform` block from `repeat_sentence_screen_test.dart`.
- LOW: `AutoRecordTimerBridgeMixin`'s doc comment update (adding Retell Lecture to its consumer list) accidentally touching its logic — Mitigation: phase-02 states explicitly this is a doc-only change, confirmed via diff review before proceeding.

## Plan-Reviewer Findings (Hard mode, Step 3)
Verdict: **APPROVED** — no CRITICAL/HIGH findings; all 5 explicitly-flagged risk areas (instruction interpolation, `_preListenSeconds` edge case, `RE_TELL_LECTURE` spelling, dispatcher constructor-arg parity, scope vs. sibling plans) independently re-verified against source and confirmed correct. Reviewed against the plan's original `_preListenSeconds = 0` design; post-review, validation Step 4 (user Q&A) changed this to `_preListenSeconds = 3` — see below. This makes the port to `RepeatSentenceScreen` even more direct (a pure constant swap, no unreachable-branch annotation needed), so none of the reviewer's findings are invalidated by the change.
- NOTED: `_preRecordSeconds = 10` is a screen-local constant, not derived from `task.prepSeconds` — if a real backend task ever delivered `prepSeconds < 10`, the instruction text ("in 10 seconds") would diverge from the actual countdown. Pre-existing characteristic inherited from `RepeatSentenceScreen`'s identical pattern, not introduced by this plan. No action required now.
- NOTED: This is an additive-only change (no schema/migration/API contract) — if Phase 2 is skipped or fails after Phase 1 lands, the new screen simply stays unreachable with no partial-failure risk to existing task types. No action required.

## Post-Review Validation (Step 4 — user Q&A)
- Confirmed: instruction text interpolates `_preRecordSeconds` (10) and `task.responseSeconds` (40), not `task.prepSeconds` (70) — user: "10 giây này chính là 10 giây chuẩn bị trước khi record".
- Confirmed: fixture keeps `prepSeconds: 70`/`responseSeconds: 40` (poll-boundary aligned).
- **Changed from the original plan**: user clarified there IS a pre-listen delay before the lecture audio starts — "trước khi phát audio, cho chuẩn bị 3 giây" (3 seconds). This flips `_preListenSeconds` from `0` to `3`, matching `RepeatSentenceScreen`'s own `_preListenSeconds = 3` exactly. To keep the already-approved `prepSeconds: 70` fixture total, the mocked audio-playback duration becomes `70 - 3 - 10 = 57` seconds (not the originally-discussed ~60) — a rounding absorbed to stay poll-boundary-aligned, not a separate user request. All phase files updated accordingly.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-23 (cook session)
**Phase in progress:** All 3 phases implemented; awaiting Step 3 tester agent / Step 4 code-reviewer per Standard-mode cook pipeline.
**Status:** All 3 phases complete. `flutter analyze`: 0 issues (whole project). Full `flutter test`: **286/286 passing** (278 baseline + 8 new: 7 in `retell_lecture_screen_test.dart`, 1 new `RE_TELL_LECTURE routing` group in `task_type_dispatcher_test.dart`). `check-standards.sh`: 0 new findings (all listed warnings pre-existing, unrelated to this feature) — `retell_lecture_screen.dart` was trimmed from 307 to 297 lines (doc-comment compression only, no logic change) to stay under the 300-line threshold that would otherwise have been a new violation.

### Decisions made this session
- Trimmed `retell_lecture_screen.dart`'s two module/class doc comments to bring the file from 307 to 297 lines, avoiding a new `check-standards.sh` 300-line warning that `RepeatSentenceScreen` (262 lines) didn't trigger — no behavior change, doc-comment wording only.
- One manual brace fix for `curly_braces_in_flow_control_structures` lint on `_uploadStatusLabel`'s `if` (surfaced only after `dart format` line-wrapped it to 2 lines).

### Next immediate action
Spawn `tester` (Step 3) and `code-reviewer` (Step 4) per the Standard-mode cook pipeline, then Step 5 finalize (project-manager, docs-manager, git-manager).
