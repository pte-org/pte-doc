# Plan: Tinh gọn mô hình entity pte-api (90 → 25)

**Spec:** [spec.md](spec.md)
**Brainstorm:** [261024-quang-entity-consolidation-brainstorm.md](../../../plans/reports/261024-quang-entity-consolidation-brainstorm.md)
Status: 🟡 In Progress
Date: 2026-10-24
Mode: Hard
Test: --tdd (mỗi phase: `ck:test --tdd --prepare` → cook → `ck:test --tdd --verify`)
Created by: quang
Revision: red-team lượt 2 = WARN, đã sửa NEW-1…NEW-6 (12 phase, giữ chức năng được đổi API; 2026-10-24: dev dùng profile `local-schema` — Hibernate dựng schema, Flyway V1 chỉ sinh một lần ở phase 11; seed hai tài khoản local)
Branch: `quang/feat/maintain-v2` (pte-api; client sửa trên nhánh hiện tại của từng repo). Agent KHÔNG commit/push — người dùng tự commit. Không merge `main` giữa chừng: push `main` kích hoạt `deploy-production.yml`, mà schema V1 mới không tương thích DB VPS hiện tại.

## Overview

Đưa `pte-api/app` từ 90 `@Entity` / 93 bảng về 24 aggregate root + 6 bảng hạ tầng + ~10 child entity (tổng `@Entity` ≤ 45, bảng ≤ 55), giữ nguyên mọi chức năng nhưng được đổi endpoint/DTO khi mô hình mới cần. Flyway cũ được rút ngay ở phase 1 và thay bằng baseline `V1` cộng dồn, kiểm chứng trên Postgres thật (Docker) ở cuối mỗi phase.

## Phases

