# Plan: Repeat Sentence Speaking Task
Status: ✅ Complete
Date: 2026-08-22
Mode: Hard

## Overview
Add the `REPEAT_SENTENCE` speaking task type by generalizing two already-shared Read Aloud pieces (auto-advance-on-upload, instruction text) and duplicating the auto-record cubit/screen-timer-bridge mechanics into a new screen — a structural mirror of the already-shipped Read Aloud task with no real audio playback, only a decorative mock "listening" status card.

## Phases
- [x] Phase 1: Shared groundwork + regression gate — generalize `AutoAdvanceOnUploadReady`/`InstructionText`, rename reused `AppStrings`/dimension constants, keep the 252/252 baseline green
- [x] Phase 2: Repeat Sentence cubit/state — duplicate the auto-record lifecycle + idempotency guards, full unit test coverage
- [x] Phase 3: Repeat Sentence screen + wiring — new listening-status card, screen, dev fixture, dispatcher routing, full widget/screen test coverage including the identity-guard case

## Research Summary
Two parallel research passes independently converged on the same approach, confirmed against this codebase's own precedents:

- **Generalize, don't inherit.** `ReadAloudAutoAdvance` becomes `AutoAdvanceOnUploadReady<C extends StateStreamable<S>, S extends UploadTrackingState>` — a generic widget over `flutter_bloc`'s own `StateStreamable<S>` bound (the same bound `BlocListener` itself uses), not a new abstraction. `UploadTrackingState` is a one-getter marker interface, matching this codebase's existing `FlushableAnswerCubit`/`TaskAnswerCubit` precedent (`task_answer_cubit.dart`). `ReadAloudInstructionText` becomes a plain `InstructionText({required String text})`, with each screen computing its own string.
- **Do not extract cubit/screen logic at the 2nd occurrence.** This codebase's own established precedent for structurally-identical task-type pairs (e.g. `McReadingSingleCubit`/`McReadingMultipleCubit`) shares only a thin marker interface, never behavior, and this project's DRY threshold is 3 occurrences. `RepeatSentenceCubit.onTimerSnapshot`'s `_startInFlight`/`_stopInFlight` synchronous guards and `RepeatSentenceScreen`'s `_forwardIfCurrentTask` timer-bridge (including the mandatory `pinnedItemPublicId` identity guard — a previously-fixed CRITICAL cross-task recorder-misfire bug) are duplicated from `ReadAloudCubit`/`ReadAloudScreen`, with a doc comment flagging extraction at the 3rd such cubit.
- **Reuse everything genuinely generic as-is**: `RecordingPhase` enum (relocated to its own file so a 2nd consumer imports cleanly, without an awkward `read_aloud_state.dart` import), `resolveReadAloudFilePath` (already keyed by `attemptPublicId`/`pinnedItemPublicId`, not Read-Aloud-specific despite its name), `ReadAloudAnswerStatusCard` (reused verbatim for the recorded/response half — its title "Recorded Answer" is genuinely correct for both task types), `PendingMediaUploadDao`/`MediaUploadCoordinator`/`AudioRecorderService`.
- **No real audio.** The prep-phase "listening" card is fully decorative (a static, non-animated volume meter) — `just_audio` stays an unused dependency. This was confirmed directly with the user, not re-litigated.

## Dependencies
None — all consumed services (`AudioRecorderService`, `PendingMediaUploadDao`, `MediaUploadCoordinator`, `SyncEngine`) are already registered in `exam_attempt_module.dart` and already threaded through `TaskTypeDispatcher`; no DI changes needed.

