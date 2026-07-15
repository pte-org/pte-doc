# MVP Slice Mapping — aptis-mvp inside the production aptis-lms repos

> Companion to **ADR-005**. Maps the 15 MVP stories / 11 entities onto the real
> `aptis-be` bounded contexts and `aptis-web` feature structure, fixes version drift,
> and registers every deferral so nothing silently ships past the pilot.

## 1. Bounded contexts in scope (apps/api only)

| Context (`libs/modules/<ctx>`) | In-scope MVP use cases | MVP entities owned | Deferred (full-system, NOT in MVP) |
|---|---|---|---|
| **iam** | Admin/Host/Student login; JWT issue/verify; RBAC Guard; credential hash (BR-001) + random gen (BR-002); tenant-scoped base repository | ADMIN, (account/credential side of HOST & STUDENT) | refresh-token rotation, password reset, impersonation, vendor roles |
| **tenancy** | Host provisioning by Admin; host = tenant; `host_id` scoping (BR-005); Admin Host overview (US-015) | HOST | licensing, seats, multi-staff sub-roles, full audit |
| **question-bank** | Question + Option CRUD; MCQ validation (≥2 opts, 1 correct, BR-007); in-use delete block (BR-009) | QUESTION, OPTION | item analysis, media questions, question import |
| **exam-operations** | Group questions into Exam; `is_assignable` (BR-006); duplicate-name; assign Exam to batch (US-009); roster import + per-row validation (US-007/008, BR-004) + student provisioning; credential export (US-010, BR-008) | EXAM, EXAM_QUESTION, IMPORT_BATCH, CREDENTIAL_EXPORT, (provisioned STUDENT) | shuffle seeds, per-part config, scheduling |
| **exam-delivery** | Student attempt lifecycle; load/answer/resume (US-012); single submit (US-013, BR-003) | EXAM_ATTEMPT, ANSWER | timers, Listening/Reading/Writing/Speaking, integrity/violations, media durability |
| **scoring** | Synchronous MCQ auto-score on submit (US-014, BR-007); deterministic, stable on re-view | (score on EXAM_ATTEMPT) | AI/subjective scoring, teacher confirmation, async worker scoring |

> Roster-import + credential-export sit in **exam-operations** (they are about provisioning a batch *for an exam*), but **account creation + credential hashing** is an `iam` application contract that exam-operations calls — never reaching into iam's repository (RULE.md cross-context rule). STUDENT is provisioned via an `iam` use case, owned (FK-wise) by `tenancy` (host) and `exam-operations` (batch).

## 2. Entity → context placement (Prisma models live with their owning context's infrastructure)

| Entity | Owning context | Notes |
|---|---|---|
| ADMIN | iam | |
| HOST | tenancy | tenant root; `host_id` is the scoping key |
| STUDENT | iam (account) / tenancy + exam-operations (FKs) | created by an iam provisioning use case; `username` derivation per FLAG-TECHLEAD-001 |
| QUESTION, OPTION | question-bank | |
| EXAM, EXAM_QUESTION | exam-operations | |
| IMPORT_BATCH, CREDENTIAL_EXPORT | exam-operations | export blob = system of record (BR-008) |
| EXAM_ATTEMPT, ANSWER | exam-delivery | score column written by scoring on submit |

## 3. Four full-stack devs → context ownership (ownership unchanged from PM plan, re-expressed)

| Dev | Owns (BE contexts + FE features) | PM tasks | Story set |
|---|---|---|---|
| **D1 — Platform + IAM + Content** | `libs/platform`, `libs/common`, `iam` (auth core, tenant-scoped base repo), `question-bank`, `exam-operations` (exam composition only); FE: Admin auth + question/exam features | T-001…008, 026 | US-001/002/003/004 |
| **D2 — Tenancy** | `tenancy` (host provisioning, host login, host overview); FE: Admin host mgmt + host dashboard | T-009…012, 023, 027 | US-005/006/015 |
| **D3 — exam-operations (roster + export)** | `exam-operations` roster-import + assignment + credential-export use cases (calls `iam` provisioning); FE: roster import + assign/export features | T-013…018, 024 | US-007/008/009/010 |
| **D4 — exam-delivery + scoring** | `exam-delivery` (attempt/answer/submit) + `scoring` (sync score); FE: student exam feature | T-019…022, 025 | US-011/012/013/014 |

> **Cross-context contract reminder (RULE.md):** contexts integrate only through public `application` contracts / `index.ts`, never by importing another context's repository. Key contracts to define Day 1: `iam.ProvisionStudentAccount`, `iam.TenantScopedRepository`, `exam-operations.ExamAssignable`, `scoring.ScoreAttempt`.

## 4. Version & dependency realignment (repo reality wins — see ADR-005)

| Item | Old MVP docs said | Repo reality (authoritative now) | Action |
|---|---|---|---|
| NestJS | 10 | **11** | use 11 |
| Node | 20 LTS | **≥22.12** | use 22 |
| Prisma | 5.x | **7.x** | use 7 |
| PostgreSQL | 15 | **17** | use 17 |
| Next.js | 14 (App Router) | **16** | use 16 — **read `node_modules/next/dist/docs/` first** (AGENTS.md: breaking changes) |
| React | (unstated) | **19** | use 19 |
| Tailwind | 3 | **4** | use 4 (`@tailwindcss/postcss`) |
| Server state (FE) | TanStack Query 5 | **not installed** | **ADD** `@tanstack/react-query` to aptis-web, or use RULE.md's server-action/API-service layer (decide Day 1) |
| Excel | exceljs | **not installed** | **ADD** `exceljs` to aptis-be |
| Redis/BullMQ | "None" | **present** (`ioredis`, `bullmq`) | leave installed but **unused** in MVP (sync path) |

`tech-stack.md` has been updated to these versions.

## 5. Post-demo hardening backlog (SCHEDULED — Sprint 3, immediately after the demo)

> Per operator decision (2026-06-21): the pre-demo slice ships **minimal** hardening. Every item below is
> **additive** — the slice already carries its readiness hook (outbox rows, RLS-ready repo scoping,
> refresh-shaped token port), so enabling these is new code, **not** rework. Tracked as PM TASK-028/029/030.

1. `apps/worker` + BullMQ/Redis scoring/exports → currently synchronous in `apps/api` (outbox row still written). **→ TASK-030.**
2. PostgreSQL **RLS** policies → currently repository-scoped only (RLS-ready, not yet enforced at DB).
3. **Refresh-token rotation** → MVP may be access-token-only; iam token port kept refresh-shaped.
4. Contexts not built: `licensing`, `integrity`, `analytics`, `notifications`, full `audit`.
5. `exam-delivery` real APTIS format (4 skills, audio, timers, shuffle, integrity guards) → MCQ-only.
6. `aptis-app` (Flutter) → **frozen** for MVP; revisit DC-01 ADR if/when mobile is reintroduced.
7. `/api/v1` versioning + OpenAPI + Swagger → keep per RULE.md even in MVP (cheap, already in deps).

## 6. Readiness checklist before Sprint 1 coding (TechLead gate)

- [ ] Day-1 kickoff agrees: Prisma schema (6-context placement), `iam` token + tenant-repo contracts, the 4 cross-context contracts in §3.
- [ ] `exceljs` added to aptis-be; FE server-state approach (TanStack Query vs server actions) decided.
- [ ] `aptis-app` confirmed frozen; no MVP task touches it.
- [ ] PM `task-breakdown.md` read as bounded contexts (this doc is the translation layer).
- [ ] Cross-tenant isolation test (TASK-023) confirmed mandatory given RLS deferral.
