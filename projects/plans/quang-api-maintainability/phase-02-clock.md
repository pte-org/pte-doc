# Phase 2: `Clock` toàn bộ

## Requirements

Thay toàn bộ 69 lời gọi lấy giờ trực tiếp bằng `Clock` inject. Theo module (đo 2026-10-25): billing 13, proctoring 11, attempt 9, session 8, scoring 8, tenancy 4, practice 3, identity 3, notification 2, media 2, enrollment 2, shared 1, reporting 1, examstaff 1, assessment 1.

## Design Constraints

- Service/controller/scheduler: thêm `Clock` vào constructor, dùng `clock.instant()`. Không tạo `Clock` cục bộ.
- Entity (`ExamAttempt`, `NotificationLog`, `ExamIncident`, `AiEvaluation`, `Organization`): bỏ `now()` khỏi entity; method domain nhận `Instant now` từ service gọi. `@PrePersist` dùng `now()` để gán `createdAt` thì chuyển sang service gán hoặc dùng cơ chế auditing sẵn có của dự án (chọn một, ghi quyết định).
- Độ chính xác: giữ nguyên chỗ nào đang `truncatedTo(MICROS)` (Postgres timestamptz).
- `ProctorStompController` và `StompAuthChannelInterceptor` cũng inject `Clock`.
- Không đổi múi giờ: `ClockConfig` vẫn `Clock.systemUTC()`.

## Steps

1. Theo từng module: sửa lớp, sửa test (dùng `Clock.fixed(...)` thay cho chờ thời gian thực hoặc so sánh khoảng).
2. Entity: đổi chữ ký method domain, cập nhật mọi nơi gọi.
3. Xoá các mục tương ứng khỏi allowlist của `NoDirectClockAccessTest`; cuối phase allowlist chỉ còn `ClockConfig`.

## Success Criteria

- `NoDirectClockAccessTest` không còn mục nào ngoài `ClockConfig`.
- Suite đầy đủ + 42 test Postgres xanh; Docker gate (luồng seed → làm bài → chấm → công bố) chạy được.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started

## Risks

- Test cũ dựa vào giờ thực (ví dụ "trong vòng 5 giây") có thể thành giòn: chuyển sang `Clock.fixed`.
- Đổi chữ ký entity lan sang nhiều service: làm theo từng entity, chạy test module sau mỗi entity.
