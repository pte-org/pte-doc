# Plan: Exam UI Design System & Full Task Screen Refactor

**Status:** Cook implementation complete; final verification recorded  
**Date:** 2026-09-12  
**Mode:** Hard  
**Author:** quang  
**Implementation target:** `D:\GitHub\pte-org\pte-app`  
**Design source:** `D:\GitHub\pte-org\pte-doc\design\stitch-pte-exam-app`

---

## Objective

Refactor the 23 existing exam task screens around interaction families while
preserving answer behavior and the existing state/API boundaries. Every task
screen must render a complete UI matching its design reference: persistent
exam chrome, task metadata, instruction/scoring blocks, stimulus, response
interaction, status/help content, and fixed navigation chrome where shown.

`pte-api` is not a prerequisite. Runtime screens continue to receive the
existing `TaskView` and injected services. A local preview catalog supplies
complete content and interaction states until the API is available. No fake API
client or API contract change is part of this work.

---

## Design Authority (locked)

The design bundle contains several complementary authorities:

1. Each task's `screen.png` and `screen.html` define the visible composition
   and interaction states.
2. `pte-doc/design/stitch-pte-exam-app/DESIGN.md` defines the product-level
   Material semantic roles, application typography and fixed-frame rules.
3. `pte-doc/design/stitch-pte-exam-app/screens/36-*/tokens.json` and
   `screens/37-*/tokens.css` define generated component semantic tokens.
4. `pte-doc/design/stitch-pte-exam-app/screens/35-*/component-spec.md` defines
   component behavior and variants.

The old plan is corrected by recording a mapping instead of flattening these
sources into one global `primary` or one global radius. The implementation must
keep distinct semantic roles where the design has distinct values:

- Material `primary` is `#004787`; `primary-container` and component
  `brand.primary` are `#0B5FAE`. A CTA/active state uses the token named by its
  reference screen, never a blanket search-and-replace.
- Header and footer are both locked to `56px`, matching `DESIGN.md` and the
  valid canonical screen HTML. The generated `64px` footer token is retained
  only as a conflict note and must not be used by the exam shell.
- The generated reading workstation token is `1160px`; the root design prose
  gives `960px` for the generic assessment content. Keep both roles: use
  `contentMaxWidth=960px` for compact screens and
  `readingWorkstationMaxWidth=1160px` for wide reading/passage screens.
- `AppTypography` must expose the 10 application styles from `DESIGN.md` and
  may expose generated component aliases only when a screen reference needs
  them. Every style's family, size, line height, weight and letter spacing must
  be copied from a design source, never invented.
- Spacing, radius, border width and shadow values come from the source that
  defines the component; radius must not be globally expanded beyond the
  product rule without a screen-level reference.

---

## Screen Coverage (23 task types)

| Family/template | Task types | Design reference |
|---|---|---|
| Record response | `PERSONAL_INTRODUCTION` | `11-personal-introduction-*` |
| Record response | `READ_ALOUD` | `01-read-aloud-*` (canonical; `12-read-aloud-*` is corrupted) |
| Record response | `REPEAT_SENTENCE` | `13-repeat-sentence-*` |
| Record response | `DESCRIBE_IMAGE` | `14-describe-image-*` |
| Record response | `RE_TELL_LECTURE` | `15-re-tell-lecture-*` |
| Record response | `ANSWER_SHORT_QUESTION` | `16-answer-short-question-*` |
| Record response | `SUMMARIZE_GROUP_DISCUSSION` | No direct asset; approved audio-prompt fallback |
| Record response | `RESPOND_TO_A_SITUATION` | No direct asset; approved audio-prompt fallback |
| Free text | `SUMMARIZE_WRITTEN_TEXT` | `17-summarize-written-text-*` |
| Free text | `WRITE_ESSAY` | `18-write-essay-*` |
| Free text | `SUMMARIZE_SPOKEN_TEXT` | `26-summarize-spoken-text-*` |
| Free text | `WRITE_FROM_DICTATION` | `33-write-from-dictation-listening-*` |
| Fill blanks | `FILL_BLANKS_READING_WRITING` | `20-reading-writing-fill-in-the-blanks-*` |
| Multi-select | `MC_READING_MULTIPLE` | `21-multiple-choice-multiple-answer-*` |
| Ordering | `RE_ORDER_PARAGRAPHS` | `22-re-order-paragraphs-*` |
| Fill blanks | `FILL_BLANKS_READING` | `23-reading-fill-in-the-blanks-*` |
| Single select | `MC_READING_SINGLE` | `24-multiple-choice-single-answer-*` |
| Multi-select | `MC_LISTENING_MULTIPLE` | `27-multiple-choice-multiple-answer-listening-*` |
| Fill blanks | `FILL_BLANKS_LISTENING` | `28-fill-in-the-blanks-listening-*` |
| Single select | `HIGHLIGHT_CORRECT_SUMMARY` | `29-highlight-correct-summary-*` |
| Single select | `MC_LISTENING_SINGLE` | `30-multiple-choice-single-answer-listening-*` |
| Single select | `SELECT_MISSING_WORD` | `31-select-missing-word-listening-*` |
| Token toggle | `HIGHLIGHT_INCORRECT_WORDS` | `32-highlight-incorrect-words-listening-*` |

