# Task Breakdown — APTIS LMS

## Tasks

### TASK-001: Monorepo scaffold (apps/api, apps/worker, libs/domain, libs/infra)
**Story:** Infra
**Type:** DevOps
**Assigned to:** TechLead
**Effort:** XL
**Sprint:** 1
**Depends on:** None
**Description:** Initialize NestJS 11 monorepo with nx or Turborepo. Create `apps/api` (REST + WebSocket), `apps/worker` (BullMQ consumers), and `libs/` structure for each bounded context (`libs/iam`, `libs/tenancy`, `libs/exam-delivery`, etc.). Configure TypeScript 5.9 strict mode, ESLint, Prettier, Husky pre-commit hooks, and shared tsconfig paths.

---

### TASK-002: PostgreSQL 17 + Prisma 7 baseline schema + RLS transaction middleware
**Story:** Infra
**Type:** Database
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 1
**Depends on:** TASK-001
**Description:** Write Prisma schema for the full 24-entity ERD. Enable PostgreSQL RLS at DB level; add `tenant_id` column to all tenant-owned tables. Implement NestJS middleware that sets `SET LOCAL app.current_tenant_id = '{id}'` within every request transaction. Write integration test verifying cross-tenant SELECT returns 0 rows. Reference: ERD.md, ADR-002.

---

### TASK-003: Redis 7 + BullMQ + Docker Compose + GitHub Actions CI skeleton
**Story:** Infra
**Type:** DevOps
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-001
**Description:** Add Redis 7 service to Docker Compose. Configure BullMQ connection in `libs/infra/queue`. Write a no-op health-check queue. Add GitHub Actions workflow: lint → unit test → integration test (Postgres + Redis in service containers). Set up `.env.example` with all required vars.

---

### TASK-004: IAM module — User entity, JWT issuance, RBAC guard
**Story:** US-001, US-002, US-004, US-005, US-006, US-007
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 1
**Depends on:** TASK-002
**Description:** Implement `POST /auth/login` (bcrypt verify, access+refresh JWT pair). Access token: 15 min; refresh token: 7 days stored as SHA-256 hash in `refresh_tokens` table (ADR-003). `POST /auth/refresh` with refresh-token rotation; reuse of revoked token revokes entire family. `POST /auth/logout`. `POST /auth/request-reset` and `POST /auth/reset` with signed 1h link. Force-change-on-first-login flag in User entity. `RolesGuard` that validates union of all roles attached to the authenticated user.

---

### TASK-005: Tenancy middleware — host-based tenant resolution
**Story:** US-003
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-004
**Description:** NestJS global middleware that reads `Host` header, strips port, extracts `{slug}` from `{slug}.aptis-lms.vn`, and loads `Tenant` record from DB. Sets `TenantContext` in AsyncLocalStorage. Returns 404 if slug not found or tenant inactive. Expose `@CurrentTenant()` decorator for use in controllers and services.

---

### TASK-006: Auth UI Flutter — login, logout, credential reset screens
**Story:** US-001, US-005, US-006, US-007
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-004
**Description:** Flutter screens: Login (email + credential input, error states), Forced-change-on-first-login (in-place redirect), Credential reset request (email entry), Reset link landing (new-credential form). Wire to `POST /auth/login`, `POST /auth/refresh` (interceptor), `POST /auth/logout`. Store access token in memory, refresh token in secure storage (flutter_secure_storage).

---

### TASK-007: Auth integration tests
**Story:** US-001–007
**Type:** Testing
**Assigned to:** Tester
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-006
**Description:** Jest integration tests against real Postgres + Redis in Docker. Cover: login success, login wrong credential (401), refresh rotation, reuse-of-revoked-refresh (401 + family revoke), logout, reset link expiry (401), RBAC rejection (403), cross-tenant login attempt (404). Target 100% branch coverage on IAM module.

---

### TASK-008: Question CRUD + versioning + immutability guard
**Story:** US-009, US-014
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 2
**Depends on:** TASK-005
**Description:** `Question` entity with all APTIS content fields: type (MCQ, gap-fill, form-fill, matching, short-answer), skill, part, text, options JSON, correct_answer JSON, band, version, parent_id, is_published. `POST /questions` creates draft. `POST /questions/{id}/publish` marks published and immutable. `PUT /questions/{id}` on a published question creates a new version child (BR-011). Full CRUD with tenant_id scoping and RLS. Implement `QuestionRepository` with Prisma.

---

### TASK-009: Asset presigned upload — audio and image handling
**Story:** US-010, US-011
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 2
**Depends on:** TASK-005
**Description:** Implement `StoragePort` interface (ADR-005). Concrete adapter: S3-compatible presigned PUT generation (configurable via `STORAGE_PROVIDER` env var). `POST /assets/presign` returns presigned URL + asset_id. After upload, client calls `POST /assets/{id}/confirm`. Asset record created with tenant_id, mime_type, size, status. Link audio/image asset_ids to Question. Provider-neutral: swap adapter without changing application layer.

---

