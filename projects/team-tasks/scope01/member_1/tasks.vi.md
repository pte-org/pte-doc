# Member 1 — Verify Runtime Backend & Hardening

*[English version](tasks.md)*

## Vì sao việc này cần làm trước

Cả 12 service của `pte-api` mới chỉ được verify bằng `mvn install` (compile + quality review). Chưa từng chạy với Postgres/Kafka/Redis/RabbitMQ/MinIO/Mailpit thật. Đây là việc có đòn bẩy cao nhất lúc này — Member 2–4 đều cần 1 backend chạy được thật để tích hợp vào.

## Task 1 — Dựng stack lên

- `cd pte-api && docker compose up -d` — dựng Postgres (có `wal_level=logical` cho Debezium), Redis, MinIO, RabbitMQ, Kafka (KRaft, single-node), Schema Registry, Debezium Connect, Jaeger, Mailpit.
- Kiểm tra container one-shot `debezium-connectors-setup` trong `docker-compose.yml` có đăng ký hết các connector trong `docker/debezium/connectors/*.json` không (8 connector: admin, authoring, exam-delivery, iam, proctor, reporting, scheduling, scoring). Verify bằng `curl http://localhost:8092/connectors`.
- Chạy từng service trong 12 service (`services/*` + `gateway`) — dùng `mvn spring-boot:run` từng module hoặc chạy file jar đã build. `application.yml` của mỗi service đều có default localhost hợp lý; kiểm tra `.env`/`.env.example` ở root `pte-api/` xem có giá trị nào cần set thật không (internal service key phải khớp nhau giữa tất cả service — hiện đang dùng chung 1 giá trị dev mặc định, kiểm tra xem có đồng nhất không).
- Sửa mọi thứ không start được. Nghi phạm thường gặp: thứ tự chạy Flyway migration, thiếu DB role/database (đáng lẽ được tạo sẵn bởi `docker/postgres/init/01-create-databases.sql` — kiểm tra đủ 12 cặp database/role, kể cả `proctor` và `notification` mới thêm sau), Kafka topic auto-create, khai báo queue/exchange RabbitMQ (queue AI-scoring của scoring, queue email của notification).

## Task 2 — Smoke-test critical path end-to-end

Đi hết luồng chính của Milestone 1 bằng tay (Postman/curl/httpie — cái nào nhanh với bạn thì dùng), theo đúng thứ tự, dùng JWT thật lấy từ `iam`:

1. `admin` onboard 1 tenant (tổ chức) → xác nhận `iam` consume `TenantOnboarded` và tenant dùng được.
2. `iam` tạo 1 user host, 1 user proctor, 1 user student trong tenant đó. Login từng người, kiểm tra role/tenant claim trong JWT đúng chưa.
3. Với vai host: `authoring` — tạo vài câu hỏi (ít nhất 1 `MC_READING_SINGLE`, 1 `READ_ALOUD`, 1 `WRITE_ESSAY`), tạo blueprint, publish snapshot.
4. Với vai host: `scheduling` — tạo session từ snapshot đó, có thể set composition practice-subset, enroll student, gán proctor.
5. Với vai student: `exam-delivery` — start attempt (kiểm tra guarded sync pull sang `scheduling`+`authoring` chạy đúng, snapshot pin đúng), đi hết cả 3 loại task, kiểm tra timer server-side có enforce thật không (cố tình để 1 task hết giờ xem sao), submit answer, submit attempt.
6. Kiểm tra `AttemptSubmitted`/`AnswerSubmitted` có thật sự lên Kafka không (topic `outbox.event.ExamAttempt`) qua Debezium — dùng console consumer nếu cần.
7. Với vai host: `scheduling` — gọi `POST /sessions/{id}/score` (`ScoringRequested`). Kiểm tra `scoring` xử lý: câu MC_READING_SINGLE chấm đồng bộ ngay; câu READ_ALOUD/WRITE_ESSAY được đẩy vào RabbitMQ, stub vendor xử lý, WRITE_ESSAY rơi vào trạng thái `AI_SCORED_PENDING_REVIEW`.
8. Với vai host: duyệt essay đang chờ review (`POST /scoring/answers/{id}/review`).
9. Với vai host: bấm publish (`POST /sessions/{id}/publish`). Kiểm tra `reporting` đánh dấu report đã publish và emit `AttemptPublished`.
10. Với vai student: `GET /reports/attempts/{id}` — kiểm tra điểm Reading tính đúng, các skill khác báo "insufficient data" (do chưa có AI vendor thật).
11. Kiểm tra `notification` có gửi email thật không — check Mailpit UI (`http://localhost:8025`) xem có email `StudentEnrolled` và `AttemptPublished` không.
12. Với vai proctor: kết nối STOMP vào endpoint `/ws` của `proctor` (cần 1 client test STOMP — `wscat` không nói được STOMP; dùng script nhỏ hoặc Postman hỗ trợ WS với raw STOMP frame), mở 1 `ProctorSession` cho session ở trên, gửi lệnh `FORCE_SUBMIT` hoặc `EXTEND_TIME` cho attempt của student, kiểm tra `exam-delivery` có áp dụng đúng không. Flag 1 violation, kiểm tra có hiện trong audit log của `notification` không và `HOST_ADMIN` có nhận email không.

