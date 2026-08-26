# Plan: Host — Add Students to an Exam (Excel/Individual), Proctor Assignment, Exam Session UI

Status: 🟡 Not started
Date: 2026-08-26
Mode: Hard
Created by: Ninh
Target platform: `pte-api` services `iam` + `scheduling` + `pte-web` app `tenant-web`

## Overview

The Host-facing request has three parts: (1) add Students to an Exam via
Excel upload or one-by-one, (2) Host can add/edit which Proctors (giám thị
coi thi) are on an exam, (3) an Exam can have students from different
classes/cohorts (`className` as a free-text tag, per user decision below).

Investigation before planning found the real starting state is **not**
"extend an existing feature" — it's closer to "build the feature for the
first time, on top of backend primitives that already exist but were never
wired to any working UI":

- `services/scheduling` already owns `ExamSession`, `Enrollment`
  (student↔session), and `ProctorAssignment` (proctor↔session) — but each
  only has a single-item `POST`, no list, no bulk, no delete
  (`EnrollmentService.java`'s own docstring: *"Milestone 1 scope — no file
  import"*).
- `apps/tenant-web/features/examoperations/` already has a **fully built**
  Excel-upload UI (dropzone, client-side `xlsx` parsing, preview, confirm)
  — but every endpoint it calls (`/api/v1/host/**`) was never wired into
  the gateway at all. A prior plan (`ninh-tenant-host-admin`, Research
  Summary item 2) already found and deliberately excluded this exact dead
  code as "a separate, pre-existing, unrelated feature gap." This plan is
  what closes that gap.
- There is **no Student entity anywhere** — a student is just an `iam`
  `User` with `Role.STUDENT`. There is **no Class/Cohort entity** anywhere.
  There is **no Excel/CSV library in any backend service.**
- `Role.PROCTOR` already exists and `HOST_ADMIN` is already permitted to
  create one (`UserProvisioningHelper.HOST_ASSIGNABLE_ROLES` already
  includes `PROCTOR` and `STUDENT`) — this part needs no new authorization
  work, only UI + the missing list/unassign endpoints.
- **There is no Exam Session UI anywhere in `tenant-web`** (confirmed by
  grep — zero matches for "session" in any FE app). The two Host pages
  that exist today are Overview and Import Learners only. Since every part
  of this request is scoped to "an Exam," a session picker/creator is a
  hard prerequisite, not an optional nice-to-have — confirmed in scope via
  AskUserQuestion (see Decisions below).

## Decisions (gathered via AskUserQuestion before phase design)

1. **Bulk/individual add creates real login accounts** (not just enrollment
   of pre-existing accounts) — matches the already-built dead-code UX
   ("Create Accounts and Download File" → credentials spreadsheet).
2. **Student profile fields (studentCode, className, phone, dateOfBirth)
   live on `iam`'s `User`** (extend `CreateUserRequest`/`User`/
   `UserResponse`), not a separate profile entity in `scheduling` and not
   dropped entirely.
3. **"Lớp" (class) is a free-text tag** (`className` string on the user
   profile), not a reusable Cohort/Class entity. Filtering/grouping by
   class is a client-side operation on that string field.
4. **"Chỉnh sửa quyền của Giám thị" = assign/unassign a Proctor to/from a
   specific Exam Session** — completing the existing `ProctorAssignment`
   CRUD (today only has single-item `POST`), not a new granular permission
   system.
5. **Exam Session management UI is in scope** (list + create + detail),
   including the blueprint→snapshot picker needed to create one, because
   nothing in this request is usable without it.
6. **Generated passwords follow a fixed, readable structure** — 8
   characters, `XXXX-XXXX`, drawn from an unambiguous alphanumeric charset
   (excludes `0/O`, `1/l/I`) — not a fully opaque random string, and not
   derived from the student's own data (which would be guessable). Raised
   by the user after reviewing the first draft of this plan.
7. **Students who forget their password are rescued by their own Host**,
   not by a self-service email flow (no SMTP infra exists, and the earlier
   `ninh-host-account-management` plan already deliberately scoped email
   out). This reuses and widens the existing `POST /users/{publicId}/reset-password`
   endpoint (today `PLATFORM_ADMIN`-only) to also allow `HOST_ADMIN` — but
   only against `STUDENT`/`PROCTOR` targets in their own tenant, never
   against a fellow `HOST_ADMIN`/`HOST_AUTHOR` (that would be a different,
   unrequested capability — same-tenant peer account takeover). Raised by
   the user after reviewing the first draft of this plan.

## Phases

- [ ] Phase 0: `iam` — Student profile fields + bulk account creation +
      readable password format + Host-assisted Student/Proctor password
      reset
