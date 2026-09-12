# Spec: Exam UI Design System & Full Task Screen Refactor

**Date:** 2026-09-12  
**Status:** Ready for revised plan execution  
**Author:** quang  
**Design source:** `pte-doc/design/stitch-pte-exam-app`  
**Implementation target:** `pte-app`  
**Scope:** `lib/core/constants`, `lib/core/widgets`, `lib/features/exam_attempt`,
offline preview fixtures and visual verification

## Problem statement

The 23 exam task types are split by skill and contain duplicated choice lists,
header mappers, word-count widgets and two Essay implementations. The current
visual layer also diverges from the supplied design: shell geometry, palette,
typography, cards, interaction states and task-specific regions are incomplete.
The refactor must deliver complete design-shaped screens while preserving the
existing answer/state/API boundaries. `pte-api` is not ready for this UI work,
so preview and tests need a complete offline fixture seam.

## User stories

- **[P1]** As a candidate, I see the same persistent shell, task context, instruction,
  stimulus, response and navigation regions as the design for every task type.
- **[P1]** As a developer, I add a task by registering its family/template and typed UI
  model instead of duplicating a skill-specific screen.
- **[P1]** As a developer, I can preview all 23 task types offline without calling
  `pte-api` or depending on network media.
- **[P1]** As a maintainer, answer payloads, timer ownership, lockdown behavior and
  upload auto-advance remain compatible with the current implementation.

## Functional requirements

### Design tokens and geometry

1. **FR-01:** Implement semantic colors from the design bundle. Preserve the
   distinct roles `Material primary=#004787`, component `brand.primary=#0B5FAE`,
   surfaces, borders, text and status colors; do not blanket-replace one with
   the other.
2. **FR-02:** Add `AppTypography` with the 10 application styles from
   `DESIGN.md`: `headline-lg`, `headline-md`, `instruction-bold`,
   `body-passage`, `body-regular`, `body-bold`, `timer-tabular`, `label-meta`,
   `label-bold`, `caption`, using Arimo and the source metrics. Bundle Arimo or
   use an approved offline package; no runtime font download is allowed.
3. **FR-03:** Add semantic spacing/radius/dimension constants from the design
   sources. Header and footer are both `56px`, matching `DESIGN.md` and the
   valid canonical screen HTML; the generated `64px` token is retained only as
   a conflict note. Keep
   generic content `960px` and reading workstation `1160px` as separate roles.
4. **FR-04:** Keep old constants as temporary deprecated aliases during
   migration, then remove them after all consumers are migrated.

### Shell and reusable components

5. **FR-05:** Add an exam shell under `lib/core/widgets/exam/` containing the
   header, sub-header/task banner, instruction/scoring content, body region,
   footer/navigation and optional chrome strip required by each reference.
6. **FR-06:** Implement props-based reusable components for instruction cards,
   audio stimulus/player, choice rows/lists, fill-blank chips and selects,
   highlightable words, editor/metrics and sub-header metadata. Components
   expose all design states used by the screens.
7. **FR-07:** Core widgets do not read BLoC/Cubit/service state. Feature-level
   composition injects state, callbacks and timer snapshots.
8. **FR-08:** Replace duplicated reading/listening choice lists with one typed
   choice system supporting single and multiple selection.
9. **FR-09:** Replace duplicated task-header title mappers with one typed
   `TaskTypeMeta` registry.
10. **FR-10:** Replace duplicated word-count labels with one props-based widget
    that works for both writing and listening tasks.
11. **FR-11:** Footer renders `Save & Exit`, disabled `Previous` and `Next`
    without adding navigation state to `ExamAttemptBloc`.

### Templates and task coverage

12. **FR-12:** Implement seven family templates: record response (8), free
    text (4), single select (4), fill blanks (3), multi select (2), ordering
    (1) and token toggle (1).
13. **FR-13:** Use a data-oriented stimulus model that supports compound
    combinations such as audio + transcript + text. The template owns layout
    policy; a slot does not force every task into a two-column layout.
