# Phase 5: Final Regression, Analyze, Standards Check, Session Notes

## Requirements
The whole feature — cubit/state unification, timer-bridge mixin, shared widgets, and the new `DescribeImageScreen` — is verified together as one coherent, regression-free change: full suite green, `flutter analyze` clean, `check-standards.sh` actually run and its output recorded, and `plan.md` updated with real results.

## Steps
1. Run the full test suite one final time from a clean state (no cached/partial run) and capture the exact pass/fail count.
2. Run `flutter analyze` and capture its exact output — must be clean (0 issues); if not, fix and re-run before proceeding.
3. Run `.github/scripts/check-standards.sh` and capture its full output — it is warning-only (always exits 0) but must actually be executed and its findings reported, not skipped or assumed clean. Pay particular attention to the "hardcoded strings in `Text()`" and "files exceeding 300 lines" checks against every file this plan touched or created.
4. If `check-standards.sh` flags a genuine new violation introduced by this feature (e.g. a new file crossing 300 lines, or a stray `Text('literal')`), fix it; if it flags a pre-existing violation unrelated to this feature, note it in Session Notes but do not scope-creep into fixing unrelated files.
5. Re-verify the specific cross-cutting regression surfaces by name: Read Aloud's 5 screen tests, Repeat Sentence's 7 screen tests (including the sub-stage group), `AutoAdvanceOnUploadReady`'s 3 tests, the merged `auto_record_cubit_test.dart` suite, and `task_type_dispatcher_test.dart`'s full group (including the new `DESCRIBE_IMAGE` case) — confirm all are present and green in the final run's output, not just "suite passed overall."
6. Update `plans/describe-image-ui/plan.md`: fill in Session Notes with the final test count (vs. the 273/273 baseline, with the net delta explained — dedup reduction from Phase 1 offset by new tests added in Phases 3–4), `flutter analyze` result, and `check-standards.sh` output summary. Move any findings surfaced during implementation that don't block merge into the Risks section's plan-reviewer NOTED slot.
7. Confirm every new/deleted file this plan introduced matches what's documented across the phase files (no orphaned files, no missed deletions) via a final directory diff against the phase files' file lists.

## Success Criteria
- Full test suite: 0 failures, exact final count recorded in `plan.md` Session Notes.
- `flutter analyze`: clean, 0 issues.
- `.github/scripts/check-standards.sh`: executed, full output captured in Session Notes (warning-only — does not block completion, but must be reported).
- `plan.md`'s Session Notes section is filled in (no longer a placeholder) with concrete numbers and outcomes.
- `grep -rn "ReadAloudCubit\|ReadAloudState\|RepeatSentenceCubit\|RepeatSentenceState\|resolveReadAloudFilePath" lib/ test/` still returns no matches (final confirmation the Phase 1 rename is complete and didn't regress).

## Risks
- Treating `check-standards.sh`'s warning-only exit code as "nothing to check" and skipping review of its output: Mitigation — Step 3/4 explicitly require capturing and reviewing the output, not just the exit code.
- Silent test-count drift being missed because only "all green" is checked, not the actual count: Mitigation — Step 5/6 require naming and counting the specific regression surfaces, not just an aggregate pass/fail.