### TASK-010: Exam template API — template builder with 16-part composition
**Story:** US-012
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 2
**Depends on:** TASK-008
**Description:** `ExamTemplate` entity: title, skills[], status (draft/active/archived), configuration JSON for 16 parts. `POST /exam-templates` creates draft. Each part references a pool of Question IDs or a QuestionSet. `POST /exam-templates/{id}/activate` validates all 16 parts present before transitioning to active. Immutable once active (versioned on change). CRUD with tenant_id guard.

---

### TASK-011: Preview API — read-only template rendering
**Story:** US-013
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** M
**Sprint:** 2
**Depends on:** TASK-010
**Description:** `GET /exam-templates/{id}/preview` returns the full template structure resolved with question content — no ExamAttempt created. Response uses same payload shape as the exam client, so FE can share rendering logic. Access restricted to Content Manager and Tenant Admin roles.

---

### TASK-012: Vendor Portal FE scaffold — routing and auth shell
**Story:** Infra
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 2
**Depends on:** TASK-073
**Description:** Next.js app for Vendor Portal (Super Admin, Content Manager, Support Staff, Sales Team). Set up routing structure: `/auth`, `/tenants`, `/licenses`, `/questions`, `/templates`, `/analytics`. Integrate generated API client from TASK-073. Auth guard redirecting unauthenticated users. Role-based sidebar visibility. Shared layout with header, sidebar, breadcrumbs.

---

### TASK-013: Question editor + template builder UI
**Story:** US-009, US-010, US-011, US-012, US-013, US-014
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 2
**Depends on:** TASK-012, TASK-010
**Description:** Next.js pages: Question CRUD form with all field types, file upload (presigned upload flow from TASK-009), question list with search/filter/version history. Exam Template builder: 16-part drag-and-drop composition, question pool selector, part validation, preview mode (renders via TASK-011 API). Publish flow with immutability warning.

---

### TASK-014: Tenant CRUD API
**Story:** US-071, US-072, US-076
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 2
**Depends on:** TASK-005
**Description:** `Tenant` entity: slug, name, subdomain, status (active/inactive/suspended), plan, settings JSON. `POST /vendor/tenants` (Super Admin only), `PUT /vendor/tenants/{id}`, `POST /vendor/tenants/{id}/deactivate`, `POST /vendor/tenants/{id}/reactivate`. Subdomain change requires validation of DNS uniqueness. Audit log entry on every status transition (insert-only, ADR-004 outbox).

---

### TASK-015: License management API
**Story:** US-073, US-074, US-075
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 2
**Depends on:** TASK-014
**Description:** `License` entity: tenant_id, seat_count, used_seats, valid_from, valid_until, status. `POST /vendor/licenses` issues new license. `GET /vendor/licenses/{tenant_id}` returns utilization. BullMQ job for expiry check (daily cron). Sends alert notification when license expires or seats exhausted. Seat quota check on every enrollment request (returns 402 when exceeded, BR-007).

---

### TASK-016: Course + Group API
**Story:** US-044, US-045
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 3
**Depends on:** TASK-005
**Description:** `Course` entity: title, description, tenant_id, status. `Group` entity: name, course_id, teacher_id (FK to User), tenant_id. `POST /courses`, `POST /groups` with teacher assignment. `GET /courses`, `GET /groups` with pagination. Full CRUD with tenant_id guard. Teacher role is validated against tenant user list.

---

### TASK-017: Bulk student import worker
**Story:** US-047, US-048
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 3
**Depends on:** TASK-016
**Description:** `POST /students/import` accepts multipart CSV/Excel upload. Validate headers, parse rows, collect per-row errors. Enqueue BullMQ job `student.import` with file reference. Worker processes rows: create User + StudentProfile + enroll in group. On completion: write import_result JSON to storage, notify requestor. `GET /students/import/{jobId}` returns progress + error rows + credentials export link (for newly created users).

---

### TASK-018: Enrollment API
**Story:** US-046, US-051
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 3
**Depends on:** TASK-016
**Description:** `Enrollment` entity: student_id, group_id, tenant_id, enrolled_at, status (active/removed). `POST /groups/{id}/enroll` with seat quota check against license (TASK-015). `DELETE /groups/{id}/students/{studentId}` soft-removes with status=removed. Seat count decremented on removal. `GET /groups/{id}/students` with search, filter, pagination.

---

### TASK-019: Tenant Portal FE scaffold — routing and auth shell
**Story:** Infra
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 3
**Depends on:** TASK-073
**Description:** Next.js app (or section) for Tenant Portal (Tenant Admin, Teacher, Exam Coordinator, Viewer). Routes: `/students`, `/courses`, `/groups`, `/sessions`, `/monitor`, `/analytics`, `/results`. Role-based navigation. Integrates with same generated API client. Multi-role union: one user can have Teacher + Exam Coordinator simultaneously; sidebar shows union of accessible routes.

---

