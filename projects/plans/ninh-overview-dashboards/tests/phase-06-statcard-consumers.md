# Phase 6 regression reference (recorded 2026-10-13, BEFORE any @pte/ui change)

No git is used. Integrity is checked by SHA256 + LastWriteTime of the files below.

## StatCard consumers (6 files, 18 usages) - current props used

None of the existing usages passes any of the new delta/tone/comparison props; all keep the current behaviour.

| File (relative to pte-web) | Usages | Props used |
|---|---|---|
| apps/tenant-web/features/examStaff/detail/proctor/ProctorOverview.tsx | 1 (in map) | `key, label, value` |
| apps/tenant-web/features/examStaff/detail/examiner/ExaminerOverview.tsx | 1 (in map) | `key, label, value` |
| apps/tenant-web/features/studentDetail/components/StudentOverviewTab.tsx | 3 | `label, value` / `label, value, compact, footnote` / `label, value, compact` |
| apps/vendor-web/features/dashboard/components/_AdminStatGrid.tsx | 3 | `label, value, trend, progress, icon` / `+ trendPositive` / `label, value, footnote, trend, progress, highlight, icon` |
| apps/vendor-web/features/licensing/components/_LicenseStatGrid.tsx | 4 | `label, value, icon` (one with `highlight`) |
| apps/vendor-web/features/questionbank/components/_QuestionStatGrid.tsx | 6 | `compact, label, value, icon` + `trend` (1) or `footnote` (5) |

Also relevant for the donut extraction (StatusDonutChart consumers include ProctorOverview.tsx and ExaminerOverview.tsx above; other consumers not enumerated here, API kept identical).

## BEFORE hashes (SHA256) and last-write times

| File | SHA256 | LastWriteTime |
|---|---|---|
| apps/tenant-web/features/examStaff/detail/proctor/ProctorOverview.tsx | 1AA2BEC4AFDCD2302BEA849290E0E4DE342089FD410952CA852C45FA49D228D4 | 2026-10-12T15:29:46.9627797+07:00 |
| apps/tenant-web/features/examStaff/detail/examiner/ExaminerOverview.tsx | DDFCF0B8B4B34531202410F86F77CEF57DFFB52F88E9A1A9C7A1A4C7E3DB42DF | 2026-10-12T15:29:46.9445548+07:00 |
| apps/tenant-web/features/studentDetail/components/StudentOverviewTab.tsx | A7C93662C620B26CAA77E18513A66F46AA91E255F7F4CAD921CC67E263079769 | 2026-10-12T15:29:47.0892652+07:00 |
| apps/vendor-web/features/dashboard/components/_AdminStatGrid.tsx | 8734B9C5CC7D8640D936B7F4E7CE81D3707CB5A5C2C9287DDC98001CD0611173 | 2026-10-12T15:29:47.2077813+07:00 |
| apps/vendor-web/features/licensing/components/_LicenseStatGrid.tsx | 4CBA39AD85EB08714FBF2280BE693D227136C93DF8FD4B27637CA751015570DF | 2026-10-12T15:29:47.2284490+07:00 |
| apps/vendor-web/features/questionbank/components/_QuestionStatGrid.tsx | F44F84428817C610F58721B92A73B0EFEDB7EE2E4B152BCDDCA46D0D866653DB | 2026-10-12T15:29:47.2587514+07:00 |

## DataTable BEFORE

- File: packages/ui/src/components/DataTable.tsx
- SHA256: 68CD792E9589399CF3D5E78DB93504029F820183D731AB9B5C69CEFA9AD8121B
- Lines: 711 (`[System.IO.File]::ReadAllLines().Length`; `Measure-Object -Line` reports 656 because it skips blank lines)
- LastWriteTime: 2026-10-12T15:29:47.4745693+07:00

## AFTER Phase 6 implementation + Build Gate (2026-10-13)

All six consumer files and DataTable.tsx: SHA256 and LastWriteTime IDENTICAL to the BEFORE tables above; DataTable still 711 lines. `apps/vendor-web/.next/dev/types/routes.d.ts` (the pre-existing corrupted file) is also untouched by the builds (hash C88FC4C7..., mtime 2026-10-10T08:16:05).