## Risks
- HIGH: Phase 1's widget-generic refactor silently changes Read Aloud's shipped behavior (the exact CRITICAL-bug class already fixed once for the identity guard). Mitigation: full existing Read Aloud suite must pass unmodified in behavior before Phase 2 starts; treat any assertion change as a regression, not an update.
- HIGH (plan-reviewer, ACCEPTED — fixed in phase-02): Phase 2's Success Criteria only required an aggregate test-count match against Read Aloud's cubit test structure, not an individually-named case for the `_startInFlight`/`_stopInFlight` synchronous double-snapshot guard — the exact tester-found/debugger-fixed bug class this plan is duplicating. Fixed: Phase 2 now names this test case as a hard, individually-checkable Success Criterion, mirroring how Phase 3 already hard-gates the identity guard.
- MEDIUM: Omitting the `pinnedItemPublicId` identity guard when duplicating the timer-bridge into `RepeatSentenceScreen` reintroduces the previously-fixed cross-task recorder-misfire bug. Mitigation: Phase 3's screen test suite must include the mismatched-task case as a hard requirement, not an optional extra.
- LOW: Renaming `AppStrings`/`AppDimensions` constants breaks a call site the grep pass missed. Mitigation: `flutter analyze` (which fails on unresolved identifiers) plus the full test suite gate every phase.
- NOTED (plan-reviewer, not blocking): Phase 1's rename list was ambiguous about which `AppStrings`/`AppDimensions` identifiers qualify as "reused" — fixed by enumerating them explicitly in phase-01 (including `readAloudBeginningInPrefix`/`Suffix`, confirmed reused since the listening card's prep-phase label is literally "Beginning in N seconds", the same wording Read Aloud already uses).
- NOTED (plan-reviewer, not blocking): `plan.md`'s Research Summary and phase-02's step text described `resolveReadAloudFilePath`'s naming inconsistently ("despite its name" vs. "generically-named") — fixed by rewording phase-02 to match: reused as-is, name intentionally left untouched, not in scope to rename.

## Validation (Step 4)
Confirmed with the user: (1) Phase 1's refactor of already-shipped Read Aloud code is approved, gated on the 252/252 regression check. (2) The real-world "prep" window is actually 3 sub-stages (3s pre-listen prep → 3-9s mocked audio playback → 3s pre-record prep) — but the UI shows exactly ONE continuous "Beginning in N seconds" countdown across all of it, no per-sub-stage text distinction. (3) Fixture's `prepSeconds` is therefore the *sum* — `3 + 6 (mid-range audio mock) + 3 = 12`, not a single stage's duration — `responseSeconds` stays `15`. Phase 3 already reflects this exact breakdown.