### TASK-020: Enrollment + student management UI
**Story:** US-044–051, US-077, US-078, US-079
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 3
**Depends on:** TASK-019, TASK-018
**Description:** Next.js pages: Course/Group list + create form. Student list with search/filter/pagination. Individual enrollment modal. Bulk import wizard: file upload → row preview with errors → confirm → progress polling → download credentials. Student profile edit form. Remove student with seat-release confirmation. Support staff read-only tenant view shell.

---

### TASK-021: Exam scheduling API
**Story:** US-037, US-038
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 3
**Depends on:** TASK-018
**Description:** `ExamSession` entity: template_id, group_id, scheduled_at, duration_minutes, status (scheduled/in_progress/completed/cancelled), coordinator_id, settings JSON (shuffle_enabled, violation_threshold, allowed_retakes). `POST /sessions` creates session; participants added from group enrollment. `PUT /sessions/{id}` edits schedule (only when status=scheduled). `POST /sessions/{id}/cancel`. Schedule conflicts blocked if same group has overlapping session. BullMQ job enqueued for T-24h and T-1h reminders.

---

### TASK-022: Support staff + audit log API
**Story:** US-077, US-079
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** M
**Sprint:** 3
**Depends on:** TASK-005
**Description:** `AuditLog` entity: actor_id, actor_role, action, target_type, target_id, tenant_id, metadata JSON, created_at. Insert-only (no update, no delete — BR-016). `POST /audit-logs` internal endpoint called from application services. `GET /vendor/audit-logs` with tenant filter for Support Staff. Impersonation: when Support Staff accesses tenant, an impersonation log entry is written automatically by middleware.

---

### TASK-023: Live monitor WebSocket — real-time student status fan-out
**Story:** US-039
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 4
**Depends on:** TASK-021
**Description:** NestJS Gateway on `/ws/sessions/{sessionId}/monitor`. Coordinator subscribes; receives real-time student status events: attempt_started, part_changed, answer_submitted, violation_detected, attempt_submitted. Events published via Redis pub/sub from the API (any pod can receive student events; all coordinator connections receive fan-out). Heartbeat every 15 s; stale connections evicted after 30 s. Student status projection: last event per student stored in Redis hash for reconnect catch-up.

---

### TASK-024: Intervention API — extend time, force-submit, close session
**Story:** US-040, US-041, US-042, US-043
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 4
**Depends on:** TASK-023
**Description:** `POST /sessions/{id}/extend-time` — adds seconds to PartTimer for one student (server-side). `POST /sessions/{id}/force-submit/{attemptId}` — transitions attempt to submitted, triggers scoring pipeline. `POST /sessions/{id}/close` — closes session, force-submits all in-progress attempts. `POST /attempts/{id}/approve-retake` — allows new attempt for student in same session. All actions write AuditLog entry and emit WebSocket event to monitor.

---

### TASK-025: Vendor and license management UI
**Story:** US-071–076
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 4
**Depends on:** TASK-012, TASK-015
**Description:** Vendor Portal pages: Tenant list with status badges, create tenant form, tenant detail with edit, deactivate/reactivate controls. License panel per tenant: current license, seat utilization bar, issue new license form, expiry warning banner. Sales team exam usage report page (read-only). Vendor admin audit log viewer with tenant filter.

---

### TASK-026: Scheduling and monitor UI
**Story:** US-037–043, US-080–082
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 4
**Depends on:** TASK-019, TASK-023
**Description:** Tenant Portal pages: Session list with status. Create session form: template selector, group selector, schedule datetime, settings (violation threshold, shuffle). Edit session form (pre-start only). Live monitor dashboard: table of students with current status, part, last-answer time, violation count. Intervention controls: per-student extend time input, force-submit button, close session. Approve retake dialog. WebSocket connection with reconnect + catch-up from last event.

---

### TASK-027: Notification module — BullMQ notification pipeline
**Story:** US-083–087
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 4
**Depends on:** TASK-004
**Description:** `Notification` entity: type, recipient_id, channel (email/push/in-app), payload JSON, status, created_at, sent_at. `NotificationPort` interface (ADR-005) with `EmailAdapter` (SMTP). BullMQ queue `notifications`. Worker processes jobs, calls adapter, marks sent or DLQ on 3 failures. `NotificationLog` append-only record. `POST /internal/notifications` called from domain services. Retry with exponential backoff.

---

### TASK-028: Session reminder scheduler
**Story:** US-083, US-084, US-085
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 4
**Depends on:** TASK-027, TASK-021
**Description:** BullMQ delayed job enqueued at session creation for T-24h and T-1h before `scheduled_at`. On fire: load session participants, enqueue notification jobs for each. On session edit: cancel old delayed jobs, enqueue new ones. BullMQ `removeOnComplete` + job ID for idempotency. Session invitation email fires immediately on session creation.

---

### TASK-029: Guest/Trial session API
**Story:** US-008, US-088, US-089, US-090, US-091, US-092
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** M
**Sprint:** 4
**Depends on:** TASK-005
**Description:** `GuestSession` entity: session_id (UUID), template_id (trial template), expires_at (24 h), ip_address, lead_email (nullable). `POST /guest/sessions` — creates guest attempt from a designated trial template without auth. No tenant_id. Lead capture: `POST /guest/sessions/{id}/lead` stores email. Trial results visible immediately (no teacher confirmation required for trial). Cron job deletes expired guest sessions daily.

