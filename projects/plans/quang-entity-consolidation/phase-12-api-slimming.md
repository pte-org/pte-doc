# Phase 12: API slimming — gộp endpoint đổi trạng thái và bản trùng

## Requirements

Giảm số endpoint (328 trước plan; còn khoảng 290 sau phase 4–11 nhờ gỡ `score-templates`, `tenants`, `proctor-sessions/close`, assignment preview/confirm) xuống khoảng 250 mà không mất chức năng. Chỉ đổi bề mặt API, không đổi entity hay schema (V1 đã sinh ở phase 11). Phục vụ tiêu chí function parity và yêu cầu người dùng 2026-10-24 ("API slimming").

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`; sửa client thì đọc `docs/CODING_STANDARDS_WEB.md` (và `CODING_STANDARDS_APP.md` cho `pte-app`). Ghi standards-read note vào progress update đầu tiên.
- Không đổi hành vi nghiệp vụ: logic hợp lệ của từng chuyển trạng thái vẫn nằm trong service/domain của aggregate; controller chỉ định tuyến. Mã lỗi và message hiện có giữ nguyên.
- Quy ước thống nhất: `PATCH /{resource}/{id}/status` với body `{ "action": "<ENUM>", "reason": "<optional>" }`. `action` là enum riêng của aggregate (ví dụ Program: `ACTIVATE|DEACTIVATE|SUSPEND|ARCHIVE`); action không hợp lệ ở trạng thái hiện tại → lỗi domain hiện có. Quyền truy cập theo từng action phải tương đương endpoint cũ (kiểm trong service hoặc `@PreAuthorize` theo action), không nới quyền.
- Workflow phê duyệt (`submit-approval`, `approve`, `reject`, `publish`) của Question, ExamDefinition, QuestionType dùng cùng quy ước `PATCH .../status`; `reason` bắt buộc với `REJECT`.
- Hành động có tham số riêng, hoặc không phải chuyển trạng thái đơn thuần (`ClassController` merge/split/transfer, `SessionController` generate/preflight/audience, publish report) KHÔNG gộp.
- Mỗi gộp liệt kê vào bảng thay đổi trong `spec.md` (cũ → mới, file client phải sửa). Client sửa trong cùng phase; client không hỏng ở ranh giới.

## Steps

1. Chụp inventory hiện tại (`ApiInventoryExportTest -Dinventory.out=.../api-inventory.before-slimming.json`) và danh sách POST đổi trạng thái còn lại; chốt bảng gộp theo aggregate (dự kiến: Program 4→1, Class 4→1, Organization suspend/reactivate →1, User/PlatformUser suspend/reactivate/archive/restore →1 mỗi loại, ServicePlan activation/archive →1, Question 8→1, ExamDefinition 5→1, Rubric 4→1, QuestionType/TaskType submit-approval/approve/retire →1, Announcement publish giữ riêng nếu kèm audience).
2. TDD (`ck:test --tdd --prepare`): test controller/service cho từng aggregate — mỗi action hợp lệ đổi đúng trạng thái, action sai trạng thái trả lỗi hiện có, quyền theo action tương đương endpoint cũ.
3. Hiện thực endpoint `PATCH .../status` cho từng aggregate; xoá endpoint cũ tương ứng và alias trùng (`approve`/`approval`, `reject`/`rejection`).
4. Gộp attendance: một bộ endpoint `/exam-sessions/{sessionId}/attendance/**` dùng chung cho HOST_ADMIN và PROCTOR (thay `HostAttendanceController` + `ProctorAttendanceController`), phân quyền theo role trong service; giữ receipt/history/identity.
5. Gỡ `/internal/**` (`InternalSessionController`, `InternalSnapshotController`, `InternalMediaController`) nếu không còn gọi: thay bằng lời gọi service trực tiếp trong monolith; kiểm bằng grep consumer trước khi xoá.
6. Sửa client trong cùng phase: `pte-web` (`packages/api-client/src/requests/**`, các hook/feature gọi endpoint cũ), `pte-app` nếu có; lint/typecheck/build theo `CODING_STANDARDS_WEB.md`/`APP.md`; cập nhật script seed/README gọi endpoint cũ.
7. Xuất lại inventory sau cùng (`api-inventory.after.json`), tạo feature map sau và so với `feature-map.before.md`: mỗi tính năng còn endpoint; grep path cũ trong `pte-web`, `pte-app`, `pte-practice`, scripts = 0; ghi số endpoint cuối.
8. Chạy compile, test toàn app, `ModuleStructureTest`, gate dev DB; cập nhật `local-dev-runbook.md` nếu đổi cách gọi.

## Success Criteria

- Số endpoint cuối ≤ 260 (từ 328), không còn alias trùng, không còn `HostAttendanceController`/`ProctorAttendanceController` riêng, không còn `/internal/**` nếu không có consumer.
- Function parity: mọi tính năng trong `feature-map.before.md` còn ít nhất một endpoint tương đương hoặc được liệt kê là đã gỡ có chủ đích trong `spec.md`.
- Quyền theo action tương đương trước khi gộp (test); grep path cũ trong 3 client, scripts, README = 0; client lint/typecheck/build pass.
- Gate dev DB (profile `local-schema`): health UP, login `admin@test.local` và `host.e2e@test.local` thành công; không chạy được thì "not verified".
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Gộp làm lỏng quyền nếu kiểm quyền theo action bị bỏ sót: test quyền theo từng action là bắt buộc.
- Client sót call site vì path đổi hàng loạt: dùng call-site inventory phase 1 (`call-sites.before.json`) làm danh sách kiểm.
- Gộp quá tay làm payload mơ hồ: giữ ngoài phạm vi các hành động có tham số riêng (liệt kê ở Design Constraints).
