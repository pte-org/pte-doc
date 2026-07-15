# Task Breakdown — APTIS MVP Tuần Này (Real Stack)

**Ngày:** 2026-06-23
**Team:** 3 Full-Stack (FS1, FS2, FS3) + 1 FE floater
**Stack thực tế:** `aptis-api` (Spring Boot 4.1.0 / Java 21), `aptis-web` (Next.js 16 Turborepo monorepo: `tenant-web` + `vendor-web`), `aptis-app` (Flutter desktop, Windows target)
**Mode:** Parallel — 3 dòng sở hữu độc lập (ownership streams) + 1 FE floater hỗ trợ động
**Nguồn:** Sinh từ `plans/aptis-mvp-week-tasks/plan.md` + 4 phase file (đã qua red-team review, adjudicated 2026-06-23)

> **Ghi chú quan trọng:** File này **bổ sung, không thay thế** [`team/pm/task-breakdown.md`](team/pm/task-breakdown.md) gốc. File gốc được viết cho stack giả định (NestJS 11 + Prisma 7 + PostgreSQL 17 + `exceljs`) và team 4 full-stack — không khớp với stack/team thực tế của tuần này. File này là bản breakdown chính xác để team dùng triển khai MVP tuần này. Phần "Sprint 3 — Post-demo hardening" trong file gốc (RLS, refresh-token rotation, BullMQ) vẫn còn giá trị tham khảo về phạm vi Out-of-Scope, không đổi.
>
> File này được đặt ở `projects/aptis-mvp/` (không nằm trong `team/pm/`) vì plan nguồn (`plans/aptis-mvp-week-tasks/`) thuộc pipeline `/ck:plan`, không phải pipeline `/team-pm` — và file đặt ngoài `team/` để tránh xung đột với level-gate hook vốn chỉ áp dụng cho artifact do pipeline virtual-team sinh ra.

---

## Các dòng sở hữu (Ownership Streams)

| Stream | Người phụ trách | Phạm vi chính |
|---|---|---|
| **FS1** | Full-Stack 1 | `iam` (auth core: JWT/RBAC/base-repo), `questionbank` CRUD, `examoperations` (exam composition). Ôm luôn Day-1 infra bootstrap (critical path). |
| **FS2** | Full-Stack 2 | `tenancy` (Host provisioning/login), `examoperations` (roster import + validate + assign + credential export). |
| **FS3** | Full-Stack 3 | `examdelivery` (attempt lifecycle + single-submit), `scoring` (sync MCQ), **Flutter desktop UI** (login/exam/score). Rủi ro dual-stack cao nhất. |
| **FE floater** | FE | Day 1–2: `packages/ui` + auth UI (vendor-web + tenant-web). Day 2 PM+: hỗ trợ động — ưu tiên proactive check-in với FS3 (Flutter), sau đó FS2 (roster UI). |

**Critical path:** FS1's JWT contract — khóa + publish **Day 1 sáng** (không phải EOD). FS2/FS3 mock ngay khi có contract, swap sang real impl khi FS1 xong issuer, không đổi interface.

---

## Quy ước Effort

- **S** = 1 (vài giờ) · **M** = 3 (nửa ngày–1 ngày) · **L** = 5 (1–2 ngày) · **XL** = 8 (2+ ngày, nên xét chia nhỏ)

---

## Tasks — FS1: Platform, IAM & Question Bank

### TASK-FS1-01: Infra bootstrap (docker-compose + datasource)
**Story:** Foundation (T-001)
**Type:** Infra
**Assigned to:** FS1
**Effort:** S
**Ngày:** Day 1 sáng
**Depends on:** Không có
**Description:** Thêm `postgres:17` vào `docker-compose.yaml`, cấu hình `spring.datasource.*` trong `application.properties`. Thêm dependency vào `pom.xml`: Apache POI (`poi`, `poi-ooxml`), `jjwt`, `spring-boot-starter-oauth2-resource-server`.
**DoD:** `docker-compose up` healthy; Spring Boot app connect DB thành công; `./mvnw clean compile` pass.