---

### TASK-030: ExamAttempt state machine — attempt lifecycle management
**Story:** US-017, US-018, US-025
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 5
**Depends on:** TASK-021
**Description:** `ExamAttempt` entity: session_id, student_id, status (pending/in_progress/submitted/scored), shuffle_seed, current_skill, current_part, started_at, submitted_at. `POST /sessions/{id}/attempts` — eligibility check: student enrolled, session in_progress, no existing non-retake attempt (BR-008). Pre-exam check: returns pre_exam_status with mic_test_passed, instructions_acknowledged booleans. `POST /attempts/{id}/acknowledge-instructions` transitions to `in_progress`. State machine enforces valid transitions only.

---

### TASK-031: Pre-exam check API
**Story:** US-018
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 5
**Depends on:** TASK-030
**Description:** `POST /attempts/{id}/pre-check/mic-test` records mic_test_passed=true with timestamp. `POST /attempts/{id}/pre-check/instructions-ack` records instructions_acknowledged=true. Attempt cannot transition to in_progress unless both checks pass (configurable per session settings). `GET /attempts/{id}/pre-check` returns current status for FE polling. Checks expire if attempt not started within 10 minutes.

---

### TASK-032: Part timer service — server-authoritative timer with sync endpoint
**Story:** US-019
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 5
**Depends on:** TASK-030
**Description:** `PartTimer` entity: attempt_id, skill, part, started_at, duration_seconds, expires_at, extended_seconds. `POST /attempts/{id}/parts/{part}/start` creates PartTimer and starts countdown. `GET /attempts/{id}/timer` returns remaining_seconds calculated server-side as `expires_at - now()`. Client polls every 5 s to sync. At `expires_at`: server-side BullMQ job auto-closes part (any answer submitted after triggers HTTP 409, BR-004). Extension from TASK-024 adds to `extended_seconds` and recalculates `expires_at`.

---

### TASK-033: Per-answer persistence + idempotency
**Story:** US-019, US-020, US-022
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 5
**Depends on:** TASK-032
**Description:** `ExamAnswer` entity: attempt_id, question_id, value JSON, sequence_number, submitted_at. `POST /attempts/{id}/answers` — validates: attempt is in_progress, PartTimer not expired, sequence_number > last stored for this question. Upsert with optimistic locking. Returns 409 if timer expired (BR-004), 409 if sequence stale (BR-005). Idempotency: duplicate requests with same sequence_number are silently accepted. Throughput target: ≤500 ms p95 under 200 concurrent attempts.

---

### TASK-034: Shuffle seed — deterministic question/option ordering per attempt
**Story:** US-093, US-094
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** M
**Sprint:** 5
**Depends on:** TASK-030
**Description:** On attempt creation, generate a cryptographically random shuffle_seed (UUID stored on ExamAttempt). Use seeded PRNG (mulberry32) to deterministically shuffle question order within each part and option order within each question. Same attempt_id always produces same order (BR-009). Seed stored on attempt so resume, review, and scoring always agree on the same ordering. Never use `Math.random()` for shuffle.

---

### TASK-035: Exam client FE scaffold — Flutter/Next.js exam shell
**Story:** Infra
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 5
**Depends on:** TASK-073, TASK-031
**Description:** Flutter app (aptis-app) or Next.js exam section (aptis-web): fullscreen enforcement on entry, pre-exam check flow (mic test widget, instruction screen). Navigation shell: skill tabs (locked until current skill complete), part progress indicator, timer bar. Timer bar subscribes to timer sync API; turns red at <60 s. Connection status indicator. Part transition screen between skills. Keyboard/focus trap for fullscreen mode.

---

### TASK-036: Reading + Listening UI — question renderers with answer capture
**Story:** US-020, US-022, US-024
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 5
**Depends on:** TASK-035, TASK-033
**Description:** Reading renderer: MCQ (single/multi), gap-fill (drag-or-type), form-fill, matching (drag-and-drop). Listening renderer: auto-play audio on part start (CDN delivery), same question types. Answer capture: debounced POST to `/attempts/{id}/answers` with sequence_number incremented per change. Optimistic UI update; no user-visible flash on 409 (timer expired — disable input, show expired banner). Timer sync polling integration.

---

### TASK-037: Writing UI — writing parts A–C with live word count
**Story:** US-021
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 6
**Depends on:** TASK-035, TASK-033
**Description:** Writing Parts A (short sentences), B (email), C (essay). Rich-text or plain-text editor per part (configurable). Live word count with min/max boundaries highlighted. Auto-save via debounced answer POST every 30 s. Character/word limit enforcement (soft warning, not hard block). Part navigation locked until current part timer expires or student explicitly navigates.

---

