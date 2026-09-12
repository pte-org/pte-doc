# Phase 1: Design Tokens & Global Retheme (FR-01, FR-02, FR-03, FR-04)

## Requirements

Replace the legacy component-named palette and scattered dimensions with the
design system's semantic tokens. Apply the mapping to every real feature that
uses `AppColors`; do not hard-code a guessed feature count. Keep migration
aliases only until the later cleanup phase.

## Design Constraints

- Read `DESIGN.md`, `tokens.json`, `tokens.css`, `component-spec.md` and the
  Phase 0 mapping before editing values.
- Preserve distinct design roles: Material `primary=#004787`, component
  `brand.primary=#0B5FAE`, surfaces/borders/text/status/interactive values from
  the authoritative source. Never blanket-replace both roles with one color.
- `AppTypography` must expose the 10 application styles from `DESIGN.md`:
  `headline-lg`, `headline-md`, `instruction-bold`, `body-passage`,
  `body-regular`, `body-bold`, `timer-tabular`, `label-meta`, `label-bold`,
  `caption`. Arimo, line height, weight and letter spacing must match source.
- Arimo must be available offline for the exam build: add the approved font
  assets and `pubspec.yaml` declarations, or use an already-approved bundled
  package. Do not depend on Google Fonts/network at runtime.
- `AppDimensions` must preserve the product's generic `960px` content frame and
  the generated reading `1160px` workstation frame as separate constants.
  Header/footer and component dimensions are not replaced by a generic scale.
- No `ThemeExtension`, runtime feature flag or second palette.
- All direct `Color(0xFF...)` literals remain in `app_colors.dart` only.
- Do not modify API/state-layer files.

## Steps

1. Read the Phase 0 mapping and make a token table: semantic name, source file,
   hex/value, consuming component and screen reference.
2. Rewrite `lib/core/constants/app_colors.dart` with semantic roles from the
   design. Keep old names as `@Deprecated` aliases only where migration needs
   them; aliases must point to the mapped semantic token, never a new color.
3. Create `lib/core/constants/app_typography.dart` with the 10 application
   styles. Add generated component aliases only when a referenced screen needs
   a distinct token style, and record that mapping.
4. Refactor `lib/core/constants/app_dimensions.dart` to source-backed spacing,
   radius, border, shadow and component dimensions. Retain `contentMaxWidth`
   and `readingWorkstationMaxWidth` separately.
5. Grep the actual repository for `AppColors.*` usages and update every
   affected feature, including `device_check` and
   `exam_attempt/speaking_writing` where present. Do not assume `speaking` is
   a top-level feature.
6. Run `flutter analyze` after the token migration and record any baseline
   failures separately from new failures.
7. Render representative states for every affected feature and compare button,
   card, header, text, border and status colors with the design references.
   Record pass/fail per feature in the phase notes.

## Success Criteria

- [ ] Every used color maps to a semantic design token; both primary roles are
  present where required (`#004787` and `#0B5FAE`).
- [ ] `AppTypography` contains the 10 exact application styles from `DESIGN.md`.
- [ ] Generic content `960px` and reading workstation `1160px` are distinct and
  used by the appropriate screen family.
- [ ] No direct color literal exists outside `app_colors.dart`.
- [ ] Every real `AppColors` consumer has been migrated or has a documented
  compatibility alias.
- [ ] Visual check passes for every affected feature; no second palette exists.
- [ ] No API or state-layer file is changed.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook runs `/ck:quality --gate` after this
  phase. Checks token mapping, aliases, direct literals, file size and visual
  evidence.
- **Testing:** not started. Run focused token/widget tests plus the required
  affected-feature visual preview. Baseline failures remain explicitly listed.

## File Ownership

**Files exclusively owned by this phase:**

- `lib/core/constants/app_colors.dart`
- `lib/core/constants/app_typography.dart`
- `lib/core/constants/app_dimensions.dart`
- approved Arimo font assets and the corresponding `pubspec.yaml` declaration
- All files whose only change is replacing a legacy `AppColors` or
  `AppDimensions` reference.

**Files not modified by this phase:**

- `pte-api` source
- `TaskView`, `ExamAttemptBloc`, `TaskAnswerCubit`, `TimerService`,
  `LockdownService`, outbox serialization

## Cook State

- **Status:** completed.
- **Testing:** final analyze and full suite passed (`582` tests).
- **Quality:** token scan passed; raw semantic color literals remain centralized.
