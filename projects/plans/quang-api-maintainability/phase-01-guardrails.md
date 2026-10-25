# Phase 1: Hàng rào kiểm tra

## Requirements

> **Quyết định khi cook phase 1 (2026-10-25):** (1) Ba test trong `app/src/test/java/com/pte/architecture/` dùng chung `SourceDebtAllowlist.ratchet(...)`; giá trị trong allowlist là số đo **chính xác** hiện tại, nên file nhỏ lại cũng phải hạ con số (không thể phình lại tới mức cũ). (2) `NoDirectClockAccessTest` bỏ qua comment/chuỗi, bắt `now()`, `now(zone)`, `::now` của các kiểu java.time, `System.currentTimeMillis()`, `new Date()`, `Calendar.getInstance()`; `now(clock)` hợp lệ; `Clock.systemUTC()` (bean và fallback trong constructor) nằm ngoài phạm vi. (3) Chênh lệch có chủ đích: `PackageDensityTest` miễn **mọi** package không thuộc `internal/**` (không chỉ package có `@NamedInterface`), vì package công khai nào cũng là ứng viên ranh giới module. (4) Allowlist ban đầu: 49 file / 69 lần đọc giờ, 23 file > 300 dòng, 14 package đông (thêm `overview/internal/service`, `scoring/internal/vendor/gemini`, `billing/internal/service` so với plan, đã bổ sung vào phase 3 và 7). (5) Bước 5 (ghi quy tắc gom thư mục vào `docs/CODING_STANDARDS_API.md` hay chỉ trong plan) **chờ người dùng quyết**; quy tắc hiện nằm ở plan.md "Quy tắc chung" 4–5.

Trước khi sửa, dựng test kiến trúc để nợ không quay lại. Test đếm vi phạm hiện có vào allowlist; mỗi phase sau chỉ được xoá mục khỏi allowlist, không được thêm.

## Design Constraints

- Test thuần JUnit đọc file nguồn `src/main/java` (không thêm thư viện mới như ArchUnit trừ khi đã có trong pom).
- Allowlist là file văn bản trong `src/test/resources/architecture/` (một đường dẫn mỗi dòng, có số dòng tối đa hiện tại cho file lớn), để diff dễ đọc.
- Quy tắc gom thư mục và danh sách package công khai giữ phẳng (`@NamedInterface`) ghi vào `docs/CODING_STANDARDS_API.md` hoặc phụ lục trong plan này, tuỳ người dùng chọn khi duyệt.

## Steps

1. `NoDirectClockAccessTest`: quét `src/main/java`, báo lỗi với `Instant.now()`, `LocalDateTime.now()`, `LocalDate.now()`, `OffsetDateTime.now()`, `ZonedDateTime.now()`, `System.currentTimeMillis()` ngoài allowlist (`ClockConfig` là ngoại lệ vĩnh viễn).
2. `SourceFileSizeTest`: file `.java` > 300 dòng phải có trong allowlist và không được dài hơn con số ghi trong allowlist.
3. `PackageDensityTest`: thư mục `internal/**` > 15 file `.java` trực tiếp phải có trong allowlist; package có `@NamedInterface` được miễn.
4. Ghi allowlist ban đầu từ số liệu hiện tại (69 lời gọi / 23 file / các thư mục đông).
5. Viết quy tắc gom thư mục (plan.md mục "Quy tắc chung" 4–5) vào tài liệu chuẩn đã chọn.

## Success Criteria

- Ba test xanh trên code hiện tại; thêm một `Instant.now()` mới hoặc làm một file dài thêm thì test đỏ (kiểm thử bằng một thay đổi tạm rồi bỏ).
- Suite đầy đủ xanh.

## Quality and Testing State

- Quality gate: approved (xem quality/phase-01-guardrails-quality-report.json)
- Testing: passed (xem tests/phase-01-guardrails-test-report.json); bước 5 chờ người dùng quyết

## Risks

- Đếm dòng khác nhau giữa CRLF/LF: test đếm theo `\n` sau khi chuẩn hoá.