14. **FR-14:** Preserve record timing behavior through one authoritative timer
    snapshot/bridge. The display timer owns no independent `Timer.periodic`.
    Preserve immediate seed, `pinnedItemPublicId` stale-task guard, disposal and
    `AutoAdvanceOnUploadReady`.
15. **FR-15:** Replace the monolithic dispatcher with family registries and keep
    lifecycle routes separate.
16. **FR-16:** Route all 23 task types through the shell and one family template.
    Every screen includes all design-required regions and states; screen file
    size is a guideline for orchestration, not a visual acceptance substitute.
17. **FR-17:** Keep one canonical `WRITE_ESSAY` implementation and normalize all
    fixtures/routes away from `WRITE_ESSAY_V2`.
18. **FR-18:** Centralize stable chrome labels and formatting in
    `ExamChromeConfig`; task-specific metadata comes from the UI adapter or
    fixture. Missing API fields render as unavailable/hidden, never fake facts.
19. **FR-19:** Preserve design affordances such as A-/A+, clear selection,
    selected status, audio states, fill-blank states, highlight states, editor
    metrics and ordering states.
20. **FR-20:** Do not modify `ExamAttemptBloc`, answer cubits, timer service,
    lockdown service, outbox submit or the `pte-api` contract.
21. **FR-21:** Provide `ExamUiPreviewCatalog` with complete deterministic data
    for all 23 task types, local/resolved media references and no answer key or
    network requirement. Preview uses the same dispatcher as runtime.
22. **FR-22:** Define a presentation adapter seam from existing `TaskView` to a
    task UI model with data provenance (`api`, `fixture`, `derived`,
    `unavailable`). Production must not silently fall back to sample fixtures.
23. **FR-23:** Capture real serialized answer payloads before migration and
    compare action order, empty values, whitespace, trailing entries and media
    identifiers after migration byte-for-byte where the current contract
    requires it.

## Non-functional requirements

- **Visual fidelity:** compare each direct design reference at `2560x2048`, DPR
  1, scroll position `(0,0)`, with documented interaction states. A smaller
  runner uses a fixed documented scale transform. Report the two
  missing assets as derived fallbacks, not as pixel-parity passes. Structural
  dimensions and colors have zero unexplained diff tolerance; only renderer
  anti-aliasing may use the documented comparison tolerance.
- **Performance:** task transition remains within the existing 300ms target on
  the lowest supported exam machine; no new independent timer clock is added.
- **Correctness:** no answer or outbox regression; baseline payloads remain
  compatible.
- **Security:** lockdown and `ViolationWarningBanner` remain present in the
  exam shell.
- **Lifecycle:** preserve `AppResumed`, force-submit, answer-edit flush before
  advance, upload auto-advance and timer stale-task protection.
- **Maintainability:** shared components are props-based, controllers and
  subscriptions are disposed, and line-count limits are used as guidance for
  ownership rather than as the primary acceptance criterion.

## Success criteria

- [ ] 23/23 task types render complete screens through the shared shell and
      family templates using the offline catalog.
- [ ] 21 direct visual references are covered and the 2 design gaps are clearly
      marked as derived fallback coverage.
- [ ] Design contract preserves both primary roles, application typography,
      header/footer geometry and the 960/1160 width variants.
- [ ] No task screen ends with placeholder/empty stimulus or response content.
- [ ] Real payload baseline and analyze/test baseline are captured and compared.
- [ ] No API/state-layer contract is changed.
- [ ] Existing record lifecycle, stale-task protection, lockdown and upload
      auto-advance behavior are verified.

## Resolved design gaps and scope boundary

- `screens/12-read-aloud-*/screen.html` is an invalid Google sign-in capture;
  use the canonical `01-read-aloud-*` assets for Read Aloud. The `04` terms
  HTML is also invalid, but that pre-exam screen is out of this task scope.
- No direct design asset exists for `SUMMARIZE_GROUP_DISCUSSION` or
  `RESPOND_TO_A_SITUATION`; use the nearest audio-prompt pattern and document
  the gap. Exact pixel parity for those two waits for design assets.
- The 12 pre-exam/transition/completion screens, features outside
  `exam_attempt`, dark mode, backend changes and new task types are out of
  scope.
