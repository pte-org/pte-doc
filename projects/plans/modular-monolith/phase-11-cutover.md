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

- [ ] Gateway chỉ route vào app monolith.
- [ ] Hai replica app chạy ổn định trên một Postgres/schema.
- [ ] Full end-to-end flow chạy với dependency thật.
- [ ] Không còn service tree hoặc artifact synchronization bị cấm.
- [ ] Seed script tái tạo được dữ liệu demo.
- [ ] Rollback route/compose cũ đã diễn tập thành công.
- [ ] Full test, Modulith verify, quality receipt và smoke report đều hợp lệ.

---

## Quality and Testing State

Chưa thực thi. Chỉ đánh dấu hoàn tất sau khi có bằng chứng runtime với Postgres,
MinIO, RabbitMQ, Redis và Mailpit/SMTP; không coi compile/unit test là đủ cho phase
cutover.
