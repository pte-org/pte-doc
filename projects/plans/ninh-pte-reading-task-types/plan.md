# Plan: 5 PTE Reading Task-Type Screens (pte-app + pte-api)

Status: 🟢 Completed
Date: 2026-07-28
Mode: Standard
Created by: Ninh
Target platform: Desktop (Windows primary), full-stack (Flutter client + Spring Boot backend)

## Overview

The exam-attempt flow in `pte-app` currently supports 3 task types end-to-end (`MC_READING_SINGLE`, `WRITE_ESSAY`, `READ_ALOUD`), each wired through `TaskTypeDispatcher` → a per-type Cubit/State/Screen → `TaskAdvanceButton` → `SyncEngine`/outbox (built by the `ninh-student-exam-flow` plan). The backend (`pte-api`) already defines 5 PTE Reading task types in `PteTaskType.java`, but the Flutter app only implements 1 of them.

This plan adds the other 4 PTE Reading UI screens (`MC_READING_MULTIPLE`, `RE_ORDER_PARAGRAPHS`, `FILL_BLANKS_READING`, `FILL_BLANKS_READING_WRITING`), following the visual style of reference screenshots (a blue-gradient header banner with a star icon + type title, timer top-right, passage + question/options) — fully integrated into the existing production architecture, not a static mockup. It also expands scope to the backend: `pte-api` DTOs, scoring evaluators, and seed data, so the full stack is genuinely usable end-to-end rather than the Flutter side outrunning a backend that can't yet serve or score these task types.

A note on prior art: `pte-app/plans/reading/plan.md` describes an earlier, unrelated "Reading R1-R4" implementation under `lib/features/reading/`/`lib/features/core_test/` (StatefulWidget + setState, no outbox/sync). That code no longer exists in the tree — it was part of the pre-pivot "Aptis" scaffold deleted outright in `ninh-student-exam-flow`'s Phase 0. It is not a dependency or reference for this plan.

## Phases

- [x] Phase 1: Backend Data Contracts & DTOs — `BlankGroupView` DTO, `TaskView`/`OptionView` updates, `OptionView.orderIndex` int→String refactor, `AttemptMapper` population [quality: approved (2 NOTED — QUAL-101 no authoring write-path for blankIndex yet, expected closed by Phase 8; QUAL-102 pre-existing FrozenOption duplication); testing: passed, 6/6]
- [x] Phase 2: Frontend Shared Model + Banner Infra + Dev Fixtures — `TaskOption`/`TaskView` model fix+extension, gap-marker parser, header banner, passage layout, dev-only fixture preview screen [quality: approved (1 NOTED — disclosed fixtures-location deviation); testing: passed, 206/206]
- [x] Phase 3: Frontend `MC_READING_MULTIPLE` — checkbox multi-select screen [quality: approved (0 findings); testing: passed, 214/214]
- [x] Phase 4: Frontend `RE_ORDER_PARAGRAPHS` — draggable paragraph reorder screen [quality: approved (1 NOTED — disclosed drag-gesture-test limitation); testing: passed, 220/220]
- [x] Phase 5: Frontend `FILL_BLANKS_READING` (drag & drop) — inline gap targets + word-bank chips [quality: approved (0 findings); testing: passed, 233/233, incl. real drag-gesture simulation]
- [x] Phase 6: Frontend `FILL_BLANKS_READING_WRITING` (dropdown) — inline per-gap dropdowns [quality: approved (1 NOTED — dead-end-state UX bug found and fixed, advance button now always present); testing: passed, 244/244]
- [x] Phase 7: Backend Payload Parsing & Scoring Engine — evaluators for all 4 new payload formats [quality: approved (1 NOTED — disclosed correctGapIndex schema addition); testing: passed, 19/19]
- [x] Phase 8: Backend Seed Data & Fixtures — realistic DB rows for local/dev end-to-end testing [quality: approved (2 NOTED — RE_ORDER_PARAGRAPHS delivery-order bug found+fixed, live-verification gap disclosed); testing: passed at unit level, 4/4; live integration deferred (Docker unavailable, see phase file)]

## The 5 task types → backend enum names

| # | UI name | Backend `taskType` | Status |
|---|---|---|---|
| 1 | Fill in the Blanks (Dropdown) | `FILL_BLANKS_READING_WRITING` | New (Phase 6) |
| 2 | Multiple Choice, Multiple Answers | `MC_READING_MULTIPLE` | New (Phase 3) |
| 3 | Re-order Paragraphs | `RE_ORDER_PARAGRAPHS` | New (Phase 4) |
| 4 | Fill in the Blanks (Drag & Drop) | `FILL_BLANKS_READING` | New (Phase 5) |
| 5 | Multiple Choice, Single Answer | `MC_READING_SINGLE` | Already implemented — gets a banner/passage-layout retrofit in Phase 2 |

## Research Summary

Decisions below were established via prior investigation, clarifying questions, and direct codebase/backend inspection:

