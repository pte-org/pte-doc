# Phase 8: Chốt

## Requirements

Đóng plan: không còn nợ trong allowlist, tài liệu khớp code.

## Steps

1. Allowlist `NoDirectClockAccessTest` chỉ còn `ClockConfig`; `SourceFileSizeTest` rỗng; `PackageDensityTest` chỉ còn các package `@NamedInterface` được miễn (nếu có). Xoá file allowlist nào đã rỗng và đơn giản hoá test tương ứng.
2. Cập nhật `AGENTS.md` (snapshot) và tài liệu chuẩn (quy tắc gom thư mục, `Clock`).
3. Báo cáo `pte-doc/plans/reports/YYMMDD-quang-api-maintainability-final-report.md`: số liệu trước/sau (lời gọi `now()`, file > 300, thư mục > 15), danh sách lớp mới, chênh lệch so với plan.

## Success Criteria

- Suite đầy đủ + 42 test Postgres xanh; Docker gate đủ luồng (seed → làm bài → chấm tay → công bố → học viên xem kết quả); 260 endpoint không đổi.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started