### TASK-FS1-02: Move Host.java (iam → tenancy) + khóa JPA entity skeleton
**Story:** FR-04, FR-05
**Type:** Backend
**Assigned to:** FS1
**Effort:** M
**Ngày:** Day 1 sáng
**Depends on:** Không có
**Description:** Chạy grep verify (`grep -rn "iam.domain.Host\|iam\.Host" src/main/java src/test/java`) **trước khi move** để liệt kê đủ chỗ tham chiếu. Move `Host.java` từ `iam.domain` sang `tenancy.domain`, update toàn bộ import, xóa file cũ, chạy lại grep xác nhận 0 hit còn sót. Sau đó khóa 11 `@Entity` class (Admin, Host, Student, Question, Option, Exam, ExamQuestion, ImportBatch, CredentialExport, ExamAttempt, AttemptAnswer) dùng **Spring Data JPA/Hibernate — không phải Prisma**. Khai báo unique constraint: `Student.username`, `Student(hostId, studentIdentifier)` composite, `Host.contactEmail`, `Exam.name`, `ExamQuestion(examId, questionId)` composite, **`ExamAttempt.studentId` UNIQUE (cơ chế DB-level cho BR-003, FS3 dùng ở Phase 3)**.
**DoD:** Grep trước/sau move ghi nhận đầy đủ, 0 reference cũ còn sót; `./mvnw clean compile` pass; entity model frozen Day 1 sáng (thay đổi sau cần PR review riêng).

### TASK-FS1-03: Scaffold JWT (SecurityConfig + JwtTokenProvider) — khóa + publish contract
**Story:** FR-02
**Type:** Backend
**Assigned to:** FS1
**Effort:** M
**Ngày:** Day 1 chiều
**Depends on:** TASK-FS1-01
**Description:** Tạo `iam.config.SecurityConfig` (Spring Security FilterChain), `iam.service.JwtTokenProvider` (issue/verify qua jjwt), `iam.security.JwtAuthenticationConverter`. **Khóa + publish claim contract `{ sub, role, hostId, iat, exp }` ngay khi viết struct xong, Day 1 sáng — không chờ tới EOD** (đây là critical path của FS2/FS3). Chưa wire vào login thật, chỉ scaffold để FS2/FS3 mock.
**DoD:** Contract đăng lên Slack/wiki trong buổi sáng Day 1; unit test issue/verify token pass.

### TASK-FS1-04: TenantScopedRepository base class (BR-005)
**Story:** BR-005
**Type:** Backend
**Assigned to:** FS1
**Effort:** S
**Ngày:** Day 1 chiều
**Depends on:** TASK-FS1-02
**Description:** Tạo `iam.repository.base.TenantScopedRepository<T, ID>` — mọi query Host/Student-scoped nhận `hostId` argument, filter `host_id = :hostId`. Default impl find-by-id-with-host-check (NotFoundException nếu mismatch).
**DoD:** Unit test: query không có hostId fail compile-time (generic contract); hostId mismatch → NotFoundException.

### TASK-FS1-05: RBAC Guard + AdminGuard
**Story:** BR-005, FR-02
**Type:** Backend
**Assigned to:** FS1
**Effort:** S
**Ngày:** Day 1 chiều
**Depends on:** TASK-FS1-03
**Description:** `iam.security.RoleGuard` annotation + interceptor check role claim; `AdminGuard` (yêu cầu ADMIN).
**DoD:** Unauthenticated → rejected; wrong role → 403; correct role → allowed (unit test).

### TASK-FS1-06: Admin login service + endpoint
**Story:** US-001, BR-001, BR-010
**Type:** Backend
**Assigned to:** FS1
**Effort:** M
**Ngày:** Day 2 sáng
**Depends on:** TASK-FS1-03, TASK-FS1-05
**Description:** `AdminService.login(email, credential) → JwtTokenResponse` (bcrypt verify, generic error khi sai — không leak account-existence). **`JwtTokenResponse` chỉ có field `accessToken` — không có field token-làm-mới** (refresh rotation Out of Scope). `POST /api/v1/admin/login`.
**DoD:** Valid → 200 + token; invalid → 401 generic; missing field → 400; integration test pass.

### TASK-FS1-07: Question + Option CRUD (BR-007, BR-009)
**Story:** US-002, US-003
**Type:** Backend
**Assigned to:** FS1
**Effort:** L
**Ngày:** Day 2 chiều
**Depends on:** TASK-FS1-05
**Description:** `Question`/`Option` entity + `QuestionService` (validate ≥2 option, đúng 1 correct — BR-007). CRUD endpoint có Admin guard. DELETE chặn nếu question đang dùng trong Exam đã assign (BR-009 → 409).
**DoD:** Unit test 4 validation path + success; E2E test delete unused (ok) / delete used (409) / delete không tồn tại (404).

