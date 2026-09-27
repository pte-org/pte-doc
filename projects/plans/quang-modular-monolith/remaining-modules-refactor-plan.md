# Kế hoạch refactor các module còn lại — Phase 04–11

**Plan cha:** [plan.md](plan.md)
**Spec:** [spec.md](spec.md)
**Branch:** `quang/refactor/backto-monolith` (`pte-api`)
**Ngày lập:** 2026-09-15
**Trạng thái:** Draft; chưa bắt đầu Phase 04

---

## Mục đích

Đây là mục lục và execution overview cho các module còn lại sau Phase 03. Hướng
dẫn triển khai chi tiết đã được tách thành một file cho từng phase, cùng format
với [Phase 01](phase-01-khung-monolith.md), [Phase 02](phase-02-identity.md) và
[Phase 03](phase-03-tenancy-enrollment.md).

Mục tiêu cuối cùng là đưa bounded context vào `pte-api/app`, giữ API công khai,
giữ tenant isolation và loại bỏ các read-model đồng bộ qua service boundary.

---

## Baseline

- Phase 01–02 đã qua quality gate.
- Phase 03 Tenancy + Enrollment đã qua quality gate; `app` có 142 test xanh.
- `shared/audit` đã được tổ chức thành `domain/`, `dto/`, `internal/`;
  service công khai vẫn ở package root.
- Các service nguồn vẫn giữ nguyên làm safety net cho tới Phase 11.
- Package đích trong app đã có: `media`, `itembank`, `assessment`, `session`,
  `attempt`, `scoring`, `proctoring`, `notification`, `reporting`.

---

## Bản đồ phase

| # | Phase | Nguồn | Số file | Đích | Tài liệu chi tiết |
|---|---|---|---:|---|---|
| 04 | Media | `services/media` | 21 | `media` | [phase-04-media.md](phase-04-media.md) |
| 05 | Itembank + Assessment | `services/authoring` | 56 | `itembank`, `assessment` | [phase-05-itembank-assessment.md](phase-05-itembank-assessment.md) |
| 06 | Session | `services/scheduling` | 89 | `session` | [phase-06-session.md](phase-06-session.md) |
| 07 | Attempt ★ | `services/exam-delivery` | 83 | `attempt` | [phase-07-attempt.md](phase-07-attempt.md) |
| 08 | Scoring | `services/scoring` | 60 | `scoring` | [phase-08-scoring.md](phase-08-scoring.md) |
| 09 | Proctoring + Notification | `services/proctor`, `notification` | 44 + 29 | `proctoring`, `notification` | [phase-09-proctoring-notification.md](phase-09-proctoring-notification.md) |
| 10 | Reporting | `services/reporting` | 43 | `reporting` | [phase-10-reporting.md](phase-10-reporting.md) |
| 11 | Cutover | service tree, gateway, compose | — | app monolith | [phase-11-cutover.md](phase-11-cutover.md) |

★ Phase 07 là mốc demo luồng thi đầu-cuối.

---

## Dependency order

```text
shared ──┬── tenancy + identity + enrollment (đã port)
         └── media
               └── itembank ──> assessment ──> session ──> attempt ──> scoring ──> reporting
                                      │             │          │
                                      │             └──────────┴──> proctoring
                                      └───────────────────────────────────────────────┐
                                                                                       └──> notification
```

Chiều mũi tên là chiều import/call public API. `notification` nhận application
event nhưng không giữ bản sao User; email resolve qua `identity`. `proctoring`
có thể gọi public command của `attempt` cho force-submit; `attempt` không import
ngược `proctoring`.

---

## Ràng buộc chung

1. Port logic hiện có; không viết lại nghiệp vụ chỉ vì chuyển HTTP thành lời gọi hàm.
2. Mỗi phase là một commit riêng; app compile, test và Modulith verify phải xanh.
3. Mọi query dữ liệu tenant phải có `tenantId`; không mở repository nội bộ module
   khác.
4. Giữ API path, request/response contract, status code, pagination và auth role.
5. Public API ở package root; repository/controller/DTO implementation ở
   `internal/`.
6. Một Postgres, một schema; migration monolith đánh số liên tục từ V1 hiện có.
7. Không port `OutboxEntry`, `ProcessedEvent`, `EventIdempotencyGuard`,
   `StudentRosterEntry`, `UserDirectoryEntry`, `AnswerProjection`,
   `ProjectionBackfill`, projection consumer, rebuild/export controller.
