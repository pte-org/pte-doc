# Phase 2: Frontend Shared Model + Banner Infra + Dev Fixtures

## Requirements

Fix the pre-existing `TaskOption.fromJson` type bug, extend `TaskView` with the additive `BlankGroup`/`blankGroups` model, build the shared gap-marker text parser and the visual infrastructure (header banner, passage layout) every one of the 4 new screens will use, and add a `kDebugMode`-gated dev-fixture preview screen so the remaining phases (and manual QA) don't depend on backend/authoring content being ready. Also retrofits `MC_READING_SINGLE` with the new banner/passage layout for visual consistency across all 5 reading types.

Maps to: unblocks Frontend Phases 3-6, each of which builds one new task-type screen on top of this infrastructure.

## Design Constraints

- `TaskOption.fromJson`'s `orderIndex` parsing must accept both a JSON string and a JSON number (`json['orderIndex'].toString()`), tolerating both the pre-Phase-1 backend shape and the post-Phase-1 shape — this is what makes Phase 1's backend change safe to land in any order relative to this phase. Comment it as transitional per `plan.md`'s Research Summary item 14: `// Safely handles both String and legacy int until BE rollout is complete.`
- `BlankGroup`/`blankGroups` on `TaskView` are additive and nullable — parsing must not throw when a backend response omits `blankGroups` entirely (every task type except `FILL_BLANKS_READING_WRITING`, and even that type until Phase 1/8 ship to a given environment).
- The existing `List<TaskOption>? options` field is reused (not duplicated) by later phases for `MC_READING_MULTIPLE`/`FILL_BLANKS_READING`/`RE_ORDER_PARAGRAPHS` — this phase doesn't need to touch `options` itself, only document on the field/class that `orderIndex` is stable *identity*, never on-screen position, since Phase 4 depends on that distinction being unambiguous later.
- `parseBlankPrompt` must fail open: a malformed or out-of-range `{{n}}` marker degrades to literal text, never throws — a bad authoring payload should degrade visually, not crash the task screen.
- Every `WidgetSpan` a later phase builds around a gap widget must use `PlaceholderAlignment.middle` (or `.baseline` + explicit `TextBaseline.alphabetic`) — call this out here since it applies to Phases 5 and 6 equally and is easy to get wrong independently in both.
- `ReadingTaskHeaderBanner` is an *addition* inside each screen's `ExamScaffold.body`, never a replacement for `ExamAppBar` — the existing timer/phase/force-submit chrome from `ninh-student-exam-flow` Phase 4 stays untouched.
- `ReadingTaskPreviewScreen` and its `main.dart` route must be reachable only behind `kDebugMode` — never compiled into a release build's navigable UI.
- New `AppStrings`/`AppColors`/`AppDimensions` constants follow the existing `private-constructor + static const` convention exactly — no inline literals in any new widget.

## Steps

