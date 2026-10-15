# Brainstorm: Tenant Exam detail actions and Questions tab

**Date:** 2026-10-08
**Related plan:** `projects/plans/quang-tenant-exam-ui-decomposition/`
**Status:** Direction approved by user; ready for planning

## Ideas Explored

### 1. Keep the current header action rail

This keeps the fewest structural changes, but the header remains visually crowded because
the exam status and three lifecycle/view actions compete for attention.

### 2. Move status and lifecycle actions into Overview

The header becomes a context bar containing only navigation and identity. Overview becomes
the place for status, schedule, capacity, policy, and state-dependent actions. This makes
the lifecycle model easier to understand and keeps destructive actions near their context.

### 3. Turn View Exam into a dedicated Questions tab

The exam's questions are important enough to deserve a first-class task tab. The tab should
show the immutable generated snapshot through the existing preview contract, grouped by
section/task type, with local loading, empty, error, and preview states.

### 4. Put question editing in the tenant Exam detail screen

This would make the tab more powerful, but it would mix authoring with a generated exam
snapshot and create new ownership, validation, and mutation risks. It is rejected for this
refinement; authoring remains in the Vendor workflow before exam creation.

### 5. Keep all seven tabs visible without responsive handling

This is simple on desktop but creates overflow and poor discoverability on narrow screens.
The accepted direction keeps the seven task tabs keyboard accessible and horizontally
scrollable without introducing page-level horizontal overflow.

## User's Direction

The user approved:

- status belongs in the Exam overview rather than beside the header buttons;
- `Open Exam` and `Cancel Exam` belong in the overview lifecycle area;
- `View Exam` should become a dedicated tab for viewing the exam questions;
- the question surface is a read-only preview of the generated exam snapshot;
- question editing remains outside this tenant detail screen.

## Accepted IA

1. `Tổng quan` / `Overview`
2. `Câu hỏi` / `Questions`
3. `Cài đặt kỳ thi` / `Exam settings`
4. `Người dự thi & coi thi` / `Participants & proctors`
5. `Bài nộp` / `Submissions`
6. `Examiner`
7. `Kết quả & phát hành` / `Results & publication`

The header keeps exam identity, back navigation, and a compact overflow menu. The
Overview tab owns the status card and state-valid lifecycle actions. The Questions tab
owns preview navigation and question grouping, not editing.

## Open Questions

No blocking clarification remains for planning. The implementation plan should confirm the
existing preview query/component owner before moving its presentation from Overview.

## Risks

- Seven tabs may need horizontal scrolling and accessible overflow behavior on narrow screens.
- Moving lifecycle buttons must preserve status guards, confirmation dialogs, mutation owners,
  and disabled states exactly.
- Moving preview content must not expose answer keys or turn an immutable generated snapshot
  into a live question-bank editor.