### TASK-FS1-08: Exam composition service + endpoint (BR-006)
**Story:** US-004
**Type:** Backend
**Assigned to:** FS1
**Effort:** L
**Ngày:** Day 3
**Depends on:** TASK-FS1-07
**Description:** `Exam`/`ExamQuestion` entity + `ExamService` (unique name, auto-recompute `is_assignable` = question_count ≥ 1 — BR-006). CRUD endpoint + `GET /exams?assignable=true` cho FS2 dùng.
**DoD:** 0 question → is_assignable=false; ≥1 → true; trùng tên → UNIQUE error; E2E test pass.

### TASK-FS1-09: BR-010 quét rò rỉ thông tin nhạy cảm trong code
**Story:** BR-010
**Type:** Backend
**Assigned to:** FS1
**Effort:** S
**Ngày:** Liên tục (trước mỗi commit đụng SecurityConfig/application.properties)
**Depends on:** TASK-FS1-03
**Description:** Chạy lệnh grep tìm chuỗi literal kiểu `key = "..."` trong `src/main/resources` và `src/main/java` trước khi commit. Giá trị nhạy cảm (khóa ký JWT, mật khẩu DB) phải đọc từ biến môi trường (`application.properties` dùng cú pháp `${TEN_BIEN_MOI_TRUONG}`), không viết literal trong code.
**DoD:** Không có hit thật (false positive như tên field được chấp nhận); xác nhận bằng log grep.

### TASK-FS1-10: FE — Admin auth UI (vendor-web)
**Story:** US-001
**Type:** Frontend
**Assigned to:** FS1
**Effort:** M
**Ngày:** Day 3–4
**Depends on:** TASK-FS1-06
**Description:** Login form (email + credential) gọi `POST /api/v1/admin/login`, lưu token, redirect dashboard. Xử lý 401/400/network error.
**DoD:** Manual verify: login → dashboard redirect; lỗi hiển thị đúng.

### TASK-FS1-11: FE — Question editor + Exam builder UI
**Story:** US-002, US-003, US-004
**Type:** Frontend
**Assigned to:** FS1
**Effort:** L
**Ngày:** Day 3–4
**Depends on:** TASK-FS1-07, TASK-FS1-08, TASK-FS1-10
**Description:** List/create/edit/delete question (validate feedback: thiếu correct option, <2 option). Surface lỗi BR-009 khi xóa. Exam builder: tạo Exam, chọn question, cập nhật `is_assignable`, surface lỗi tên trùng.
**DoD:** Manual verify: tạo question → tạo exam → thử xóa question đang dùng (fail đúng).

---

## Tasks — FS2: Tenancy, Host Login & Roster Pipeline

### TASK-FS2-01: Scaffold tenancy package + xác nhận Host.java
**Story:** FR-04
**Type:** Backend
**Assigned to:** FS2
**Effort:** S
**Ngày:** Day 1 chiều
**Depends on:** TASK-FS1-02
**Description:** Nhận `Host.java` từ FS1 (đã move sang `tenancy.domain`), xác nhận compile. Scaffold các subpackage còn lại của `tenancy` (`repository`, `service`, `controller`, `dto`, `config`, `interfaces`) theo khung 7-subpackage của `iam`.
**DoD:** `tenancy.domain.Host` compile; `HostRepository extends TenantScopedRepository<Host, Long>` tạo xong.

### TASK-FS2-02: Host provisioning service + endpoint
**Story:** US-005, BR-001, BR-002
**Type:** Backend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 2 sáng
**Depends on:** TASK-FS2-01, TASK-FS1-04
**Description:** `HostService.createHost(orgName, contactEmail) → HostResponse` — sinh credential ngẫu nhiên ≥8 ký tự (BR-002), bcrypt hash, plaintext chỉ trả về **một lần duy nhất** trong response tạo mới. Trùng `contactEmail` → reject. `POST /api/v1/admin/hosts`.
**DoD:** Tạo thành công → plaintext hiện 1 lần; reload không còn plaintext; trùng email → exception (unit + E2E test).

