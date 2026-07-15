# Task Breakdown — APTIS MVP (Host-Driven Exam Distribution)

> **Assignment model:** 4 full-stack developers (D1–D4). "Assigned to" names the owning
> full-stack dev who builds the task end-to-end (API + UI + tests for their vertical).
> Effort sizes: S=1, M=3, L=5, XL=8 (nominal). Level `senior` applies ×0.75 at the velocity layer.
>
> **⚠ Read with ADR-005 + `team/techlead/mvp-slice-mapping.md`.** Per ADR-005 the MVP is built
> **inside the production `aptis-lms` repos** as the first vertical slice. Task ownership and story
> mapping below are unchanged, but each "module" is a **DDD bounded context** (`iam`, `tenancy`,
> `question-bank`, `exam-operations`, `exam-delivery`, `scoring`) under `aptis-be/libs/modules/`,
> layered domain/application/infrastructure/presentation — see the mapping doc §1–§3 for placement.

## Tasks

### TASK-001: Bootstrap the MVP slice inside the existing repos
**Story:** Foundation (all)
**Type:** DevOps
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** L
**Sprint:** 1
**Depends on:** None
**Description:** The repos are **already scaffolded** to the full `aptis-lms` architecture (per ADR-005) — this task wires up the MVP slice, it does NOT create from scratch. Confirm `aptis-be apps/api` boots (`npm run start:dev`) and `aptis-web` (Next 16) dev server runs; confirm `docker-compose` (`postgres:17` + `redis:7`) is healthy. Create the 6 in-scope bounded-context module shells under `libs/modules/` (`iam`, `tenancy`, `question-bank`, `exam-operations`, `exam-delivery`, `scoring`) with the domain/application/infrastructure/presentation layout per `aptis-be/RULE.md`. **Add `exceljs`** to aptis-be; decide aptis-web server-state lib (TanStack Query vs server actions) and install if chosen. Complete `.env.example` per service (no secrets — BR-010); confirm CI lint+test on PR. Leave `apps/worker` and Redis/BullMQ present-but-unused (ADR-005 deferral); **do not touch `aptis-app`** (frozen). **DoD:** `apps/api` + web boot locally against compose; `/api/v1` health responds; 6 context shells compile; `exceljs` installed; CI green.

### TASK-002: Prisma schema + initial migration (full data model)
**Story:** Foundation (all)
**Type:** Database
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-001
**Description:** Author the complete `schema.prisma` for all 11 entities from `team/techlead/ERD.md`: ADMIN, HOST, STUDENT, QUESTION, OPTION, EXAM, EXAM_QUESTION, IMPORT_BATCH, CREDENTIAL_EXPORT, EXAM_ATTEMPT, ANSWER. Encode every constraint/index: `STUDENT.username` UNIQUE (global), `STUDENT(host_id, student_identifier)` UNIQUE (BR-004), `HOST.contact_email` UNIQUE, `EXAM.name` UNIQUE, `EXAM_QUESTION(exam_id, question_id)` UNIQUE, `CREDENTIAL_EXPORT.batch_id` UNIQUE, `EXAM_ATTEMPT.student_id` UNIQUE (BR-003/Assumption 4), `ANSWER(attempt_id, question_id)` UNIQUE, plus indexes on `STUDENT.host_id`, `IMPORT_BATCH.host_id`, `CREDENTIAL_EXPORT.host_id`. Single-owner per ADR-002 to avoid migration conflicts; **schema frozen end of Day 1** — later changes go via small reviewed PRs. **DoD:** `prisma migrate dev` applies cleanly; generated types compile across all modules.

### TASK-003: Auth core — JWT, RBAC Guard, host-scoped base repository
**Story:** Foundation (all) / US-001, US-006, US-011
**Type:** Backend
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-002
**Description:** Implement the shared auth layer per ADR-003: bcrypt credential hashing (BR-001), a random ≥8-char alphanumeric credential generator (BR-002, server-side), `@nestjs/jwt` + Passport-JWT issuance/verification with `role` and (for Host/Student) `hostId` claims, a NestJS RBAC Guard reading the role claim, and a **host-scoped base repository helper** that mandates a `hostId` argument sourced **only** from the verified JWT — the single lynchpin enforcing BR-005. Provide a shared login service consumable by all three role controllers. JWT secret from env only (BR-010). **DoD:** unit tests cover hash/verify, token issue/verify, Guard role rejection, and that the base repo refuses a call without `hostId`.

