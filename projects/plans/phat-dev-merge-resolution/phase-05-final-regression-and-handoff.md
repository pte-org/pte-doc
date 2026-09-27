# Phase 5: Final Regression & Handoff

## Requirements
Confirm the merged codebase compiles cleanly and the full test suite passes, run the repo's standards check, and hand off to the user with an explicit statement that the merge itself is not finalized.

## Steps
1. Run `flutter analyze` across the whole repo; fix any remaining errors/warnings surfaced by the merge (should be near-zero given Phases 1–4's per-phase `dart analyze` gates, but this is the first whole-repo pass — some cross-file issues, e.g. an unused import left behind by a relocation, may only surface here).
2. Run the full `flutter test` suite; record the actual pass/fail/skip counts verbatim — do not assume a number. If anything fails, triage whether it's a genuine regression from this merge's resolutions (fix it) or a pre-existing flake independent of the merge (note it, don't mask it).
3. Re-run the two CRITICAL-guard verification greps one final time against the final merged state (`_startInFlight`/`_stopInFlight` in `speaking_writing/presentation/cubit/read_aloud_cubit.dart`, `pinnedItemPublicId` identity guard in `speaking_writing/presentation/widgets/auto_record_timer_bridge_mixin.dart`) as a final confirmation neither regressed across Phases 2–4's edits.
4. Run `.github/scripts/check-standards.sh` (warning-only per this repo's convention) and report its output verbatim in the phase's completion summary — do not silently drop warnings.
5. Do a final repo-wide sweep confirming no orphaned old-path files remain (`lib/features/exam_attempt/presentation/{cubit/auto_record_*.dart,cubit/upload_tracking_state.dart,cubit/recording_phase.dart,cubit/read_aloud_cubit.dart,widgets/auto_advance_on_upload_ready.dart,pages/speaking/,pages/writing/}` and `lib/features/exam_attempt/dev/` all absent) and no remaining conflict markers anywhere.
6. Stage the resolved files with `git add` (or `git mv` where a plain relocation was performed) so the merge is ready for the user to finish — but explicitly do **not** run `git commit` or `git merge --continue`. State this in the completion summary: "Merge is NOT finalized. Conflicts are resolved and the working tree is staged; run `git commit` yourself (or `git merge --continue` if that's the flow you're in) to complete the merge, per this project's 'user commits their own code' policy."

## Success Criteria
- `flutter analyze` reports 0 issues (or an explicitly justified, pre-existing, non-merge-related issue list if truly unavoidable — should not happen given Phases 1–4's gates).
- `flutter test` full-suite run completes; the actual pass count is recorded verbatim in the phase completion summary as this merge's new baseline (explicitly not compared against any stale pre-merge number, since none is stable across both sides' independent test additions).
- Both CRITICAL-guard greps from step 3 pass identically to their Phase 2/Phase 3 results — zero drift.
- `check-standards.sh` output is captured and reported (warnings allowed, silent failures are not).
- `git status` shows a clean "all conflicts resolved, ready to commit" state with nothing left in an unmerged (`U`) status — and the summary explicitly states the merge commit itself was intentionally not run.

## Risks
- A test passing in isolation (Phase 3's spot-check) but failing in the full suite due to shared mutable state (e.g. `GetIt` singletons, a leaked `StreamSubscription`) between relocated and non-relocated tests — Mitigation: this phase's full-suite run is the actual gate, Phase 3's spot-checks were only an early-warning signal, not a substitute.
- Scope creep into actually finishing the merge (`git commit`/`git merge --continue`) — Mitigation: step 6 explicitly forbids it and the phase's own success criteria don't require a commit hash, only a clean staged state.
