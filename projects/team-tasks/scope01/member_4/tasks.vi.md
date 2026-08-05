# Member 4 — Nối AI Vendor thật + Dockerize + CI

*[English version](tasks.md)*

## Task 1 — Nối AI vendor thật (đang chờ API key)

`SpeechScoringClient`/`EssayScoringClient` của `scoring` là interface sạch (`pte-api/services/scoring/src/main/java/com/pte/scoring/vendor/`); implementation duy nhất hiện có là `StubSpeechScoringClient`/`StubEssayScoringClient` — trả điểm giả cố định, không gọi mạng, đã ghi chú rõ đây chỉ là placeholder. Đọc kỹ `pte-doc/projects/plans/quang-pte-microservice-platform/phase-09-media-speaking-writing-ai-vendor.md` trước khi bắt đầu — file đó ghi rõ:

- Interface seam chính xác (implement `SpeechScoringClient`/`EssayScoringClient`, nối qua config property `scoring.ai.provider`, thay bean stub bằng bean thật).
- **Phát hiện từ việc live-test 2 provider ứng viên** (OpenRouter, OpenCode) — sẽ áp dụng cho provider bạn dùng nếu nó cũng là "reasoning model": response API tách riêng `message.reasoning` với `message.content` — chỉ parse `.content` thôi, không thì sẽ chấm điểm 1 chuỗi rỗng mà không biết. Set `max_tokens >= 800` (budget nhỏ bị ăn hết bởi reasoning token trước khi sinh ra answer content — việc này đã thực sự xảy ra lúc test, response trả về rỗng). Dùng `response_format: {"type":"json_object"}` nếu provider hỗ trợ, để parse ổn định hơn.
- Contract về scale: `AiScoreResult.rawScore()` phải là **0–100**, khớp với scale của `ObjectiveScoringService` (đây là fix có chủ đích trong Phase 9 — objective scoring trước đó là 0/1, đổi riêng để điểm AI và điểm objective average đúng với nhau trong phần aggregation của `reporting`). Đừng làm lệch scale lại.
- `WRITE_ESSAY` cần human review trước khi hiện ra cho student (`AI_SCORED_PENDING_REVIEW` → host duyệt → `SCORED`); `READ_ALOUD` thì không cần. Luồng routing này đã có sẵn trong `AiScoringWorker` — bạn chỉ thay phần gọi vendor thôi, không đụng vào state machine xung quanh.

**Bạn cần 1 API key/model thật sự hỗ trợ input audio cho `READ_ALOUD`** (2 credential đã test ở Phase 9 chỉ nhận text hoặc bị chặn thanh toán) — đây là phụ thuộc bên ngoài do leader cung cấp, không tự gỡ được. Bắt đầu với `WRITE_ESSAY` trước (chỉ cần text, LLM nào cũng dùng được) trong lúc chờ credential hỗ trợ audio.

## Task 2 — ~~Dockerize từng service~~ ✅ Đã xong (2026-08-05) — không còn việc gì ở đây cho bạn

Việc này đã hoàn tất: 1 `pte-api/Dockerfile` multi-stage dùng chung (tham số hoá qua build-arg `SERVICE_MODULE` — 1 Dockerfile dùng lại cho cả 11 module thay vì mỗi service 1 file như task này ban đầu yêu cầu, gọn hơn) + `pte-api/docker-compose.services.yml` (gateway + cả 10 backend service, nối vào các service hạ tầng đã có bằng container name, không dùng `localhost`, vẫn giữ nguyên pattern env-var `${SERVICE_PORT:-default}`). `docker compose -f docker-compose.yml -f docker-compose.services.yml up --build` dựng đủ 17 container (6 hạ tầng + gateway + 10 service), tất cả đều lên `healthy`. Xem mục "Running services locally with Docker Compose" trong `pte-api/README.md` và `pte-doc/projects/plans/phat-docker-compose-services/plan.md` để biết chi tiết đầy đủ.

Lưu ý thêm: danh sách hạ tầng ở trên cũng đã cũ, không liên quan đến task này — `docker-compose.yml` hiện chạy Postgres, Redis, RabbitMQ, MinIO, Mailpit, Jaeger. Kafka/Schema Registry/Debezium đã bị bỏ toàn hệ từ 2026-07-31 (xem note "Superseded-in-part" của ADR-002) — event backbone giờ là RabbitMQ + outbox relay polling ở tầng application, không còn Kafka/Debezium CDC.

## Task 3 — Pipeline CI

- Backend: `mvn install` (compile-only là đủ vì chưa có test suite — thống nhất với Member 1 khi có integration test rồi thì thêm stage `mvn verify` hoặc stage test riêng).
- Frontend: `flutter analyze` + `flutter test` + `dart format --check` (khớp checklist pre-review đã ghi trong `pte-app/README.md`).
- Fail pipeline nếu 1 trong 2 bên fail — đây là rào chắn regression rẻ nhất có thể có trước khi có test coverage thật.

## Task 4 — Audit secrets & environment

- Audit `pte-api/.env.example` xem đủ chưa — mỗi service đọc env var nào (internal service key, password DB, `MAIL_HOST`, `RABBITMQ_*`, key AI vendor khi Task 1 xong) đều nên có placeholder ghi rõ ở đó.
- Internal service key (`INTERNAL_SERVICE_KEY`, dùng cho ranh giới tin cậy service-to-service `/internal/**` — placeholder cho mTLS của ADR-003) hiện đang dùng chung 1 giá trị dev mặc định ở mọi `application.yml`. Kiểm tra xem có đồng nhất thật không, và ghi chú rõ đây là mục "phải đổi trước khi deploy thật" — hiện tại nó không phải secret theo nghĩa thật sự nào cả.

## Sản phẩm bàn giao

- Chấm essay bằng AI thật (không phải stub) chạy được end-to-end, chấm speaking chạy được khi có credential đủ khả năng.
- `docker compose up` dựng được cả platform — cả hạ tầng lẫn service ứng dụng — không cần start tay từng service. ✅ Đã có sẵn từ Task 2 ở trên.
- 1 pipeline CI chạy trên mỗi push/PR cho cả 2 repo.