1. Fix `TaskOption.fromJson` in `lib/features/exam_attempt/domain/task_view.dart`: `orderIndex: json['orderIndex'].toString()`.
2. Add `BlankGroup` class (`{blankIndex: int, options: List<TaskOption>}`, with `fromJson`) to `task_view.dart`, and `final List<BlankGroup>? blankGroups` to `TaskView` + its `fromJson`.
3. Create `lib/features/exam_attempt/domain/blank_prompt_parser.dart`: `PromptSegment` sealed class (`PromptTextSegment`, `PromptGapSegment`), `List<PromptSegment> parseBlankPrompt(String promptText)` splitting on `{{n}}` markers.
4. Create `lib/features/exam_attempt/presentation/widgets/reading_task_header_banner.dart`: `ReadingTaskHeaderBanner({required title})` — gradient container + star icon + text.
5. Create `lib/features/exam_attempt/presentation/widgets/reading_task_header_labels.dart`: `String readingTaskHeaderTitle(String taskType)`, a `switch` over all 5 reading `taskType` values mapping to new `AppStrings` entries.
6. Create `lib/features/exam_attempt/presentation/widgets/reading_passage_layout.dart`: `ReadingPassageLayout({required passage, required interactive})` — side-by-side above a new `AppDimensions.readingPassageLayoutBreakpoint`, stacked below it.
7. Add new constants: `AppStrings` (5× `readingHeaderTitle*`, `fillBlanksWordBankSectionLabel`, `fillBlanksGapPlaceholder`, `reorderParagraphsHintLabel`, `fillBlanksContentUnavailableTitle`/`Message`), `AppColors` (`readingHeaderGradientStart/End`, `fillBlanksGapEmptyBorder`, `fillBlanksGapFilledBackground`, `dragChipBackground`, `dragTargetHoverBackground`), `AppDimensions` (`readingHeaderBannerRadius/PaddingVertical/PaddingHorizontal`, `readingHeaderStarIconSize`, `readingHeaderTitleFontSize`, `readingPassageLayoutBreakpoint`, `fillBlanksGapMinWidth/Padding`, `dragChipPadding/Spacing`).
8. Retrofit `lib/features/exam_attempt/presentation/pages/mc_reading_single_screen.dart`: wrap its body in `ReadingTaskHeaderBanner` + `ReadingPassageLayout(passage: Text(task.promptText ?? ''), interactive: McOptionList(...))` — first real `promptText` rendering for this screen.
9. Create `test/fixtures/reading_task_fixtures.dart`: one hand-built `TaskView` sample per new task type (realistic `promptText` with gap markers, `options`, and `blankGroups` where applicable), shared by this phase's and later phases' widget tests.
10. Create `lib/features/exam_attempt/dev/reading_task_preview_screen.dart`: a `kDebugMode`-gated screen listing the 5 fixtures, rendering the picked one through the real `TaskTypeDispatcher`.
11. Wire a `kDebugMode`-gated route to the preview screen in `main.dart`.
12. Test: `blank_prompt_parser_test.dart` — no-marker, multi-marker, malformed-marker, edge-of-string cases.
13. Test: `task_view_test.dart` — `orderIndex` accepts both `int` and `String` JSON and normalizes to `String`; `BlankGroup.fromJson` round-trip.
14. Test: `reading_task_header_banner_test.dart` — renders given title text and a star icon.
15. Test: extend/add an `mc_reading_single_screen` widget test — banner renders with the correct label, passage text renders when `promptText` is non-null, existing selection behavior unchanged.

## Success Criteria

- [x] `TaskOption.fromJson` no longer throws on a real backend response containing options (accepts both int and string `orderIndex`).
- [x] `TaskView.blankGroups` parses as `null` when absent from JSON, and correctly when present.
- [x] `parseBlankPrompt` never throws on malformed input — verified by an explicit test case.
- [x] `ReadingTaskHeaderBanner`/`ReadingPassageLayout` render correctly in isolation and inside the retrofitted `MC_READING_SINGLE` screen.
- [x] `ReadingTaskPreviewScreen` is unreachable outside `kDebugMode` (route only registered when `kDebugMode` is true in `main.dart`).
- [x] No new literal strings/colors/dimensions outside `AppStrings`/`AppColors`/`AppDimensions`.
- [x] `flutter analyze` and `flutter test` both pass with zero new issues (206/206 passing, up from 187).

**Deviation from the original Steps list**: `test/fixtures/reading_task_fixtures.dart` (Step 9) was relocated to `lib/features/exam_attempt/dev/reading_task_fixtures.dart` during implementation — a `lib/` file (the dev preview screen) cannot import from `test/`, so the canonical fixture source had to live in `lib/` for both the preview screen and later widget tests to share it via a normal package import. This is a corrected file location, not a scope change; the "share one canonical fixture source" intent from Design Decision 12 is preserved.

## Quality and Testing State

- Quality gate: approved (0 blocking findings; 1 NOTED — QUAL-201, the disclosed fixtures-location deviation, resolved). Report: `pte-app/plans/ninh-pte-reading-task-types/quality/phase-02-frontend-shared-model-banner-quality-report.json`. Receipt issued.
- Testing: PASSED — 19/19 new tests (7 `blank_prompt_parser_test.dart`, 6 `task_view_test.dart`, 1 `reading_task_header_banner_test.dart`, 4 `mc_reading_single_screen_test.dart` — added since no widget test previously existed for this screen, mirroring `write_essay_screen_test.dart`'s `BlocProvider<ExamAttemptBloc>` wrapping convention). Full suite: 206/206 passing (up from 187 before this phase), confirming zero regression to `MC_READING_SINGLE`'s existing behavior.

## Risks

- **LOW**: this phase touches `mc_reading_single_screen.dart`, the one already-shipped screen — its existing widget tests must still pass unchanged after the retrofit, or this phase has introduced a regression in already-working functionality.