### TASK-FS2-03: Host login service + endpoint + `/me`
**Story:** US-006
**Type:** Backend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 2 chiều
**Depends on:** TASK-FS2-02, TASK-FS1-03
**Description:** `HostService.loginHost(email, credential) → JwtTokenResponse` (check `is_active`, verify hash, issue JWT `role=HOST, hostId`). `POST /api/v1/host/login` (public). `GET /api/v1/host/me` trả org name + student count.
**DoD:** Valid → token đúng claim; deactivated → rejected; wrong credential → generic message (unit + E2E test).

### TASK-FS2-04: Roster upload + parsing (Apache POI)
**Story:** US-007, BR-007 (file size)
**Type:** Backend
**Assigned to:** FS2
**Effort:** L
**Ngày:** Day 3 sáng
**Depends on:** TASK-FS2-03
**Description:** `ImportBatch` entity (host_id, status). `RosterImportService.uploadRoster(hostId, file)` — reject non-.xlsx, empty, oversized **trước khi parse**; parse qua Apache POI.
**DoD:** Unit test: valid .xlsx parsed; non-.xlsx/empty/oversized rejected đúng.

### TASK-FS2-05: Per-row validation (BR-004 cross-batch + same-file duplicate)
**Story:** US-008, BR-004
**Type:** Backend
**Assigned to:** FS2
**Effort:** L
**Ngày:** Day 3 sáng
**Depends on:** TASK-FS2-04
**Description:** Validate field bắt buộc + uniqueness **cross-batch** (DB) **và same-file** (track `Set<String>` identifier trong khi đọc file hiện tại — flag **cả 2 dòng** trùng, không chỉ dòng sau). Reason: "duplicate identifier within this file, row {N}".
**DoD:** Unit test: mixed valid/invalid, cross-batch duplicate, **same-file duplicate (cả 2 dòng bị reject)**, all-valid, all-invalid.

### TASK-FS2-06: Student provisioning + validation report endpoint
**Story:** US-008
**Type:** Backend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 3 chiều
**Depends on:** TASK-FS2-05, TASK-FS1-03 (CredentialProvisioning interface, publish Day 2 sáng)
**Description:** Gọi `iam.CredentialProvisioning.provisionStudent(...)` cho mỗi dòng hợp lệ. `POST /api/v1/host/imports` trả `{ batchId, validCount, errorCount, errors }`. `GET /api/v1/host/imports/{batchId}` trả lại report.
**DoD:** E2E test: upload → report đúng row + reason; student tạo và liên kết batch.

### TASK-FS2-07: Exam assignment service + endpoint
**Story:** US-009, BR-006
**Type:** Backend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 4 sáng
**Depends on:** TASK-FS2-06, TASK-FS1-08
**Description:** `ImportBatchService.assignExamToBatch(hostId, batchId, examId)` — verify exam `is_assignable=true`, support reassign (idempotent). `POST /api/v1/host/imports/{batchId}/assign`, `GET .../exams` (danh sách assignable).
**DoD:** Unit test: assign thành công, exam non-assignable bị reject, reassign idempotent.

### TASK-FS2-08: Credential export generation + scoped download (BR-008)
**Story:** US-010, BR-001, BR-008
**Type:** Backend
**Assigned to:** FS2
**Effort:** L
**Ngày:** Day 4 chiều
**Depends on:** TASK-FS2-07
**Description:** `CredentialExportService.generateExport(hostId, batchId)` — sinh .xlsx (full name, username, credential plaintext, exam name) qua Apache POI, **xóa giá trị credential-chờ-xuất khỏi DB trong cùng transaction**. `POST .../export` (idempotent), `GET /api/v1/host/exports/{exportId}` chỉ host sở hữu mới download được (403 nếu khác host).
**DoD:** Export đúng dữ liệu; giá trị credential-chờ-xuất bị xóa sau export; Host khác bị 403; unit + E2E test.

### TASK-FS2-09: FE — Host management UI (vendor-web)
**Story:** US-005
**Type:** Frontend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 4–5
**Depends on:** TASK-FS2-02
**Description:** Form tạo Host, hiện plaintext credential 1 lần + nút copy + cảnh báo "không hiện lại". List Host + detail (ẩn plaintext).
**DoD:** Manual verify: tạo Host → thấy credential 1 lần → reload → credential biến mất.

