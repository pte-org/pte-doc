# Phase 1: BE foundation

**Repo:** `pte-api` · **Ước lượng:** 1–1.5 ngày · **Phủ:** FR-01, P3 (cấu hình `chat.ai.*`), nền cho NFR-04

## Requirements
Có module `chat` biên dịch được và qua kiểm tra kiến trúc, với cấu hình `chat.ai.*` riêng, schema V7 sẵn sàng cho quota/phiên/lịch sử/cache, và cổng entitlement từ `practice` mà `chat` gọi hợp lệ. Chưa có endpoint hay lời gọi Gemini.

## Design Constraints
- `chat` chỉ phụ thuộc `practice` (qua interface ở gốc package) và `shared`; `practice` không được phụ thuộc ngược `chat`. Không import gì từ `scoring.internal`.
- Không sửa hành vi của `PracticeEntitlementService` hay chấm điểm; chỉ thêm cổng công khai.
- Cấu hình chat tách hẳn khỏi `scoring.ai.*`: khoá riêng, model ghim tên cụ thể (từ chối `-latest`), không dùng chung giá trị mặc định với scoring.
- Mọi bean chat (config, client, service, quota, gate, cache, controller) gắn cùng điều kiện `chat.ai.enabled=true`; khi tắt thì validate `chat.ai.*` được bỏ qua và ứng dụng khởi động không cần key.
- Entity chat tương thích H2 (không `jsonb`, không `columnDefinition`) vì ngữ cảnh test mặc định dùng H2 `create-drop`.
- Mọi lớp tuân thủ kiểm tra kiến trúc: ≤ 15 class mỗi package `internal`, ≤ 300 dòng mỗi file, không đọc thời gian trực tiếp (dùng `Clock` inject; không đăng ký bean `Clock` thứ hai).
- Migration chỉ thêm bảng mới, không đổi bảng hiện có; `ddl-auto: validate` phải pass trên hồ sơ Postgres.

## Steps
1. Kiểm tra số migration kế tiếp (hiện V1–V6, chọn `V7__chat_*.sql`) trên `main` và các nhánh đang mở để tránh trùng; xác minh quy ước cột chung của entity (id, `public_id`, `created_at`… như V5) và entity cha dùng trong `practice/internal/domain`.
2. Dựng khung module `chat` theo khuôn `practice`: `package-info` khai báo module, gốc package chứa API công khai (nếu có), `internal` chia sẵn `controller/service/repository/domain/dto/exception/config/constant/client/prompt`; thêm hằng số (đường dẫn, mã lỗi, tên thuộc tính cấu hình, múi giờ `Asia/Ho_Chi_Minh`, tập giá trị `status` OK/REFUSED/FAILED).
3. Thêm lớp cấu hình `chat.ai.*`: `enabled` (mặc định tắt), khoá API riêng, model ghim, `temperature` thấp, `max-tokens`, timeout, `daily-limit` (≥ 1), `max-input-chars`, `history-size`, số slot đồng thời (mặc định 20). Kiểm tra khi khởi động **chỉ khi `enabled=true`**, gộp mọi lỗi cấu hình vào một thông báo như mẫu `AzureGeminiProviderConfig`. Thêm khối `chat:` vào `application.yml` với biến môi trường `CHAT_AI_*`.
4. Viết migration V7: `chat_usage` (UNIQUE `student_id, usage_date`, `used >= 0`), `chat_session` (khoá chính `session_id`, `student_id`, thời điểm tạo), `chat_message` (session, student, tenant, thời điểm, câu hỏi, câu trả lời — rỗng được cho FAILED, task type, ngôn ngữ, token vào/ra/thinking, `finish_reason`, `from_cache`, `on_topic` cho phép null, **`status` ∈ OK/REFUSED/FAILED có CHECK**, model, phiên bản prompt) với index theo (student, session, status, thứ tự) và (student, thời gian), `chat_answer_cache` (khoá băm UNIQUE, câu trả lời, phiên bản prompt, model, thời điểm; cân nhắc cột `expires_at` tuỳ chọn). Kiểu cột dùng loại phổ thông để entity khớp cả H2 lẫn Postgres.
5. Thêm entity và repository JPA khớp DDL cho các bảng chat (quota sẽ dùng JDBC ở Phase 3 nên chỉ cần entity cho phiên/tin/cache); không dùng `jsonb`/`columnDefinition`.
6. Chốt ranh giới entitlement (chỉ làm sau khi Open Decision a, b, c, e đã được xác nhận): thêm interface công khai ở gốc `practice` (kiểm tra student được mở khoá Practice) và cho `PracticeEntitlementService` implement; ghi lại quyết định Gemini client (A1/A2/A3) — mặc định A1. **Ghi chú:** `assertUnlocked` fail-closed khi `practice.strict-entitlement.enabled=false` (mặc định), khiến chat trả 403; mọi môi trường chạy chat phải đặt `practice.strict-entitlement.enabled=true` và ghi điều này vào `application.yml`/tài liệu cấu hình.
7. Cập nhật `ModuleStructureTest`: thêm `"chat"` vào danh sách module và sửa tên/comment "fifteen" cho đúng số lượng; chạy `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest`.
8. Dựng hạ tầng test Postgres (Open Decision e): thêm phụ thuộc test Testcontainers vào `app/pom.xml` và một **hồ sơ test Postgres riêng** (Flyway bật, `ddl-auto: validate`, URL nạp qua `@DynamicPropertySource`, tách khỏi cấu hình H2 mặc định); thêm test migration V7 chạy trên hồ sơ này, bỏ qua khi không có Docker (khi đó cổng `psql` thủ công ở Phase 5 là bắt buộc).