### TASK-004: Admin login page (FE) + auth wiring
**Story:** US-001
**Type:** Frontend
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** S
**Sprint:** 1
**Depends on:** TASK-003
**Description:** Admin login form (email + credential) calling the auth API; store JWT in memory + httpOnly cookie; redirect to Admin dashboard on success. Handle the 3 AC cases: generic "invalid email or credential" for both wrong-credential and non-existent account (no account-existence leak), and field-level validation for empty fields with no auth attempt. **DoD:** all US-001 acceptance scenarios pass.

### TASK-005: Question CRUD API + validation
**Story:** US-002, US-003
**Type:** Backend
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-003
**Description:** CRUD endpoints for QUESTION + OPTION (Admin-only via Guard). Write-time validation: non-empty text, ≥2 options, exactly one `is_correct` (BR-007 — MCQ only). Edit/delete: not-found on bad id; **block deletion when the question belongs to an Exam already assigned to ≥1 batch (BR-009)** — application-layer check per ERD note. **DoD:** US-002 and US-003 acceptance scenarios pass, including the in-use-deletion block.

### TASK-006: Question editor UI
**Story:** US-002, US-003
**Type:** Frontend
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-005
**Description:** Admin question list + create/edit/delete editor with inline validation feedback (missing correct option, <2 options, empty text). Surface the BR-009 in-use error clearly when deletion is blocked. **DoD:** Admin can author and manage questions; validation errors render per AC.

### TASK-007: Exam grouping API
**Story:** US-004
**Type:** Backend
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-005
**Description:** Create/edit EXAM, attach/remove QUESTION via EXAM_QUESTION (ordered by `order_index`). Recompute `is_assignable` = (question count ≥ 1) on every change (BR-006); a zero-question Exam saves as a non-assignable draft. Reject duplicate Exam name (UNIQUE, AC US-004). **DoD:** US-004 acceptance scenarios pass, including draft/assignable transitions and duplicate-name rejection.

### TASK-008: Exam builder UI
**Story:** US-004
**Type:** Frontend
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-007
**Description:** Admin Exam builder: create a named Exam, add/remove questions, show draft vs assignable state, surface duplicate-name error. **DoD:** Admin can compose an assignable Exam; non-assignable drafts are visibly marked.

### TASK-009: Host provisioning API
**Story:** US-005
**Type:** Backend
**Assigned to:** D2 (Host & Admin Console)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-003
**Description:** Admin-only endpoint to create a HOST (organization_name, contact_email): generate a random credential, hash it (BR-001), persist, and return the plaintext **once** in the creation response only — never re-served (AC: reload shows no plaintext, only a reset action). Reject duplicate contact_email (UNIQUE) and missing organization name. **DoD:** US-005 acceptance scenarios pass, including show-once and duplicate-email rejection.

### TASK-010: Admin Host management UI
**Story:** US-005
**Type:** Frontend
**Assigned to:** D2 (Host & Admin Console)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-009
**Description:** Admin Host management screen: create-Host form, one-time credential reveal (copyable, with a clear "won't be shown again" notice), and a host detail view exposing only a "reset credential" action thereafter. **DoD:** Admin can create a Host and capture its credential exactly once.

### TASK-011: Host login + host dashboard shell
**Story:** US-006
**Type:** Backend + Frontend
**Assigned to:** D2 (Host & Admin Console)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-003
**Description:** Host login (email + credential) issuing a JWT with `role=HOST` and `hostId`; reject deactivated hosts even with correct credentials (`is_active=false`); generic invalid-login message on wrong credential. Build the org-scoped Host dashboard shell (landing after login) and verify that any direct-URL access to another Host's resource returns not-found/forbidden via the base repo (BR-005). **DoD:** US-006 acceptance scenarios pass, including deactivated-host block and the cross-host direct-URL rejection.

