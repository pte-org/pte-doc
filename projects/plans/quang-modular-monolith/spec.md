# Spec: Modular Monolith cho pte-api

**Date:** 2026-09-15
**Status:** Draft

---

## Problem Statement

11 microservice tách theo năng lực nghiệp vụ trong khi 2 app frontend tách theo vai
trò, khiến chủ sở hữu không trả lời được câu hỏi "code của host nằm ở đâu?" và không
đủ tự tin trình bày hệ thống khi phỏng vấn. 21% codebase (140/639 file Java, 19 bảng
DB) chỉ phục vụ đồng bộ giữa các service, không phục vụ nghiệp vụ nào. Không có ràng
buộc scale nào bắt buộc phải tách service.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** Là người phát triển, tôi muốn mở đúng một thư mục để sửa một khái niệm
  nghiệp vụ, thay vì lần qua nhiều service.
  Accepted when: Mỗi module chứa đủ Controller, Service, Repository, Entity của nó;
  thay đổi một nghiệp vụ điển hình (ví dụ thêm trường cho Question) chỉ chạm file
  trong một module.

- **[P1]** Là người phát triển, tôi muốn đọc dữ liệu liên quan bằng một câu truy vấn
  thay vì qua projection đồng bộ bằng event.
  Accepted when: `/student-roster` trả dữ liệu từ một câu JOIN trực tiếp; không còn
  `StudentRosterEntry`, `StudentRosterConsumer`, `StudentRosterRebuildService`,
  `ProjectionBackfill`.

- **[P1]** Là người phát triển, tôi muốn giải thích được kiến trúc trong vòng 2 phút.
  Accepted when: Sơ đồ module một trang tồn tại trong repo; mỗi tên module là một
  danh từ nghiệp vụ tự giải thích được nó chứa gì.

- **[P1]** Là student, tôi muốn nộp bài được nhận ngay kể cả khi nhiều người cùng nộp.
  Accepted when: Endpoint nộp bài ghi DB + đẩy queue rồi trả `202` mà không chờ chấm.

- **[P1]** Là người vận hành, tôi muốn chạy toàn hệ thống trên máy cá nhân.
  Accepted when: `docker compose up` khởi động đủ stack với 1 app service, 1 Postgres,
  Redis, RabbitMQ, MinIO.

- **[P2]** Là người vận hành, tôi muốn chịu được burst bằng cách nhân bản app.
  Accepted when: Chạy được ≥2 bản sao sau load balancer, không dính session affinity.

- **[P1]** Là người phát triển, tôi muốn ranh giới module không bị vi phạm âm thầm.
  Accepted when: `ApplicationModules.verify()` của Spring Modulith chạy trong test
  suite và fail khi một module truy cập vào `internal/` của module khác.

- **[P2]** Là sinh viên làm đồ án, tôi muốn sơ đồ kiến trúc luôn khớp với code thật.
  Accepted when: Sơ đồ module được sinh tự động từ code bằng Spring Modulith
  Documenter, không vẽ tay.

- **[P3]** _(ngoài phạm vi)_ Tách lại thành service nếu sau này có nhu cầu scale thật.
- **[P3]** _(ngoài phạm vi)_ Viết lại 2 app Next.js.

---

## Functional Requirements

1. **FR-01:** Codebase gom về một ứng dụng Spring Boot với 12 module nghiệp vụ dưới
   root `com.pte`, đặt tên theo bounded context chứ không theo entity:

   | Module | Chứa | Vai trò |
   |---|---|---|
   | `identity` | User, Credential, RefreshToken, Role | Xác thực, phân quyền |
   | `tenancy` | Tenant, Organization, QuotaTransaction | Đa người thuê |
   | `enrollment` | Program, StudentClass, ClassMembership, Enrollment | Ai thuộc về đâu |
   | `itembank` | Question, QuestionOption | Ngân hàng câu hỏi |
   | `assessment` | ExamBlueprint, BlueprintItem, Snapshot, ExamPolicy | Định nghĩa đề thi |
   | `session` | ExamSession, SessionComposition, ProctorAssignment | Ca thi đã lên lịch |
   | `attempt` | ExamAttempt, AttemptAnswer, AttemptHeartbeat | Lượt làm bài ★ |
   | `scoring` | Score, ScoringJob, AiScorer | Chấm điểm |
   | `proctoring` | ProctorSession, ViolationEvent | Giám sát thi |
   | `reporting` | AttemptReport | Báo cáo, thống kê |
   | `media` | MediaObject | File audio (MinIO) |
   | `notification` | NotificationLog | Email, thông báo |

   Cộng `shared` (security, web, exception, audit, config).

   Sáu module cốt lõi xếp thành dây chuyền đọc được thành câu — dùng làm xương sống
   để giải thích hệ thống:
   `itembank → assessment → session → attempt → scoring → reporting`

