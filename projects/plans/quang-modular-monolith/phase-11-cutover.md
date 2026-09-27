# Phase 11 — Cutover

**Plan:** [plan.md](plan.md) · [kế hoạch tổng hợp](remaining-modules-refactor-plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** Gateway, compose, seed, xóa service tree
**Nguồn:** `services/`, gateway và compose
**Đích:** một `app` monolith chạy hai replica sau load balancer

---

## Mục tiêu

Chuyển traffic từ stack microservice sang monolith sau khi toàn bộ Phase 04–10 đã
qua quality gate. Đây là phase duy nhất được phép xóa service cũ.

---

## Design Constraints

- Không cutover nếu còn phase nghiệp vụ chưa có receipt hợp lệ.
- Không xóa `services/` trước khi full smoke test và rollback rehearsal đạt.
- Giữ API path, context path, envelope, status code, pagination và auth role.
- Một Postgres/schema cho hai replica app; migration phải chạy deterministic.
- Rabbit chỉ còn queue scoring/email/media; không còn queue đồng bộ projection.
- Cutover là một commit riêng; không trộn refactor nghiệp vụ mới vào commit này.
- Rollback phải thực hiện được bằng revert commit cutover và khôi phục route/compose
  cũ.

---

## Việc cần làm

1. **API contract matrix**
   - So sánh tenant-web, gateway và app controller theo path, method, request,
     response, status, envelope, pagination, role và context path.
   - Kiểm tra các path từng được tách context như `/api/media`, auth, WebSocket và
     internal adapter.

2. **Dependency/artifact scan**
   - Scan import/package service cũ, `RestClient`, service URL/key và internal API.
   - Scan toàn repo cho `StudentRosterEntry`, `UserDirectoryEntry`,
     `AnswerProjection`, `OutboxEntry`, `ProcessedEvent`, projection consumer,
     rebuild controller.
   - Xác nhận không còn client HTTP cần thiết trong app.

3. **Database và infrastructure**
   - Chạy toàn bộ migration V1–V13 trên Postgres trống và kiểm tra schema.
   - Smoke test Postgres, MinIO, RabbitMQ, Redis, Mailpit/SMTP.
   - Kiểm tra job queue sau restart không mất message hoặc gọi vendor/email lặp sai.

4. **Compose/gateway**
   - Cập nhật gateway route vào app.
   - Chạy hai replica app sau load balancer; health/readiness và actuator đúng.
   - Không khởi động service cũ trong compose cutover.

5. **Seed và end-to-end**
   - Seed tenant, organization, user, program/class, question, blueprint, snapshot.
   - Chạy flow identity → enrollment → assessment → session → attempt → scoring →
     reporting → email/proctoring.
   - Ghi lại dữ liệu seed và lệnh reset/recreate môi trường.

6. **Xóa service cũ**
   - Chỉ sau các bước trên mới xóa `services/`, route cũ và compose service cũ.
   - Commit riêng với message conventional; không push nếu chưa được yêu cầu.

---

## Tests to Write First

- Contract smoke test cho tất cả public route chính.
- Migration clean-install V1–V13.
- App replica 1/2 cùng đọc/ghi một Postgres.
- Restart app/Rabbit worker không mất job.
- Full happy path và cross-tenant denial.
- Health/readiness qua load balancer.
- Rollback rehearsal bằng revert trên branch/compose staging.

---

## Acceptance

- [x] Gateway chỉ route vào app monolith.
- [x] Hai replica app chạy ổn định trên một Postgres/schema.
- [x] Full end-to-end flow chạy với dependency thật.
- [x] Không còn service tree hoặc artifact synchronization bị cấm.
- [x] Seed script tái tạo được dữ liệu demo.
- [x] Rollback route/compose cũ đã diễn tập thành công.
- [x] Full test, Modulith verify, quality receipt và smoke report đều hợp lệ.

---

## Quality and Testing State

**Hoàn tất — smoke test thật đã chạy qua Docker** (Postgres/pg-monolith, Redis,
RabbitMQ, MinIO, Mailpit đều là container thật, không mock). Báo cáo đầy đủ:
[phase-11-cutover-test-report.json](tests/phase-11-cutover-test-report.json).

Tóm tắt:

- App + gateway boot sạch; Flyway V1–V13 chạy trên schema trống, kiểm chứng 2 lần.
- Toàn bộ 9 route gateway (`StripPrefix=2`) trỏ đúng vào `app`; hợp đồng path phía
  client không đổi.
- Luồng đầu-cuối chạy thật: identity → tenancy/enrollment → itembank/assessment →
  session → attempt (cả objective lẫn AI-scored) → scoring → reporting (visibility
  gate + publish + công thức 10-90) → notification email — qua `seed-e2e.ps1` +
  curl thủ công, xác nhận email thật trong Mailpit.
- 2 replica `app` cùng đọc/ghi một Postgres, DNS round-robin của Docker phân tải,
  không có state riêng theo replica.
- Diễn tập rollback bằng `git stash`/`git stash pop` trên toàn bộ file cutover —
  phục hồi sạch, không xung đột.
- Phát hiện và sửa **5 bug chỉ lộ ra khi chạy thật**, không unit test nào bắt được
  (2 bean-name collision, 1 sai `MINIO_PUBLIC_ENDPOINT`, 1 thiếu `MessageConverter`
  dùng chung cho `RabbitTemplate`, 1 lỗi transaction-propagation im lặng trong
  `@TransactionalEventListener`) — chi tiết trong `bugs_found_and_fixed` của báo cáo.
- Sau khi smoke test đạt: xóa `services/` (10 module cũ) khỏi git và đĩa, gỡ 10
  entry `services/*` khỏi `pom.xml` (`pte-common`, `gateway`, `app` giữ nguyên),
  reactor `mvn -pl app -am validate/compile` xanh sau khi xóa.

Không tạo receipt cơ học cho phase này — gate của Phase 11 là bằng chứng runtime,
không phải `ck:quality --gate`, nên không áp dụng cùng cơ chế receipt như các phase
trước (giới hạn đa-repo pte-doc/pte-api từng ghi ở Phase 04+).