### TASK-038: Speaking UI — 5-stage flow with IndexedDB audio buffer
**Story:** US-023
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 6
**Depends on:** TASK-035
**Description:** Speaking Parts A–E, each with 5 stages: (1) instruction, (2) image/prompt display, (3) preparation countdown, (4) recording (MediaRecorder API), (5) upload. Audio chunks buffered to IndexedDB while recording. After recording: upload to presigned URL from TASK-009 with retry every 30 s until success. Status per part: pending/recording/uploaded/upload_failed. Upload failure does not block advancing to next part — retries in background.

---

### TASK-039: Exam submission + transactional outbox
**Story:** US-026
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 6
**Depends on:** TASK-033
**Description:** `POST /attempts/{id}/submit` — validates all required parts have answers, transitions attempt to `submitted`. Within a single PostgreSQL transaction: (1) set attempt.status = submitted, (2) insert outbox record `attempt.submitted` event (ADR-004). BullMQ outbox relay picks up event and enqueues `score.auto` job. Idempotent: repeated submit on already-submitted attempt returns 200 with current state. Force-submit from coordinator (TASK-024) uses same endpoint with coordinator role.

---

### TASK-040: Integrity module — violation detection, logging, threshold
**Story:** US-094–098
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 6
**Depends on:** TASK-030
**Description:** `ViolationEvent` entity: attempt_id, type (FULLSCREEN_EXIT, TAB_SWITCH, FOCUS_LOSS), occurred_at, metadata JSON. Append-only table (BR-016). `POST /attempts/{id}/violations` — logs violation event, increments violation count on attempt. `GET /attempts/{id}/violations/count` for threshold check. Session-level `violation_threshold` setting from ExamSession. When count reaches threshold: auto-terminate (same as force-submit + status=violation_terminated). Warning notification sent at threshold-1.

---

### TASK-041: Violation monitor API — real-time violation events to coordinator
**Story:** US-099, US-100
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 6
**Depends on:** TASK-040
**Description:** Violation events published to Redis pub/sub channel `session:{id}:violations`. Monitor WebSocket (TASK-023) fan-out to coordinator includes violation count updates. `GET /sessions/{id}/violations` — session-level summary per student. `GET /sessions/{id}/violations/report` — full audit report (attempt_id, student, violation list, termination flag). Proctor notification enqueued when threshold breached (TASK-027).

---

### TASK-042: Integrity UI — fullscreen guard, tab detection, violation warnings
**Story:** US-095, US-096, US-097, US-098
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 6
**Depends on:** TASK-035, TASK-041
**Description:** Browser Fullscreen API wrapper: enforce fullscreen on exam start, detect exit event and POST violation. Page Visibility API: detect `visibilitychange` and `blur` events, POST violation. Warning overlay: displays current violation count and threshold remaining. Auto-terminate UI: shows "Exam terminated due to repeated violations" overlay, disables all inputs, submits attempt. Violations queued locally if offline; flushed on reconnect.

---

### TASK-043: Auto-scoring worker — Reading/Listening raw score computation
**Story:** US-027, US-028, US-029
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 7
**Depends on:** TASK-039
**Description:** BullMQ consumer `score.auto`: loads ExamAttempt + all ExamAnswers + question correct_answer fields. Computes raw scores per skill per part by comparing submitted answer JSON to correct_answer JSON. Stores `RawScore` record per skill. Idempotent: re-scoring same attempt produces same result. Target: complete within 30 s of attempt submission. Emits `score.auto.complete` outbox event on finish.

---

### TASK-044: Band mapping service
**Story:** US-028
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 7
**Depends on:** TASK-043
**Description:** `BandMapping` lookup table: skill, raw_score_min, raw_score_max, band (A1/A2/B1/B2/C). Seeded from official APTIS conversion table. `BandMappingService.lookup(skill, rawScore)` returns band or MAPPING_ERROR if out-of-range. Called by auto-scoring worker and teacher confirmation flow. Admin endpoint to update mapping table (Super Admin only, audited).

---

### TASK-045: STT pipeline worker — audio transcript generation
**Story:** US-030
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 7
**Depends on:** TASK-039
**Description:** BullMQ consumer `score.stt`: receives attempt_id + list of speaking asset_ids. Downloads audio from storage (via StoragePort). Calls `SttPort.transcribe(audioBuffer)` (ADR-005 provider-neutral). On success: stores transcript text in `SpeakingTranscript` table. On failure after 3 retries: writes STT_FAILED status. Emits `stt.complete` or `stt.failed` outbox event. Teacher scoring queue (TASK-048) shows STT_FAILED as "manual transcript required".

---

### TASK-046: LLM scoring pipeline — Writing/Speaking AI draft generation
**Story:** US-031
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 7
**Depends on:** TASK-045
**Description:** BullMQ consumer `score.llm`: receives attempt_id, skill (Writing/Speaking), transcript/text content. Constructs prompt with APTIS rubric. Calls `LlmPort.score(prompt)` (ADR-005). Validates response against canonical schema: `{criteria: [{name, score, justification}], overall_band, reasoning}`. Invalid schema → retry 3× then DLQ. Stores `AiScoreDraft` with status=`pending_review`. Never exposed on student-facing APIs (BR-013). Emits `llm.draft.ready` event.

