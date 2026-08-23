# Plan: Read Aloud Task Screen UI
Status: ✅ Complete — implemented, tested, reviewed (APPROVED, 96/100)
Date: 2026-08-22
Mode: Hard

## Overview
Replace the placeholder `read_aloud_screen.dart` with the real PTE-style UI (bordered passage panel, recording indicator with waveform, auto-record) driven by `ExamAttemptBloc`'s existing `TimerService`-backed clock, with no second timer and no manual record button.

## Phases
- [x] Phase 1: Timer bridge foundation — extract shared mm:ss formatter, add idempotent `ReadAloudCubit.onTimerSnapshot`, unit-test the auto-start/auto-stop logic in isolation.
- [x] Phase 2: Presentational widgets — build the passage panel and recording indicator as pure prop-driven widgets, add their tokens/strings, widget-test them (including animation-controller disposal).
- [x] Phase 3: Screen wiring — rewrite `read_aloud_screen.dart` to bridge `ExamAttemptBloc`'s stream into the cubit, compose the new widgets by phase, remove the manual button and dead strings, final analyze pass.

## Research Summary
Two independent research passes both converged on the same architecture: `TimerService` (surfaced via `ExamAttemptBloc.state.timerSnapshot`) is the single authoritative clock in the app — its own doc comment says "not two independent timer mechanisms." `ReadAloudCubit` must **not** compute its own deadlines from `TaskView.prepDeadline`/`responseDeadline`; instead it exposes a plain, idempotent `onTimerSnapshot(TimerSnapshot)` method guarded purely off its own `RecordingPhase` state (same guard style as the existing `stopRecording()`), so it stays unit-testable with hand-built `TimerSnapshot` values and no stream/widget-test plumbing. The **screen**, not the cubit, owns the bridge: it forwards the bloc's current snapshot on cubit creation (covers resume-mid-task) and subscribes to `ExamAttemptBloc.stream` for the screen's lifetime, cancelling on dispose — mirroring the cubit's own `_rowSubscription` lifecycle discipline. This keeps `ReadAloudCubit`'s constructor dependency list unchanged and keeps stream ownership wherever `BuildContext` already lives.

The waveform is explicitly decorative (a looping `AnimationController`-driven bar row, not real mic amplitude) — `AudioRecorderService`'s interface is untouched. The manual Start/Stop `PrimaryButton` is removed entirely; there is no Skip button since no such concept exists at the `ExamAttemptBloc`/backend level — the only advance affordance remains the existing, unmodified `ReadAloudAdvanceButton`.

## Dependencies
None. All collaborators already exist and are unmodified in their public surface: `TimerService`/`ExamAttemptBloc` (clock), `AudioRecorderService`, `PendingMediaUploadDao`, `MediaUploadCoordinator`, `ReadAloudAdvanceButton`, `ExamScaffold`.

