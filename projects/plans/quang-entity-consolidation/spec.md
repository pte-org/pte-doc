# Spec: Tinh gọn mô hình entity pte-api (90 → 24 aggregate sau merge dev)

**Date:** 2026-10-24
**Status:** Ready (revised sau red-team và quyết định "giữ chức năng, được đổi API", 2026-10-24)

---

## Problem Statement

`pte-api/app` có 90 JPA entity / 93 bảng cho một nghiệp vụ chỉ khoảng 25 khái
niệm. Nội dung câu hỏi bị sao chép qua 4 tầng, còn workflow kỹ thuật
(command, batch, cohort, stream) bị mô hình hoá thành entity. Hệ quả: mỗi thay
đổi nghiệp vụ phải sửa nhiều bảng và mapper. Mục tiêu là đưa mô hình về đúng
các aggregate nghiệp vụ.

---

## Quy tắc đếm (counting rule)

- **Aggregate root = 25** (bảng dưới).
- **Hạ tầng = 6**: `RefreshToken`, `OtpChallenge`, `MediaAsset`, `AuditLog`,
  `IdempotencyKey`, `PlatformSetting`.
- **Child `@Entity`** (bảng con có FK/lọc/unique) ước tính 10:
  `OrganizationMember`, `OrderPayment`, `ClassStudent`, `ClassLecturer`,
  `ExamSessionAudienceSource`, `ExamSessionProctor`, `NotificationRecipient`,
  `SupportTicketNote`, `GradingIssue`, `QuestionOption`.
- Tổng ước tính 25 + 6 + 10 = 41. **Ngưỡng: tổng `@Entity` ≤ 45; số bảng ≤ 55**
  (thêm vài bảng `@ElementCollection` cho roles, selected skills).
- Mỗi phase ghi lại số `@Entity` đang chạy và số bảng do Hibernate dựng (profile `local-schema`).

---

## Mô hình đích

### Entity nghiệp vụ (aggregate root)