### TASK-FS2-10: FE — Host login UI (vendor-web + tenant-web)
**Story:** US-006
**Type:** Frontend
**Assigned to:** FS2
**Effort:** S
**Ngày:** Day 4–5
**Depends on:** TASK-FS2-03
**Description:** Form login Host, gọi `POST /api/v1/host/login`, redirect dashboard hiện org name.
**DoD:** Manual verify: login → dashboard hiện đúng org name.

### TASK-FS2-11: FE — Roster import UI (validation report)
**Story:** US-007, US-008
**Type:** Frontend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 4–5
**Depends on:** TASK-FS2-06
**Description:** File picker .xlsx, upload progress, hiển thị report lỗi theo từng dòng (row + reason), số lượng tạo thành công.
**DoD:** Manual verify: upload hợp lệ → report 0 lỗi; upload có trùng → lỗi hiện đúng theo dòng.

### TASK-FS2-12: FE — Exam assignment + credential export UI
**Story:** US-009, US-010
**Type:** Frontend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 4–5
**Depends on:** TASK-FS2-07, TASK-FS2-08, TASK-FS2-11
**Description:** Dropdown chọn exam assignable, confirm assign. Nút download credential Excel, hỗ trợ re-download. Empty state khi chưa có exam assignable.
**DoD:** Manual verify: assign → download file đúng cột/dữ liệu → re-download hoạt động.

### TASK-FS2-13 (Optional, low priority): Host overview dashboard
**Story:** US-015
**Type:** Backend+Frontend
**Assigned to:** FS2
**Effort:** M
**Ngày:** Day 5 (nếu còn thời gian)
**Depends on:** TASK-FS2-08
**Description:** List toàn bộ Host kèm số student + trạng thái assignment.
**DoD:** Defer nếu hết giờ — đánh dấu optional, không block MVP.

---

## Tasks — FS3: Exam Delivery, Scoring & Flutter Desktop

### TASK-FS3-01: Student login service + endpoint (public, no guard)
**Story:** US-011
**Type:** Backend
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 2 chiều
**Depends on:** TASK-FS1-03 (JWT contract)
**Description:** `StudentService.loginStudent(username, credential)` — resolve exam đã assign qua `ImportBatchRepository`; nếu đã submit → trả score redirect; nếu chưa có batch → trả "no exam assigned". `POST /api/v1/student/login` **cố ý public, không guard** (đây là entry point đổi credential lấy JWT, giống `/admin/login`, `/host/login`) — ghi rõ trong Javadoc. **"No exam assigned" là response hợp lệ cho Student login Day 2–3 trước khi FS2 hoàn thành assignment (Day 3 chiều) — không block task này theo FS2.**
**DoD:** Unit + E2E test: valid → token + exam state; sai credential → 401 generic; chưa có exam → message; đã submit → score redirect.

### TASK-FS3-02: ExamAttempt/AttemptAnswer entity + repository
**Story:** US-012, BR-003
**Type:** Backend
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 3 sáng
**Depends on:** TASK-FS1-02 (entity model frozen)
**Description:** `ExamAttempt` (student_id UNIQUE — BR-003), `AttemptAnswer` (attempt_id + question_id UNIQUE composite). Repository extends `TenantScopedRepository`.
**DoD:** Unit test: UNIQUE constraint enforced; answer upsert hoạt động.

### TASK-FS3-03: Exam attempt creation/loading + answer upsert
**Story:** US-012
**Type:** Backend
**Assigned to:** FS3
**Effort:** L
**Ngày:** Day 3 sáng
**Depends on:** TASK-FS3-02, TASK-FS1-08 (exam/question data)
**Description:** `ExamAttemptService.loadOrCreateAttempt` (tạo attempt lần đầu, load lại nếu đã có — resume). `saveAnswer` (upsert, chặn nếu đã submit → 409). `GET /api/v1/student/exam`, `PUT /api/v1/student/attempts/{id}/answers`.
**DoD:** E2E test: load → answer → đổi answer → bỏ trống → resume sau re-login (answer còn nguyên).

