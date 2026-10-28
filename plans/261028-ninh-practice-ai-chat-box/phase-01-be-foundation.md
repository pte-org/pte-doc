# Phase 1: BE foundation

**Repo:** `pte-api` · **Ước lượng:** 0.5–1 ngày · **Phủ:** FR-01, P3 (cấu hình `chat.ai.*`), nền cho NFR-04

## Requirements
Có module `chat` biên dịch được và qua kiểm tra kiến trúc, với cấu hình `chat.ai.*` riêng, schema V7 sẵn sàng cho quota/phiên/lịch sử/cache, và cổng entitlement từ `practice` mà `chat` gọi hợp lệ. Chưa có endpoint hay lời gọi Gemini.

## Design Constraints
- `chat` chỉ phụ thuộc `practice` (qua interface ở gốc package) và `shared`; `practice` không được phụ thuộc ngược `chat`. Không import gì từ `scoring.internal`.
- Không sửa hành vi của `PracticeEntitlementService` hay chấm điểm; chỉ thêm cổng công khai.
- Cấu hình chat tách hẳn khỏi `scoring.ai.*`: khoá riêng, model ghim tên cụ thể (từ chối `-latest`), không dùng chung giá trị mặc định với scoring.
- Mọi lớp tuân thủ kiểm tra kiến trúc: ≤ 15 class mỗi package `internal`, ≤ 300 dòng mỗi file, không đọc thời gian trực tiếp (dùng `Clock` inject).
- Migration chỉ thêm bảng mới, không đổi bảng hiện có; `ddl-auto: validate` phải pass.

## Steps
1. Kiểm tra số migration kế tiếp (hiện V1–V6, chọn `V7__chat_*.sql`) trên `main` và các nhánh đang mở để tránh trùng; xác minh quy ước cột chung của entity (id, `public_id`, `created_at`… như V5) và entity cha dùng trong `practice/internal/domain`.
2. Dựng khung module `chat` theo khuôn `practice`: `package-info` khai báo module, gốc package chứa API công khai (nếu có), `internal` chia sẵn `controller/service/repository/domain/dto/exception/config/constant/client/prompt`; thêm hằng số (đường dẫn, mã lỗi, tên thuộc tính cấu hình, múi giờ `Asia/Ho_Chi_Minh`).
3. Thêm lớp cấu hình `chat.ai.*` kiểm tra khi khởi động: `enabled` (mặc định tắt), khoá API riêng, model ghim, `temperature` thấp, `max-tokens`, timeout, `daily-limit` (≥ 1), `max-input-chars`, `history-size`, số slot đồng thời (mặc định 20); gộp mọi lỗi cấu hình vào một thông báo như mẫu `AzureGeminiProviderConfig`. Thêm khối `chat:` vào `application.yml` với biến môi trường `CHAT_AI_*`.
4. Viết migration V7: `chat_usage` (UNIQUE `student_id, usage_date`, `used >= 0`), `chat_session` (khoá chính `session_id`, `student_id`, thời điểm tạo/tin cuối), `chat_message` (session, student, tenant, thời điểm, câu hỏi, câu trả lời, task type, ngôn ngữ, token vào/ra/thinking, `finish_reason`, `from_cache`, `on_topic`, model, phiên bản prompt) với index theo (student, session, thứ tự) và (student, thời gian), `chat_answer_cache` (khoá băm UNIQUE, câu trả lời, phiên bản prompt, model, thời điểm).
5. Thêm entity và repository JPA khớp DDL cho các bảng chat (quota sẽ dùng JDBC ở Phase 3 nên chỉ cần entity cho phiên/tin/cache).
6. Chốt ranh giới entitlement: thêm interface công khai ở gốc `practice` (kiểm tra student được mở khoá Practice) và cho `PracticeEntitlementService` implement; ghi lại quyết định Gemini client (A1/A2/A3) theo Open Decision a trong `plan.md` — nếu chưa được xác nhận thì mặc định A1 (client riêng ở Phase 2).
7. Cập nhật `ModuleStructureTest`: thêm `"chat"` vào danh sách module và sửa tên/comment "fifteen" cho đúng số lượng; chạy `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest`.
8. Quyết định hạ tầng test Postgres (Open Decision e): nếu chọn Testcontainers thì thêm phụ thuộc test vào `app/pom.xml` và một test migration V7 chạy trên Postgres thật.

## Files
- `pte-api/app/src/main/java/com/pte/chat/package-info.java` — khai báo module
- `pte-api/app/src/main/java/com/pte/chat/internal/constant/ChatConstants.java` — đường dẫn, mã lỗi, tên thuộc tính
- `pte-api/app/src/main/java/com/pte/chat/internal/config/ChatAiProperties.java` — thuộc tính `chat.ai.*` + validate
- `pte-api/app/src/main/java/com/pte/chat/internal/domain/{ChatSession,ChatMessage,ChatAnswerCache}.java` — entity (tên cuối cần xác nhận khi đọc entity mẫu)
- `pte-api/app/src/main/java/com/pte/chat/internal/repository/*` — repository JPA
- `pte-api/app/src/main/java/com/pte/practice/` (gốc package) — interface cổng entitlement mới; sửa `practice/internal/service/PracticeEntitlementService.java` để implement
- `pte-api/app/src/main/resources/db/migration/V7__chat_*.sql` — schema chat
- `pte-api/app/src/main/resources/application.yml` — khối `chat:`
- `pte-api/app/src/test/java/com/pte/ModuleStructureTest.java` — thêm `chat`
- `pte-api/app/pom.xml` — Testcontainers (nếu chọn e)

## Success Criteria
- `./mvnw test -pl app -Dtest=ModuleStructureTest` pass, danh sách module có `chat`, `modules_have_no_boundary_violations` pass.
- `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest` pass.
- Ứng dụng khởi động được với `chat.ai.enabled=false` mà không cần key; với `enabled=true` thiếu key hoặc model chứa `-latest` thì khởi động thất bại, liệt kê đủ mọi lỗi cấu hình.
- Flyway chạy V7 trên Postgres thật (Testcontainers hoặc DB dev) không lỗi; Hibernate `validate` không báo lệch; chèn hai dòng cùng (student, ngày) vào `chat_usage` bị từ chối bởi UNIQUE.
- `chat` gọi được cổng entitlement mà không vi phạm Modulith.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- V7 trùng số với nhánh khác: kiểm `db/migration` trên các nhánh trước khi đặt tên, đổi số khi cần.
- Entity không khớp DDL làm `validate` thất bại: đối chiếu quy ước V5 và entity mẫu, chạy thử sớm.
- Thêm interface vào `practice` có thể kéo vòng phụ thuộc: kiểm tra bằng `ModuleStructureTest` ngay sau bước 6.
- Testcontainers cần Docker: có đường lui là test migration bằng DB dev + script `psql` ở Phase 5.