2. **FR-02:** Áp dụng quy ước Spring Modulith: API công khai của module đặt ở gốc
   package, chi tiết nội bộ (Repository, Controller) đặt trong `internal/`. Module
   khác chỉ gọi được qua Service công khai.

   ```
   com.pte.attempt/
   ├── Attempt.java              ← module khác dùng được
   ├── AttemptService.java       ← module khác dùng được
   └── internal/                 ← module khác KHÔNG dùng được
       ├── AttemptRepository.java
       └── AttemptController.java
   ```

2b. **FR-02b:** Thêm `spring-modulith-starter-core` + `spring-modulith-starter-test`.
   `ApplicationModules.verify()` chạy như một test thường, fail build khi ranh giới
   bị vi phạm. Sinh sơ đồ module bằng `Documenter` để dùng trong báo cáo đồ án.
3. **FR-03:** Một instance Postgres duy nhất thay cho `pg-core`, `pg-exam`,
   `pg-live`, `pg-async`.
4. **FR-04:** Xoá toàn bộ hạ tầng đồng bộ giữa service: `OutboxEntry` (8 bản),
   `ProcessedEvent` (7 bản), `StudentRosterEntry`, `UserDirectoryEntry`,
   `AnswerProjection`, `ProjectionBackfill`, cùng consumer/relay/idempotency guard
   đi kèm.
5. **FR-05:** Giữ RabbitMQ **chỉ** cho việc async thật: chấm điểm AI, gửi email,
   xử lý media. Không dùng để đồng bộ dữ liệu giữa module.
6. **FR-06:** Nộp bài ghi DB rồi đẩy job vào queue và trả `202` kèm mã tra cứu; chấm
   điểm chạy ở worker tiêu thụ queue.
7. **FR-07:** Giữ MinIO cho file audio, Redis cho cache/session/rate-limit,
   OpenTelemetry cho tracing.
8. **FR-08:** Ứng dụng stateless — không giữ state trong bộ nhớ giữa các request, để
   nhân bản được sau load balancer.
9. **FR-09:** Giữ nguyên hợp đồng API công khai mà `tenant-web` và `vendor-web` đang
   gọi, hoặc cập nhật đồng bộ hai phía trong cùng một thay đổi.
10. **FR-10:** Gom `ExamSnapshot` / `PinnedExamSnapshot` / `SnapshotRef` (3 bản ở 3
    service) về **một** khái niệm snapshot duy nhất trong module `assessment`.
11. **FR-11:** Giữ kiểm tra phân tách tenant ở mọi truy vấn có dữ liệu theo tenant.
    Gộp service không được nới lỏng ranh giới tenant.

---

## Non-Functional Requirements

<!-- Use numbers, not adjectives -->

- **Performance:** Endpoint nộp bài phản hồi p95 < 300ms ở 200 request đồng thời
  (đo bằng việc không chấm đồng bộ). Chấm điểm hoàn tất bất đồng bộ, không có ngưỡng
  cứng cho MVP.
- **Performance:** `docker compose up` đến trạng thái healthy < 90 giây (hiện tại 11
  JVM cần `start_period: 120s` mỗi cái).
- **Security:** Giữ nguyên phân tách tenant. Không endpoint nào trả dữ liệu chéo
  tenant. Giữ xác thực JWT và phân quyền theo vai trò như hiện tại.
- **Availability:** Chạy được ≥2 bản sao app sau load balancer, tắt 1 bản không làm
  gián đoạn request đang phục vụ.
- **Maintainability:** File Java trong `src/main` phục vụ đồng bộ giữa service về 0
  (hiện 140).

---

## Success Criteria