---

### TASK-047: Provider-neutral ports — storage, STT, LLM adapters
**Story:** Infra
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 7
**Depends on:** TASK-045, TASK-046
**Description:** Formalize and document the three ports from ADR-005: `StoragePort`, `SttPort`, `LlmPort`. Each as NestJS abstract class/interface registered in DI. Concrete adapters in `libs/infra/adapters/`. Add `STORAGE_PROVIDER`, `STT_PROVIDER`, `LLM_PROVIDER` env vars to `.env.example`. Write adapter factory module that selects adapter by env var. Integration test: mock adapter satisfies port contract.

---

### TASK-048: Teacher scoring queue API
**Story:** US-032
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 7
**Depends on:** TASK-046
**Description:** `GET /scoring-queue` — returns list of AiScoreDraft records for the authenticated teacher's groups, status=pending_review. Includes: attempt_id, student name, skill, AI band suggestion, criteria breakdown, transcript (if available), STT_FAILED flag. `GET /scoring-queue/{draftId}` — full draft detail. Pagination and filter by skill, group. Sorted by submitted_at ascending (oldest first).

---

### TASK-049: Score confirmation — teacher review and finalization
**Story:** US-033
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 8
**Depends on:** TASK-048
**Description:** `POST /scoring-queue/{draftId}/confirm` — teacher submits: confirmed_band per skill, written_feedback (optional). Validates band is a valid APTIS value. Sets AiScoreDraft status=confirmed. Within transaction: creates `FinalScore` record, writes outbox event `score.confirmed`. Outbox relay enqueues `notification.score_ready`. Idempotent: re-confirming with same band returns 200 with existing FinalScore. `POST /scoring-queue/{draftId}/override` — manual override when STT_FAILED (teacher provides transcript + scores manually).

---

### TASK-050: Results-ready notification trigger
**Story:** US-086
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** M
**Sprint:** 8
**Depends on:** TASK-049, TASK-027
**Description:** BullMQ consumer `notification.score_ready`: loads FinalScore + student User record. Enqueues email notification (TASK-027 pipeline). Email: "Your APTIS practice results are ready." with link to results page. In-app notification record created. Student sees in-app badge on next login. Notification status tracked in NotificationLog.

---

### TASK-051: Student results FE — band dashboard and attempt history
**Story:** US-034, US-035, US-036
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 8
**Depends on:** TASK-035, TASK-049
**Description:** Results page: 4-skill band radar/bar chart, overall score summary, disclaimer "AI-assisted, confirmed by teacher" (BR-013). Pending skill shows PENDING badge (not hidden). Teacher written feedback section (displayed when present). Attempt history table: date, template, 4-skill bands. Click attempt → detailed result. Student portal in Flutter (aptis-app) and Next.js (aptis-web) — shared API, different UI implementation.

---

### TASK-052: Teacher scoring queue UI
**Story:** US-032, US-033
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 8
**Depends on:** TASK-035, TASK-048
**Description:** Tenant Portal page: scoring queue table with filter by skill/group/status. Queue item detail: transcript panel, AI suggestion per criterion, band selector, feedback text area, confirm button. STT_FAILED indicator with manual transcript input. Optimistic submission with loading state. After confirmation: item removed from queue, success toast. Paginated queue with auto-refresh every 60 s.

---

### TASK-053: Item analysis read model job
**Story:** US-016
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 8
**Depends on:** TASK-043
**Description:** Nightly BullMQ cron job `analytics.item_analysis`: for each published question with ≥20 scored answers, compute p-value (proportion correct) and discrimination index (point-biserial correlation). Store on `Question` record: `p_value`, `discrimination_index`, `analysis_at`. Flag questions with discrimination_index < 0.2 as `low_discrimination`. Incremental: only recomputes questions that had new answers since last run.

---

### TASK-054: Student analytics API
**Story:** US-052, US-053
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 8
**Depends on:** TASK-049
**Description:** `GET /analytics/students/{id}/progression` — per-skill band history across all attempts, sorted by date. `GET /analytics/students/{id}/skills` — latest band per skill with trend direction (improved/declined/stable). Uses `FinalScore` records. Available to: Student (own data), Teacher (students in own groups), Tenant Admin (all students in tenant). RLS + RBAC enforced.

---

### TASK-055: Class analytics API
**Story:** US-054, US-055, US-056, US-057, US-058
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 8
**Depends on:** TASK-054
**Description:** `GET /analytics/groups/{id}/summary` — average band per skill, attempt count, completion rate, score distribution histogram (A1/A2/B1/B2/C counts). `GET /analytics/groups/{id}/progression` — average band trend over time (weekly/monthly). Teacher sees all own groups; Tenant Admin sees all groups. Computed from FinalScore projection table updated by analytics worker on each score.confirmed event.

---

