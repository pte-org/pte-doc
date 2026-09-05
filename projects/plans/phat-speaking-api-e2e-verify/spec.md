# Spec: Speaking Screens ↔ pte-api End-to-End Verification

**Date:** 2026-08-25
**Status:** Draft

---

## Problem Statement

`pte-app`'s Speaking screens (starting with Read Aloud) are already fully wired in code to call `pte-api`'s real endpoints, but this has never actually been run against a live backend — there is no seed data, no documented bootstrap path, and no repeatable way to get `pte-api` from an empty local stack into a state pte-app can test against. The developer needs real confidence, not just a code review, that the chain (login → session → task fetch → recording → media upload → answer submission → DB row) genuinely works.

---

## User Stories

<!-- P1 = MVP (must ship), P2 = nice-to-have, P3 = future/out-of-scope -->

- **[P1]** As the developer, I want a repeatable, idempotent seed script that creates one tenant, one HOST_ADMIN, one STUDENT, one published `READ_ALOUD` question/session, opened and with the student enrolled, so that I can get a testable backend with a single command instead of manually replaying ~11 API calls every time the local stack resets.
  Accepted when: running the seed script against either a clean stack or one it has already seeded always ends with exactly one usable tenant/student/session/question — no duplicate-key errors, no duplicate rows, on any number of re-runs.

- **[P1]** As the developer, I want to log into `pte-app` with the seeded STUDENT account through the real `LoginPage` and complete a Read Aloud task, so that I can confirm the entire real chain works end-to-end against a live backend, not just that the code compiles.
  Accepted when: after a real login (`POST /api/iam/auth/login`), resolving the seeded session (`POST /api/exam-delivery/attempts`), seeing the seeded question's real `promptText` on screen, recording, and letting the app's existing auto-upload flow run — a `MediaObject` row with status `UPLOADED` exists for the recording, and an `attempt_answers` row exists referencing it.

- **[P2]** As the developer, I want `pte-app`'s API base URL to be switchable to `http://localhost:8080` (or the Android-emulator equivalent) without a throwaway code edit, so this verification pass — and future ones — doesn't require hand-editing and reverting a hardcoded URL.

- **[P3]** _(out of scope — noted for future)_ Verifying the other 5 Speaking screens (Repeat Sentence, Describe Image, Personal Introduction, Answer Short Question, Respond to a Situation) and their media-prompt-upload paths.

- **[P3]** _(out of scope — noted for future)_ Fixing the server-side gap where a submitted answer's media `publicId` is never checked against a real `UPLOADED` `MediaObject` owned by the submitting student.

---

## Functional Requirements

1. FR-01: A standalone external orchestration script (`pte-api/scripts/seed-e2e.ps1`, PowerShell + `Invoke-RestMethod` — NOT a Spring `CommandLineRunner`; research confirmed `ReadingTaskSeedRunner`'s in-process pattern is structurally single-service-scoped and cannot span the 4 separately-deployed services this needs) calls only the gateway's public REST API (`http://localhost:8080/api/...`) in sequence to create: one tenant (admin), one `HOST_ADMIN` + one `STUDENT` user (iam), one `READ_ALOUD` question + blueprint + published snapshot (authoring), and a scheduling session with that snapshot — composition set, opened, seeded student enrolled.
2. FR-02: The script is idempotent via get-or-create per step (pre-check GET or catch a 409-conflict response, skip creation if the resource already exists by its natural key) — safe to run any number of times against the same running stack without erroring or creating duplicates.
3. FR-03: The one step the script cannot perform via API (bootstrapping the very first `PLATFORM_ADMIN` account — `pte-api` has no self-registration endpoint) is either included in the script as a direct `psql`/DB call, or documented as an exact copy-pasteable SQL statement the developer runs once manually, including how to generate the required BCrypt password hash.
4. FR-04: `pte-app`'s `AppConfig.gatewayBaseUrl` (`lib/core/config/app_config.dart:10`) is corrected from its current value `http://localhost:8081` (the raw `iam` service port — bypasses the gateway entirely, would not route `/api/{service}/**` prefixes at all) to `http://localhost:8080` (the actual gateway, confirmed via `pte-api`'s `docker-compose.services.yml`). A plain hardcoded-constant edit is consistent with this file's own documented intent ("swap for compile-time env value... out of scope for Milestone 1").
5. FR-05: A manual, developer-executed verification pass confirms: real login via `LoginPage`, real session resolution via `SessionEntryPage`, the Read Aloud screen showing the seeded question's actual `promptText` (not fixture text), a completed recording auto-uploading through the existing `MediaUploadCoordinator` pipeline, and a resulting `attempt_answers` DB row.