### TASK-FS3-04: Submit + single-submit enforcement (BR-003)
**Story:** US-013, BR-003
**Type:** Backend
**Assigned to:** FS3
**Effort:** L
**Ngày:** Day 3 chiều
**Depends on:** TASK-FS3-03
**Description:** `submitAttempt` — dùng `UPDATE ... WHERE submitted_at IS NULL` trong 1 `@Transactional`, check affected-row count (0 row → 409) thay vì read-then-write riêng (tránh TOCTOU). `POST /api/v1/student/attempts/{id}/submit`.
**DoD:** Unit test: submit đầu thành công, submit lần 2/3 → 409, **test concurrency: 2 submit gần như đồng thời → đúng 1 thành công, không corrupt score.**

### TASK-FS3-05: MCQ scoring service (BR-007, DTO boundary)
**Story:** US-013, US-014, BR-007
**Type:** Backend
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 3 chiều
**Depends on:** TASK-FS3-04
**Description:** `ScoringService.scoreAttempt` — đếm đúng/tổng, %. **Nhận data qua DTO param từ `ExamAttemptService`, không import trực tiếp `examdelivery` repository** (tránh circular dependency giữa `examdelivery` ↔ `scoring`).
**DoD:** Unit test: all-correct=100%, all-wrong=0%, partial đúng %, unanswered=sai.

### TASK-FS3-06: Score view endpoint + resume confirm
**Story:** US-014
**Type:** Backend
**Assigned to:** FS3
**Effort:** S
**Ngày:** Day 4 sáng
**Depends on:** TASK-FS3-05
**Description:** `GET /api/v1/student/attempts/{id}/score` — trả score đã lưu, **không tính lại**. Xác nhận flow resume: login → attempt cũ + answer restore → submit lại bị 409.
**DoD:** E2E test: submit → xem score → re-login → score giữ nguyên (không recalculate).

### TASK-FS3-07: Flutter — enable Windows target + login screen scaffold
**Story:** US-011
**Type:** Frontend (Flutter)
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 2
**Depends on:** Không có
**Description:** `flutter config --enable-windows-desktop`, scaffold `student_login_page.dart` (mock API). **Tiêu chí thành công rõ ràng: `flutter pub get && flutter build windows` phải exit code 0 trước hết Day 2** (không phải "gần xong"). **Rule escalate 30 phút:** nếu build fail >30 phút, **escalate cho FE floater trước** (floater confirmed biết Flutter), chỉ escalate tech lead nếu floater cũng bó tay.
**DoD:** `flutter build windows` exit 0 ghi nhận trước EOD Day 2; nếu escalate, ghi rõ ai đã hỗ trợ.

### TASK-FS3-08: Flutter — wire ApiClient + real Student login
**Story:** US-011
**Type:** Frontend (Flutter)
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 3 sáng
**Depends on:** TASK-FS3-01, TASK-FS3-07
**Description:** `ApiClient.loginStudent()` wire vào `POST /api/v1/student/login` thật. Lưu token vào `TokenStore`, navigate sang exam screen. Wire refresh interceptor đã có sẵn.
**DoD:** Test: login form → token lưu → navigate đúng.

### TASK-FS3-09: Flutter — exam-taking screen
**Story:** US-012
**Type:** Frontend (Flutter)
**Assigned to:** FS3
**Effort:** L
**Ngày:** Day 3 chiều
**Depends on:** TASK-FS3-03, TASK-FS3-08
**Description:** `exam_delivery_page.dart` — load exam, hiển thị câu hỏi + navigation, chọn answer (radio), gọi `submitAnswers` mỗi lần chọn, confirm trước submit cuối (hiện số câu chưa trả lời).
**DoD:** Local test: render đúng, navigation hoạt động, capture answer đúng.

### TASK-FS3-10: Flutter — score screen + resume integration
**Story:** US-014
**Type:** Frontend (Flutter)
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 4
**Depends on:** TASK-FS3-06, TASK-FS3-09
**Description:** `score_page.dart` hiển thị score + %. Login flow detect đã submit → navigate trực tiếp score screen. Exam screen handle re-login (restore answer).
**DoD:** E2E Flutter test: login → exam → submit → score; logout/login → score hiện đúng.

### TASK-FS3-11: Flutter — integration + polish
**Story:** US-011 đến US-014
**Type:** Frontend (Flutter)
**Assigned to:** FS3
**Effort:** M
**Ngày:** Day 4
**Depends on:** TASK-FS3-10
**Description:** Test full flow trên Windows desktop, fix mismatch API, error handling (network/timeout/409 resubmit), test TokenStore persist/clear, `flutter test` xanh.
**DoD:** `flutter test` pass; không lỗi compile/lint trên feature `exam_delivery`.