### TASK-056: Tenant analytics API
**Story:** US-059, US-060
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 9
**Depends on:** TASK-055
**Description:** `GET /analytics/tenants/{id}/aggregate` — tenant-wide: total attempts, avg bands per skill, score distribution, active vs inactive students. `GET /analytics/tenants/{id}/license` — seat utilization vs capacity, trend. Available to Tenant Admin only. Aggregated from group-level analytics read model. No per-student PII exposed at aggregate level.

---

### TASK-057: Analytics export worker
**Story:** US-061, US-062, US-063
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 9
**Depends on:** TASK-056
**Description:** BullMQ job `analytics.export`: accepts scope (student/group/tenant), entity_id, format (xlsx/csv), requester_id. Generates Excel/CSV using exceljs. Uploads to presigned URL. Notifies requester via in-app notification with download link (valid 24 h). `GET /analytics/exports/{jobId}` returns status + download URL. Re-generation on duplicate request within 1 h returns cached result.

---

### TASK-058: Analytics UI
**Story:** US-054–060, US-059
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 9
**Depends on:** TASK-019, TASK-055
**Description:** Tenant Portal analytics pages: Student progression charts (line chart over time, skill breakdown). Class analytics: bar chart average bands, histogram, completion rate gauge. Tenant aggregate dashboard: KPI cards + trend lines. License utilization bar with expiry countdown. Filter controls: date range, group selector, skill selector. Export button triggers TASK-057 job + poll for download link. Chart library: Recharts or Chart.js.

---

### TASK-059: Guest/Trial UI
**Story:** US-088–092
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** L
**Sprint:** 9
**Depends on:** TASK-035, TASK-029
**Description:** Public-facing trial flow (no auth required). Landing page: "Try APTIS Practice" with start button. Creates guest session via `POST /guest/sessions`. Renders exam using exam client shell (TASK-035) with trial template. Trial results page: immediate band summary (no teacher confirmation required), upgrade prompt CTA. Lead capture modal: optional email input after results. Expiry banner if trial session older than 24 h.

---

### TASK-060: Bulk question bank import
**Story:** US-015
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 9
**Depends on:** TASK-008
**Description:** `POST /questions/bulk-import` — multipart CSV/Excel upload with question schema. Validates headers, parses rows, previews errors (like TASK-017 pattern). BullMQ job processes valid rows: creates Question records in draft status. Import result: total rows, success count, error rows with reasons. Questions created as drafts requiring explicit publish action. Supports all question types in the schema.

---

### TASK-061: Notification delivery polish
**Story:** US-083–087
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** L
**Sprint:** 9
**Depends on:** TASK-027
**Description:** Complete notification type coverage: session invitation (TASK-028), T-24h reminder, T-1h reminder, score-ready (TASK-050), violation alert (TASK-041), bulk group notification (`POST /sessions/{id}/notify-all`). `GET /notifications/me` — student/teacher in-app notification inbox. Mark-read endpoint. Notification preference settings per user (email opt-out). Ensure all notification jobs have idempotency keys to prevent duplicate sends on retry.

---

### TASK-062: Item analysis advanced — visualization and auto-flagging
**Story:** US-064, US-065, US-066
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 10
**Depends on:** TASK-053
**Description:** `GET /questions/{id}/analysis` — full item analysis: p-value, discrimination_index, response distribution per option (distractor analysis), trend over question versions. `GET /questions?filter=low_discrimination` — list of auto-flagged questions. `GET /questions/{id}/analysis/history` — p-value and discrimination trend across version history. API for Vendor Portal item analysis dashboard.

---

### TASK-063: Exam resume endpoint
**Story:** US-104, US-107
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 10
**Depends on:** TASK-033
**Description:** `GET /attempts/{id}/state` — returns full resume payload: current_skill, current_part, all ExamAnswer records (for restoring UI state), PartTimer remaining_seconds (server-calculated). FE uses this to rebuild UI after disconnect or app restart. Endpoint idempotent — safe to call repeatedly. Access restricted to the authenticated student who owns the attempt. Returns 404 if attempt not found or not owned by caller.

---

### TASK-064: Network recovery backend — reconnect handling
**Story:** US-105, US-106
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 10
**Depends on:** TASK-063
**Description:** WebSocket reconnect protocol: client sends `{attemptId, lastSeqNo}` on reconnect. Server replays missed answer acknowledgements since lastSeqNo. Timer state re-sent on reconnect (remaining_seconds recalculated server-side). Answer submission queue on client (IndexedDB) flushed on reconnect in sequence order. Server validates sequence_number ordering; gaps accepted (client may have submitted while offline via retry). Connection state tracked per attempt in Redis.

---

### TASK-065: Exam audio retry FE — speaking upload retry with IndexedDB
**Story:** US-108, US-109
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 10
**Depends on:** TASK-038, TASK-064
**Description:** Extend TASK-038 speaking UI with: persistent retry queue in IndexedDB (survives app restart). Background upload manager: retries failed uploads every 30 s using exponential backoff. Per-part upload status indicator: pending/uploading/uploaded/failed. On reconnect: resume interrupted uploads from IndexedDB buffer. If upload still pending at exam submission: submit attempt anyway with `pending_audio_parts` flag set. Teacher UI shows "audio pending" state.