- [ ] Phase 1: `scheduling` — Enrollment CRUD completion (bulk-create, list, remove)
- [ ] Phase 2: `scheduling` — ProctorAssignment CRUD completion (list, unassign)
- [ ] Phase 3: `tenant-web` — Exam Session UI (list, create w/ blueprint→snapshot picker, detail shell)
- [ ] Phase 4: `tenant-web` — Student roster: rewire Excel import + add individual student, delete dead `/api/v1/host/**` code
- [ ] Phase 5: `tenant-web` — Proctor management UI (create Proctor, assign/unassign per session)

## Research Summary

Facts established by direct codebase inspection before writing phases
(not re-derived per-phase):

1. **`services/scheduling` domain, exact shape**:
   `ExamSession` (`domain/ExamSession.java`): `name`, `tenantId`,
   `snapshotPublicId`, `opensAt`, `closesAt`, `status`
   (SCHEDULED/OPEN/CLOSED), `composition`.
   `Enrollment` (`domain/Enrollment.java`): `session` (ManyToOne),
   `studentPublicId` (bare UUID, no cross-service join), `tenantId`; DB
   unique constraint on `(session_id, student_public_id)` is the
   concurrency guard (not check-then-act).
   `ProctorAssignment` (`domain/ProctorAssignment.java`): same shape,
   `proctorPublicId` instead, unique on `(session_id, proctor_public_id)`.
   Both `EnrollmentController` (`/sessions/{id}/enrollments`) and
   `ProctorAssignmentController` (`/sessions/{id}/proctors`) delegate to
   the SAME `EnrollmentService` class today (`enrollStudent`/
   `assignProctor` methods) — Phase 1/2 extend that one service class,
   not two.
   `SessionController` (`/sessions`) already has full `POST`/`GET`
   (single)/`GET` (list, tenant-scoped via `caller`)/`PUT .../composition`/
   `POST .../open`/`POST .../close` — **no backend changes needed for
   session list/create/get**, only the FE.
2. **`iam` role/provisioning model**: `Role.java` enum is exactly
   `PLATFORM_ADMIN, PLATFORM_AUTHOR, HOST_ADMIN, HOST_AUTHOR, PROCTOR,
   STUDENT`. `UserProvisioningHelper.HOST_ASSIGNABLE_ROLES = EnumSet.of(
   HOST_AUTHOR, PROCTOR, STUDENT)` — a `HOST_ADMIN` caller can already
   create `PROCTOR`/`STUDENT` users today via the existing `POST /users`;
   no authorization change needed anywhere in this plan for who can create
   what role. `CreateUserRequest`/`User`/`UserResponse` currently have no
   `studentCode`/`className`/`phone`/`dateOfBirth` fields — Phase 0 adds
   them as nullable/optional, profile-only (not used for auth).
3. **The dead FE code, exact inventory** (`apps/tenant-web/features/examoperations/`):
   `RosterImport.tsx` + `_RosterDropzone.tsx` + `cleanRosterFile.ts` (real,
   working `xlsx` client-side parsing — reusable as-is) call
   `packages/api-client/src/requests/host/{imports,studentImport,students}.ts`,
   which target `/api/v1/host/**` — a path prefix the gateway has **never**
   routed (`gateway/.../application.yml` only defines `/api/{service}/**`
   for `iam,admin,authoring,scheduling,exam-delivery,proctor,scoring,
   reporting,notification,media` — no `host` service, no `/v1` segment,
   anywhere). Every one of these calls 404s unroutably, confirmed by the
   prior `ninh-tenant-host-admin` plan's own Research Summary item 2 and
   re-confirmed independently this session. `components/_ExamAssignment.tsx`
   and `components/_ValidationReport.tsx` are prefixed `_` (already
   excluded from `components/index.ts` — dead, unwired) but map closely to
   real needs this plan has (choosing which session to enroll into,
   surfacing per-row import errors) — Phase 4 repurposes rather than
   recreates them where the shape still fits.
   `packages/api-client/src/types/host/student.ts`'s `HostStudentResponse`
   uses a numeric `id` and fields with no backend counterpart at all — this
   type is deleted, not patched, in Phase 4.
4. **Inter-service call convention, if ever needed**: `services/proctor`'s
   `SchedulingClient.java` + `InternalClientConfig.java` is the reference
   pattern (`RestClient` bean, `X-Internal-Service-Key` header via
   `InternalServiceAuth`, target service's own `/internal/**` path,
   `@CircuitBreaker`). **This plan does not need it** — Phase 0's bulk
   account creation and Phase 1's bulk enrollment are each called directly
   by the FE as two sequential user-facing (JWT-authenticated) requests,
   not chained via a new internal service-to-service call. This avoids
   adding brand-new `/internal/**` infrastructure to `iam` (it has none
   today) purely for this feature, and keeps each service's existing
   transaction boundary intact. Trade-off accepted explicitly: if Phase 1's
   bulk-enroll fails after Phase 0's bulk-create-accounts already
   succeeded, the created accounts are not enrolled in this session but
   still exist and are usable (re-enrollable, or usable in a different
   session) — not orphaned/broken, just requires a retry of the enroll
   step. Documented per-phase, not silently accepted.