## Risks
- HIGH: A wrong idempotency guard in `onTimerSnapshot` double-calls `recorder.start()`/`recorder.stop()` on repeated ~1s ticks — mitigation: guard purely off the cubit's own `RecordingPhase`, verify via mocktail `called(1)` in unit tests for repeated/irrelevant snapshots.
- HIGH (plan-reviewer CRITICAL, ACCEPTED — fixed in Phase 3): a stale/outgoing `ReadAloudScreen`'s `ExamAttemptBloc.stream` subscription can receive the *next* task's first snapshot before its own `dispose()` cancels it (Flutter defers old-Element disposal to end-of-frame while the bloc's emission is delivered via microtask), reachable on every proctor-forced or stale-rejection advance since those bypass the recorded/upload-gated advance path — mitigation: every forward to `onTimerSnapshot` (initial + stream) must check `state.task.pinnedItemPublicId == widget.task.pinnedItemPublicId` first; covered by a dedicated screen test case.
- MEDIUM: The screen's `ExamAttemptBloc.stream` subscription leaks or double-forwards on rebuild — mitigation: create/subscribe once in `initState`, cancel in `dispose`, no subscription work in `build()`.
- MEDIUM: `AnimationController`(s) in the recording indicator leak when the screen is torn down mid-task — mitigation: create in `initState`/dispose in `dispose()`, cover with a widget test that pops the widget and asserts no leaked ticker.
- LOW: Hardcoded colors/strings/magic numbers creep into the two new widget files — mitigation: `flutter analyze` plus manual review against `AppColors`/`AppDimensions`/`AppStrings` at the end of every phase.
- NOTED (plan-reviewer, not blocking): `TimerSnapshot.remaining` is only guaranteed non-negative/clamped-to-zero because `TimerService._nonNegative` enforces it today — `onTimerSnapshot`'s stop guard relies on this invariant holding; add a code comment noting the dependency so a future change to `TimerService`'s remaining-calculation can't silently break auto-stop.
- NOTED (plan-reviewer, not blocking): resuming after the response deadline has already fully expired can record ~1s of spurious near-silent audio (the first forwarded snapshot satisfies only the start transition; the matching stop fires on the next ~1s tick) — self-corrects within one tick, not worth blocking on, but add an explicit "idle + response + remaining already zero on first snapshot" test case in Phase 1 for coverage.

## Plan Review (Step 3 red-team)
`plan-reviewer` returned **BLOCK** on the first pass over one CRITICAL finding (cross-task stream-forwarding race, above) — fixed directly in `phase-03-screen-wiring.md` (Step 1 identity guard, new test case, updated Success Criteria) and in this file's Risks. A MEDIUM finding (line-count limit was asserted by reading rather than run) was also ACCEPTED and fixed in Phase 3's Steps/Success Criteria (now requires actually running `check-standards.sh` or an equivalent line-count command). Two NOTED findings are recorded above for awareness; a scope-creep finding and a dead-code-cleanup-safety finding were both investigated and REJECTED (verified safe against the actual codebase).

## Session Notes
<!-- Updated by cook automatically — do not edit manually -->

**Last active:** 2026-08-22 00:00
**Phase in progress:** none — all 3 implementation phases complete, awaiting Step 3 (tester agent) per Standard mode
**Status:** Phases 1–3 complete. `flutter analyze` clean on every touched file (only the pre-existing, unrelated `re_order_paragraphs_list.dart` breakage remains — not touched by this plan). Full `test/widget/features/exam_attempt` + `test/unit/features/exam_attempt` run: 136/138 pass, the only 2 failures are that same pre-existing compile break (`re_order_paragraphs_list_test.dart`, `task_type_dispatcher_test.dart`).

### Decisions made this session
- `onTimerSnapshot` uses `if / else if` (idle-check first) so the resume-after-expiry case (idle + response + remaining already zero) only starts recording and never stops in the same call, matching the plan-reviewer NOTED finding's expected behavior.
- `formatMmSs` lives in new `lib/core/utils/duration_format.dart`, first file in that directory; `exam_app_bar.dart`'s private `_formatRemaining` was deleted (not deprecated) since it had no other callers.
- `onTimerSnapshot`/`startRecording`/`stopRecording` calls are wrapped in `unawaited(...)` (repo's `unawaited_futures: true` lint requires it) — matches the existing pattern already used elsewhere in this cubit.
- **No new `AppColors` tokens needed** — the passage panel border reuses `AppColors.fillBlanksGapEmptyBorder` (existing neutral border color), the record dot reuses `AppColors.error`, and the waveform bars reuse `AppColors.primary`. Fully honors the user's confirmed choice to keep the app's existing color language rather than the mockup's orange/green.
- The instruction template uses only `responseSeconds` (interpolated twice: "In N seconds... You have N seconds to read aloud"), not `prepSeconds` — this matches the reference mockup image verbatim (both numbers in the image are the same value, the response window; prep countdown is already shown separately by `ExamAppBar`). Read literally, phase-02's plan text could imply both `prepSeconds` and `responseSeconds` belong in the string; deviated from that reading deliberately to match the actual reference image instead of inventing an instruction PTE doesn't use.
- Animation timing (`_dotPulseDuration`, `_waveformLoopDuration`) is kept as private `static const Duration` fields inside `read_aloud_recording_indicator.dart` rather than added to `AppDimensions` — that file's own doc comment scopes it to spacing/radius/font-size (all `double`), and these durations are single-widget implementation details, not shared dimensions.
- **Pre-existing, unrelated breakage found (not fixed, out of scope):** `lib/features/exam_attempt/presentation/widgets/re_order_paragraphs_list.dart` (last touched 2026-08-21, before this session) fails `flutter analyze`/compile against the installed Flutter SDK — `ReorderableListView` no longer accepts `onReorderItem` (wants `onReorder`, which is also missing). This breaks `re_order_paragraphs_list_test.dart` and (transitively, via import) `task_type_dispatcher_test.dart`. Confirmed via `git diff HEAD` that this session touched neither file. Flagged to the user; not fixed here since it's unrelated to the Read Aloud UI plan.

### Phase 3 decisions
- `ReadAloudScreen`'s own `initState` reads `context.read<ExamAttemptBloc>()` directly (no `Builder`-for-inner-context needed, unlike `McReadingSingleScreen`) — `ExamAttemptBloc` is an ancestor-provided singleton here, not something this screen provides itself, so plain `context` access works at every point in this widget.
- The mandatory `pinnedItemPublicId` identity guard (plan-reviewer CRITICAL fix) lives in `_forwardIfCurrentTask`, applied identically to both the initial synchronous forward and every subsequent stream event — never `recorder.start`/`stop` for a state whose task doesn't match `widget.task`.
- The `_ReadAloudBody`'s own `BlocSelector<ExamAttemptBloc,...>` (for the visual timer phase/remaining, mirroring `ExamAppBar`'s existing pattern) is intentionally **not** guarded by the same task-identity check — that guard only protects the cubit's real side effects (mic start/stop, file writes, uploads). A momentarily-stale visual render for one frame before Flutter tears the old screen down is a pre-existing characteristic `ExamAppBar` itself already has (its own `BlocSelector` isn't task-scoped either) — cosmetic, not a correctness bug.
- Removed `readAloudStartRecordingLabel`/`readAloudStopRecordingLabel` (manual button gone) and `readAloudNotRecordedYetLabel` (superseded by the Phase 2 prep hint) from `AppStrings`; also removed `readAloudRecordingIndicator`, which the new design made dead too (recording state is now shown visually via the pulsing dot, not a text label) — confirmed via repo-wide grep all four had zero other references before deleting.
- The `recorded`-but-`uploadStatus`-still-null transitional window (brief gap between the DB write and `PendingMediaUploadDao.watchRow` emitting) now falls back to `readAloudStillUploadingLabel` instead of the old (now-nonsensical, button-referencing) "not recorded yet" text.
- `ReadAloudScreen`'s internal `ReadAloudCubit` still uses its default `resolveReadAloudFilePath` (real `path_provider` call) — the screen-level widget test needed a `PathProviderPlatform.instance` fake (`path_provider_platform_interface` added as a new dev dependency) since no platform channel handler exists in the widget-test environment; this is a test-only addition, no production code changed for it.