---

### TASK-066: Analytics export + advanced analytics UI
**Story:** US-061–063, US-067–070
**Type:** Frontend
**Assigned to:** FE Dev
**Effort:** XL
**Sprint:** 11
**Depends on:** TASK-058, TASK-057
**Description:** Analytics pages: Export button per scope (student/group/tenant) → polls for download URL → triggers browser download. Scheduled report UI: create/list/delete scheduled export jobs. Date range filter across all analytics charts. Custom view config (Tenant Admin): pin preferred metrics to dashboard. Report-ready in-app notification badge. Item analysis pages: p-value + discrimination scatter plot, distractor analysis table, low-discrimination question list with bulk review action.

---

### TASK-067: Speaking audio continuity worker — STT retry queue
**Story:** US-110, US-111
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** XL
**Sprint:** 11
**Depends on:** TASK-045
**Description:** When TASK-038/TASK-065 uploads speaking audio after attempt submission: BullMQ job `audio.late_upload` detects new audio for a submitted attempt. Triggers STT pipeline re-run. Updates `SpeakingTranscript` from STT_FAILED to completed status. Notifies teacher scoring queue that transcript is now available (replaces "manual required" with AI transcript). If LLM draft already confirmed, no re-scoring — teacher sees transcript as additional information only. Teacher UI: "audio pending" → "transcript ready" status transition visible in real time.

---

### TASK-068: Security hardening
**Story:** Infra
**Type:** Backend
**Assigned to:** TechLead
**Effort:** L
**Sprint:** 11
**Depends on:** None
**Description:** Rate limiting: 5 auth requests/min per IP (NestJS throttler), 20 answer writes/s per attempt. Helmet middleware (CSP, HSTS, X-Frame-Options). Input validation: class-validator on all DTOs, strip unknown properties. RLS hostile-tenant test suite: 10 patterns (cross-tenant SELECT, INSERT with wrong tenant_id, UPDATE bypass attempt). Secrets audit: verify no hardcoded secrets in codebase (BR-025). CORS whitelist for tenant subdomains. Dependency vulnerability scan (npm audit).

---

### TASK-069: Performance and load tests
**Story:** Infra
**Type:** Testing
**Assigned to:** Tester
**Effort:** L
**Sprint:** 11
**Depends on:** None
**Description:** k6 load test scripts: 200 concurrent exam attempts simultaneously. Measure: answer persist p95 ≤500 ms, timer sync p95 ≤2 s, WebSocket fan-out p95 ≤1 s, auto-scoring completion ≤2 min. DB connection pool sizing validated. BullMQ worker concurrency tuned. Redis memory usage under load profiled. Report: p50/p95/p99 latencies, error rate, throughput. Fix any regressions found before marking sprint complete.

---

### TASK-070: E2E regression suite
**Story:** Infra
**Type:** Testing
**Assigned to:** Tester
**Effort:** L
**Sprint:** 11
**Depends on:** None
**Description:** Playwright (web) + Flutter integration test (mobile) E2E suite covering the critical path: register tenant → create question → build template → enroll students → schedule session → student completes exam → auto-score → teacher confirms → student views results. Additional flows: violation detection, force-submit, guest trial. Tests run against staging environment with real PostgreSQL (no mocks). CI gate: E2E must pass before deploy.

---

### TASK-071: Observability setup
**Story:** Infra
**Type:** DevOps
**Assigned to:** TechLead
**Effort:** L
**Sprint:** 11
**Depends on:** None
**Description:** Pino structured JSON logging with correlation_id, tenant_id, user_id on every log line. OpenTelemetry traces for HTTP requests, BullMQ job execution, DB queries. Export to Jaeger (local) or OTLP endpoint (staging). Prometheus metrics: BullMQ queue depth, job duration histogram, active WebSocket connections, answer-write throughput. Grafana dashboard: exam health KPIs. Alert rules: DLQ depth >10, outbox lag >5 min, error rate >1%.

---

### TASK-072: Deployment runbook
**Story:** Infra
**Type:** DevOps
**Assigned to:** TechLead
**Effort:** M
**Sprint:** 11
**Depends on:** None
**Description:** Document: Docker image build + multi-stage Dockerfile for api and worker. `.env.example` with all required environment variables and documentation. Prisma migration procedure: `prisma migrate deploy` in init container before api starts. Staging deploy checklist: DB backup, migration, api rolling update, worker restart. Rollback procedure. Health check endpoints: `GET /health` (api), `GET /health/worker`. README section: local dev setup in 3 commands.

---

### TASK-073: OpenAPI codegen — Flutter/Dart client generation
**Story:** Infra
**Type:** Backend
**Assigned to:** BE Dev
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-004
**Description:** NestJS Swagger decorator setup on all auth controllers from TASK-004. `npm run swagger:gen` script exports `openapi.json`. OpenAPI Generator CLI configured for `dart-dio` client. Generated client published to `libs/api-client/` (monorepo shared lib). GitHub Actions step regenerates client on API spec change. FE teams import from generated client; never hand-write API calls.