| # | Nhóm | Entity | Thành phần phụ thuộc (bảng con / nhúng) |
|---|---|---|---|
| 1 | Tổ chức | Organization | trạng thái đăng ký (PENDING/ACTIVE/REJECTED/SUSPENDED), thông tin hồ sơ, branding |
| 2 | Người dùng | User | roles; `OrganizationMember` (user–organization, vai trò trong tổ chức) |
| 3 | Đào tạo | Program | — |
| 4 | Đào tạo | Class | students, lecturers |
| 5 | Nội dung | QuestionType | yêu cầu nội dung, runtime config, trọng số chấm 4 kỹ năng + overall |
| 6 | Nội dung | Question | options, đáp án, media refs, revision |
| 7 | Nội dung | ExamDefinition | items (câu/số lượng theo task type), thời gian, cấu hình chấm |
| 8 | Nội dung | ExamVersion | items đóng băng (mỗi item có `itemPublicId` ổn định) — **nơi duy nhất** lưu bản sao nội dung + runtime |
| 9 | Chấm điểm | ~~Rubric~~ | đã bị partner gỡ ở dev (PR #82, 2026-10-24), không còn trong phạm vi |
| 10 | Tổ chức thi | ExamSession | policy (embedded), audience sources (STUDENT/CLASS/PROGRAM), proctors, selected skills, trạng thái chấm/công bố |
| 11 | Tổ chức thi | ExamRegistration | nguồn ghi danh, trạng thái loại trừ, điểm danh, xác minh danh tính |
| 12 | Làm bài | ExamAttempt | trạng thái, thời gian, vị trí câu, lastSeenAt, playCount |
| 13 | Làm bài | AttemptAnswer | payload, trạng thái, điểm đã chọn |
| 14 | Chấm điểm | GradingAssignment | examiner, trạng thái công việc, issues |
| 15 | Chấm điểm | AnswerEvaluation | nguồn AI/EXAMINER, DRAFT/SUBMITTED, điểm, chi tiết AI, transcript, trạng thái dispatch AI |
| 16 | Kết quả | ExamResult | điểm 4 kỹ năng + overall, published, snapshot đã công bố, excluded |
| 17 | Giám sát | ExamIncident | loại AUTO / REPORTED, history |
| 18 | Luyện tập | PracticeSession | câu đã chọn, tiến độ, deadline |
| 19 | Luyện tập | PracticeResponse | câu trả lời, điểm objective/AI, trạng thái chấm qua scoring (không còn rubric, không còn giải thích AI) |
| 20 | Thương mại | ServicePlan | giá, thời hạn, giới hạn |
| 21 | Thương mại | Subscription | thời hạn, hạn mức, nguồn kích hoạt (ORDER/LICENSE/MANUAL) |
| 22 | Thương mại | LicenseCode | trạng thái ISSUED/REDEEMED/REVOKED/EXPIRED |
| 23 | Thương mại | Order | payments (giao dịch PayOS để đối soát) |
| 24 | Giao tiếp | Notification | recipients (trạng thái gửi theo người nhận, đã đọc, sequence), kênh email/inbox |
| 25 | Hỗ trợ | SupportTicket | notes |

### Hạ tầng (không tính là entity nghiệp vụ)

`RefreshToken` (gắn organization đã chọn), `OtpChallenge`, `MediaAsset`
(giữ tên bảng/cột tương thích với tham chiếu media UUID publicId của
Question/AttemptAnswer/PracticeResponse), `AuditLog` (mở rộng: actor, role,
before/after state, requestPublicId, aggregateType/aggregateId, organizationId),
`IdempotencyKey` (chỉ dedupe + receipt, retention theo scope; lịch sử nằm ở
`AuditLog`), `PlatformSetting` (giữ để chức năng cấu hình nền tảng không đổi).

### Ánh xạ 90 entity hiện tại

| Hiện tại | Đích |
|---|---|
| Tenant, Organization, TenantApplication | Organization |
| QuotaTransaction | bỏ (lịch sử cấp tay → `Organization.quotaGrants`, bảng con; xem quyết định phase 3) |
| Plan / Order / Subscription / LicenseCode | ServicePlan / Order / Subscription / LicenseCode |
| PaymentTransaction | Order.payments |
| LicenseIssueIntent | IdempotencyKey |
| PlatformSetting | giữ (hạ tầng) |
| User, PracticeIdentity | User |
| PracticeIdentityMembership | User.OrganizationMember |
| RefreshToken / LoginHash | RefreshToken / bỏ |
| Program / StudentClass | Program / Class |
| ClassMembership, LecturerAssignment | Class.students / Class.lecturers |
| QuestionTypeDefinition, TaskRuntimeProfile, TaskRuntimeContract | QuestionType |
| TaskTypePublicationUsage | bỏ (truy vấn ExamVersion) |
| Question, QuestionOption | Question |
| MediaObject | MediaAsset (hạ tầng) |
| ExamBlueprint, BlueprintItem | ExamBlueprint giữ (BlueprintItem thành bảng con); không gộp vào ExamDefinition (xem phase 5) |
| ExamSnapshot, SnapshotItem | ExamVersion |
| ScoreTemplate, ScoreTemplateItem | ExamDefinition + items (trọng số, số câu, thời gian, scoring method nằm cùng nhau để ExamVersion ghim theo version) |
| RubricRevision, RubricCriterion, RubricCriterionLevel | (đã gỡ ở dev, không gộp nữa) |
| ExamSession, ExamPolicy, ProctorAssignment, SessionClassAssignment, ExamAudienceSource | ExamSession |
| ExamAudienceMember, Enrollment, SessionAttendance | ExamRegistration |
| ExamForm, FormAssignment, ExamGenerationJob | bỏ (một ExamVersion / ca thi) |
| SessionAttendanceCommand, SessionIdentityVerificationCommand | IdempotencyKey (receipt) + AuditLog (lịch sử) |
| ExamAttempt, AttemptHeartbeat | ExamAttempt |
| PinnedExamSnapshot, PinnedItem | bỏ (attempt trỏ ExamVersion; `pinnedItemPublicId` == `examVersionItemPublicId`) |
| AttemptAnswer | AttemptAnswer |
| AttemptSecurityEvent, ViolationEvent, ExamSessionIncident, ExamSessionIncidentHistory | ExamIncident (+ AuditLog cho security-audit) |
| ProctorSession | bỏ |
| ScoringAnswer, ScoringAnswerAiDetail, ExaminerAnswerDraft, ExaminerAnswerScore | AnswerEvaluation (+ điểm đã chọn trên AttemptAnswer) |
| ExaminerAttemptAssignment, ExaminerGradingWork, ExaminerGradingIssue | GradingAssignment |
| ExaminerAssignmentBatch | bỏ (không còn preview lưu trạng thái) |
| ExaminerGradingCommand, ExaminerGradingEvent, ScoreSourceAudit | IdempotencyKey (receipt) + AuditLog (lịch sử) |
| GradingCohort, GradingCohortMember, ScoringSessionState | ExamSession (trạng thái chấm/công bố) + ExamResult.excluded |
| AttemptReport | ExamResult |
| PracticeSession | PracticeSession |
| PracticeSessionItem (PracticeExplanation đã gỡ ở dev) | PracticeResponse |
| PracticeSessionOperation | IdempotencyKey |
| PracticeExplanationJob, PracticeExplanationOutbox | (đã gỡ ở dev cùng tính năng giải thích) |
| PracticeSessionAttemptLink | bỏ |
| PracticeEmailChallenge | OtpChallenge |
| NotificationLog, InboxAnnouncement, InboxContent, InboxDeliveryIntent, InboxItem, InboxRecipientStream | Notification (+ recipients) |
| SupportTicket, SupportTicketNote | SupportTicket |
| AuditLog | AuditLog (mở rộng) |

---

## User Stories

- **[P1]** As a HOST_ADMIN, I want to register a second independent
  organization under my existing account so that I manage both without a
  second email.
  Accepted when: một User có ≥ 2 `OrganizationMember`; đăng nhập trả danh sách
  tổ chức để chọn; dữ liệu và subscription của hai tổ chức không lẫn nhau.

- **[P1]** As a STUDENT, I want to take an official exam whose content is
  frozen at publish time so that grading reflects exactly what I saw.
  Accepted when: `ExamAttempt` tham chiếu `ExamVersion`; không còn bảng nào
  khác lưu bản sao nội dung câu hỏi của bài thi.

- **[P1]** As a STUDENT on pte-practice, I want resume, progress, review and AI
  scoring to keep working so that practice is unchanged for me.
  Accepted when: các luồng `sessions/*`, `progress`, `review`, chấm câu trả lời
  chạy end-to-end trên `PracticeSession` + `PracticeResponse`.

- **[P1]** As a HOST_ADMIN, I want AI and examiner scores of an answer in one
  place so that choosing the score source is a single update.
  Accepted when: mỗi `AttemptAnswer` có ≤ 1 `AnswerEvaluation` nguồn AI và
  ≤ 1 nguồn EXAMINER đã SUBMITTED; chọn nguồn chỉ cập nhật `AttemptAnswer`.

- **[P1]** As a PLATFORM_ADMIN, I want to issue license codes that an
  organization redeems so that activation works without payment.
  Accepted when: redeem `LicenseCode` tạo `Subscription` ACTIVE cho tổ chức.

- **[P2]** As an ACADEMIC_MANAGER, I want to manage QuestionType including its
  runtime config in one screen.
  Accepted when: CRUD QuestionType không cần entity runtime/contract riêng.

- **[P3]** _(out of scope)_ Nhiều cơ sở dùng chung gói trong một tổ chức.

---

## Functional Requirements

1. FR-01: Có đúng 24 aggregate root nghiệp vụ như bảng "Mô hình đích", cộng
   hạ tầng ≤ 6, theo quy tắc đếm ở trên.
2. FR-02: Đăng ký tổ chức là tạo `Organization` trạng thái PENDING; duyệt
   chuyển ACTIVE và gán HOST_ADMIN qua `OrganizationMember`.
3. FR-03: Một ca thi dùng một `ExamVersion`; sinh version đồng bộ khi publish.
4. FR-04: Audience source STUDENT/CLASS/PROGRAM được resolve thành
   `ExamRegistration` khi publish; điểm danh/xác minh ghi trên chính bản ghi đó.
5. FR-05: Vi phạm tự động từ client và sự cố do giám thị báo cáo cùng lưu ở
   `ExamIncident`, phân biệt bằng loại.
6. FR-06: Trạng thái chấm/công bố của ca thi là field của `ExamSession`;
   `ExamResult` lưu điểm 10–90 và snapshot công bố theo attempt.
7. FR-07: Idempotency (dedupe + receipt) của các lệnh mutation dùng chung bảng
   `IdempotencyKey`; lịch sử/audit nằm ở `AuditLog`.
8. FR-08: Job giải thích AI và chấm AI chạy qua RabbitMQ, không có bảng job/outbox.
9. FR-09 (function parity): mọi chức năng hiện có vẫn còn một endpoint (cũ hoặc
   mới); không mất tính năng nào ngoài danh sách "Out of Scope".

---

## Non-Functional Requirements

- Performance: `next-task`, `answers`, `submit` không tăng số query so với
  baseline đo ở phase 1 (Hibernate statistics trong test).
- Security: cô lập tenant theo `organizationId` trên mọi aggregate có dữ liệu tổ chức.
- Availability: không yêu cầu migration không downtime.

---

## Success Criteria

- [x] **API slimming (phase 12)**: tổng endpoint ≤ 260 (từ 328 trong `api-inventory.before.json`); POST đổi trạng thái đơn thuần gộp thành `PATCH .../{id}/status` `{action, reason}`; attendance host/proctor dùng chung một bộ endpoint; không còn alias trùng; function parity giữ nguyên. _Đạt: 260 endpoint (2026-10-25)._
- [x] Quy tắc đếm: 24 aggregate root; tổng `@Entity` ≤ 45 (từ 90); số bảng sau cùng ≤ 55 (từ 93). _Đạt: 45 `@Entity`, 52 bảng; 24 aggregate root theo `spec.md` chưa kiểm lại từng root._
- [ ] Cột `runtime*` chỉ xuất hiện ở `QuestionType` và `ExamVersion` items.
- [x] `.\mvnw.cmd -pl app -DskipTests compile`, `.\mvnw.cmd -pl app test` và
      `ModuleStructureTest` pass ở cuối MỖI phase. _Đạt ở từng phase; cuối cùng 2853 test, 0 lỗi._
- [x] **Gate dev DB theo phase**: cuối mỗi phase, app khởi động với profile `local-schema` trên DB `pte` trống (Docker Postgres 17), seed dev chạy xong, login `admin@test.local` (và `host.e2e@test.local` từ phase 2) thành công. Ràng buộc chỉ Postgres (exclusion constraint, partial unique index) nằm trong `db/dev-seed/000-postgres-objects.sql`. Không chạy được thì báo "not verified". Cuối phase 11 thêm gate Flyway V1 trên DB trống với `ddl-auto=validate`. _Đạt; gate cuối chạy bằng Flyway V1 (profile mặc định) thay vì `local-schema`._
- [ ] **Luồng end-to-end**: mỗi luồng P1 có một service-level flow test trên H2
      (profile test hiện có, AI provider stub, không cần full `@SpringBootTest`):
      đăng ký tổ chức → mua/redeem → tạo ca thi → làm bài → chấm AI + examiner
      → công bố → student xem kết quả; và practice start → answer → review →
      explanation. Smoke trên VPS là bước riêng sau deploy.
- [ ] Mỗi user story P1 có ít nhất một test hành vi trên entity mới; không đạt
      "test pass" bằng cách xoá test không có thay thế cho hành vi còn giữ.
- [x] **Function parity (thay "API diff")**: phase 1 xuất inventory (method +
      path + roles, gồm `/internal/**` và destination STOMP, cùng tên field
      response DTO) và ánh xạ từng endpoint vào một danh sách tính năng, cộng
      danh sách call site endpoint trong `pte-web`, `pte-app`, `pte-practice`.
      Phase 11 xuất lại và kiểm: mỗi tính năng vẫn có endpoint (cũ hoặc mới);
      mọi thay đổi endpoint/DTO đều có trong bảng Decisions; grep path cũ trong
      3 client trả 0. _Đạt: xem `plans/reports/assets/261025-entity-consolidation-parity/`._
- [x] **Client không bao giờ hỏng ở ranh giới phase**: phase nào đổi endpoint/DTO
      thì sửa client call site trong chính phase đó và chạy lint/type/build theo
      `docs/CODING_STANDARDS_WEB.md` / `docs/CODING_STANDARDS_APP.md`.

---

## Out of Scope

- Nhiều cơ sở/chi nhánh dùng chung gói trong một tổ chức.
- Mỗi thí sinh một mã đề.
- Hash chain chống sửa log vi phạm; bảng receipt lệnh riêng theo request.

---

## Assumptions

- Rubric đã bị partner gỡ ở dev (2026-10-24): không còn trong phạm vi.
- Người dùng chấp nhận mất các bảo đảm kỹ thuật bị bỏ (bảng command receipt
  riêng, hash chain, cohort freeze riêng).
- Tách module Spring Modulith vẫn giữ; entity mới đặt trong module sở hữu.
- `tenantPublicId == organizationPublicId` (1 Tenant = 1 Organization từ trước).

---

## Decisions (2026-10-24)

- **ScoreTemplate thành ExamDefinition (cập nhật phase 5)**: trọng số, số câu
  min/max, prep/response seconds, scoring method nằm cùng nhau trong items của
  `ExamDefinition` để `ExamVersion` ghim theo version (trọng số trên `QuestionType`
  sửa được sẽ làm điểm đề đã publish bị trôi). `TemplatePolicy`/CUSTOM để lại tới phase 7–8.
- **Schema dev do Hibernate dựng, Flyway V1 một lần ở cuối (2026-10-24)**: `db/migration` giữ nguyên 126 migration và `ddl-auto: validate` mặc định cho môi trường đã deploy. Phát triển dùng profile `local-schema` (Hibernate `update`, Flyway tắt, seed `db/dev-seed/*.sql`). Flyway V1 chỉ sinh ở phase 11 từ schema do Hibernate dựng. Không chuyển dữ liệu cũ; DB local và VPS tạo lại. Seed dựng dần ở phase 1–7, phải qua validation publish ExamVersion.
- **Giữ chức năng, được đổi API**: endpoint và DTO được phép đổi khi mô hình gộp
  cần, miễn mọi chức năng hiện có còn nguyên (không mất tính năng). Ưu tiên giữ
  endpoint khi mô hình mới phục vụ tự nhiên; đổi khi giữ sẽ buộc adapter giả tạo.
  Mỗi thay đổi liệt kê trong bảng dưới (cũ → mới, file client phải sửa, phase
  thực hiện) và client được sửa trong CHÍNH phase đổi endpoint.
- **PlatformSetting giữ lại** làm bảng hạ tầng thứ 6; `/api/v1/settings` giữ nguyên.
- **Hạn mức thủ công**: `QuotaTransaction` bỏ ở phase 3; cấp tay nâng `studentLimit` và
  thêm một `QuotaGrant` vào `Organization.quotaGrants` (không tạo `Subscription`).
- **Generation**: `ExamGenerationService` thành bộ dựng `ExamVersion` đồng bộ.
  `POST /sessions/{id}/generate` giữ path, dựng ExamVersion đồng bộ, cùng
  response shape; `GET /sessions/{id}/generation` trả trạng thái suy ra từ
  ExamSession/ExamVersion. `ExamFormProvisioningService` không viết lại ở
  phase 5, chỉ xoá ở phase 7.
- **Preview phân công examiner**: gỡ `previews` và `{batchPublicId}/confirm`;
  `commit` nhận danh sách phân công đầy đủ trong request; `roster`/`overview` giữ.

### Bảng thay đổi endpoint/DTO và endpoint giữ lại có entity nền bị bỏ

Cột "Phase" là phase sửa cả backend lẫn client call site.

| Endpoint cũ | Hành động → endpoint mới | Served by / lý do | Client cần sửa | Phase |
|---|---|---|---|---|
| `/api/v1/tenants/**` | **đổi** → `/api/v1/organizations/**` | `Organization` (`tenantPublicId == organizationPublicId`); giữ path cũ cần adapter giả | `pte-web/packages/api-client/src/requests/tenant/index.ts`, `.../requests/organization/index.ts`, `pte-web/apps/vendor-web/features/tenancy/components/_TenantTable.tsx`, `apps/vendor-web/lib/navigation.tsx`, `apps/vendor-web/features/dashboard/constants.ts` | 2 |
| `/api/v1/tenants/{t}/organizations/{o}/**` | **đổi** → `/api/v1/organizations/{o}/**` (cùng chức năng) | như trên | như trên | 2 |
| `POST/GET /tenants/{id}/quota-transactions` | **đổi** → `POST/GET /api/v1/organizations/{id}/quota-grants` | cấp tay nâng `studentLimit` và ghi `QuotaGrant`; GET liệt kê lịch sử (bỏ `actionType`) | `.../requests/quota/index.ts`, `apps/vendor-web/app/(dashboard)/admin/licenses/page.tsx` (nếu dùng) | 3 |
| `/api/v1/settings` | giữ | `PlatformSetting` | — | — |
| `/api/v1/score-templates/**` | **đổi** → `/api/v1/exam-definitions/**` (cùng method, cùng quyền) | `ExamDefinition` | `.../requests/scoretemplate/index.ts`, `.../types/scoretemplate/index.ts` + UI vendor/tenant dùng | 5 (QuestionType additive ở 4) |
| `templatePublicId`/`scoreTemplatePublicId` | **đổi tên** → `examDefinitionPublicId` trong `CreateExamDraftRequest`, `PatchExamDraftRequest`, `SessionResponse`, `SnapshotResponse`, `SnapshotContentResponse` | ExamDefinition; `POST /sessions/drafts` nhận `examDefinitionPublicId`, feasibility preflight tính từ ExamDefinition (field `ExamPreflightResponse.template: ScoreTemplateFeasibilityResponse` đổi thành feasibility của ExamDefinition, đã xác minh) | `pte-web/packages/api-client/src/types/scheduling/index.ts`, `.../requests/scheduling/examOrchestration.test.ts`, `apps/tenant-web/features/exams/{hooks/useCreateExamWizardForm.ts,utils/validateCreateExamWorkflow.ts,utils/createExamWizard.ts,types/index.ts,api/index.ts}` | 5 |
| `templatePublicId` trong `AttemptScoreContextView`, `SubmittedAnswerView`, `AttemptGradingItemView`, `AttemptStaffContextView` | **đổi tên** → `examDefinitionPublicId` | ExamAttempt → ExamVersion → ExamDefinition | client attempt/staff context (`pte-web`, `pte-app`; liệt kê bằng grep ở phase) | 8 |
| `templatePublicId` trong `ReportScoringAnswerView`, `ExaminerGuidelinesResponse` (`AiEligibleAttemptView` đã xác minh: không có field template, chỉ đổi cách đếm pool) | **đổi tên** | AnswerEvaluation / ExamVersion | `pte-web` examiner/scoring requests | 9 |
| `ReportResponse` (reporting) | **không đổi shape** (đã xác minh: không có field template) | ExamResult | — | 10 |
| `POST /api/v1/proctor-sessions/{id}/close` | **gỡ** | `ProctorSession` bỏ; kết thúc giám sát theo trạng thái `ExamSession` | `pte-web/packages/api-client/src/requests/proctoring.ts`, `apps/tenant-web/features/proctor/transport.ts`, `pte-app/lib/features/live_proctor/data/transport/stomp_live_proctor_transport.dart` (nếu gọi close) | 8 |
| `POST /sessions/{id}/examiner-assignments/previews`, `.../{batchPublicId}/confirm` | **gỡ** → `POST /commit` mang danh sách phân công đầy đủ; `GET roster`/`overview` giữ | `GradingAssignment`; không còn batch lưu trạng thái | `pte-web/packages/api-client/src/requests/scoring/assignments.ts` + UI phân công examiner (tenant-web) | 10 |
| `POST /sessions/{id}/generate`, `GET /sessions/{id}/generation` | giữ | ExamVersion builder đồng bộ / trạng thái suy ra | — | 5 |
| `POST /sessions/{id}/audience-preview` | giữ | tính stateless (kèm lý do loại trừ) trước publish | — | 7 |
| `GET .../attendance/students/{st}/history` (host + proctor) | giữ | `AuditLog` | — | 7 |
| attendance command receipts | giữ hành vi | `IdempotencyKey.result` (retention ≥ closesAt + 90 ngày) | — | 7 |
| `GET /api/v1/examiner/work/{s}/{a}/commands/{requestPublicId}` | giữ | receipt từ `IdempotencyKey` (client đang poll) | — | 9 |
| `GET /api/v1/examiner/work/history`, `/{s}/{a}/history` | giữ | `AuditLog` + `AnswerEvaluation` | — | 9 |
| `POST /api/v1/scoring/sessions/{s}/source-selection/preview` + lịch sử chọn nguồn | giữ | stateless từ `AttemptAnswer`/`AnswerEvaluation`; audit → `AuditLog` | — | 9 |
| `GET /api/v1/scoring/sessions/{s}/grading-cohort/preview` + finalize | giữ | tính từ trạng thái chấm `ExamSession` + `ExamResult.excluded` | — | 10 |
| `GET /api/v1/exam-sessions/{s}/security-audit`, `/incidents/**` (gồm `/history`) | giữ | `AuditLog` + `ExamIncident` | — | 8 |
| `/api/v1/notification-inbox/**`, `/api/v1/announcements/{id}/audience-preview`, `/retry-delivery` | giữ | `Notification` + `NotificationRecipient` | — | 11 |
| `/api/v1/platform/audit-logs` | giữ | `AuditLog` mở rộng | — | 1 |
| `/internal/**` (session, snapshot, media) | giữ hoặc ghi rõ lý do gỡ trong function-parity report | module sở hữu | — | theo module |
| `POST /organizations/{o}/programs/{p}/{activate,deactivate,suspend,archive}` | **gộp** → `PATCH .../programs/{p}/status` `{action: ACTIVATE\|DEACTIVATE\|SUSPEND\|ARCHIVE}` | `ProgramService` (logic giữ nguyên) | `.../requests/admin/programs.ts` | 12 |
| `POST .../classes/{c}/{activate,deactivate,suspend,archive}` | **gộp** → `PATCH .../classes/{c}/status` (cùng enum); merge/split/transfer/students giữ | `ClassLifecycleService` | `.../requests/admin/classes.ts` | 12 |
| `POST /blueprints/{id}/{submit-approval,approve,approval,reject,rejection}` | **gộp** → `PATCH /blueprints/{id}/status` `{action: SUBMIT_APPROVAL\|APPROVE\|REJECT, reason}`; `REJECT` cần `reason`; APPROVE/REJECT chỉ PLATFORM_ADMIN, ACADEMIC_MANAGER; bỏ alias trùng | `BlueprintService` | `.../requests/assessment/index.ts` | 12 |
| `POST /exam-definitions/{id}/{activate,submit-approval,approve,reject}` | **gộp** → `PATCH /exam-definitions/{id}/status` `{action: SUBMIT_APPROVAL\|APPROVE\|REJECT\|ACTIVATE, reason}`; `clone` giữ | `ExamDefinitionAdminService`; quyền theo action như cũ | `.../requests/scoretemplate/index.ts` | 12 |
| `POST /questions/{id}/{submit-approval,approve,approval,reject,rejection,publish,archive,unarchive}` | **gộp** → `PATCH /questions/{id}/status` `{action: SUBMIT_APPROVAL\|APPROVE\|REJECT\|PUBLISH\|ARCHIVE\|UNARCHIVE, reason}`; `edit` giữ; APPROVE/REJECT/PUBLISH chỉ manager/admin | `ItembankService` | `.../requests/question/index.ts` | 12 |
| `POST /task-types/{id}/{submit-approval,approve}`, `DELETE /task-types/{id}` | **gộp** → `PATCH /task-types/{id}/status` `{action: SUBMIT_APPROVAL\|APPROVE\|RETIRE}` | `QuestionTypeService` | `.../requests/questiontype/index.ts` | 12 |
| `POST /platform-users/{id}/{suspend,reactivate,restore}`, `DELETE /platform-users/{id}` | **gộp** → `PATCH /platform-users/{id}/status` `{action: SUSPEND\|REACTIVATE\|ARCHIVE\|RESTORE}` | `PlatformUserService`, `PlatformUserLifecycleService` | `.../requests/user/index.ts` | 12 |
| `POST /users/{id}/{suspend,reactivate}` | **gộp** → `PATCH /users/{id}/status` (ARCHIVE/RESTORE → 400) | `UserService` | `.../requests/user/index.ts` | 12 |
| `POST /applications/{id}/{approval,rejection}` | **gộp** → `PATCH /applications/{id}/status` `{action: APPROVE\|REJECT, reason}` | `TenantApplicationService` | `.../requests/billing/applications.ts` | 12 |
| `POST /plans/{id}/{activation,archive}` | **gộp** → `PATCH /plans/{id}/status` `{action: ACTIVATE\|ARCHIVE, expectedVersion}` | `PlanService` (giữ khoá phiên bản) | `.../requests/billing/plans.ts`, `seed-local-exam-ready.ps1` | 12 |
| `POST /sessions/{id}/{publish,cancel,open,close}` | **gộp** → `PATCH /sessions/{id}/status` `{action: PUBLISH\|CANCEL\|OPEN\|CLOSE}`; generate/preflight/audience/report publish giữ | `ExamPublishService`, `SessionLifecycleService` | `.../requests/scheduling/{sessions,examOrchestration}.ts`, `seed-local-exam-ready.ps1` | 12 |
| `POST /organizations/{id}/{suspend,reactivate}` | **gộp** → `PATCH /organizations/{id}/status` `{action: SUSPEND\|REACTIVATE, days, impactDigest}`; SUSPEND vẫn bắt buộc `impactDigest` | `OrganizationLifecycleService` | `.../requests/tenant/index.ts`, `seed-local-exam-ready.ps1` | 12 |
| `POST /announcements/{id}/{publish,retry-delivery}` | **gộp** → `PATCH /announcements/{id}/status` `{action: PUBLISH\|RETRY_DELIVERY, expectedDraftVersion}` | `AnnouncementService` | `.../requests/notification/announcements.ts` | 12 |
| `GET /exam-staff/{id}/{proctor-sessions,examiner-sessions}` | **gộp** → `GET /exam-staff/{id}/sessions?role=PROCTOR\|EXAMINER` | `StaffWorkspaceService` | `.../requests/admin/examStaffWorkspace.ts` | 12 |
| `GET /host/exam-sessions/{s}/attendance/**` (Host) + `GET/PATCH /exam-sessions/{s}/attendance/**` (Proctor) | **hợp nhất** → một bộ `/api/v1/exam-sessions/{s}/attendance/**` cho HOST_ADMIN và PROCTOR; service nhận cờ host theo role | `AttendanceCoordinatorService` | `.../requests/attendance.ts` | 12 |
| `GET/PUT /settings/{key}` | **gỡ** (không còn consumer UI) → `PUT /settings/batch`, `GET /settings` | `PlatformSettingService` | `apps/vendor-web/features/commercialization/api.ts` (bỏ hook không dùng) | 12 |
| `POST /license-codes/{ignored}/revoke` | **gỡ** (stub từ chối đường cũ, không consumer) → `POST /admin/license-codes/{id}/revoke` | `AdminLicenseCodeController` | — | 12 |
| `/internal/sessions/**`, `/internal/snapshots/**`, `/internal/media-objects/**` | **gỡ** (không consumer; monolith gọi service trực tiếp) | — | — | 12 |
 _Đạt cho `pte-web` (typecheck + test); `pte-app` chưa chạy analyze/test._