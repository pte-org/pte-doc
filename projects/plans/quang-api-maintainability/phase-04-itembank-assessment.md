# Phase 4: itembank + assessment

## Requirements

> **Quyết định khi cook phase-04-itembank-assessment (2026-10-25):** ItembankService 828->183, QuestionTypeService 689->220, ExamDefinitionAdminService 739->233 (definition/ sub-package), ExamGenerationService 340->79, SnapshotPublishService 311->215; collaborators named by responsibility, all <= 300 lines. Facades keep signatures and delegate to injected beans. Review bắt được 4 BLOCKER do agent làm rơi logic (feasibility, media validation, custom-template profile, @Autowired) — đã khôi phục và so sánh từng method với HEAD; thêm test cho feasibility, media validator, contract resolver.

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

- Quality gate: approved (xem quality/phase-04-itembank-assessment-quality-report.json)
- Testing: passed (xem tests/phase-04-itembank-assessment-test-report.json)

## Risks

- `@MockitoBean ItembankService` trong test module khác vẫn hoạt động vì facade giữ nguyên; test nội bộ itembank cần trỏ lớp mới.
