# Platform audit trail — verification report

Date: 2026-11-25. Plan: `pte-doc/projects/plans/quang-platform-audit-trail/`. Branch: `quang/feat/maintain-v3` (pte-api, pte-web).

## Scope delivered

| Phase | Result |
|---|---|
| 01 Hạ tầng + API đọc | `AuditLogChangeWriter.recordState` + `AuditStateSerializer` (sorted keys, 64 KB cap → truncation marker, serialize failure keeps the summary row); `PlatformAuditLogQuery` (filters `aggregateType`, `aggregateId`, `actorId`, `search`, dates); `GET /api/v1/platform/audit-logs/{publicId}` returns `beforeState/afterState` as JSON; list rows add `actorRole`, `hasStateChange`. Platform read path moved out of `AuditLogService`. No migration. |
| 02 Ghi trước/sau | Question draft `update` (`QuestionAuditState`), template create/clone/CEFR/time frame/items/delete (`ExamDefinitionAuditState`, no `runtime_*`), blueprint create/update, standard task type create/update/delete, dynamic task type create/update (one row; action `RUNTIME_CONTRACT_UPDATED` when the runtime binding changes), plan create/update/activate/archive/delete draft. New `GET /api/v1/questions/{publicId}/revisions`. |
| 03 Lọc theo người (web) | `/admin/audit-log`: actor filter, `?actorId=` deep link, "Xem thay đổi" drawer. Platform user menu: "Xem lịch sử thao tác" (also on protected accounts, read-only). |
| 04 Tab Lịch sử (web) | Question detail: "Các phiên bản" (compare any two revisions; reviewers only, same rule as the answer key) and "Nhật ký thao tác" (platform operators). Template detail: change history (platform operators). Shared `diffAuditState` + `AuditChangeDiff`. |

## Decisions taken during implementation

- Task type governance (submit/approve/publish/retire) keeps summary-only rows: the action already names the new status.
- Question publish/revision needs no snapshot: the revision chain (`supersedesPublicId`, archived source unchanged) is the content history.
- Dynamic task type update now writes one row instead of two; no reader depended on the second row (checked API and web).
- Fallback: services built without a writer (unit-test constructors) still write the old summary row.
- Web label of aggregate `SCORE_TEMPLATE` corrected from "Mẫu điểm" to "Template đề".
- No index migration: the local table is too small for `EXPLAIN` to be meaningful; revisit when `audit_logs` grows.

## Verification

| Check | Result |
|---|---|
| `mvnw -pl app -DskipTests compile` | OK |
| `mvnw -pl app test` | 5647 run, 5 failures, 1 error, 102 skipped — **all 6 pre-existing, none in changed code** (below) |
| New/changed backend tests | `AuditStateRecordTest` (6), `PlatformAuditLogQueryTest` (4), `QuestionUpdateAuditTest` (2), `ExamDefinitionAuditStateTest` (2), `PlanAuditTrailTest` (2), existing audit/blueprint/template/task-type/plan tests — pass |
| vendor-web `tsc`, `eslint` (changed files), vitest auditLog/platformUsers/questionbank/scoretemplate | clean; 185/185 |
| tenant-web `tsc` | clean (shared `AuditLogResponse` type changed) |
| api-client `tsc`, vitest requests | clean; 650/650 |
| Local `app` container rebuilt | healthy |
| Browser check | not done (user tests the UI) |

Pre-existing failures (from `dev` merges, not touched here):

- `BillingOverviewQueriesTest` ×3, `AdminDashboardControllerTest` ×1 — commit `6850c9d2` (BUG_035) changed `EXPIRING_SOON_DAYS` 30 → 7 without updating these tests.
- `SourceFileSizeTest` — `session/internal/service/draft/ExamPublishService.java` is 322 lines (commit `5cf056cc`).
- `ModuleStructureTest` — `proctoring` uses `session.domain.enums.AttendanceStatus` (commit `2930fe63`).

## Manual scenarios for the user

1. Edit an answer option of a draft question → question detail › Nhật ký thao tác › Xem thay đổi shows `Options › n › Correct`.
2. Open a revised question → Các phiên bản compares it with the version it replaced.
3. Edit template items → template detail › Lịch sử thay đổi shows the item diff.
4. Platform users › ⋯ › Xem lịch sử thao tác → audit log filtered to that person.
5. A tenant token on `GET /api/v1/platform/audit-logs/{id}` → 403.