5. **Session creation needs a snapshot, and there is a real, narrow gap
   here**: `CreateSessionRequest.snapshotPublicId` is required.
   `services/authoring`'s `BlueprintController` has `GET /blueprints`
   (list) and `POST /blueprints/{id}/publish` (returns a `SnapshotResponse`
   with the new snapshot's `publicId`, in that same response). There is
   **no `GET /snapshots` (list-all)** and `BlueprintResponse` does not
   carry back a previously-published snapshot's id. So: a blueprint that
   was published in the past (in some other flow, before this feature
   existed) has no discoverable snapshot id from this UI. Phase 3's
   "create session" flow therefore only supports the primary path — pick a
   blueprint, publish it inline (capturing the returned snapshot id),
   create the session in the same action — and explicitly does not support
   re-using an already-published blueprint's snapshot. This is a narrow,
   pre-existing gap in `authoring`, out of this plan's service boundary to
   fix (would mean adding a field + migration to `Blueprint` in a service
   this plan otherwise never touches); flagged here so it reads as a known
   limitation, not an oversight.
6. **No Flyway anywhere** — every service uses `ddl-auto: update`; no
   migration files for Phase 0/1/2's new columns/endpoints.
7. **Outbox convention (ADR-002), applies to every new write this plan
   adds, including removals**: Phase 1/2's new `DELETE` (unenroll/unassign)
   endpoints get their own outbox events, matching the "no exceptions, not
   even small ops like reactivate" precedent from `ninh-tenant-host-admin`.
8. **Delete semantics for `Enrollment`/`ProctorAssignment` are a real hard
   delete**, not a soft-status flag — deliberately different from the
   "never hard-delete Tenant/Organization" precedent in the prior plan.
   Reasoning: those are business entities with their own lifecycle;
   `Enrollment`/`ProctorAssignment` are pure join-table facts ("is X on
   this roster or not") with no independent identity worth preserving, and
   the DB unique constraint already relies on the row's absence to permit
   re-adding the same student/proctor later.
9. **`tenant-web`'s nav is per-page inline arrays, not a shared config**:
   both existing Host pages duplicate an identical `HOST_NAV` array
   (`app/(dashboard)/host/{dashboard,roster}/page.tsx`). Phase 3 hoists
   this into one shared constant when it adds the first new nav entries
   (Exams), rather than adding a third copy of the duplicated array.

## Dependencies

- `pte-api` running locally (gateway + `iam` + `scheduling` + `authoring`
  at minimum) for end-to-end verification.
- A seeded `HOST_ADMIN` (or `HOST_AUTHOR`) user + at least one `Blueprint`
  with importable questions in `authoring`, to exercise session creation.
- Phases 1–2 depend on Phase 0 only loosely (different services, no shared
  code) but should land first since Phase 4/5's FE work calls both.
  Phase 4 depends on Phase 0 + Phase 1 + Phase 3 (needs a real session to
  enroll into). Phase 5 depends on Phase 0 + Phase 2 + Phase 3.

## Risks

- **MEDIUM → mitigated (this plan's own red-team pass upgraded the
  original framing to HIGH and required a concrete fix, now in Phase 4)**:
  bulk-create-accounts and bulk-enroll are two separate FE-orchestrated
  calls, not one atomic operation (see Research Summary item 4) — a
  failure between them leaves created accounts un-enrolled. The original
  risk framing understated the consequence: since `generatedPassword` is
  write/return-once and unrecoverable afterward (not even by an admin
  reset, which only sets a NEW password), an abandoned or failed step 2
  could permanently strand real login credentials, not just "require a
  retry." Phase 4 now requires the credentials download to be offered
  immediately on step 1's success (persisted to `sessionStorage` until
  step 2 confirms), decoupled from step 2's outcome entirely.
- **LOW (scoped out, documented)**: re-using an already-published
  blueprint's snapshot when creating a session isn't supported by this
  plan (Research Summary item 5) — only "publish then immediately create"
  is. Flagged, not silently dropped.
- **LOW**: `className` is a free-text field, not a validated/reusable
  entity — two Hosts (or one Host at different times) can spell the same
  class differently ("12A1" vs "12/A1"). Accepted per the user's explicit
  choice of the simpler modeling option; not a bug to fix in this plan.