---

## Tasks — FE Floater: Shared UI, Auth & Dynamic Support

### TASK-FE-01: Scaffold `packages/ui` design system
**Story:** Foundation
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** M
**Ngày:** Day 1
**Depends on:** Không có
**Description:** Scaffold `packages/ui/` (Tailwind 4 + React 19 + TS): `components/`, `hooks/`, `layouts/`, `utils/`, `index.ts` export.
**DoD:** Package build được, export tối thiểu 1 component placeholder.

### TASK-FE-02: Auth UI components (LoginForm, CredentialDisplay, AuthLayout, ProtectedRoute, TokenManager)
**Story:** US-001, US-005, US-006, US-011
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** L
**Ngày:** Day 1–2
**Depends on:** TASK-FE-01
**Description:** `<LoginForm />`, `<CredentialDisplay />` (plaintext + copy + "không hiện lại"), `<AuthLayout />`, `<ProtectedRoute />`, hook `useTokenManager` (save/retrieve/clear token).
**DoD:** Unit test TokenManager (save/retrieve/clear) pass.

### TASK-FE-03: API client layer (`@aptis/api-client`)
**Story:** FR-02
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** M
**Ngày:** Day 1–2
**Depends on:** TASK-FE-01
**Description:** `loginAdmin/loginHost/loginStudent` — **response chỉ có `accessToken`, không có field token-làm-mới** (khớp với `JwtTokenResponse` của FS1, refresh rotation Out of Scope). Bearer injection middleware, error mapping (400/401/403/409).
**DoD:** Unit test: token injected vào header, 401 trigger logout, network error map đúng exception.

### TASK-FE-04: Auth flow vendor-web (Admin + Host login)
**Story:** US-001, US-006
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** M
**Ngày:** Day 1–2
**Depends on:** TASK-FE-02, TASK-FE-03
**Description:** `/login` page (role param admin|host), token storage, redirect dashboard theo role, logout action.
**DoD:** E2E test: Admin login → admin dashboard; Host login → host dashboard.

### TASK-FE-05: Auth flow tenant-web (Host login)
**Story:** US-006
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** S
**Ngày:** Day 1–2
**Depends on:** TASK-FE-02, TASK-FE-03
**Description:** `/login` page cho Host (reuse LoginForm + TokenManager + ProtectedRoute), redirect `/host/dashboard`, logout.
**DoD:** Manual verify: Host login → dashboard.

### TASK-FE-06: Error boundary + loading states + dashboard shells
**Story:** Foundation
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** S
**Ngày:** Day 2 chiều
**Depends on:** TASK-FE-04, TASK-FE-05
**Description:** Error boundary, loading skeleton, dashboard shell (sidebar nav theo role), fetch `/me` on mount.
**DoD:** Manual verify: dashboard load, logout hoạt động.

### TASK-FE-07: Anticipatory form scaffolds (question/exam/host/roster)
**Story:** US-002–US-009
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** M
**Ngày:** Day 2 chiều (khi chưa có việc ưu tiên hơn)
**Depends on:** TASK-FE-06
**Description:** Tạo "skeleton form" cho question editor, exam builder, host creation, roster import — để FS1/FS2 cắm business logic vào sau.
**DoD:** Form render được, chưa cần validate logic thật.

### TASK-FE-08: Proactive check-in + Flutter pairing với FS3
**Story:** Risk mitigation (FS3 dual-stack)
**Type:** Frontend (Flutter, nếu cần)
**Assigned to:** FE floater
**Effort:** L (biến động theo nhu cầu FS3)
**Ngày:** **Day 2 chiều trở đi** (chủ động hỏi, không chờ FS3 báo trễ)
**Depends on:** Không có (độc lập, theo lịch chủ động)
**Description:** Day 2 chiều, floater hỏi FS3 "Windows build + login screen sao rồi?" dù FS3 chưa yêu cầu. Nếu FS3 hơi trễ, floater pair ngay: co-implement `student_login_page.dart`, `exam_delivery_page.dart`, `score_page.dart`, hỗ trợ wiring BLoC, viết widget test.
**DoD:** Check-in Day 2 chiều được thực hiện và ghi nhận (kể cả khi FS3 báo "đang ổn"); nếu pair, code theo đúng pattern đã scaffold bởi FS3.