The table intentionally records the two missing design assets. Their fallback
must reuse the same audio-prompt response pattern and exact design tokens; it
must not introduce an unreviewed visual language. Phase 0 owns the canonical
matrix and corrects this table if the design team supplies the missing assets.
These derived fallbacks are accepted in scope as complete usable screens; they
must not be reported as pixel-parity matches until direct assets exist.

---

## Architecture Decisions

1. **Semantic static tokens:** keep `AppColors`, `AppTypography`, and
   `AppDimensions` as static classes. Names map to design semantics (`brand*`,
   `surface*`, `border*`, `text*`, `status*`, `interactive*`), not screen names.
2. **Design-first component system:** components are props-based and own no
   Cubit/BLoC. `RecordResponseTemplate` may own subscription lifecycle, but
   receives an injected timer stream/bridge; the feature layer owns the
   `ExamAttemptBloc` read and the `pinnedItemPublicId` guard.
3. **Template families:** seven templates own composition; screens only map
   `TaskView` state to `StimulusSlot` and response widgets.
4. **Full-screen composition:** templates compose the complete mockup regions,
   not merely a two-column body. A two-column body is used only where the
   reference screen uses it.
5. **API-independent preview:** preview fixtures use the existing `TaskView`
   and answer cubits where possible. No API client, backend model, or state
   machine is invented to make the screen render.
6. **State boundary:** do not modify `ExamAttemptBloc`, `TaskAnswerCubit`,
   `TimerService`, `LockdownService`, answer serialization, or outbox behavior.
7. **Recording safety:** preserve `AutoRecordCubit`,
   `AutoAdvanceOnUploadReady`, and the `pinnedItemPublicId` guard. The feature
   layer owns bloc wiring; the record template owns only injected subscription
   lifecycle and is disposed safely.
8. **Strangler migration:** old screens remain for comparison until Phase 7.
   No legacy screen/widget deletion occurs in Phase 2 or migration phases.
9. **Payload baseline:** capture current serialized answers before migration;
   every migrate phase must diff its family against that baseline.
10. **Visual gate:** each family phase must render all of its task screens in
    the preview catalog and compare the important states against its design
    reference before completion.

---

## Phases

- [ ] **Phase 0 — Design Contract, Offline Preview & Baseline**
  - coverage matrix, design contract, 23-task fixture catalog, baseline payload,
    baseline analyze/test report
- [ ] **Phase 1 — Design Tokens & Global Retheme**
  - exact colors, typography, dimensions and all affected feature usages
- [ ] **Phase 2 — Complete Exam Chrome & Shared Components**
  - header/footer, task banner, instruction/scoring blocks, stimulus players,
    response primitives, registry and props-only enforcement
- [ ] **Phase 3 — Migrate Single-Select Screens**
  - 4 screens, `StimulusSlot`, choice interaction and design states
- [ ] **Phase 4 — Migrate Record-Audio Screens**
  - 8 screens, timer bridge, recording/upload states and auto-advance
- [ ] **Phase 5 — Migrate Free-Text Screens**
  - 4 screens, editor toolbar, live metrics, limits and validation states
- [ ] **Phase 6 — Migrate Remaining Interaction Families**
  - fill blanks, multi-select, ordering and token toggle; 7 screens
- [ ] **Phase 7 — Dispatcher Registry & Legacy Cleanup**
  - 7 family dispatchers, root dispatcher and deletion of superseded files
- [ ] **Phase 8 — Chrome Consolidation & Final Visual Conformance**
  - static chrome registry, final grep/analyze/test/visual verification

Dependencies are strictly linear: a phase may not activate until the previous
phase's success criteria and selected checks are recorded.

---

## Quality and Testing Policy

- Cook mode: `Hard`.
- Unit tests: yes by default; migration phases must add/run focused behavior
  tests for their interaction and payload seam.
- Quality gate: yes by default; `/ck:quality --gate` checks design fidelity,
  architecture, file ownership and repository conventions.
- TDD is not required for pure screen migration. The test must still run after
  each migration family, not only at the end.
- Visual verification is mandatory even when automated tests pass. Use the
  local PNG/HTML reference, preview fixture, fixed desktop viewport and record
  the result per screen in the phase notes. The canonical visual comparison is
  `2560x2048`, DPR 1, scroll position `(0,0)`; any smaller runner must apply a
  documented fixed scale transform.
- Existing baseline failures are recorded and assigned in Phase 0. They may be
  present during intermediate migration gates only; all blockers must be fixed
  before Phase 8 and no silent skip is allowed.