> **Cập nhật sau merge `dev` (PR #82/#83, 2026-10-24):** partner đã gỡ module `rubric` (RubricRevision/Criterion/CriterionLevel, `RubricController`) và tính năng giải thích AI của practice (PracticeExplanation/Job/Outbox, `PracticeExplanationController`, `PracticeRubricBindingService`); practice nay chấm qua module scoring (`PracticeScoringRequest/Route`, `PracticeScoringDispatcher/Worker`) với trạng thái chấm nằm trên `PracticeSessionItem` (migration V130/V131). Hệ quả: Phase 4 bỏ Rubric; Phase 11 không còn explanation/job/outbox; số aggregate đích 25 → 24; các ngưỡng `@Entity` ≤ 45 và bảng ≤ 55 giữ nguyên.

- [x] Phase 1: Nền tảng — [phase-01-foundation-spike-infra.md](phase-01-foundation-spike-infra.md) — inventory + feature map, spike JSON/H2, profile `local-schema` + seed dev (`admin@test.local`), IdempotencyKey/OtpChallenge/MediaAsset/AuditLog mở rộng [quality: approved; tests: passed 2667; completed 2026-10-24]
- [x] Phase 2: Organization & User — [phase-02-organization-user.md](phase-02-organization-user.md) — Organization, User + OrganizationMember, đa tổ chức, `/organizations/**`, seed `host.e2e@test.local` [quality: approved; tests: passed 2709; completed 2026-10-24]
- [x] Phase 3: Thương mại — [phase-03-commerce.md](phase-03-commerce.md) — ServicePlan, Subscription, LicenseCode, Order.payments, `Organization.quotaGrants`, seed subscription ACTIVE [quality: approved; tests: passed 2798; completed 2026-10-24]
- [x] Phase 4: Nội dung A — [phase-04-content-question-type-question-rubric.md](phase-04-content-question-type-question-rubric.md) — QuestionType (+runtime từ registry), Question (+options embeddable) (Rubric đã bị gỡ ở dev; `ScoreConfigFacade` dời sang phase 5) [quality: approved; tests: passed 2802; completed 2026-10-24]
- [x] Phase 5: Nội dung B — [phase-05-content-exam-definition-version.md](phase-05-content-exam-definition-version.md) — ExamDefinition (=ScoreTemplate), ExamVersion (=ExamSnapshot), items embeddable, gỡ module scoretemplate (ExamBlueprint giữ; builder đồng bộ dời phase 7–8)s
- [ ] Phase 6: Đào tạo (6a) — [phase-06-training-program-class.md](phase-06-training-program-class.md) — Program, Class (enrollment module)
- [ ] Phase 7: Ca thi & ghi danh (6b) — [phase-07-session-registration.md](phase-07-session-registration.md) — ExamSession, ExamRegistration, điểm danh, xoá cơ chế form
- [ ] Phase 8: Làm bài & sự cố — [phase-08-attempt-incident.md](phase-08-attempt-incident.md) — ExamAttempt trỏ ExamVersion, ExamIncident
- [ ] Phase 9: Chấm điểm A — [phase-09-scoring-answer-evaluation.md](phase-09-scoring-answer-evaluation.md) — AnswerEvaluation, chọn nguồn điểm, AI dispatch, receipt/audit
- [ ] Phase 10: Chấm điểm B & báo cáo — [phase-10-scoring-grading-reporting.md](phase-10-scoring-grading-reporting.md) — GradingAssignment, ExamResult, xoá facade/cohort
- [ ] Phase 11: Practice, Notification, Support, hoàn tất — [phase-11-practice-notification-support-finalize.md](phase-11-practice-notification-support-finalize.md) — PracticeSession/Response, Notification, SupportTicket, xoá legacy, function parity
- [ ] Phase 12: API slimming — [phase-12-api-slimming.md](phase-12-api-slimming.md) — gộp POST đổi trạng thái thành `PATCH .../status`, hợp nhất attendance host/proctor, gỡ `/internal` và alias; 328 → ≤ 260 endpoint


## Research Summary

Hướng đã chốt:

1. **Strangler theo module**: viết lại phần bên trong từng module sau public service/DTO (`com.pte.<module>.*Service`), xoá entity cũ trong chính phase đó. Entity còn consumer chỉ xoá sau khi consumer đã chuyển (bảng Dependencies). Adapter tạm được phép *trong* phase.
2. **Quy tắc ánh xạ**: jsonb `@JdbcTypeCode(SqlTypes.JSON)` không `columnDefinition` cho dữ liệu đóng băng/đọc nguyên khối; bảng con cho dữ liệu cần lọc/join/aggregate/FK/unique; `@ElementCollection` cho tập nhỏ; cột lọc là cột thật; không toán tử jsonb.
3. **Không ghim trạng thái lúc làm bài**: presign URL tính khi đọc; prep/response seconds, scoringMethod, runtime contract, `audioDurationSeconds` đóng băng vào ExamVersion items (mỗi item có `itemPublicId` ổn định); validation runtime/section chuyển sang publish ExamVersion.
4. **Schema dev do Hibernate dựng, Flyway V1 một lần ở cuối (quyết định 2026-10-24)**: `db/migration` giữ nguyên 126 migration, mặc định `ddl-auto: validate`. Phát triển dùng profile `local-schema` (`application-local-schema.yml`: Flyway tắt, `ddl-auto: update`, `spring.sql.init` đọc `db/dev-seed/*.sql`). Gate cuối mỗi phase chạy từ `D:\GitHub\pte-org\pte-api` với DB `pte` trống trên Docker Postgres 17 (`pte-postgres`): `APP_SPRING_PROFILES=local-schema` trong `.env.local`, `docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app`, health UP, rồi `POST /api/v1/auth/login` với `admin@test.local` và (từ phase 2) `host.e2e@test.local`. `update` không dùng được trên DB do Flyway dựng (Hibernate 7 nới cột bị view chặn) nên mỗi lần đổi mô hình lớn hoặc khi lệch schema, sao lưu rồi drop/recreate DB `pte` (đã được người dùng duyệt). Flyway V1 sinh ở phase 11 bằng `pg_dump --schema-only` DB do Hibernate dựng + `000-postgres-objects.sql` + seed. Suite test vẫn H2 + service-level flow test; không thêm Testcontainers.
5. **Giữ chức năng, được đổi API**: mọi đổi endpoint/DTO nằm trong bảng của spec; client sửa trong chính phase đổi nên không bao giờ hỏng ở ranh giới phase. Phase 1 lập feature map và call-site inventory.
6. **E2E**: service-level flow test trên H2 với stub, một flow mỗi luồng P1; ràng buộc cấp DB (exclusion constraint, partial unique, timestamptz) do gate dev DB từng phase (các đối tượng nằm trong `db/dev-seed/000-postgres-objects.sql`) và gate Flyway V1 ở phase 11.
7. **ScoreConfigFacade**: đặt ở module `assessment` (sở hữu `ExamDefinition`, nằm trên `itembank` nên không tạo vòng phụ thuộc). Tạo ở phase 4, phục vụ trọng số/scoringMethod/timing; xoá ở phase 10 khi consumer cuối (`ScoreAggregationService`, scoring) chuyển sang `QuestionType` và ExamVersion items. Enum `ScoringMethod` trùng (`scoring/domain/enums` và `scoretemplate/domain/enums`) hợp nhất về một enum trong `itembank` ở phase 4, cùng `TaskTypeScoringMethods`.

Tài liệu bắt buộc (tồn tại tại `D:\GitHub\pte-org\docs`): `CODING_STANDARDS_API.md`, `CODING_STANDARDS_WEB.md`, `CODING_STANDARDS_APP.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `HOST_STUDENT_IMPORT_FLOW.md`, `TEST_SCENARIOS_IAM.md`.

### Tài khoản seed local và script (áp dụng cho MỌI phase)

Sau mỗi lần reset DB, seed dev `db/dev-seed/*.sql` (không phải SQL thủ công; V1 demo seed ở phase 11 sinh từ đây) phải tạo: `admin@test.local` (PLATFORM_ADMIN, trước đây bootstrap SQL ở `pte-api/README.md` khoảng dòng 64–67) và `host.e2e@test.local` (HOST_ADMIN của Organization ACTIVE slug `e2e` có Subscription ACTIVE, trước đây do `pte-api/scripts/seed-local-exam-ready.ps1` khoảng dòng 421). Seed chỉ lưu BCrypt hash sinh bằng `PasswordEncoder` của app lúc implement; **không bao giờ ghi mật khẩu plaintext vào file repo, plan hay báo cáo**. Admin có từ phase 1, host + org từ phase 2, subscription ACTIVE từ phase 3; gate Postgres mỗi phase login cả hai tài khoản đang tồn tại.

Quy tắc các phase 4–7 (cũng là một phần Steps/Success Criteria của chúng): mỗi phase cập nhật seed dev `db/dev-seed/` phần của mình (phase 4: task types, questions; phase 5: exam definition publish được; phase 6: program/class/students mẫu; phase 7: ca thi mẫu) và cập nhật hoặc retire script bị ảnh hưởng. Quyết định cho từng script:

| Script / tài liệu | Cập nhật ở | Quyết định |
|---|---|---|
| `README.md` bootstrap SQL (admin) | phase 1 | thay bằng mô tả profile `local-schema` + seed dev |
| `scripts/seed-local-platform-roles.ps1` | phase 1 | rà: retire nếu seed dev thay hoàn toàn, nếu không cập nhật |
| `scripts/seed-local-exam-ready.ps1` | phase 2, 3, 5, 7, 8, 9, 10 | giữ làm kịch bản session → attempt → chấm → công bố; bỏ dần các bước đã nằm trong seed; cập nhật theo endpoint mỗi phase |
| `scripts/seed-local-template-and-question-bank.ps1` | phase 4/5 | retire ở phase 5 (seed task type/question/exam definition thay thế); trong phase 4 cập nhật nếu còn dùng score-template |
| `scripts/seed-local-sample-class-students.ps1` | phase 2, 6 | cập nhật path `/organizations/**` ở phase 2; retire ở phase 6 nếu seed có class/students, ngược lại cập nhật |
| `scripts/seed-plan-b.sh` | mỗi phase đổi endpoint | cập nhật theo endpoint mới; quyết định giữ/retire cuối ở phase 11 |

## Dependencies

Phụ thuộc ngoài: Docker Linux engine (đã có, Docker 29.2.1) để chạy `postgres:17` và RabbitMQ/Redis theo `docker-compose.yml`; Phase 1 là tiền đề của mọi phase.

Phối hợp với plan khác: [quang-tenant-student-roster-pagination](../quang-tenant-student-roster-pagination/plan.md) và [quang-row-level-security](../quang-row-level-security/plan.md) chạm cùng bảng/entity (roster student, `tenant_id` nullable). Hai plan đó **tạm dừng cho đến khi phase 2 xong**; plan RLS nên viết lại sau phase 11 vì tên bảng/cột đổi.

Bảng thứ tự xoá entity (entity → phase xoá → consumer phải chuyển xong ở phase ≤ N):

| Entity (nhóm) | Xoá ở phase | Consumer đã chuyển (file/module) |
|---|---|---|
| LoginHash, Tenant, TenantApplication, Organization cũ, PracticeIdentity, PracticeIdentityMembership | 2 | billing `TenantApplicationService`, enrollment roster/import, practice `PracticeEmailAuthService`/`PracticeEntitlementService` — phase 2 |
| QuotaTransaction, Plan, Order, PaymentTransaction, Subscription, LicenseCode, LicenseIssueIntent | 3 | `StudentQuotaController`, session `SessionSubscriptionService`/`EntitlementService`; adapter `SubscriptionRevocationListener` (session, lắng nghe `SubscriptionRevokedEvent` do billing phát, gọi `SessionRevocationService` để huỷ ca đã lên lịch) — phase 3 |
| QuestionTypeDefinition, TaskRuntimeProfile, TaskRuntimeContract, TaskTypePublicationUsage, Question, QuestionOption | 4 | assessment, attempt `SnapshotPinService` (đọc contract), scoring, practice qua public API itembank — phase 4 |
| ScoreTemplate, ScoreTemplateItem, module `scoretemplate` (controller/service) | 5 | assessment, session (preflight/draft DTO) trỏ sang `ExamDefinition` qua facade — phase 5. `ScoreConfigFacade` sống tới phase 10 |
| ExamBlueprint, BlueprintItem, ExamSnapshot, SnapshotItem | 5 | session (`ExamOrchestrationService`, `SessionExamPreviewService`, `ExamFormProvisioningService`) và attempt `SnapshotPinService` đọc qua `AssessmentService` DTO ổn định → compile không đổi ở phase 5; `ExamFormProvisioningService` xoá ở phase 7, `SnapshotPinService` xoá ở phase 8 |
| Program, StudentClass, ClassMembership, LecturerAssignment | 6 | identity roster, session `SessionClassAssignmentService`, reporting — phase ≤ 6 |
| ExamSession, ExamPolicy, ProctorAssignment, SessionClassAssignment, ExamAudienceSource/Member, Enrollment, SessionAttendance, SessionAttendanceCommand, SessionIdentityVerificationCommand, ExamForm, FormAssignment, ExamGenerationJob | 7 | attempt enrollment check, proctoring attendance, scoring session lookup, reporting, notification qua `SessionService`/`StaffScheduleService` — phase 7 |
| ExamAttempt cũ, AttemptHeartbeat, PinnedExamSnapshot, PinnedItem, SnapshotPinService, ProctorSession, AttemptSecurityEvent, ViolationEvent, ExamSessionIncident(+History) | 8 | không còn `Pinned*` trong attempt; scoring chỉ giữ UUID `pinnedItemPublicId` (== `examVersionItemPublicId`) cho tới phase 9 |
| ScoringAnswer, ScoringAnswerAiDetail, ExaminerAnswerDraft, ExaminerAnswerScore, ExaminerGradingCommand, ExaminerGradingEvent, ScoreSourceAudit, `ScoringMethodResolver` | 9 | `ExaminerDraftCommandService`, `ExaminerWorkflowCommandService`, `ScoreSourceSelectionService` (sở hữu các command/audit) cùng `ScoredAnswerQueryService` — phase 9; `ExaminerGradingWork`/Assignment/Issue đọc `AnswerEvaluation` qua adapter nội bộ tới phase 10 |
| ExaminerAttemptAssignment, ExaminerGradingWork, ExaminerGradingIssue, ExaminerAssignmentBatch, GradingCohort(+Member), ScoringSessionState, AttemptReport, `ScoreConfigFacade` | 10 | `ScorePublicationLockService`, `GradingProgressListener`, `GradingReconciliationWorker` (viết lại trên `ExamSession`), `ScoreAggregationService` — phase 10 |
| PracticeSessionItem/Operation/AttemptLink (Explanation/Job/Outbox đã bị partner gỡ), NotificationLog, Inbox* (5), SupportTicket cũ, thư mục migration legacy | 11 | `NotificationService` public API giữ ổn định cho mọi module gọi |

## Risks

- HIGH: Module `scoring` lớn nhất (264 file) — tách hai phase 9/10, giữ test dispatch AI/chọn nguồn trước khi xoá entity.
- HIGH: H2 không chứng minh được DDL Postgres — gate dev DB (Docker `postgres:17`, profile `local-schema`) cuối mỗi phase và gate Flyway V1 trên DB trống ở phase 11; không môi trường nào thì "not verified".
- HIGH: Khối lượng viết lại test (576 test) — mỗi phase chuyển test của module mình, cấm xoá test không có thay thế; ghi số test trước/sau mỗi phase.
- MEDIUM: Client đổi vì endpoint/DTO đổi (`pte-web`, `pte-app`, `pte-practice`) — sửa trong chính phase đổi, chạy lint/type/build theo `CODING_STANDARDS_WEB.md`/`APP.md`; phase 1 có call-site inventory.
- MEDIUM: Script seed/README gọi API hoặc bảng đổi — cập nhật/retire theo bảng ở Research Summary, không để script hỏng ở ranh giới phase.
- MEDIUM: Phase 7 (ExamSession + ExamRegistration) nặng — đã tách khỏi Program/Class (phase 6).
- MEDIUM: Reset volume `pte_postgres_data` xoá dữ liệu dev — đã được người dùng duyệt; tuyệt đối không đụng volume Caddy; không dùng `docker compose down -v` rộng.
- MEDIUM: Hiệu năng `next-task`/`answers`/`submit` — baseline query count đo ở phase 1, so sánh ở phase 8.
- MEDIUM: Plan roster-pagination và RLS chạm cùng entity — tạm dừng đến sau phase 2 (RLS sau phase 11).
- MEDIUM: Seed demo phải qua validation publish ExamVersion — dựng dần ở phase 2–5; mật khẩu seed chỉ ở dạng hash.
- LOW: Dirty worktree — không dùng lệnh phá huỷ; lỗi test không liên quan thì báo cáo.

## Cook Order Recommendation

Cook tuần tự 1 → 12, không song song. Đầu mỗi phase: đọc đầy đủ `docs/CODING_STANDARDS_API.md` (và tài liệu liên quan nêu trong phase) và ghi "standards-read note" vào progress update đầu tiên. Cuối mỗi phase: `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test`, `ModuleStructureTest`, gate Postgres (Research Summary mục 4, gồm login hai tài khoản seed), ghi số `@Entity`/bảng V1 hiện tại, rồi `/ck:quality --gate`.
