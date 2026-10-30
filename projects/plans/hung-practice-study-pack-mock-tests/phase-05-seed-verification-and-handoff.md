# Phase 5: Seed, kiểm chứng và handoff

Status: Not started
User stories: tất cả
FR: FR-08 + mọi tiêu chí spec §9

## Requirements

- `pte-api/scripts/seed-local-practice-question-bank.ps1`: thêm `-MockTests <0..20>` (mặc định 0). Sau khi seed câu, gọi `POST /api/v1/admin/practice/mock-tests:generate {count}` bằng token admin seed hiện có; in danh sách đề tạo được. Chạy lại không tạo trùng ngoài ý muốn: chỉ generate khi số đề hiện có < `MockTests` (generate phần thiếu).
- Chạy seed `-PerTask 12 -MockTests 3` trên local.
- Kiểm chứng thủ công (Playwright, tài khoản `pte-center.practice01`):
  - TC1 Study-Pack: 4 hàng đúng thứ tự, số đếm; Reading 10 câu untimed → 10 item ≥ 2 dạng.
  - TC2 Study-Pack TIMED Speaking → engine chạy theo từng câu.
  - TC3 Danh sách đề: 3 đề, 65 câu, thời lượng ước tính.
  - TC4 Hai học viên cùng Đề 2 → cùng câu (SQL so `source_question_id` theo order).
  - TC5 Trả lời 5 câu, thoát, Tiếp tục → câu 6, 5 câu cũ còn.
  - TC6 Làm lại khi có lượt dở → modal → lượt cũ DISCARDED.
  - TC7 Hoàn thành đề (có thể bỏ qua nhiều câu) → review có điểm ước lượng + nhãn.
  - TC8 Phiên cũ trước V134 vẫn mở/review được.
  - TC9 STUDENT gọi generate → 403.
- Gates: BE full suite, `ModuleStructureTest`; FE tsc/eslint/vitest.
- Báo cáo `pte-doc/projects/plans/reports/261025-hung-practice-study-pack-mock-tests-report.md`: lệnh + kết quả, bảng tiêu chí §9 → bằng chứng, quyết định D1–D10, rủi ro còn lại, TC chưa chạy (nếu có, nói rõ).
- Cập nhật `plan.md` (checkbox + trạng thái quality/testing). Xoá `pte-api/.playwright-mcp` cuối cùng.
- **Không commit/push** khi Hung chưa bảo; khi được bảo: commit theo feat, tác giả `duckhynh`, không dòng Claude.

## Design Constraints

- Script giữ phong cách hiện có (`Invoke-SeedApi`, `Write-Host "== … =="`), ASCII, không thêm phụ thuộc.
- SQL kiểm chứng chạy bằng `docker exec pte-postgres psql -U pte-db -d pte`.

## Related files

- `pte-api/scripts/seed-local-practice-question-bank.ps1`
- `pte-doc/projects/plans/reports/261025-hung-practice-study-pack-mock-tests-report.md` (mới)
- `pte-doc/projects/plans/hung-practice-study-pack-mock-tests/plan.md`

## Steps

1. Thêm `-MockTests` vào script; chạy seed.
2. Chạy gates BE/FE.
3. Chạy TC1–TC9, chụp bằng chứng (ảnh/SQL).
4. Viết báo cáo, cập nhật plan.
5. Dọn `.playwright-mcp`; báo Hung và chờ lệnh commit.

## Success Criteria

- Mọi tiêu chí spec §9 có bằng chứng trong báo cáo hoặc được ghi rõ là chưa chạy kèm lý do.
- Gates xanh.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