### TASK-012: Admin Host activity overview (API + UI)
**Story:** US-015
**Type:** Backend + Frontend
**Assigned to:** D2 (Host & Admin Console)
**Effort:** M
**Sprint:** 2
**Depends on:** TASK-009, TASK-016
**Description:** Admin-only list of all Hosts with organization name, student count, and latest-batch exam-assignment status; `ILIKE` name search (tech-stack.md — no search infra); hosts with zero students show "no import yet"; deactivated hosts remain visible with a "deactivated" status (not hidden). **DoD:** all US-015 acceptance scenarios pass.

### TASK-013: Roster upload + Excel parse API
**Story:** US-007
**Type:** Backend
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-003
**Description:** Host-only `POST /host/imports` accepting a `.xlsx` upload, parsed in-process with `exceljs` (ADR-004 — synchronous, no queue). Reject non-`.xlsx`/corrupted files (format error, no accounts created), empty files (header only / zero data rows), and oversized files **before parsing** (platform-configured max roster size). Create the IMPORT_BATCH row scoped to `hostId` from JWT (base repo, BR-005). **DoD:** US-007 acceptance scenarios pass, including all four rejection paths.

### TASK-014: Per-row validation + student account generation
**Story:** US-008
**Type:** Backend
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-013
**Description:** Validate each parsed row: required fields present; identifier unique within the Host across all batches (BR-004) — duplicates flagged per-row, never overwritten. For valid rows only, create STUDENT accounts: derive `username = {host_slug}-{identifier_or_email_local_part}` with numeric suffix on collision (FLAG-TECHLEAD-001), generate a random ≥8-char credential (BR-002), store its bcrypt hash + the transient `credential_plaintext_pending`, and link to the batch. Return `{batchId, createdCount, errors:[{row, reason}]}`; batch status VALIDATED (all valid) or PARTIAL (mixed); zero accounts when all rows invalid. **DoD:** US-008 acceptance scenarios pass (mixed/all-valid/all-invalid/cross-batch-duplicate).

### TASK-015: Roster import UI + per-row validation report
**Story:** US-007, US-008
**Type:** Frontend
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-014
**Description:** Host roster import screen: file picker with client-side type/size hints, upload progress, and a validation report listing each invalid row with its row number + reason while confirming the created-count for valid rows; primary CTA to proceed to Exam assignment. **DoD:** Host can upload a roster and read a clear per-row outcome.

### TASK-016: Exam assignment to batch API
**Story:** US-009
**Type:** Backend
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-014, TASK-007
**Description:** Host-only `POST /host/imports/{batchId}/assign {examId}`: only Exams with `is_assignable=true` are selectable (BR-006); link every student in the batch to that Exam (set batch `exam_id`); support resume — a batch left unassigned (e.g., session expired) can be completed later; empty state when no assignable Exam exists. All access host-scoped (BR-005). **DoD:** US-009 acceptance scenarios pass (assign / non-assignable excluded / none-available / resume).

### TASK-017: Credential export generation + download API
**Story:** US-010
**Type:** Backend
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-016
**Description:** On assignment, generate the credentials `.xlsx` with `exceljs` (full name, username, generated credential, Exam name per student), persist it as a `bytea` blob on CREDENTIAL_EXPORT (with denormalized `host_id`), and **null every consumed `credential_plaintext_pending` in the same transaction** (BR-001) — plaintext never reconstructed afterward. `GET /host/exports/{exportId}` streams the stored blob only after `export.host_id == jwt.host_id` (BR-008); block download before assignment completes; allow idempotent re-download. **DoD:** US-010 acceptance scenarios pass, including the unauthorized-download 403 and pre-assignment block.

### TASK-018: Exam assignment + export/download UI
**Story:** US-009, US-010
**Type:** Frontend
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-017
**Description:** Host UI to pick an assignable Exam for the batch (assignable-only list, empty state), confirm assignment, then download the generated credentials file; re-download remains available; clear messaging when assignment must precede download. **DoD:** Host completes assign→export→download from one screen.

