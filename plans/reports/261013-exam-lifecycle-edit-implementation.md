# Báo cáo triển khai vòng đời và chỉnh sửa kỳ thi

Ngày: 2026-10-13  
Phạm vi: `pte-api`, `pte-web`, `pte-doc`  
Trạng thái: Đã triển khai trong working tree; chưa commit

## Kết quả chính

- Gộp thông tin tổng quan và cấu hình kỳ thi vào một panel detail; bỏ thông tin kỹ thuật `id` và `snapshotPublicId` khỏi giao diện.
- Đưa status và action vào panel thông tin, dùng common `ActionMenu`, `Select`, `ConfirmDialog`, `Alert` và form inline.
- Exam list có cột `Thao tác`, action `Xem chi tiết`, và chỉ hiển thị `Xóa kỳ thi` cho `DRAFT`.
- Thêm chỉnh sửa schedule sau khi kỳ thi rời `DRAFT`:
  - `SCHEDULED`: sửa tên, `opensAt`, `closesAt` và policy được cho phép.
  - `OPEN`: chỉ được gia hạn `closesAt`; không đổi tên, thời gian bắt đầu, snapshot, skill hoặc policy đã khóa.
  - `CLOSED` và `CANCELLED`: chỉ xem.
- Status editor dùng common dropdown và chỉ cho chọn transition hợp lệ; không dùng `PREPARING` làm trạng thái tạm khi host mở form.
- Thêm cảnh báo T-10, confirm khi bắt đầu chỉnh sửa gần giờ thi, và confirm nhắc kiểm tra/gia hạn giờ kết thúc khi lưu sau thời điểm bắt đầu.
- Backend thêm endpoint `PATCH /api/v1/sessions/{publicId}/schedule`, optimistic version check, tenant/entitlement/window/overlap validation và audit event.
- Backend thêm worker tự động `SCHEDULED -> OPEN` tại `opensAt`; worker auto-close hiện có tiếp tục đóng `OPEN -> CLOSED` tại `closesAt`.
- Nếu form mở từ `SCHEDULED` nhưng save sau `opensAt`, backend re-check dưới row lock và áp dụng rule `OPEN`, không cho sửa nhầm identity/start time.
- Khi có mutation conflict, client invalidate lại session detail để lấy status/version mới.
- Cập nhật plan tổng hợp tại [plan.md](../quang-pte-web-admin-detail-and-exam-operations/plan.md).

## Contract và file chính

- Backend schedule boundary: `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionScheduleService.java`.
- Backend auto-open: `pte-api/app/src/main/java/com/pte/session/internal/service/lifecycle/SessionAutoOpenWorker.java`.
- Backend controller/DTO: `SessionController.java`, `PatchExamScheduleRequest.java`.
- Frontend API hook: `pte-web/apps/tenant-web/features/exams/api/index.ts`.
- Frontend inline editor: `ExamEditForm.tsx`, `ExamScheduleFields.tsx`, `ExamOverviewTab.tsx`, `ExamInformationPanel.tsx`.
- API client contract: `pte-web/packages/api-client/src/requests/scheduling/sessions.ts` và `types/scheduling/index.ts`.

## Xác minh

### Backend

- `.\mvnw.cmd -pl app -DskipTests compile`: pass.
- Targeted lifecycle tests: **39 tests pass** (`SessionScheduleServiceTest`, `SessionAutoOpenWorkerTest`, `SessionAutoCloseWorkerTest`, `SessionLifecycleServiceTest`).
- Full `.\mvnw.cmd -pl app test`: **1367 tests, 1 failure, 1 error, 41 skipped**. Lỗi nằm ở `ModuleStructureTest` do module graph hiện tại phát hiện module `examstaff` ngoài danh sách kỳ vọng và các boundary/cycle violations giữa `enrollment`, `session`, `reporting`, `attempt`; chưa có dấu hiệu liên quan đến schedule lifecycle patch.

### Frontend

- `pnpm test -- --run` trong `packages/api-client`: **448 tests pass**.
- `pnpm exec tsc --noEmit -p tsconfig.json` trong `apps/tenant-web`: pass.
- `pnpm run lint` trong `apps/tenant-web`: pass.
- `pnpm run build` trong `apps/tenant-web`: pass.
- Prettier check cho các file thay đổi: pass.
- `git diff --check` trong `pte-web`, `pte-api`, `pte-doc`: pass; chỉ còn cảnh báo line-ending LF/CRLF của Git ở các file working tree.
- Tenant feature Vitest hiện không có test file; không coi đây là test pass.

### Docker và browser smoke

- Đã build/recreate `pte-platform-app-1` bằng Docker Compose sau khi sửa backend.
- `/actuator/health` trả `{"groups":["liveness","readiness"],"status":"UP"}`; Flyway báo schema version 93 đã up to date.
- Browser smoke với host account đã kiểm tra: exam list không còn cột cấu hình, action menu draft có `Xem chi tiết`/`Xóa kỳ thi`, breadcrumb detail, panel tổng hợp, action menu `Chỉnh sửa`, inline form và status dropdown có các transition hợp lệ.
- Không lưu screenshot runtime vào `pte-doc`; log/runtime artifact nếu cần tiếp tục phải đặt trong `D:\GitHub\pte-org\.playwright-mcp`.

## Giới hạn còn lại

- Chưa chạy full browser E2E cho thao tác save thật trên một session mới có window `SCHEDULED`/`OPEN`; smoke hiện kiểm tra render và action surface trên dữ liệu local hiện có.
- Full backend suite vẫn bị chặn bởi `ModuleStructureTest` như trên; cần tách một task riêng để xử lý module graph, không sửa lẫn trong slice lifecycle này.
- Browser console còn cảnh báo accessibility từ form/common control hiện hữu: một cảnh báo thiếu `id/name` và ba cảnh báo label association; không có runtime exception trong flow đã kiểm tra.
