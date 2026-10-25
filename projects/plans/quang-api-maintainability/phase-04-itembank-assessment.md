# Phase 4: itembank + assessment

## Requirements

Đưa các file sau về ≤ 300 dòng, không đổi hành vi:

| File | Dòng |
|---|---|
| `itembank/ItembankService.java` (facade công khai) | 828 |
| `itembank/QuestionTypeService.java` (công khai) | 689 |
| `assessment/internal/service/ExamDefinitionAdminService.java` | 735 |
| `assessment/internal/service/ExamGenerationService.java` | 340 |
| `assessment/internal/service/SnapshotPublishService.java` | 311 |

Kèm: gốc module `itembank/` có 18 file phẳng → rà lại, lớp nào không phải API công khai thì dời vào `internal/`.

## Design Constraints

- `ItembankService`, `QuestionTypeService` là API module khác gọi: giữ chữ ký public, thân chuyển sang service trong `itembank/internal/service/` (ví dụ tách theo: truy vấn câu hỏi, vòng đời/duyệt câu hỏi, thống kê/batch, media). Facade chỉ ủy quyền.
- `ExamDefinitionAdminService`: tách theo trách nhiệm (CRUD định nghĩa, workflow trạng thái/duyệt, kiểm tra hợp lệ blueprint/trọng số, mapper response). Gom vào `assessment/internal/service/definition/` nếu ≥ 3 lớp.
- Giữ nguyên ranh giới `@Transactional` của từng method public.

## Steps

1. Đọc từng lớp, liệt kê method theo nhóm trách nhiệm, chốt cách tách (ghi vào mục "Quyết định khi cook" của phase).
2. Tách, chạy test module sau mỗi lớp.
3. Cập nhật allowlist `SourceFileSizeTest`, `PackageDensityTest`.

## Success Criteria

- Năm file ≤ 300 dòng; facade không đổi chữ ký (module khác không phải sửa).
- Suite + test Postgres xanh; Docker gate: seed `seed-local-template-and-question-bank.ps1` và luồng thi chạy được.

## Quality and Testing State

- Quality gate: not evaluated
- Testing: not started

## Risks

- `@MockitoBean ItembankService` trong test module khác vẫn hoạt động vì facade giữ nguyên; test nội bộ itembank cần trỏ lớp mới.
