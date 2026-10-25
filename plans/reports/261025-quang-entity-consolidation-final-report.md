# Báo cáo cuối: tinh gọn mô hình entity pte-api (12 phase)

Ngày: 2026-10-25 · Người thực hiện: Claude (theo kế hoạch `pte-doc/projects/plans/quang-entity-consolidation/`).
Không có commit hay push nào được tạo; toàn bộ thay đổi nằm trong working tree để anh/chị review.

## 1. Kết quả chính

| Chỉ số | Trước | Sau |
|---|---|---|
| `@Entity` | 90 | **45** (ngưỡng ≤ 45) |
| Bảng Postgres | 93 | **52** (ngưỡng ≤ 55) |
| Migration Flyway | 128 file | **1 file** `V1__baseline.sql` |
| Endpoint REST (exporter) | 328 | **260** (ngưỡng ≤ 260) |
| Test backend | — | **2852 pass, 0 lỗi**; 16 skip khi bật DB test (spike AI cần key thật) |
| Test web | — | api-client 623, tenant-web 540, vendor-web 68, đều pass; typecheck sạch |

Cả 12 phase đã có báo cáo chất lượng (APPROVED + receipt) và báo cáo test trong `quality/` và `tests/` cùng thư mục plan.

## 2. Đã làm theo từng nhóm phase

- **Phase 1–9:** nền tảng (IdempotencyKey, AuditLog...), Organization/User, thương mại, nội dung, ca thi, ghi danh, bài làm, `AnswerEvaluation` (xem báo cáo từng phase).
- **Phase 10 (chấm B & báo cáo):** `GradingAssignment`+`GradingIssue`; trạng thái chấm/công bố là field của `ExamSession`; loại trừ attempt nằm trên `ExamAttempt`; `AttemptReport` → `ExamResult` (thêm 5 cột điểm). Gỡ preview/confirm phân công.
- **Phase 11:** `PracticeResponse`; idempotency practice qua `IdempotencyKey`; notification gộp còn `Notification`, `NotificationRecipient`, `NotificationRecipientStream` (+ `Announcement`, `NotificationLog` giữ riêng); sinh `V1__baseline.sql` từ DB Hibernate dựng và xoá 128 migration cũ.
- **Phase 12:** `PATCH .../{id}/status {action, reason?}` thay hơn 50 POST/DELETE đổi trạng thái; một bộ endpoint attendance dùng chung cho Host/Proctor; gỡ `/internal/**` và các route không còn ai gọi; sửa client `pte-web` và script seed cùng phase.

## 3. Lỗi nghiệp vụ thật phát hiện và đã sửa khi chạy thử

1. Examiner **finalize** không chọn nguồn điểm EXAMINER và không báo tiến độ → phiên chấm tay không bao giờ công bố được. Nay finalize chọn nguồn EXAMINER và hoàn tất chấm ngay trong cùng commit.
2. `GlobalExceptionHandler` trả **500** cho: `ResponseStatusException` (409/404 của examiner), route không tồn tại, sai verb, thiếu tham số query, sai content-type. Nay trả 4xx đúng (404/405/400/415).
3. `readyAttemptCount` của preflight công bố có thể **âm** khi có blocker cấp ca thi.
4. Bảng `notification_inbox_snapshots` không có entity nên DB do Hibernate dựng thiếu bảng (API snapshot inbox sẽ lỗi); đã đưa vào `000-postgres-objects.sql` và V1.
5. Khoá idempotency của practice có thể vượt cột 128 ký tự; nay băm khoá client.
6. Hai script seed vẫn gọi route đã gộp (`plans/{id}/activation`, `questions/{id}/unarchive`, `sessions/{id}/publish|open`...); đã cập nhật.

## 4. Chênh lệch so với spec (đã ghi trong ghi chú từng phase)

