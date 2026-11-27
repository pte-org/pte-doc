# Phase 07: kiểm tra và tài liệu

**Trạng thái:** [ ] Chưa làm · **Phụ thuộc:** 01–06

## Việc cần làm

- [ ] pte-api: `.\mvnw.cmd -pl app test` (toàn bộ). Báo đúng các lỗi có sẵn không liên quan nếu còn: `SourceFileSizeTest` (ExamPublishService), `BillingOverviewQueriesTest`, `AdminDashboardControllerTest`, `ModuleStructureTest`.
- [ ] pte-web: `tsc`, `eslint`, vitest cho vendor-web và api-client.
- [ ] Kiểm tra tay trên local, sau khi rebuild container `app` và áp migration V60 bằng tay (local dùng `local-schema`):
  1. Lô 6 câu, 2 câu mỗi job, 3 luồng. Dừng khi 3 luồng đang viết thì lô `PAUSED` trong khoảng 2 giây và không job nào giữ lease.
  2. Tạo lô khác trong lúc dừng thì bị từ chối.
  3. Tiếp tục: đủ 6 câu, đúng thứ tự, không có câu `CANCELLED`.
  4. Dừng rồi hủy: lô `CANCELLED`, quota hôm nay giảm đúng số câu của các job chưa chạy.
  5. Tự hủy: admin đặt hạn 1 giờ trong panel "Giới hạn", dừng lô, rồi lùi `paused_at` trong DB local quá 1 giờ. Chờ vòng quét: lô `CANCELLED`, có audit hệ thống. Đặt lại hạn về 0: lô dừng không bị hủy.
- [ ] Báo cáo `pte-doc/plans/reports/YYMMDD-ai-generation-batch-pause-verification.md`.
- [ ] Cập nhật `AGENTS.md` (mục snapshot): trạng thái mới, endpoint mới, migration V60, biến env mới.
- [ ] Deploy: không bắt buộc thêm env. `QUESTION_GEN_BATCH_PAUSED_EXPIRY_HOURS` chỉ là giá trị dự phòng; admin sửa trên giao diện.
