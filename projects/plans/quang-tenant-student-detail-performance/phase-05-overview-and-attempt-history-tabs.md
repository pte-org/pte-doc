# Phase 05: Overview and attempt history tabs

**Status:** Implemented; tenant-web typecheck/build passed; manual UI review pending
**Surface:** `pte-web/apps/tenant-web`
**Depends on:** Phase 04 route/account shell and Phase 03 query state
**Blocks:** Final quality handoff

## Goal

Render the server-owned performance summary and paginated attempt history in the approved student workspace without duplicating scoring logic or creating a request waterfall.

## Work items

1. Build the `Tổng quan` tab with attempt-count, average-overall, and latest-attempt KPI cards.
2. Render four skill summaries for Listening, Reading, Speaking, and Writing using the existing progress/chart primitives and Recharts wrapper.
3. Provide explicit unavailable/insufficient/no-data states and explanatory copy.
4. Add a compact recent-attempt table using the existing `DataTable` or established tenant table pattern.
5. Build the `Lịch sử làm bài` tab with server pagination, date/status filters, loading/empty/error states, and stable page state.
6. Link an attempt row to an existing report detail only when the API says the report is available to the current actor; do not fabricate a report for an unavailable row.
7. Add responsive behavior for skill cards, KPI blocks, table columns, and long session names.
8. Verify the page does not refetch independent account data unnecessarily when switching tabs, while still refreshing after relevant mutations.
9. Add focused request instrumentation/assertions to verify the data layer does not issue one report request per visible attempt row.

## Overview display rules

- `attemptCount` is server-provided within the declared scope.
- `averageOverall` is displayed only when the server marks it valid/sufficient and it was calculated from a published immutable report; otherwise show an explicit unavailable state.
- Per-skill values use the server's sample count and sufficiency state from published immutable reports.
- A skill with no tested data is not shown as `0`.
- Unpublished/live reports may appear in history as report state, but their scores are not included in official overview averages.
- The latest-attempt card links to the attempt report only when permitted and available.

## History display rules

- Pagination and filters are encoded in the API request.
- Date/status filters use the backend's accepted format and timezone semantics.
- Do not render a program dropdown in the student detail workspace for V1. Program filtering remains a responsibility of the student roster; future detail analytics may add program context only after a reliable historical relationship is approved.
- Do not derive historical program context from the student's current membership, and do not duplicate the roster's program filter inside the detail workspace.
- Empty history, no matching filters, forbidden, and API failure are distinct states.
- History rows show lifecycle/report states even when no published score exists.
- The table is a summary surface; full report details are loaded only on explicit navigation.

## Design Constraints

- Do not calculate official averages in React from the history response.
- Do not convert missing/untested score data to zero.
- Do not call the report endpoint per row.
- Do not add a new charting dependency; reuse Recharts already installed and the existing wrapper.
- Reuse `StatCard`, `ProgressBar`, `StatusBadge`, `DataTable`, pagination, and existing tokens.
- Keep filters server-owned and page size bounded.
- Detail history does not infer historical program from current membership and does not add a program snapshot/migration solely for this V1 workspace.
- Preserve independent tab loading/error states so a history failure does not hide account information.

## Quality and Testing State

Implementation evidence: tenant-web `tsc --noEmit` and production build passed. The following planned checks were skipped or remain pending by explicit user request:

- component tests for KPI/skill/empty/insufficient/report-unavailable states;
- history filter/pagination request tests;
- focused component/request checks for tab data, filters, pagination, chart states, no-data, and error states;
- network assertion or request instrumentation showing no per-row report fan-out;
- tenant-web lint, typecheck, build, and manual UI inspection by the user at supported widths/themes.

## Blocking gate

Phase 06 cannot start until overview and history render the final API contract and focused checks cover request behavior; manual UI review is handed to the user.

## Acceptance criteria

- Overview values and skill states match the backend response semantics.
- History filters change the server request and results without client-side full-list filtering.
- Pagination works for empty, first, middle, and last pages.
- Attempt detail navigation is permission-aware.
- The page remains readable with long Vietnamese labels and in light/dark themes.
- Detail history has no duplicate program selector in V1; program filtering on the student roster remains unchanged.