1. **Full integration, not a mockup**: confirmed with the user — every new screen follows the existing production architecture (`TaskTypeDispatcher` → Cubit extending `TaskAnswerCubit<S>` → `TaskAdvanceButton` → `SyncEngine`/`AnswerOutboxDao`), the same pattern as `MC_READING_SINGLE`/`WRITE_ESSAY`/`READ_ALOUD`.
2. **`TaskView` model extension over `promptText` encoding tricks**: confirmed with the user — add new additive/nullable Dart-side fields (`BlankGroup`, `blankGroups`) rather than cramming per-blank option data into `promptText` itself.
3. **Pre-existing bug**: `TaskOption.fromJson` (`lib/features/exam_attempt/domain/task_view.dart:13`) casts `json['orderIndex'] as String`, but backend `OptionView.orderIndex` is a Java `int` (serializes as a JSON number) — this throws a runtime `TypeError` on any real response containing options. Fixed in Phase 2 (defensive `.toString()` client-side) and at the source in Phase 1 (`OptionView.orderIndex` refactored to `String`).
4. **Payload format** extends the existing "opaque decimal-string" convention (no JSON): `MC_READING_MULTIPLE` = comma-joined selected `orderIndex`, sorted ascending (`"0,2,3"`); `RE_ORDER_PARAGRAPHS` = comma-joined `orderIndex` in final chosen order, sequence = answer (`"2,0,3,1"`); both fill-blank types = positional comma-join, one entry per gap, empty entry for unanswered (including a required trailing empty entry, e.g. `"2,0,"` not `"2,0"`), sourced from the shared word bank (`FILL_BLANKS_READING`) or that gap's own `BlankGroup.options` (`FILL_BLANKS_READING_WRITING`).
5. **`options` field reuse**: the existing `List<TaskOption>? options` field is reused (not duplicated into 3 new fields) for `MC_READING_MULTIPLE` (checkboxes), `FILL_BLANKS_READING` (shared drag word bank), and `RE_ORDER_PARAGRAPHS` (shuffled paragraphs — `text` = paragraph body, `orderIndex` = stable correct-position identity, never current on-screen position). Only `FILL_BLANKS_READING_WRITING` needs a genuinely new field (`blankGroups`), since a flat list can't express "each blank has its own distinct option list."
5a. **Backend design revised during Phase 1 Preflight**: rather than a new parallel `blankGroupsJson` column threaded through every layer (`authoring`'s `SnapshotItem` → `AuthoringSnapshotContentResponse` → `PinnedItem`/`PinnedItemView` → `AttemptMapper`), investigation showed every one of those intermediate layers already treats `optionsJson` as an opaque string — only `SnapshotPublishService.serializeOptions` (write) and `AttemptMapper.parseOptions` (read) ever parse its structure. So `blankGroups` is carried by adding one nullable `blankIndex` field to the existing option shape (`QuestionOption.blankIndex`, nullable DB column) instead: `AttemptMapper` groups by `blankIndex` when present, and every intermediate DTO/entity needs zero changes. See Phase 1's own file for the full corrected design — this is the authoritative version, superseding any earlier description of a separate `blankGroupsJson` pipeline.
6. **Gap-marker convention**: `{{n}}` markers embedded in `promptText`, split by a shared `parseBlankPrompt` helper into alternating text/gap segments, rendered via `Text.rich`/`WidgetSpan` with `PlaceholderAlignment.middle` to avoid baseline offset.
7. **All 4 new cubits are discrete-selection style** (toggle/drop/reorder/select) — every one mirrors `McReadingSingleCubit` exactly (write to the outbox synchronously, `flushPendingEdit()` is an intentional no-op). None need `WriteEssayCubit`'s debounce style.
8. **Flutter built-ins only** for drag/drop/reorder/dropdown (`Draggable`, `DragTarget`, `ReorderableListView`, `DropdownButton`) — confirmed zero existing package and zero prior art in `pte-app`, no new pubspec dependency needed.
9. **Accessibility is required, not optional**: every new interactive widget gets a `Semantics` label reflecting current state (e.g. "Gap 1, empty" / "Gap 1, filled with 'mattered'"), since this is exam software — confirmed as a user-requested addition, not a default assumption.
10. **Fallback UI for missing backend content**: `FILL_BLANKS_READING_WRITING` renders the existing `StatusBanner` common widget instead of crashing/blank-screen when `task.blankGroups` is null/empty (e.g. before Phase 1/8 ship to a given environment) — a user-requested addition.
11. **Drag feedback + word-bank ordering stability**: `DragTarget`'s `builder` callback drives a hover-highlight color change while a candidate hovers; the word-bank `Wrap` always renders from `task.options`' original order filtered by current assignments (never a separately mutated/re-appended list), so an undone chip reappears at its original position, not the end — both user-requested additions after reviewing the initial design.
12. **Explicitly deferred**: a confirm-dialog gate on advancing past an incomplete fill-blank task was considered and rejected — real PTE Reading lets a student skip unanswered blanks within their self-managed time budget, and `TaskAdvanceButton` is a deliberately un-forked shared component reused unmodified by every task type.
13. **Backend scope expansion**: initially scoped Flutter-only, expanded per explicit user decision to include backend DTOs (Phase 1), scoring evaluators (Phase 7), and seed data (Phase 8) — see Phase 1/7/8 below.
14. **Rollout ordering / backward compatibility**: `pte-app` has no released production/store build as of this plan — Phase 1 (backend `OptionView.orderIndex` type change) and Phase 2 (frontend tolerant parsing) can therefore deploy freely without ordering constraints today. **This changes the moment a build is ever released to real users**: from that point on, Phase 1's backend change must never reach a production/staging environment before a Phase-2-equivalent tolerant Flutter client has been released and adopted, since an already-installed older client doing `json['orderIndex'] as int` would crash the instant the backend starts sending a JSON string. Re-confirm "has this app shipped yet?" before ever promoting Phase 1 past a local/dev environment.
15. **`QuestionOption.correctGapIndex` added during Phase 7 Preflight**: scoring `FILL_BLANKS_READING` (shared word bank) needs to know which specific gap each correct word belongs to, but its flat `correct: true/false` flag can't express that, and reusing `blankIndex` (Phase 1) for this would conflict with `AttemptMapper.requireHomogeneousBlankIndex`'s mixed-list guard. Resolved with one more nullable, scoring-only field (`correctGapIndex`, migration `V3__...`) that `AttemptMapper`/delivery never reads (Jackson ignores the unknown JSON key) — only `authoring`'s write side and `scoring`'s read side know about it. See Phase 7's own file for the full rationale.

## Dependencies

- `pte-app`'s existing exam-attempt architecture (`ninh-student-exam-flow` plan, completed 2026-07-26): `TaskTypeDispatcher`, `TaskAnswerCubit<S>`/`FlushableAnswerCubit`, `TaskAdvanceButton`, `SyncEngine`/`AnswerOutboxDao`, `ExamScaffold`/`ExamAppBar`, common widgets (`PrimaryButton`, `LoadingView`, `StatusBanner`, `showConfirmDialog`).
- `pte-api`'s `services/exam-delivery` (`TaskView`/`OptionView`/`AttemptMapper`/`SubmitAnswerRequest`), `services/authoring` (`PteTaskType` enum, already defines all 5 reading types), `services/scoring` (existing evaluator pattern for `MC_READING_SINGLE`/`WRITE_ESSAY`, to be mirrored for the 4 new types).
- No new Flutter pubspec dependencies (Flutter built-ins only for drag/drop/reorder/dropdown).
- No new backend dependencies expected (standard Spring Boot/Jackson/Flyway patterns already in use).

## Risks

- **MEDIUM**: `FILL_BLANKS_READING_WRITING` has no live backend content until Phase 1 (DTO) and Phase 8 (seed data) both ship — Phase 2's `StatusBanner` fallback and Phase 2's dev-fixture preview screen are the mitigation, so Phase 6's UI can be built and verified independently of backend timing.
- **MEDIUM**: `OptionView.orderIndex` int→String is a breaking backend contract change (Phase 1). Mitigated for the *new* Flutter client by Phase 2's `.toString()` normalization (tolerates both shapes); **not** mitigated for any already-released older client build. Per Research Summary item 14, this is a live constraint only once `pte-app` ships to real users — not yet applicable, but must be re-checked before any future production rollout of Phase 1.
- **LOW**: Backend scoring formulas (Phase 7 — negative marking for `MC_READING_MULTIPLE`, adjacent-pair credit for `RE_ORDER_PARAGRAPHS`) are specified in this plan at the level of PTE's public scoring guidance; the actual `scoring` service's existing evaluator interface for `MC_READING_SINGLE` should be read first during Phase 7 implementation so the 4 new evaluators match its established shape rather than introducing a parallel convention.
- **LOW (found by Phase 1's quality gate, QUAL-101)**: `QuestionOption.blankIndex` is fully wired through the delivery pipeline (serialize → snapshot → mapper → `TaskView.blankGroups`), but no reachable write path exists anywhere in `authoring`'s current public API (`OptionRequest`, `QuestionService.addOptions`, `QuestionValidationHelper`) to actually set it from a real authoring request. Phase 8's seed data closes this gap for local/dev verification by writing `blankIndex` directly at the `Question`/`QuestionOption` layer; a real authoring-tool UI/API for creating `FILL_BLANKS_READING_WRITING` content remains a future follow-up beyond this plan's scope, not something Phase 1-8 need to solve.
- **LOW**: No passage/question field split exists on the backend — `promptText` is rendered as one flowing block for all 5 types across every phase in this plan. A future passage/question visual split would need a further backend DTO field; out of scope here, noted for awareness only.