- Loại trừ attempt nằm trên `ExamAttempt` (không phải `ExamResult.excluded`) vì `ExamResult` chỉ tạo khi công bố.
- Trọng số QuestionType giữ ở `ExamDefinitionItem` (quyết định phase 5), không đọc từ itembank.
- `Announcement` và `NotificationLog` không gộp vào `Notification` (vòng đời khác); vẫn đạt ngưỡng 45.
- Tài khoản vừa HOST_ADMIN vừa PROCTOR nay luôn thấy attendance dạng host.
- Phase 12 đạt đúng 260 nhờ gỡ các route không có consumer và gộp trạng thái; **không** gộp các cặp single/bulk hay `merge/split/transfer` vì đổi hình dạng request.

## 5. Việc anh/chị cần quyết định hoặc kiểm tra

1. **Triển khai production:** `V1__baseline.sql` không áp lên được DB đã migrate bằng lịch sử cũ. Trước lần deploy đầu phải drop và tạo lại DB `pte` (kể cả bảng `flyway_schema_history`), giữ nguyên volume Caddy. Đã ghi trong `AGENTS.md`.
2. **Test Postgres (bổ sung 2026-10-25):** đã chạy trên container Postgres tạm riêng (`pte-test-pg`, cổng 55439; cách dựng trong `local-dev-runbook.md`): 42/42 pass sau khi sửa test cho mô hình mới (thiếu bean `IdempotencyKeyService`/Jackson; `InboxTestSchema` nay nạp V1 bằng Flyway thay vì tách `;`; xoá spike `JsonColumnH2SpikeTest` vì entity test của nó làm `validate` trên Postgres thất bại; race khác payload cùng khoá nay chấp nhận 409 in-flight). Full suite có DB test: 2852 test, 0 lỗi, 16 skip (spike AI cần key thật).
3. **Chưa xác minh:** công bố chế độ AI_ONLY (điểm AI local là STUB nên không chọn được); luồng HTTP của practice trên Docker; `pte-app` (Flutter) chưa chạy analyze/test sau khi đổi route attendance (`pte-app` không gọi route đã đổi theo grep).
4. **Nợ có sẵn:** (đã xử lý 2026-10-25) `pte-app` gỡ 6 tính năng host/giám thị (`scheduling`, `scoring_review`, `live_proctor`, `host_users`, `host_audit`, `host_console`) vốn gọi đường gateway cũ trả 404 — host/giám thị làm trên `pte-web`; app nay chỉ cho tài khoản `STUDENT`, role khác thấy màn từ chối + đăng xuất (`flutter analyze` không lỗi mới, `flutter test` 609 pass). Còn lại: 69 lời gọi `now()` thay `Clock`, 23 file > 300 dòng, các thư mục `internal/` quá đông → plan `pte-doc/projects/plans/quang-api-maintainability/` (chờ duyệt); code lỗi của `ResponseStatusException` chỉ là tên status.
5. **Script seed (đã sửa):** `seed-local-exam-ready.ps1` từng lỗi 403 ở preflight của học viên vì gọi trước `opensAt` (backend đúng: không cho vào trước giờ mở); nay script chờ tới `opensAt`.
6. Đã xoá: 128 migration cũ, `seed-plan-b.sh` (lỗi thời), 9 test chỉ kiểm nội dung migration cũ, `/internal/**`.

## 6. Bằng chứng

- Inventory trước/sau, diff endpoint và feature map: `pte-doc/plans/reports/assets/261025-entity-consolidation-parity/` (`api-inventory.after.json`, `endpoint-diff.json`, `feature-map.after.md`) cùng `261024-entity-consolidation-api-inventory/` (trước).
- Bảng thay đổi endpoint cũ → mới: cuối `spec.md`.
- Gate Docker cuối: DB trống → Flyway V1 → `validate` → healthy → đăng nhập `admin@test.local` và `host.e2e@test.local` → seed → làm bài → chấm tay → công bố → học viên xem kết quả.
