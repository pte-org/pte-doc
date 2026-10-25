# Phase 1: Hàng rào kiểm tra

## Requirements

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

- Quality gate: not evaluated
- Testing: not started

## Risks

- Đếm dòng khác nhau giữa CRLF/LF: test đếm theo `\n` sau khi chuẩn hoá.