Ghi lại mọi lỗi gặp phải và cách bạn sửa. Nếu chỗ sửa không đơn giản (không chỉ là sửa config sai), ghi vào mục "Runtime-verification TODO" hoặc "Risks" của file `phase-XX-*.md` liên quan để tài liệu luôn đúng thực tế.

## Task 3 — Kiểm tra độ chịu lỗi của event backbone

- Kill 1 consumer giữa chừng lúc đang xử lý (ví dụ dừng `scoring` ngay sau khi nó đọc message Kafka nhưng chưa commit) rồi restart lại — kiểm tra ledger idempotency (`ProcessedEvent`) có chặn xử lý trùng khi message bị gửi lại không.
- Tương tự với RabbitMQ: cố tình cho vendor chấm điểm fail 3 lần (stub có thể chỉnh để throw lỗi) và kiểm tra nó có rơi vào DLQ đúng không, câu trả lời hiện `SCORING_FAILED` chứ không bị retry mãi mãi.
- Kiểm tra độ trễ CDC của Debezium khi có burst ghi liên tục (không cần đo khoa học gì, chỉ cần chắc là không bị rớt âm thầm).

## Task 4 — Integration test cho critical path

Project này cố tình bỏ qua test trong lúc cook (quyết định có chủ đích, không phải thiếu sót). Giờ code đã có và (hy vọng) chạy được, thêm integration test cho phần quan trọng nhất:

- `exam-delivery`: state machine của attempt (start → in-progress → submit), timer hết giờ tự động advance, chặn double-attempt.
- `scoring`: trigger host-gated (không bao giờ tự chạy khi submit), độ đúng của objective scoring, hành vi retry/DLQ của queue AI-scoring.
- Testcontainers (Postgres + Kafka + RabbitMQ) hợp với stack này nhất — kiểm tra xem đã có dependency này ở đâu chưa (tính đến lúc bàn giao thì chưa) trước khi thêm vào toàn project.

Đừng cố phủ hết coverage cho cả 12 service một mình — task này chỉ giới hạn ở critical path. Phần coverage còn thiếu thì báo lại cho team, không cần ôm hết.

## Sản phẩm bàn giao

- `docker compose up` chạy được và cả 12 service hoạt động, critical path đã chứng minh chạy đúng end-to-end.
- Các fix được commit rõ ràng (commit nhỏ, dễ review — không gộp thành 1 commit "fix everything").
- Cập nhật mục "Runtime-verification TODO" trong các phase doc đã có sẵn mục này (phase-04, phase-05, phase-08 đã có sẵn — điền vào những gì bạn thực sự tìm thấy).
- 1 bản tóm tắt ngắn (thêm file `findings.md` vào folder này) ghi lại: cái gì hỏng, bạn sửa thế nào, cái gì còn rủi ro cho người tiếp theo.