---

## Cross-Phase Acceptance Criteria

- [ ] Every design color/type/spacing/radius/height used by exam UI maps to the
  authoritative design files and the mapping is recorded in Phase 0.
- [ ] Both design primary roles are preserved: Material `primary=#004787` and
  component `brand.primary=#0B5FAE`; no old palette remains outside token aliases.
- [ ] Persistent header and footer are `56px`; generic content max-width is
  `960px` and reading
  workstation max-width is `1160px` where the reference uses it.
- [ ] 23/23 task types render complete screens through the preview catalog;
  no task ends at a placeholder, empty response slot or missing chrome region.
- [ ] Each of the 21 direct references has visual verification; the 2 design
  gaps have explicit fallback verification and are not presented as pixel
  parity until assets exist.
- [ ] Visual checks use exact colors and structural dimensions; unexplained
  screenshot differences have zero tolerance. Only renderer anti-aliasing may
  use the documented fixed comparison tolerance.
- [ ] Answer payload serialization is byte-for-byte unchanged for all 23 task
  types compared with Phase 0 baseline.
- [ ] `Color(0xFF...)` literals occur only in `app_colors.dart` and match design.
- [ ] Shared components are props-based; no file under `lib/core/widgets` reads
  an exam bloc. Record timer wiring lives at the feature boundary and is
  injected into the template.
- [ ] No production API/state-layer changes are introduced.
- [ ] No newly introduced Dart file in scope exceeds 300 lines and no newly
  migrated screen exceeds 80 lines unless the phase notes document an
  approved exception. Existing state-layer files remain outside this cleanup
  because the refactor explicitly preserves API/state ownership.
- [ ] `flutter analyze` has 0 errors and 0 warnings at final phase.
- [ ] `flutter test` passes at final phase. A baseline failure may be tolerated
  only during intermediate phases; it must be fixed before Phase 8 or the plan
  remains incomplete (no final pass is claimed under a silent waiver).
- [ ] No empty `lib/core/widgets` directory remains.

---

## Known Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Timer bridge receives the next task's first snapshot | Preserve `pinnedItemPublicId` guard and test consecutive task replacement |
| API is unavailable | Use `ExamUiPreviewCatalog` with complete `TaskView` fixtures; keep runtime constructor API-free |
| Visual drift hidden by passing unit tests | Mandatory fixed-viewport screenshot review per task/family |
| Design bundle lacks 2 task screenshots | Record explicit fallback pattern in coverage matrix; do not claim direct parity |
| Existing baseline analyze/test failures | Capture and classify in Phase 0; fix blockers before final gate |
| Legacy deletion breaks imports | Delete only in Phase 7, after a clean analyze with new dispatchers |
| Payload changes during screen extraction | Snapshot before migration and diff after every family |

---

## Out of Scope

- Implementing or changing `pte-api`.
- Changing `TaskView` shape or server payload contracts.
- Modifying exam state machines, timers, lockdown, outbox or answer scoring.
- Non-task pre-exam/transition/completion screens; they will consume this common
  layer in a later plan.
- Dark mode and responsive narrow layout; exam delivery is fullscreen desktop.

---

## Cook Handoff

After the user approves the revised plan and Phase 0 preflight is ready, run:

```text
/ck:cook --hard --tests --quality --checks-all-phases --plan D:\GitHub\pte-org\pte-doc\projects\plans\quang-exam-ui-design-system\plan.md
```

Do not delete legacy files or alter API/state-layer code while executing Phase 0
through Phase 6. Final code review is required after the final quality/test
reports are current.

---

## Cook Result (2026-09-12)

Implementation is complete for the revised scope. The shared semantic tokens,
exam chrome, seven template families, runtime screen adapters and the complete
offline 23-entry preview catalog are implemented in `pte-app`. The preview is
visual-only and uses deterministic fixtures; it does not call `pte-api`, open a
microphone, create an outbox row or submit an answer.

Verification recorded in `visual-conformance-report.md`:

- `flutter analyze`: clean.
- `flutter test`: 582 tests passed.
- `flutter build web --release -t lib/dev/exam_ui_preview_main.dart`: passed.
- Browser smoke: all 23 catalog entries opened and advanced; 23/23 screenshots
  had unique hashes at viewport `1280x800`, DPR 1.
- Quality checks: no core-widget BLoC imports, no raw color literals outside
  `app_colors.dart`, no legacy `WRITE_ESSAY_V2`/reading-passage identifiers,
  and no newly introduced in-scope file over 300 lines.

The canonical design comparison remains `2560x2048`; the available browser
runner used the documented fixed `1280x800` scale. The two task types without
direct design assets remain explicitly classified as derived audio-prompt
fallbacks and are not claimed as direct pixel-parity matches.

Final source recheck after the preview tokenization fix repeated analyze,
focused preview tests, the full test suite, the Web release build and the
23-screen browser smoke successfully.
