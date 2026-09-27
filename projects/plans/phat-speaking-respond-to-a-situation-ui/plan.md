# Plan: Respond to a Situation (Speaking) UI
Status: ✅ Complete
Date: 2026-08-23
Mode: Hard

## Overview
Add a `RespondToASituationScreen` for the `RESPOND_TO_A_SITUATION` Speaking task type — the first Speaking screen combining a persistent situation-text display with the existing audio-listening/record 2-card system — by promoting the private `_ListeningCard`/`_RecordCard`/`_elapsedPrepSeconds` pieces of `AudioPromptRecordBody` to public exports and composing them directly alongside the situation text.

## Phases
- [x] Phase 1: Promote `AudioPromptRecordBody`'s private pieces to public — mechanical rename only, verified behavior-preserving via all 4 existing consumers' unmodified tests passing.
- [x] Phase 2: Build `RespondToASituationScreen` — situation text + reused cards, strings, dispatcher wiring, dev fixture, mixin doc update.
- [x] Phase 3: Test the new screen and its routing, then run the full regression gate (`flutter test`, `flutter analyze`, `check-standards.sh`).

## Research Summary
Two researchers investigated how to reuse the `_ListeningCard`/`_RecordCard`/`_elapsedPrepSeconds` logic currently private to `audio_prompt_record_body.dart` (already shared by Repeat Sentence, Retell Lecture, Answer Short Question, Summarize Group Discussion via `AudioPromptRecordBody`). One proposed duplicating the card logic into the new screen (since `RespondToASituationScreen` needs the situation text interleaved between `InstructionText` and the Listening card — a layout `AudioPromptRecordBody`'s fixed internal `Column` doesn't support); the other proposed promoting the private members to public and composing them directly in the new screen's own body, reusing `AudioPromptRecordBody.build()`'s wiring shell (Padding → BlocSelector → BlocBuilder → Column) as a template rather than calling `AudioPromptRecordBody` itself.

**User-confirmed decision: promote to public (pure rename, zero logic/behavior change).** This avoids duplicating the clamp math, countdown-label logic, and upload-status handling a fifth time, at the cost of a one-time mechanical rename across `audio_prompt_record_body.dart` and its 5 test consumers (verified via unmodified test pass, not test edits — only doc-comment references to the old private names in `audio_prompt_record_body_test.dart` and `auto_record_status_card.dart` need touching, and only as comments, not test assertions).

Also user-confirmed (2 rounds of Q&A, not to be re-litigated):
- Timing: 15s situation-text read + 5s pre-audio merged into one 20s "Beginning in" countdown (`_preListenSeconds = 20`), 10s mocked audio, 10s pre-record (`_preRecordSeconds = 10`) → `prepSeconds = 40`, `responseSeconds = 40` (both land on the dev-preview 10s poll boundary — no rounding needed, unlike several prior fixtures).
- Layout: situation text (`task.promptText`) renders ABOVE the two cards, directly below `InstructionText` — unlike `ReadAloudScreen`'s passage-after-card layout.
- Backend enum verified: `RESPOND_TO_A_SITUATION(PteSection.SPEAKING, true, true, false, true, false, false, false)` in `pte-api/services/authoring/src/main/java/com/pte/authoring/domain/enums/PteTaskType.java:21` — `scored=true`, `requiresAudioPrompt=true`, `requiresPromptText=true`. Re-verify by grep at implementation time, not just from this document.

## Dependencies
None — purely a Flutter-app-side addition, no backend/API change required (the task-type enum and prompt/audio-prompt requirement flags already exist server-side).

## Risks
- HIGH: Instruction text and dev-fixture situation-text wording in this plan are content judgment calls, not yet user-confirmed verbatim — do not let them get hardcoded into tests before confirmation. Mitigation: Phase 2 explicitly re-confirms the exact strings with the user before writing them into `speaking_writing_strings.dart`/the fixture, mirroring the Summarize Group Discussion plan's resolved process (that plan's original mistake was leaving no concrete draft — this plan supplies one but still gates on confirmation before cook).
- MEDIUM: The Phase 1 rename touches a file shared by 4 existing screens (Repeat Sentence, Retell Lecture, Answer Short Question, Summarize Group Discussion) — any accidental logic change would regress all 4 silently. Mitigation: rename-only diff (no reformatting, no logic edits), correctness gated on those 4 screens' existing test files plus `audio_prompt_record_body_test.dart` passing completely unmodified.
- LOW: `AudioListeningPrepCard`/`RecordedAnswerPrepCard` naming could still be confused with the existing public leaf widgets `AudioListeningStatusCard`/`RecordedAnswerStatusCard` in adjacent files. Mitigation: names chosen specifically to differ by role word (Prep vs Status) and are documented in the promoted classes' doc comments explaining the distinction.
- LOW: Grepping for `RESPOND_TO_A_SITUATION` before implementation might reveal the value is stale if the backend enum changes between plan-writing and cook. Mitigation: Phase 2 re-verifies the exact string via grep against `PteTaskType.java` before wiring the dispatcher constant, not just trusting this plan document.

## Plan-Reviewer Findings (Hard mode, Step 3)
Verdict: **WARN** (1 NOTED, fix applied before cook) — rename completeness (re-read the full 242-line file, confirmed no other private references missed, confirmed repo-wide grep finds only doc-comment prose hits outside the file itself), arithmetic (all Phase 3 test cases, including the trickiest elapsed=29/30 boundary, independently re-traced through the actual card logic), `RESPOND_TO_A_SITUATION` string/flags, composition correctness (no double `InstructionText` render), and file scope vs. sibling plans all verified correct against actual source.
- NOTED: The instruction-text draft was complete, but the fixture situation-text draft was only a truncated fragment ("You are at a hotel reception..." with an ellipsis) — inconsistent with the Summarize Group Discussion precedent's actual fix (a complete draft, not just a confirmation gate). The plan's Phase 2 Step 1 gate would have caught this before it reached source/tests, so this was not blocking, but **fix applied anyway**: phase-02 Step 1 now supplies the full, complete situation-text draft ("You are a student at a university. You have realized that you will miss an important exam because of a family emergency. Explain the situation to your professor and ask what you should do.") alongside the already-complete instruction-text draft, both pending final Step 4 user confirmation before cook.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-23 (cook session)
**Phase in progress:** All 3 phases implemented; proceeding to cook Step 3 (tester) / Step 4 (code-reviewer).
**Status:** All 3 phases complete. `flutter analyze`: 0 issues (whole project). Full `flutter test`: **322/322 passing** (311 baseline + 11 new: 10 in `respond_to_a_situation_screen_test.dart`, 1 new `RESPOND_TO_A_SITUATION routing` group in `task_type_dispatcher_test.dart`). Phase 1's rename verified behavior-preserving: all 5 dependent test files (repeat_sentence, retell_lecture, answer_short_question, summarize_group_discussion, audio_prompt_record_body) pass **unmodified** (30/30). `check-standards.sh`: 1 NEW finding — `speaking_writing_task_fixtures.dart` now 308 lines (over the 300-line soft threshold), from organic growth across 8 accumulated fixture getters. Warning-only, non-blocking, dev-only tooling file (kDebugMode-gated, never shipped). Not split in this phase — flagging honestly rather than silently ignoring; a future feature could split it into per-task-type fixture files if this keeps growing.

### Decisions made this session
- (none beyond plan's already-recorded post-review Q&A decisions)

### Next immediate action
Spawn `tester` (Step 3) and `code-reviewer` (Step 4) per the Standard-mode cook pipeline, then Step 5 finalize.