## Plan Review (Step 3 red-team)
`plan-reviewer` verified the `StateStreamable<S>` generic bound is real (checked against this project's actual resolved `bloc-9.2.1`/`flutter_bloc-9.1.1` package sources, not assumed), confirmed Phase 1's regression gate is genuinely rigorous (full-suite/zero-failure/exact-count, not a loose "some tests pass" claim), confirmed the Phase 3 identity guard is already a named hard release gate, and found zero scope creep into `ExamScaffold`/other task types. **Verdict: WARN** — 1 HIGH (Phase 2's re-entrancy-guard test wasn't individually gated the way Phase 3's identity guard was) ACCEPTED and fixed; 4 LOW findings NOTED, two of which (the rename-list ambiguity and the `resolveReadAloudFilePath` wording inconsistency) were also fixed directly since the corrections were cheap and concrete. The remaining two NOTED items (the volume meter's decorative-only contract being enforced by doc comment rather than a structural gate; the listening-card naming choice) are accepted as low-blast-radius and left as-is.

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-22
**Phase in progress:** none — all 3 implementation phases complete; testing (271/271 PASS) and code review (APPROVED 10/10) gates passed
**Status:** Phases 1–3 complete. `flutter analyze` clean on the whole repo. Full suite: exactly 271/271 pass (252 baseline + 11 Phase 2 cubit tests + 7 Phase 3 widget/screen tests + 1 dispatcher-routing test added during Phase 3 to close a gap the plan's own Success Criteria named). All new files well under the 300-line limit (screen 209, card 98, cubit 127, state 26). `check-standards.sh` shows only pre-existing, unrelated warnings. Code review: APPROVED, 10/10 checklist items.

### Decisions made this session
- `RecordingPhase` moved to its own file (`recording_phase.dart`); `read_aloud_state.dart` re-exports it (`export 'recording_phase.dart';`) so `read_aloud_cubit.dart` and its existing test needed zero changes — lowest-risk way to satisfy "a 2nd consumer can import it without going through `read_aloud_state.dart`" while keeping the Phase 1 diff minimal on already-shipped files.
- `AppStrings.repeatSentenceInstructionText` was added a phase early (during the Phase 1 string-file edit) since it was a one-line addition in a file already being touched — harmless, doesn't rename/remove anything unexpected, Phase 1's success criteria are unaffected.
- Renamed exactly the 9 identifiers enumerated in phase-01 (7 `AppStrings` + 2 `AppDimensions`), no more, no less — verified via repo-wide grep that zero stale references remain (one stale mention was in a test file's code *comment*, not compiled code — fixed too for accuracy).
- `RepeatSentenceCubit` imports `resolveReadAloudFilePath` from `read_aloud_cubit.dart` via a `show` combinator (`import 'read_aloud_cubit.dart' show resolveReadAloudFilePath;`) rather than duplicating the function — it's a free top-level function, not a class member, so this is the cleanest "reuse as-is, no rename" option matching phase-02's explicit instruction.
- `RepeatSentenceCubit`'s doc comment explains the `prep` phase covers the whole real-world listen sequence (pre-listen + audio + pre-record) without needing to know that internal sub-structure — only the screen's status card (Phase 3) needs to render the countdown; the cubit only cares about the `prep`→`response` transition, unchanged from `ReadAloudCubit`.

### Phase 3 decisions
- `AudioListeningStatusCard` uses a bordered (not filled-background) card, distinguishing it visually from the filled-blue `ReadAloudAnswerStatusCard` reused for the "Recorded Answer" half — matches the reference image's two visually-distinct cards.
- The decorative "Volume" meter is a `Stack` (static grey line + a fixed-position red dot at `Alignment(0.8, 0)`) — never animates, never reads any data source, per the confirmed "mock completely" decision. New `AppDimensions` tokens (`audioListeningMeterHeight`, `audioListeningDotSize`) and `AppStrings.audioListeningVolumeLabel` ("Volume") added for it.
- `RepeatSentenceScreen`'s body has no passage/prompt text at all (audio-only task) — the fixed `AppStrings.repeatSentenceInstructionText` is the only always-visible text, followed by the phase-appropriate status card.
- Added a `TaskTypeDispatcher` routing test (`test_type_dispatcher_test.dart`) beyond what phase-03 explicitly listed, to make the plan's own Success Criterion ("Selecting a task fixture with taskType: 'REPEAT_SENTENCE' through TaskTypeDispatcher renders RepeatSentenceScreen") independently verifiable by an actual automated test, not just true-by-construction from the screen test alone.

### Completion summary
All 3 implementation phases passed all pipeline validation gates:
- Step 1–2 (Implementation & unit test): COMPLETE
- Step 3 (Tester): COMPLETE — 271/271 tests pass
- Step 4 (Code review): COMPLETE — APPROVED, 10/10 items
- Step 5 (Finalize): project-manager + docs-manager complete; git-manager skipped per user's standing no-auto-commit instruction

### Post-cook revision — body layout corrected against live reference screenshots
After the pipeline finished, the user compared the running app against their reference images and corrected the body design, which had diverged from what they actually wanted (an earlier /ck:plan validation answer approximated this without live visuals, and turned out wrong once compared side-by-side):
- **Two cards are always visible simultaneously** (Listening card + "Recorded Answer" card, stacked), not one swapped for the other by phase as originally built.
- Each card runs its **own independent 2-stage sequence**: Listening card = "Beginning in N seconds" (3s pre-listen) → "Playing… N seconds left" (mocked audio, frozen at 0 once elapsed); Record card = blank while Listening is still active → "Beginning in N seconds" (3s pre-record) → "Recording… N seconds left" (unchanged) → upload status (unchanged).
- Implementation: `_elapsedPrepSeconds()` derives how far into the shared 12s `prep` window we are (from `TimerSnapshot.remaining`, or fully-elapsed once `response`/`recorded`); `_ListeningCard` and `_RecordCard` each independently derive their own sub-stage from that single elapsed value — no new `TimerPhase`/cubit changes, purely a body-composition and status-derivation rewrite in `repeat_sentence_screen.dart`.
- New string `AppStrings.audioListeningPlayingPrefix`/`Suffix` ("Playing… "/" seconds left") — wording chosen by pattern-matching the existing "Recording… N seconds left" convention since no reference frame showed this exact sub-stage; flagged to the user as an assumption, not confirmed pixel-for-pixel.
- `repeat_sentence_screen_test.dart` fully rewritten (7 tests) to assert each of the 4 sub-stage combinations plus the recording/recorded/mismatch cases. Full suite: **273/273** (271 + 2 net new). Not re-run through the full cook pipeline (tester/code-reviewer) — this was a direct, verified fix in response to live screenshot feedback; `flutter analyze` clean and the rewritten test suite passes, but no second Standard-mode test/review pass was performed for this specific revision.