## Files
- `pte-api/app/src/main/java/com/pte/chat/package-info.java` — khai báo module
- `pte-api/app/src/main/java/com/pte/chat/internal/constant/ChatConstants.java` — đường dẫn, mã lỗi, tên thuộc tính, múi giờ, status
- `pte-api/app/src/main/java/com/pte/chat/internal/config/ChatAiProperties.java` — thuộc tính `chat.ai.*` + validate khi bật
- `pte-api/app/src/main/java/com/pte/chat/internal/domain/{ChatSession,ChatMessage,ChatAnswerCache}.java` — entity (tên cuối cần xác nhận khi đọc entity mẫu)
- `pte-api/app/src/main/java/com/pte/chat/internal/repository/*` — repository JPA
- `pte-api/app/src/main/java/com/pte/practice/` (gốc package) — interface cổng entitlement mới; sửa `practice/internal/service/PracticeEntitlementService.java` để implement
- `pte-api/app/src/main/resources/db/migration/V7__chat_*.sql` — schema chat
- `pte-api/app/src/main/resources/application.yml` — khối `chat:` + ghi chú `practice.strict-entitlement.enabled=true`
- `pte-api/app/src/test/java/com/pte/ModuleStructureTest.java` — thêm `chat`
- `pte-api/app/pom.xml` — Testcontainers; `pte-api/app/src/test/` — hồ sơ/cấu hình test Postgres

## Success Criteria
- `./mvnw test -pl app -Dtest=ModuleStructureTest` pass, danh sách module có `chat`, `modules_have_no_boundary_violations` pass.
- `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest` pass.
- Ứng dụng và ngữ cảnh test H2 `create-drop` khởi động được với `chat.ai.enabled=false` mà không cần key và không có bean chat; với `enabled=true` thiếu key hoặc model chứa `-latest` thì khởi động thất bại, liệt kê đủ mọi lỗi cấu hình.
- Flyway chạy V7 trên Postgres thật (hồ sơ test Postgres hoặc DB dev) không lỗi; Hibernate `validate` không báo lệch; chèn hai dòng cùng (student, ngày) vào `chat_usage` bị từ chối bởi UNIQUE; `chat_message.status` ngoài tập OK/REFUSED/FAILED bị CHECK từ chối.
- `chat` gọi được cổng entitlement mà không vi phạm Modulith.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- V7 trùng số với nhánh khác: kiểm `db/migration` trên các nhánh trước khi đặt tên, đổi số khi cần.
- Entity không khớp DDL làm `validate` thất bại, hoặc kiểu cột chỉ Postgres làm hỏng ngữ cảnh H2: dùng kiểu phổ thông, chạy thử cả hai hồ sơ sớm.
- Thêm interface vào `practice` có thể kéo vòng phụ thuộc: kiểm tra bằng `ModuleStructureTest` ngay sau bước 6.
- Quên đặt `practice.strict-entitlement.enabled=true` làm chat trả 403 khó hiểu: ghi rõ trong cấu hình và tài liệu.
- Testcontainers cần Docker: nếu không có thì test bị bỏ qua và cổng `psql` thủ công ở Phase 5 là bắt buộc, không phải tuỳ chọn.
