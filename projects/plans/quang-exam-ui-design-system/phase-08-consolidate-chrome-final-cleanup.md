# Phase 8: Chrome Consolidation & Final Visual Conformance

## Goal

Finish task-specific chrome and run the full design-fidelity gate. Static UI
labels live in one typed configuration, while task-specific values come from
the runtime model or the offline fixture adapter.

## Design constraints

- `ExamChromeConfig` may own labels, formatting rules and stable accessibility
  text. It must not pretend that fixture `Ref`, checksum, engine version,
  scoring or skills are production facts.
- Dynamic metadata is supplied by a presentation adapter. When the API has not
  implemented a field, render an explicit `Not available` state or hide that
  optional region according to the design; never silently use sample data in a
  production exam.
- Keep the design roles recorded in Phase 0: Material `primary=#004787`,
  component `brand.primary=#0B5FAE`, header/footer `56px`,
  generic content `960px` and reading workstation `1160px`.
- Visual verification uses fixed viewport, DPR, scroll position, fixture id and
  interaction state. Direct references and the two derived fallback screens
  must be reported separately.

## Steps

1. Create `lib/core/constants/exam_chrome_config.dart` for stable labels,
   number/time formatting and unavailable-data labels. Keep fixture values in
   the preview catalog or adapter, not as default production metadata.
2. Update shell, sub-header, instruction/scoring regions and footer/chrome
   strip to consume the config plus the task UI model. Verify that every screen
   displays the regions present in its reference instead of a generic empty
   placeholder.
3. Run screenshot/golden checks for all 23 task types and required states:
   shell, hover/focus/disabled, selected/clear-selection, audio preparing/
   playing/finished, recording/upload, fill-blank variants, highlight normal/
   hover/active, editor empty/typing/limit/error/autosaved, and ordering
   initial/reordered.
4. Compare the 21 direct design references by family and record the two missing
   references (`SUMMARIZE_GROUP_DISCUSSION`, `RESPOND_TO_A_SITUATION`) as
   audio-prompt design-gap fallbacks. Do not call those two pixel-parity
   matches until design assets exist.
5. Verify semantic-token usage, content-width variants, header/footer geometry,
   complete screen regions, no accidental network dependency in preview, and
   no production fallback to fixture content.
6. Run analyzer/tests and review the diff. Clean only genuinely empty folders
   and remove temporary preview-only wiring that is not part of the agreed
   seam.

## Acceptance

- [ ] All 23 task screens render complete design-shaped UI through the shared
      shell and family templates; none ends in a blank response slot.
- [ ] 21 direct references pass the documented visual comparison; the 2 design
      gaps are explicitly listed as derived fallback coverage.
- [ ] No fake chrome metadata is shown as production truth when the API field is
      unavailable.
- [ ] `ExamChromeConfig` contains stable chrome labels/formatters only, and
      duplicated static labels are removed from feature widgets.
- [ ] `rg 'WRITE_ESSAY_V2' lib test` returns no runtime/dev fixture reference.
- [ ] Payload serialization, timer lifecycle, lockdown banner and upload
      auto-advance remain regression-free against Phase 0 baselines.
- [ ] `flutter analyze` has no new issue relative to the Phase 0 baseline; all
      pre-existing failures have a recorded disposition.
- [ ] Final report records viewport/DPR, source asset, fixture, state and diff
      result for each visual check.

## Quality and testing state

- **Quality gate:** run `/ck:quality --gate` after final implementation and
  resolve BLOCKER/HIGH/current-change MEDIUM findings.
- **Testing:** run visual/golden, widget, payload, timer/lifecycle and the full
  relevant Flutter suite. Use `/ck:test --all-phases` when all phases are done.

## File ownership

**Files exclusively owned by this phase:**

- `lib/core/constants/exam_chrome_config.dart`;
- final chrome adapters and visual verification artifacts;
- final conformance report.

**Files not modified by this phase:**

- `pte-api`;
- backend contracts and core attempt state machines.

## Cook State

- **Status:** completed.
- **Testing:** analyze clean, `582` tests passed, web build passed, and 23/23 browser smoke screens verified.
- **Quality:** final manual audit and diff checks passed; canonical 2560x2048 pixel parity remains documented as a runner limitation.