### TASK-FE-09: Roster import/export UI backup (nếu FS2 trễ)
**Story:** US-007, US-008, US-009, US-010
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** L
**Ngày:** Day 3+ (ưu tiên 1 sau FS3 check-in)
**Depends on:** TASK-FE-07, phối hợp với FS2 (TASK-FS2-04..08)
**Description:** File upload .xlsx drag-drop, validation report table (row #, reason), dropdown assign exam, nút download/re-download credential.
**DoD:** Manual verify: upload → report → assign → download — phối hợp format response với FS2.

### TASK-FE-10: Backup integration + polish
**Story:** Cross-cutting
**Type:** Frontend
**Assigned to:** FE floater
**Effort:** M
**Ngày:** Day 4–5
**Depends on:** TASK-FE-08, TASK-FE-09
**Description:** Khi FS2 + FS3 đã ổn, polish: validation UI feedback, loading/error state, responsive layout, animation, hỗ trợ E2E test + fix lint.
**DoD:** Không còn warning lint nghiêm trọng; E2E flow chính chạy được trên cả 2 web app.

---

## Risks cần theo dõi (tóm tắt từ plan.md)

**HIGH:**
- FS3 dual-stack (Spring Boot + Flutter) — mitigation: FE floater proactive check-in từ Day 2 chiều (TASK-FE-08).
- JWT là critical path cho FS2/FS3 — mitigation: khóa + publish Day 1 sáng (TASK-FS1-03); nếu trễ, FS1 tự xử lý, chỉ escalate tech lead nếu trễ >nửa ngày.
- `tenancy` + `scoring` module rỗng — mitigation: lock JPA entity layout Day 1 sáng (TASK-FS1-02), FS2/FS3 follow template từ `iam`.

**MEDIUM:**
- FE floater workflow — mitigation: explicit handoff point Day 2 chiều (FS2 roster UI) + Day 2 chiều (FS3 Flutter, proactive).
- Excel parsing/validation phức tạp (BR-004 cross-batch + same-file) — mitigation: TDD-first, test case 2 dòng trùng trong cùng 1 file (TASK-FS2-05).

**LOW:**
- Windows Flutter target chưa enable trước — mitigation: enable Day 1/2 sớm (TASK-FS3-07).
- Next.js 16 breaking changes — đọc doc trước khi code.

**NOTED (theo dõi, không block):**
- Exam assignment idempotency/race condition khi Host double-click assign gần đồng thời — chưa block MVP (single-operator workflow), nên dùng optimistic locking (`@Version` trên `ImportBatch`) nếu có thời gian.
- `ScoringService` phải nhận data qua DTO, không import trực tiếp `examdelivery` repository (đã áp dụng ở TASK-FS3-05).

---

## Success Criteria (end-to-end, từ spec.md)

- [ ] Admin login → tạo câu hỏi → dựng đề assignable: chạy được trên `aptis-api` thật.
- [ ] Admin tạo Host → Host login → upload roster Excel → thấy lỗi từng dòng → gán đề → tải credential.
- [ ] Student dùng credential từ Excel → login trên **Flutter desktop build** (Windows) → làm bài → nộp (chặn nộp lần 2) → thấy điểm ngay.
- [ ] `./mvnw clean test` xanh trên `aptis-api`; `flutter test` xanh trên phần `aptis-app` đã đụng tới.
- [ ] Không có dữ liệu nhạy cảm hardcode trong code đã commit (BR-010).

---

## Tham chiếu

- Plan gốc: `plans/aptis-mvp-week-tasks/plan.md` + `phase-01..04-*.md`
- Spec: `plans/aptis-mvp-week-tasks/spec.md`
- Business rules: `aptis-doc/projects/aptis-mvp/team/ba/business-rules.md`
- Tech stack quyết định: `aptis-doc/projects/aptis-mvp/team/techlead/tech-stack.md`, `mvp-slice-mapping.md`
- Task breakdown gốc (NestJS/Prisma, 4 dev, đã supersede cho tuần này): [`team/pm/task-breakdown.md`](team/pm/task-breakdown.md)
