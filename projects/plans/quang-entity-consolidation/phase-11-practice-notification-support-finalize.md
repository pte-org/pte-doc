# Phase 11: Practice, Notification, Support và hoàn tất

## Requirements

Chuyển `PracticeSession`/`PracticeResponse`, `Notification` (+`NotificationRecipient`, gộp `NotificationLog` + 5 entity Inbox), `SupportTicket` (+notes); rồi hoàn tất: xoá `db/legacy-migration`, chốt `V1` + seed demo, function parity, client grep 0. Đáp ứng story P1 practice và FR-08.

## Design Constraints

- Đọc đầy đủ `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`, `docs/CODING_STANDARDS_WEB.md` (`pte-web`, `pte-practice`), `docs/CODING_STANDARDS_APP.md` (`pte-app`). Ghi standards-read note vào progress update đầu tiên.
- Giải thích AI đã bị partner gỡ; chấm practice đi qua RabbitMQ (`PracticeScoringDispatcher/Worker`), không bảng Job/Outbox/Operation/AttemptLink; idempotency qua `IdempotencyKey` (PRACTICE_SESSION_OP).
- Hành vi giữ kèm test: announcement `retry-delivery` và `audience-preview` cần trạng thái gửi theo người nhận trên `NotificationRecipient`; inbox `unread-count`/`upperSequence` (`InboxSnapshotResponse(token, upperSequence, expiresAt)`) đòi hiển thị không hụt: DB sequence toàn cục KHÔNG đủ (giao dịch cấp 6 có thể commit trước 5, snapshot `upperSequence=6` bỏ sót 5). Dùng bảng counter theo người nhận `NotificationRecipientStream(recipientUserPublicId, organizationId, lastSequence, readRevision)` cấp sequence bằng `SELECT ... FOR UPDATE` trong cùng giao dịch append; tính vào số `@Entity` (kiểm ngưỡng ≤ 45). Thêm test append đồng thời hai thông báo cho một người nhận và snapshot không bỏ sót.
- Chỉ xoá migration legacy sau khi V1 chứa đủ bảng của mọi phase; khi test đang chạy trên H2, ràng buộc DB-level vẫn chứng minh bằng gate Postgres.
- Không ghi plaintext mật khẩu seed vào repo/báo cáo; DB reset chỉ volume `pte_postgres_data`, không động volume Caddy.

## Steps

1. Chuyển practice (`PracticeSessionService`, `PracticeSessionPersistenceService`, `PracticeProgressService`, `PracticeAnswerValidationService`, `PracticeEntitlementService`, `PracticeMediaBindingService`, `PracticeSessionController`, `PracticeProgressController`, `PracticeCatalogController`, `PracticeAuthController`, `PracticeEntitlementController`): `PracticeSession` + `PracticeResponse`; xoá `PracticeSessionItem`, `PracticeSessionOperation`, `PracticeSessionAttemptLink` (trạng thái chấm `scoring_status`, `scoring_attempts`, `scoring_dispatch_token`… từ V130 gộp vào `PracticeResponse`; giữ `PracticeScoringStateService`/`Dispatcher`/`Worker` và API item result + retry); test practice start → answer → score → review (flow test).
2. Chuyển notification (`NotificationService`, `NotificationDispatchService`, `NotificationLogService`, `InboxAppendService`, `InboxDeliveryService`, `InboxReadService`, `AnnouncementService`, `InboxController`, `AnnouncementController`, `NotificationLogController`): `Notification` + `NotificationRecipient` (delivery state theo người nhận, đã đọc, sequence); giữ API inbox/announcement; `NotificationService` public API ổn định.
3. Chuyển support (`SupportTicketService`, `HostSupportTicketController`, `AdminSupportTicketController`, `SupportOverviewService`): `SupportTicket` + notes.
4. Sinh Flyway V1 (một lần): dựng DB trống bằng profile `local-schema`, `pg_dump --schema-only --no-owner --no-privileges` schema đã hoàn chỉnh, ghép `db/dev-seed/000-postgres-objects.sql` (đổi sang dạng không dùng `@@`) và dữ liệu tham chiếu + seed demo (organization `e2e`, `admin@test.local`, `host.e2e@test.local`, plan, subscription ACTIVE, question types/questions/rubrics, exam definition, program/class mẫu) thành `db/migration/V1__baseline.sql`; chuyển 126 migration cũ sang `db/legacy-migration/` (xoá sau khi V1 qua gate). Kiểm bằng DB trống: Flyway V1 + `ddl-auto=validate` boot, login hai tài khoản. Kiểm đếm tổng `@Entity` ≤ 45, bảng ≤ 55.
5. Function parity: xuất lại inventory và so với phase 1 bằng feature map; mỗi tính năng còn endpoint (cũ hoặc mới), mọi thay đổi có trong bảng spec; grep path cũ (`/tenants`, `quota-transactions`, `score-templates`, `proctor-sessions`, `previews`, `templatePublicId`) trong `pte-web`, `pte-app`, `pte-practice` trả 0.
6. Client còn lại: `pte-practice` nếu response practice đổi, `pte-web` phần notification/support nếu đổi; lint/typecheck/build theo `CODING_STANDARDS_WEB.md`/`APP.md`.
7. Scripts: `seed-local-template-and-question-bank.ps1` retire (V1 seed thay); `seed-local-sample-class-students.ps1` retire nếu seed có class/students, ngược lại cập nhật; `seed-local-platform-roles.ps1` retire hoặc cập nhật theo seed; `seed-plan-b.sh` cập nhật theo endpoint mới hoặc retire kèm lý do; `seed-local-exam-ready.ps1` giữ như kịch bản session → attempt → chấm, đã cập nhật; README ghi đúng quy trình seed. Mỗi quyết định ghi vào báo cáo.
8. Gate cuối: compile, test toàn app, `ModuleStructureTest`, các flow test P1, gate Flyway V1 trên DB trống (validate) với login hai tài khoản seed; ghi số liệu cuối, cập nhật snapshot trong `AGENTS.md` nếu kiến trúc đổi; viết báo cáo vào `pte-doc/plans/reports/` theo `YYMMDD-<topic>-<type>.md`.

## Success Criteria

- Tổng `@Entity` ≤ 45, bảng ≤ 55, 24 aggregate root; `runtime*` chỉ ở QuestionType và ExamVersion items.
- Flow test practice và các luồng P1 pass trên H2; function parity pass; grep path cũ trong 3 client = 0; client build/typecheck pass.
- `V1__baseline.sql` là migration duy nhất trong `db/migration`, qua gate validate; seed tạo `admin@test.local` và `host.e2e@test.local` (hash only).
- Gate dev DB (profile `local-schema`): từ `D:\GitHub\pte-org\pte-api`, DB `pte` trống trên Docker Postgres 17; `APP_SPRING_PROFILES=local-schema` trong `.env.local`; `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app` khởi động (health UP) với Hibernate dựng schema, `db/dev-seed/*.sql` chạy xong, và `POST /api/v1/auth/login` thành công với `admin@test.local` và `host.e2e@test.local`. Ràng buộc chỉ Postgres phải có trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì ghi "not verified", không bỏ qua im lặng.
- `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest` xanh.

## Quality and Testing State

- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks

- Môi trường Docker/Postgres không chạy được: báo "not verified", là điều kiện trước deploy VPS.
- Khoá counter theo người nhận làm nghẽn khi broadcast announcement: append theo lô theo người nhận, giao dịch ngắn.
- Seed cũ phụ thuộc migration đã xoá: seed chạy qua validation publish.
- VPS DB phải tạo lại: không dùng `docker compose down -v` rộng.