8. RabbitMQ chỉ dùng cho AI scoring, email và media work thật; không dùng để đồng
   bộ bản sao giữa các module.
9. Không xóa `services/` trước Phase 11; trong các phase trước, test source vẫn
   là regression safety net.

---

## Migration sequence dự kiến

| Migration | Phase | Phạm vi |
|---|---|---|
| V5 | 04 | Media |
| V6–V7 | 05 | Itembank, Assessment |
| V8 | 06 | Session |
| V9 | 07 | Attempt |
| V10 | 08 | Scoring |
| V11–V12 | 09 | Proctoring, Notification |
| V13 | 10 | Reporting canonical record |

Phase 11 không thêm migration; chỉ cutover infrastructure và xóa service tree sau
khi smoke test/rollback rehearsal đạt.

---

## Quality gate chung

Trước khi chuyển phase:

- [ ] `mvn -pl app test` xanh.
- [ ] `mvn -pl app -DskipTests compile` xanh.
- [ ] `ApplicationModules.verify()` pass.
- [ ] Test service nguồn liên quan vẫn xanh hoặc có deviation được ghi rõ.
- [ ] Tenant isolation, API contract và migration đã được kiểm chứng.
- [ ] Scan không có client HTTP hoặc artifact synchronization không còn cần thiết.
- [ ] Quality report và receipt hợp lệ.
- [ ] Commit riêng với conventional message; chưa push nếu chưa được yêu cầu.

---

## Trạng thái

| Phase | Trạng thái | Điều kiện bắt đầu |
|---|---|---|
| 04 Media | **Hoàn tất** (gộp Phase A với 05) | Phase 03 receipt hợp lệ; MinIO test strategy sẵn sàng |
| 05 Itembank + Assessment | **Hoàn tất** — port xong, 181/181 test xanh, quality gate APPROVED | Phase 04 app xanh |
| 06 Session | **Hoàn tất** — port xong, 209/209 test xanh, quality gate APPROVED | Phase 05 snapshot API ổn định (đã sẵn sàng — `AssessmentService.getSummary`) |
| 07 Attempt ★ | **Hoàn tất** — port xong, 301/301 test xanh, quality gate APPROVED | Phase 06 entitlement/composition xanh (đã sẵn sàng — `SessionService.checkEntitlement`) |
| 08 Scoring | **Hoàn tất** — port xong, 382/382 test xanh, quality gate APPROVED | Phase 07 end-to-end flow xanh (đã sẵn sàng — `AttemptService.forceSubmit`, `AttemptAnswer` là dữ liệu canonical) |
| 09 Proctoring + Notification | **Hoàn tất** — port xong, 428/428 test xanh, quality gate APPROVED | Phase 08 queue/vendor/email boundary ổn định (đã sẵn sàng — RabbitMQ chỉ còn dùng cho AI scoring work queue, không còn sync artifact) |
| 10 Reporting | **Hoàn tất** — port xong, 479/479 test xanh, quality gate APPROVED | Phase 09 event/public query boundary ổn định (đã sẵn sàng — event dời sang `reporting.dto.event.AttemptPublishedEvent`, notification's listener nhận thật) |
| 11 Cutover | **Hoàn tất** — smoke test thật qua Docker đạt, 5 bug runtime-only đã sửa, `services/` đã xóa, `pom.xml` đã gỡ 10 module cũ | Phase 10 direct-reporting + full smoke test đạt |

Phase A (04+05), Phase 06 (Session), Phase 07 (Attempt ★ — mốc luồng thi
đầu-cuối), Phase 08 (Scoring), Phase 09 (Proctoring + Notification), Phase 10
(Reporting — xóa bỏ hoàn toàn `AnswerProjection`) và Phase 11 (Cutover — xóa
hẳn `services/`, gateway chỉ route vào `app`, 2 replica xác nhận trên một
Postgres) đã hoàn tất. Toàn bộ kế hoạch modular-monolith đã xong; xem
[phase-11-cutover.md](phase-11-cutover.md#quality-and-testing-state) và
[tests/phase-11-cutover-test-report.json](tests/phase-11-cutover-test-report.json)
cho bằng chứng runtime đầy đủ. Còn lại: người dùng tự commit khi sẵn sàng
(Cook không tự commit theo yêu cầu).
