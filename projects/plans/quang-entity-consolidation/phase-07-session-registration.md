# Phase 7: Ca thi & ghi danh (6b) — ExamSession, ExamRegistration

## Requirements

Gộp `ExamSession` + `ExamPolicy` + `ProctorAssignment` + `SessionClassAssignment` + `ExamAudienceSource` thành `ExamSession`; `ExamAudienceMember` + `Enrollment` + `SessionAttendance` thành `ExamRegistration`; xoá cơ chế form (`ExamForm`, `FormAssignment`, `ExamGenerationJob`). Đáp ứng FR-03, FR-04 và cột trạng thái chấm/công bố cho phase 10.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`; nếu đổi endpoint thì đọc thêm `docs/CODING_STANDARDS_WEB.md`/`CODING_STANDARDS_APP.md`. Ghi standards-read note vào progress update đầu tiên.
- Policy nhúng; audience sources, proctors là bảng con (`ExamSessionAudienceSource`, `ExamSessionProctor`); selected skills `@ElementCollection`; `ExamRegistration` là bảng con có FK + unique (session, student), lọc theo trạng thái/điểm danh.
- Mỗi ca thi đúng một `examVersionId`; exclusion constraint chống chồng lấp phải còn trong V1.
- Hành vi giữ kèm test: (a) `audience-preview` tính stateless, kèm lý do loại trừ, trước publish; (b) receipt điểm danh/xác minh nằm ở `IdempotencyKey.result` với retention ≥ `closesAt` + 90 ngày; (c) lịch sử điểm danh `GET .../attendance/students/{st}/history` đọc từ `AuditLog`.
- Phase này viết cột trạng thái chấm/công bố trên `ExamSession` (phase 10 điền hành vi).

## Steps

1. Thiết kế `ExamSession` thay `ExamSession`, `ExamPolicy`, `ProctorAssignment`, `ExamAudienceSource`, `SessionClassAssignment`: cập nhật `SessionCreationService`, `SessionPolicyService`, `SessionScheduleService`, `SessionStateService`, `SessionSubscriptionService`, `SessionLifecycleService`, `SessionReadService`, `SessionClassAssignmentService`, `SessionController`, `ProctorAssignmentController`, `ProctorAssignmentQueryController`.
2. Thiết kế `ExamRegistration` thay `Enrollment`, `ExamAudienceMember`, `SessionAttendance`: `EnrollmentService`, `EntitlementService`, `EnrollmentController`, `StudentEnrollmentController`, `AttendanceCommandService`, `AttendanceQueryService`, proctoring `AttendanceCoordinatorService`, `HostAttendanceController`, `ProctorAttendanceController`; audience STUDENT/CLASS/PROGRAM resolve thành registration khi publish (dùng public API enrollment của phase 6).
3. Cài hành vi (a): `audience-preview` stateless với lý do loại trừ, test riêng.
4. Thay `SessionAttendanceCommand`/`SessionIdentityVerificationCommand` bằng `IdempotencyKey` (receipt, retention nêu trên) + `AuditLog` (lịch sử, có actor/role/before-after/requestPublicId); test lấy lại receipt và history.
5. Xoá cơ chế form: `ExamFormProvisioningService`, `ExamForm`, `FormAssignment`, `ExamGenerationJob`; ca thi gắn một `examVersionId` do builder phase 5 dựng; cập nhật `ExamOrchestrationService`, `SessionExamPreviewService`, `InternalSessionController`.
6. Cập nhật consumer (`ProctorMonitoringQueryService`, `SessionStaffAssignmentQueryService`, `StaffScheduleQueryService`, attempt/scoring/reporting/notification qua `SessionService`, `StaffScheduleService`); thay view monitoring bằng truy vấn trên bảng mới.
7. Nếu endpoint/DTO đổi: ghi vào bảng spec, sửa client call site trong phase (tenant-web/proctor, pte-app) và chạy lint/type/build; test: lifecycle, overlap, audience resolve, attendance idempotent, tenant isolation, flow test tạo ca thi (e2e bước 3).
8. Seed V1: ca thi mẫu gắn ExamVersion seed; cập nhật `V1__baseline.sql` (`exam_session`, `exam_session_audience_source`, `exam_session_proctor`, `exam_registration`, exclusion constraint); chạy compile, test toàn app, `ModuleStructureTest`, gate Postgres.

## Success Criteria

- Publish ca thi tạo `ExamRegistration` cho audience và gắn một `examVersionId`; điểm danh/xác minh ghi trên registration, receipt và history lấy lại được (test).
- `audience-preview` stateless trả lý do loại trừ (test).
- Không còn `ExamForm`, `FormAssignment`, `ExamGenerationJob`, `ExamFormProvisioningService`, `SessionClassAssignment`, `*Command` của attendance, `Enrollment`, `ExamAudienceMember`.
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres (exclusion constraint `no_overlap_per_subscription`) phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh; ghi số `@Entity` và số bảng do Hibernate dựng.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Phase nặng nhất sau scoring: chia commit nội bộ theo bước 1–2, 3–4, 5–6 nhưng không kết thúc dở dang.
- View monitoring cũ phụ thuộc bảng enrollment: viết lại truy vấn, không giữ view.
- Mất đề riêng từng thí sinh là quyết định đã chấp nhận.
