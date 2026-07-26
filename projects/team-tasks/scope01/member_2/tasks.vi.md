# Member 2 — Flutter: Luồng thi của Student

*[English version](tasks.md)*

## Quyết định cần chốt trước khi code

`pte-app/` hiện tại là scaffold từ trước pivot (`aptis_app`, 1 commit, trỏ backend khác). Phần `lib/core/` (Dio HTTP client + interceptor, Drift offline answer outbox, timer service monotonic, sync engine chạy nền) có kiến trúc khá generic — không gắn với domain Aptis — có thể đáng để tái dùng nguyên cho luồng exam-delivery của `pte-api`, vì đúng cái hình dạng cần (offline-resilient, server-authoritative, không mất answer). Phần `lib/features/*` (word-matching, grammar MCQ, listening, reading, speaking) là task type riêng của Aptis, KHÔNG khớp với task type Milestone-1 của PTE (`MC_READING_SINGLE`, `READ_ALOUD`, `WRITE_ESSAY`) hay contract của `pte-api`.

**Trước khi bắt đầu: xác nhận lại với leader xem nên (a) giữ `core/` và viết lại `features/`, hay (b) làm mới hoàn toàn.** Đừng tự đoán — đây là câu hỏi leader chưa trả lời tại thời điểm bàn giao. Nếu tái dùng `core/`, đọc kỹ `pte-app/README.md` trước (có ghi chi tiết kiến trúc offline-outbox) và đổi `AppConfig.apiBaseUrl` trỏ về gateway (`http://localhost:8080/api` lúc dev), không phải `api.aptis.example.com`.

## Nguồn contract chuẩn

Chưa có OpenAPI spec sinh sẵn. Đọc thẳng file controller + DTO của từng service:
- Auth: `pte-api/services/iam/src/main/java/com/pte/iam/controller/*` — login, refresh, JWKS.
- Luồng attempt: `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/controller/{AttemptController,TimerController}.java` + `dto/request`/`dto/response` của nó.
- Upload media: `pte-api/services/media/src/main/java/com/pte/media/controller/MediaController.java` (luồng presigned PUT cho audio Read Aloud).
- Report: `pte-api/services/reporting/src/main/java/com/pte/reporting/controller/ReportController.java`.
- Mọi request đi qua gateway (`gateway/src/main/resources/application.yml` liệt kê path prefix của từng service, ví dụ `/api/exam-delivery/**`).

## Task 1 — Auth

- Màn login → gọi endpoint login của `iam` → lưu access+refresh token (tránh lưu plain SharedPreferences nếu có thể; nếu tái dùng `core/network/token_store.dart`, lưu ý `InMemoryTokenStore` hiện tại đang ghi rõ "NOT production-ready" — cần sửa).
- Refresh 401 trong suốt (nếu tái dùng `core/`, `token_refresh_interceptor.dart` đã có sẵn pattern này — kiểm tra lại xem còn chạy đúng với contract refresh thật của iam không).
- JWT có claim `tenant_id` + `roles` — chỉ decode phía client để phân nhánh UI (student vs host), đừng bao giờ tin nó cho việc gì liên quan bảo mật (server luôn re-validate lại).

## Task 2 — Start attempt

- Gọi endpoint start-attempt của exam-delivery với `sessionPublicId` (student cần lấy id này từ đâu đó — thống nhất với Member 3 xem student có thấy list session không, hay host chia sẻ session ID/link cho scope Milestone 1).
- Xử lý case "đã attempt rồi" (resume attempt đang dang dở vs. từ chối attempt lần 2) — backend enforce bằng unique constraint ở DB; app cần phản hồi UI hợp lý, không phải hiện thẳng lỗi 409 thô.

## Task 3 — UI làm bài (3 loại task)

- **`MC_READING_SINGLE`**: hiện prompt + options, chọn 1, submit `orderIndex` làm answer payload (chuỗi số dạng decimal, ví dụ `"2"` — xem javadoc của `SubmitAnswerRequest` để biết chính xác contract payload theo từng loại task).
- **`READ_ALOUD`**: ghi âm (package `record` đã có sẵn trong dependency của pte-app), upload qua luồng presigned-PUT của media (`POST /media/objects` → PUT vào URL trả về → `POST /media/objects/{id}/complete`), sau đó submit `MediaObject.publicId` trả về làm answer payload — **không phải audio thô** (ADR-003: dữ liệu binary không bao giờ đi qua tầng API transactional).
- **`WRITE_ESSAY`**: text editor, đếm từ so với `minWordCount`/`maxWordCount` của item đã pin, submit text thô làm payload.

## Task 4 — Timer server-authoritative

- Poll hoặc subscribe endpoint timer-state của exam-delivery để lấy `prepDeadline`/`responseDeadline`. Timer phía client chỉ để UX — đừng bao giờ tin nó để enforce; server tự động hết-giờ/tự-submit khi client gọi `getNextTask`/`submitAnswer` quá deadline.
- Tự động advance UI khi server báo task đã hết giờ (đừng chỉ đứng hình — gọi endpoint next-task và làm theo cái nó trả về).

## Task 5 — Submit & hoàn thành

- Gọi submit-answer và submit-attempt. Nếu tái dùng `core/sync` (offline outbox + `SyncEngine`), cho việc submit answer đi qua Drift outbox để app bị kill / mất kết nối giữa chừng lúc thi không làm mất answer — đây là thuộc tính reliability quan trọng nhất của màn này (cả thiết kế exam-delivery tồn tại là để bảo vệ đúng cái này).
- Màn hoàn thành → poll `reporting` để lấy report đã publish; trước khi publish, hiện trạng thái "đang chờ host publish", không phải lỗi.

## Task 6 — Màn kết quả/report

- Hiện điểm scaled 10–90 theo từng skill, trạng thái "insufficient data" rõ ràng (không để trống/trông như bị lỗi — Milestone 1 sẽ hiện insufficient data cho mọi skill trừ Reading cho tới khi Member 4 nối AI vendor thật).

## Sản phẩm bàn giao

- Student login được, làm hết 1 attempt qua cả 3 loại task, sống sót khi bị kill app giữa chừng mà không mất answer (nếu build được offline-outbox), và thấy report sau khi được publish.
- `flutter analyze` và `flutter test` sạch (theo quy tắc bắt buộc trong `pte-app/CLAUDE.md` — không hardcode string/color, dispose hết controller, kiểm tra mounted sau await, BLoC event là sealed class).
