# Phase 05: verification, rollout và tài liệu

**Status:** verification report created; runtime rollout checks pending  
**Dependency:** Phase 02–04  
**Output:** bằng chứng kiểm thử và hướng dẫn vận hành đủ để review, chưa phải production deployment.

## Công việc

1. Chạy backend compile/test theo `docs/CODING_STANDARDS_API.md`; tách lỗi do feature mới khỏi dirty worktree không liên quan.
2. Chạy API-client/vendor-web checks theo `docs/CODING_STANDARDS_WEB.md`.
3. Chạy migration/schema/integration tests với PostgreSQL; xác minh unique published constraint và backward-compatible nullable columns.
4. Chạy security matrix cho Academic Staff, Academic Manager, Platform Author, Platform Admin, Host, Proctor, Examiner và Student.
5. Kiểm tra audit event success/failure, expected version, self-review block và override reason.
6. Tạo seed/import fixture rubric `PTEPREP-PRACTICE-RUBRIC` ở trạng thái `DRAFT`; không seed published trước Academic Manager approval.
7. Kiểm tra Practice catalog không chọn task thiếu published rubric; session cũ và retired rubric vẫn đọc được.
8. Kiểm tra Gemini với fixture/mocked provider, không đưa secret hoặc raw answer vào logs/evidence.
9. Cập nhật report/plan/runbook mô tả lifecycle, role matrix, output limitation và cách tạo revision mới.
10. Lưu report theo convention `pte-doc/plans/reports/YYMMDD-quang-pte-practice-rubric-<type>.md`, assets dưới thư mục `assets` tương ứng.

## Common/shared bắt buộc

- Evidence phản ánh response envelope và error code dùng thật từ common API setup.
- Không tạo test helper riêng nếu shared fixture/factory hiện có đáp ứng được.
- UI evidence phải kiểm tra route và API contract thật, không chỉ snapshot component.
- Không claim production readiness từ local compile, mocked Gemini hoặc seed draft.

## Design Constraints

- Không publish/deploy production trong phase này.
- Không dùng `docker compose down -v`, reset branch hoặc xóa dữ liệu hiện có.
- Không thay đổi chính sách retention hoặc role ngoài phạm vi rubric.
- Report phải ghi rõ automated test, local browser, migration và production boundary riêng biệt.

## Quality and Testing State

- Quality: chạy `ck:quality --changed` sau implementation; blocker/high phải xử lý trước handoff.
- Testing: chạy backend targeted tests và web checks; full suite nếu cook/user chọn.
- Release gate: lifecycle, authorization, immutable pin, historical read, shared client/UI và no-leak checks đều có evidence.
- Final status chỉ là “ready for review” cho đến khi Academic Manager approve rubric seed và operator quyết định rollout.
