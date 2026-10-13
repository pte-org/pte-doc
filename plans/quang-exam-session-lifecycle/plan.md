# Plan: Hoàn thiện nghiệp vụ vòng đời kỳ thi

Status: Implemented — targeted gates passed; full suite has a repository-level module-structure gate  
Date: 2026-10-13  
Scope: `pte-api`, `pte-web`, `pte-doc`

## Mục tiêu

Hoàn thiện state machine và các nghiệp vụ còn thiếu của kỳ thi: mở/đóng đúng trạng thái, hủy kỳ thi đúng đối tượng, xóa bản nháp an toàn, giữ tính toàn vẹn dữ liệu và có quality gate đủ cho backend/frontend.

## Quyết định nghiệp vụ

1. Không triển khai **Archive/Lưu trữ**. Kỳ thi `CANCELLED`, `CLOSED` hoặc đã có dữ liệu tham gia chỉ được xem lại, không xóa.
2. Chỉ `DRAFT` được xóa mềm.
3. Student không dùng tenant platform cho luồng exam; không gửi notification hủy kỳ thi cho `STUDENT` và không tạo phụ thuộc vào `pte-practice`.
4. **Exam staff** trong phạm vi này là user tenant-scoped có role `PROCTOR` hoặc `EXAMINER`, đang được gán vào kỳ thi. Chỉ những người được gán mới nhận notification; không broadcast toàn tổ chức.
5. Host mở/đóng kỳ thi theo thao tác hiện có. `opensAt`/`closesAt` là cửa sổ cho phép student attempt; auto-open chưa đưa vào MVP. Auto-close sẽ được bổ sung để tránh session bị treo `OPEN` sau thời gian kết thúc.
6. Mọi transition phải được enforce ở backend; UI chỉ phản ánh quyền thao tác.

## State policy

| Trạng thái | Được phép | Không được phép |
|---|---|---|
| `DRAFT` | Sửa, preflight, generate, xóa bản nháp | Hủy kỳ thi |
| `PREPARING` | Hủy sinh đề | Sửa, xóa |
| `READY` | Publish, hủy kỳ thi | Sửa nội dung draft, xóa |
| `SCHEDULED` | Mở kỳ thi, hủy kỳ thi | Sửa, xóa |
| `OPEN` | Đóng kỳ thi | Hủy, xóa |
| `CLOSED` | Xem, chấm, báo cáo, phát hành kết quả theo flow hiện có | Mở lại, hủy, xóa |
| `CANCELLED` | Xem lịch sử | Mở lại, xóa, archive |

Khuyến nghị khi hủy `PREPARING`: hủy generation job trước, sau đó trả session về `DRAFT` để host có thể sửa và generate lại. Hủy `READY` hoặc `SCHEDULED` là transition terminal sang `CANCELLED`.

## Các phase

| Phase | Nội dung | Phụ thuộc |
|---|---|---|
| 01 | State machine và API guards | Không |
| 02 | Hủy kỳ thi và notification cho exam staff | Phase 01 |
| 03 | Xóa bản nháp và toàn vẹn soft-delete | Phase 01 |
| 04 | Cửa sổ thời gian và auto-close | Phase 01 |
| 05 | Regression, integration và quality gate | Phase 01–04 |

Chi tiết từng phase nằm trong cùng thư mục này.

## Phạm vi kỹ thuật chung

- Backend: `SessionStatus`, `ExamSession`, `SessionStateService`, `ExamOrchestrationService`, repository/query, audit và notification event.
- Notification: dùng boundary hiện có của `notification`; không gọi repository module khác trực tiếp nếu đã có service facade.
- Frontend: action menu/detail action phải phản ánh đúng state policy; không dùng hidden button làm security boundary.
- Test: unit/service/controller/integration cho allow-deny matrix; frontend typecheck/lint/build và smoke các action menu.
- Documentation: cập nhật phase reports trong `pte-doc`; không lưu screenshot/log Playwright trong `pte-web`.

## Acceptance criteria toàn plan

- Không thể đóng session khác `OPEN` bằng UI hoặc direct API.
- Không thể xóa session khác `DRAFT`; `CANCELLED` không có action xóa/archive.
- Hủy kỳ thi gửi notification chỉ đến các exam staff active được gán vào session; không có recipient student.
- Generation cancellation không để job chạy tiếp hoặc làm session rơi vào trạng thái không thể phục hồi.
- Session quá `closesAt` không bị treo `OPEN` vô thời hạn.
- Query list/detail/attempt/enrollment không làm lộ session đã xóa mềm.
- Test và quality report ghi rõ command, environment, kết quả và giới hạn kiểm chứng.

## Ngoài phạm vi

- Xây student exam platform mới.
- Gửi notification cho student qua `pte-practice`.
- Archive/restore hoặc purge dữ liệu exam.
- Thay đổi scoring algorithm, proctoring policy hoặc cấu trúc enrollment ngoài phần cần để bảo vệ lifecycle.