---

## Non-Functional Requirements

<!-- Use numbers, not adjectives. "p95 latency < 500ms" not "fast" -->

- Performance: not a concern for this manual, one-time verification pass.
- Security: the seed script must be profile-gated exactly like `ReadingTaskSeedRunner` (never active under the default/prod profile) — this spec must not weaken that existing convention.
- Availability: N/A (local dev-only verification).

---

## Success Criteria

<!-- Measurable outcomes. Each must be independently verifiable. -->

- [ ] Seed script run against a clean `docker compose` stack creates exactly 1 tenant, 1 host admin, 1 student, 1 published `READ_ALOUD` question/snapshot, 1 opened session with the student enrolled — verifiable via direct DB query or the corresponding list endpoints.
- [ ] Re-running the seed script against an already-seeded database completes with no errors and no new/duplicate rows.
- [ ] `pte-app` successfully authenticates as the seeded STUDENT via a real `POST /api/iam/auth/login` call (not a mocked or manually injected token).
- [ ] `pte-app` successfully starts a real attempt against the seeded session (`POST /api/exam-delivery/attempts` returns a `READ_ALOUD` task, not an error).
- [ ] The Read Aloud screen renders the seeded question's real `promptText` from the server response.
- [ ] After recording and the app's existing auto-submit flow completes, a `MediaObject` row exists with status `UPLOADED`, and a corresponding `attempt_answers` row exists referencing it — confirmed via direct DB query.

---

## Out of Scope

- Verifying Repeat Sentence, Describe Image, Personal Introduction, Answer Short Question, or Respond to a Situation (and their media-prompt-upload paths) — a follow-up round once Read Aloud is proven end-to-end.
- Fixing the server-side media-ownership-validation gap.
- Fixing `pte-web/docs/FE-08-flutter-handoff.md`'s stale, incorrect API contract documentation.
- Real (non-stub) speech-scoring vendor integration — this spec only requires the answer to be saved to the database, not scored.

---

## Assumptions

- Docker and `docker compose` are available and working on the developer's machine, and `docker compose -f docker-compose.yml -f docker-compose.services.yml up --build` brings up a usable full stack behind the gateway at `localhost:8080`.
- `pte-api`'s current schema (`ddl-auto=update`, no Flyway) matches the entity definitions read during this brainstorm's scouting pass — not independently re-verified against live migrations.
- The developer can generate a BCrypt hash locally (e.g. via `htpasswd` from Git Bash's Apache tools, or any bcrypt CLI/site) for the one manual bootstrap insert.

---

## Resolved (were [NEEDS CLARIFICATION] during brainstorm)

- **Idempotency mechanism:** research (2 parallel `/ck:plan` researchers) confirmed the seed script must be an external orchestration script hitting only the gateway's public REST API — NOT an in-process Spring `CommandLineRunner` like `ReadingTaskSeedRunner`, since that pattern is structurally scoped to one service's own JVM/repositories and cannot reach across the 4 separately-deployed services (admin/iam/authoring/scheduling) this flow spans. Idempotency is get-or-create per HTTP call (pre-check GET, or catch a 409-conflict and continue) using each resource's natural key — `users.email` is globally unique (`iam`'s `User.java:40-41`) and `tenants.name` is unique (`admin`'s `Tenant.java:27-28`), so fixed sentinel values for these (e.g. a known tenant name, known host/student emails) make re-runs safe. Written as PowerShell (`Invoke-RestMethod`) rather than Python/Node/bash+jq — matches the developer's primary shell, avoids introducing a new runtime dependency into a Java-only backend repo, and `Invoke-RestMethod` parses JSON natively.
- **`ApiClient` base URL:** does NOT already support environment-based configuration — `AppConfig.gatewayBaseUrl` (`lib/core/config/app_config.dart:10`) is a plain hardcoded `static const String`, currently `http://localhost:8081` (wrong — the raw `iam` port, not the gateway). See FR-04 above for the required fix.