- [ ] Số file Java phục vụ đồng bộ giữa service: **140 → 0**
- [ ] Số bảng DB kiểu outbox/projection/idempotency: **19 → 0**
- [ ] Số instance Postgres: **4 → 1**
- [ ] Số service ứng dụng chạy trong compose: **11 → 1** (+ worker nếu tách tiến trình)
- [ ] `/student-roster` phục vụ bằng một câu JOIN, không qua projection
- [ ] Chủ sở hữu giải thích được đường đi của một request từ controller đến DB mà
      không cần mở code
- [ ] Chủ sở hữu đọc được dây chuyền `itembank → assessment → session → attempt →
      scoring → reporting` thành câu chuyện vòng đời một bài thi
- [ ] `ApplicationModules.verify()` pass; cố tình gọi chéo vào `internal/` làm test đỏ
- [ ] Sơ đồ module sinh tự động từ code, không vẽ tay
- [ ] Toàn bộ test hiện có vẫn pass sau migration
- [ ] Nộp bài trả `202` < 300ms ở p95 với 200 request đồng thời
- [ ] Chạy 2 bản sao app sau LB, request phân phối đều

---

## Out of Scope

- Viết lại 2 app Next.js (`tenant-web`, `vendor-web`)
- Thêm tính năng nghiệp vụ mới trong lúc migration
- Đổi database engine, đổi thư viện, đổi phiên bản Spring Boot
- Tách lại thành microservice trong tương lai
- Tự động migrate dữ liệu prod hiện có (xem NEEDS CLARIFICATION)
- Kubernetes — load balancer làm ở tầng Caddy/nginx trong compose

---

## Assumptions

- Không có ràng buộc scale nào bắt buộc phải tách service. Tải thực tế là các đợt
  burst khi thi, xử lý được bằng nhân bản app + queue.
- Cả 11 service hiện dùng chung một stack (Spring Boot, JPA, Postgres) nên code port
  sang được mà không phải viết lại logic.
- Hai app frontend gọi backend qua gateway, nên đổi backend thành một app là thay đổi
  cấu hình routing chứ không phải viết lại frontend.
- Đây là đồ án tốt nghiệp kiêm project CV; khả năng đọc hiểu và trình bày được ưu
  tiên cao hơn tính thuần khiết kiến trúc.
- Còn hơn 3 tháng trước hạn nộp.
- Không có ràng buộc tuân thủ nào bắt buộc dữ liệu phải nằm ở database tách biệt.

---

## Quyết định thực thi

- **Cách migration:** Port code sang cấu trúc mới, thực hiện trực tiếp trong repo
  `pte-api` trên nhánh `quang/refactor/backto-monolith` (nhánh đã tồn tại, cây làm
  việc sạch tại `3bb9670`). Ưu tiên giữ logic đã chạy đúng thay vì viết lại từ đầu.
- **Database:** Một instance Postgres, **một schema duy nhất**. Ranh giới module do
  Spring Modulith kiểm soát ở tầng code, không cần DB gác thêm — và JOIN tự do chính
  là lý do gộp monolith.
- **Dữ liệu:** Khởi tạo lại, kèm seed script tạo dữ liệu demo. Prod hiện chỉ có 1
  tenant (Long An Campus), 2–3 user, 1 program (Khối 12) nên không có gì đáng migrate.
- **Deploy hiện tại:** Giữ nguyên microservice đang chạy trên `pte-tenant.duckdns.org`
  cho tới khi monolith sẵn sàng thay thế. Không tắt sớm.

## Ràng buộc tiến độ

Người dùng nêu hai mốc khác nhau trong cùng phiên: hạn nộp còn **hơn 3 tháng**, nhưng
**cần thấy tiến triển gấp**. Kế hoạch phải chia mốc sao cho:

- Mỗi mốc để lại repo ở trạng thái **build được và test xanh** — không có mốc nào
  kết thúc giữa chừng.
- Ưu tiên các module cho phép chạy được một luồng đầu-cuối sớm, thay vì hoàn thiện
  từng module một cách tuần tự.
- Rủi ro lớn nhất đã xác định: **bỏ dở giữa chừng**, để lại trạng thái nửa
  microservice nửa monolith — tệ hơn cả hai phương án.