### Step 3 — Testing (tester + debugger)
`tester` agent reviewed all existing tests for gaps and added 4 more (repeated-mid-recording-tick idempotency, `didUpdateWidget` animation start/stop coverage, full prep→response→recorded screen transition) — and in doing so **found a genuine re-entrancy bug**: `onTimerSnapshot`'s guard read `state.recordingPhase` synchronously, but `startRecording()`/`stopRecording()` only flip that phase after awaiting real async work (`path_provider` + the recorder plugin), so two snapshots delivered in the same synchronous turn could both pass the `idle` check and double-call `recorder.start()`. Matches the plan's own HIGH risk exactly.

`debugger` agent fixed it: added synchronous private in-flight latches (`_startInFlight`/`_stopInFlight`) in `read_aloud_cubit.dart`, checked-and-set before dispatching, cleared via `whenComplete` (covers both success and failure) so a later legitimate transition is never permanently blocked. Single file, no `RecordingPhase`/`ReadAloudState`/screen changes.

**Final verification (independently re-run, not just trusted from the agents):** `flutter test test/unit/features/exam_attempt test/widget/features/exam_attempt` → 142 pass, 2 fail (same pre-existing, unrelated `re_order_paragraphs_list.dart` break, confirmed untouched by this session). `flutter analyze` across `lib/features/exam_attempt`, `lib/core`, and both test directories → clean except those same 2 pre-existing errors.

### Step 4 — Code Review
`code-reviewer` independently re-ran `flutter analyze` and the full suite (reproduced 142 pass / 2 known-unrelated fail exactly), re-verified both previously-fixed races itself rather than trusting the notes, and confirmed the 4 removed `AppStrings` entries had zero other references via its own grep.

**Score: 96/100 — 0 CRITICAL/HIGH/MEDIUM, 2 LOW (cosmetic) — Verdict: APPROVED.** Clears the ≥9.5-with-0-CRITICAL auto-approve threshold. Both LOW findings (magic opacity constants in `_PulsingDot`, a stray blank line in `exam_app_bar.dart`) were fixed immediately after (trivial, in-scope) and re-verified clean.

### Next immediate action
Implementation, testing, and review are all complete and green. Proceeding to Step 5: project-manager → docs-manager → git-manager.