### TASK-019: Student login + assigned-exam resolution
**Story:** US-011
**Type:** Backend
**Assigned to:** D4 (Student Exam Experience & QA)
**Effort:** S
**Sprint:** 1
**Depends on:** TASK-003, TASK-014
**Description:** Student login (username + credential) issuing a JWT with `role=STUDENT` and `hostId`; resolve the assigned Exam via the student's batch. Return states: exam-entry (assigned, not submitted), "no exam assigned yet" (batch unassigned), or redirect to the score screen if the one attempt is already submitted (BR-003). Generic invalid-login on wrong credential. **DoD:** US-011 acceptance scenarios pass (all four login states).

### TASK-020: Exam-taking API (load, answer, resume)
**Story:** US-012
**Type:** Backend
**Assigned to:** D4 (Student Exam Experience & QA)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-019, TASK-007
**Description:** `GET /student/exam` lazily creates an EXAM_ATTEMPT on first entry and returns the ordered questions + current attempt state; `PUT /student/attempts/{id}/answers` upserts a single answer per question (overwrite-on-change), unanswered = no row; resume restores in-progress answers after re-login. Enforce `ANSWER(attempt_id, question_id)` uniqueness. **DoD:** US-012 acceptance scenarios pass (answer/change/leave-blank/resume).

### TASK-021: Submit + scoring API
**Story:** US-013, US-014
**Type:** Backend
**Assigned to:** D4 (Student Exam Experience & QA)
**Effort:** M
**Sprint:** 1
**Depends on:** TASK-020
**Description:** `POST /student/attempts/{id}/submit`: enforce single submission (BR-003) via the `EXAM_ATTEMPT.student_id` unique attempt + an idempotency check — a second/replayed submit returns 409 and changes nothing. On first submit, score synchronously against `OPTION.is_correct` (BR-007, MCQ only; unanswered = incorrect), persist `submitted_at` + `score`, and return number-correct + percentage. Re-views return the same stored score (no recompute). **DoD:** US-013 + US-014 acceptance scenarios pass (single submit, second-submit reject, partial submit, deterministic score, stable re-view).

### TASK-022: Student exam-taking UI (full flow)
**Story:** US-011, US-012, US-013, US-014
**Type:** Frontend
**Assigned to:** D4 (Student Exam Experience & QA)
**Effort:** L
**Sprint:** 1
**Depends on:** TASK-021
**Description:** Student web flow end-to-end: login screen, "no exam assigned" state, question navigation with answer capture (change before submit, leave blank allowed), resume-on-reentry, a submit confirmation prompt listing the unanswered count, and the immediate score/result screen (also shown on later logins). **DoD:** a Student completes login→answer→submit→score with all US-011…US-014 AC satisfied.

### TASK-023: Cross-tenant isolation test suite
**Story:** Cross-cutting (BR-005, BR-008)
**Type:** Testing
**Assigned to:** D2 (Host & Admin Console)
**Effort:** M
**Sprint:** 2
**Depends on:** TASK-017, TASK-011
**Description:** The explicit mitigation for ADR-003's #1 residual risk. Integration tests proving Host A cannot read or download Host B's students, import batches, exam assignments, or credential export by id (expect not-found/forbidden), and that no host-scoped repository path can be reached without a JWT-sourced `hostId`. **DoD:** suite is green and fails loudly if any host-scoped query drops its filter.

### TASK-024: End-to-end happy-path test
**Story:** Cross-cutting
**Type:** Testing
**Assigned to:** D3 (Roster Import & Credential Export)
**Effort:** M
**Sprint:** 2
**Depends on:** TASK-022, TASK-017
**Description:** One automated E2E covering the whole MVP loop: Admin login → create questions → build assignable Exam → create Host → Host login → upload roster → assign Exam → download credentials → Student login (using exported credentials) → answer → submit → see score. **DoD:** the full chain passes against a freshly migrated DB.

### TASK-025: Unit tests — scoring, validation, auth (≥80%)
**Story:** Cross-cutting
**Type:** Testing
**Assigned to:** D4 (Student Exam Experience & QA)
**Effort:** M
**Sprint:** 2
**Depends on:** TASK-021, TASK-014
**Description:** Unit coverage on the correctness-critical services to hit the senior qa-standard (≥80% on core): scoring determinism (BR-007), roster row validation + BR-004 uniqueness, username derivation/collision, credential generation strength (BR-002), and auth hash/JWT/Guard. **DoD:** coverage report ≥80% on targeted services; edge cases (all-unanswered, all-correct, duplicate identifier, collision suffix) asserted.

### TASK-026: Pilot deployment (PaaS)
**Story:** Cross-cutting
**Type:** DevOps
**Assigned to:** D1 (Platform & Admin Content)
**Effort:** M
**Sprint:** 2
**Depends on:** TASK-022, TASK-017
**Description:** Deploy the single combined Pilot environment per architecture.md: one API container, one Web container, one managed Postgres, TLS terminated at the platform edge. Run `prisma migrate deploy`; configure all secrets via environment only (BR-010); smoke-test the deployed E2E loop. **DoD:** pilot URL serves the full flow over HTTPS with no committed secrets.

### TASK-027: PR descriptions, README & DoD checklist
**Story:** Cross-cutting
**Type:** Documentation
**Assigned to:** D2 (Host & Admin Console)
**Effort:** S
**Sprint:** 2
**Depends on:** None
**Description:** Finalize per-service README (run/setup/env), complete `.env.example` for api + web (BR-010), and a per-PR description template embedding the Definition of Done checklist (AC pass, host-scoping via base repo, no plaintext leak, peer-reviewed, no hardcoded secrets). **DoD:** a new contributor can clone, configure, and run from the docs alone.

---

## Sprint 3 — Post-demo hardening (production-readiness)

> Runs immediately after the demo gate (end of Sprint 2). Each task enables a deferral from ADR-005 §Decision; all are **additive** because the pre-demo slice was built production-correct (outbox-ready, RLS-ready repo scoping, refresh-shaped token port). After Sprint 3, development continues on the full `aptis-lms` 111-FR roadmap.

### TASK-028: Add PostgreSQL Row-Level Security policies
**Story:** Hardening (BR-005 defense-in-depth)
**Type:** Database
**Assigned to:** D2 (Tenancy)
**Effort:** M
**Sprint:** 3
**Depends on:** TASK-017, TASK-023
**Description:** Add Postgres RLS policies on every Host/Student-scoped table (`STUDENT`, `IMPORT_BATCH`, `CREDENTIAL_EXPORT`, `EXAM_ATTEMPT`, `ANSWER`) atop the existing repository-layer scoping, with transaction-local tenant context set per request (never leaked across pooled connections, per `aptis-be/RULE.md`). Keep the cross-tenant tests (TASK-023) green. **DoD:** a query missing tenant context is rejected by the DB, not just the repository.

### TASK-029: Add refresh-token rotation to the iam token port
**Story:** Hardening (auth baseline per RULE.md)
**Type:** Backend
**Assigned to:** D1 (Platform & IAM)
**Effort:** M
**Sprint:** 3
**Depends on:** TASK-003
**Description:** Implement access ≤15 min + opaque refresh tokens that rotate on use and are stored only as hashes (single-flight refresh), via the iam token port that was pre-shaped in TASK-003 — no call-site changes. **DoD:** refresh rotation works for all three roles; reused/invalidated refresh tokens are rejected; access-token lifetime ≤15 min.

### TASK-030: Migrate scoring + Excel export to apps/worker (BullMQ)
**Story:** Hardening (async per RULE.md)
**Type:** Backend
**Assigned to:** D4 (scoring) + D3 (export)
**Effort:** M
**Sprint:** 3
**Depends on:** TASK-021, TASK-017
**Description:** Move synchronous scoring and credential-export generation into `apps/worker` BullMQ processors that consume the outbox events already written by the api write path (no change to the api write path). Processors are idempotent, concurrency-bounded, and safe under at-least-once delivery, with dead-letter handling. **DoD:** scoring + export run in worker; api returns immediately after committing state + outbox; duplicate delivery is safe.
