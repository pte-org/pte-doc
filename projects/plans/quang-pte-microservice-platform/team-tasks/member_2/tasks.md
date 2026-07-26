# Member 2 — Flutter: Student Exam Runner

*[Bản tiếng Việt](tasks.vi.md)*

## Open decision — resolve before writing app code

`pte-app/` today is a pre-pivot scaffold (`aptis_app`, one commit, targets a different backend). Its `lib/core/` layer (Dio HTTP client + interceptors, Drift-based offline answer outbox, monotonic timer service, background sync engine) is architecturally generic — not tied to Aptis's domain — and may be worth reusing wholesale for `pte-api`'s exam-delivery flow, which needs exactly this shape (offline-resilient, server-authoritative, answers never lost). Its `lib/features/*` (word-matching, grammar MCQ, listening, reading, speaking) are Aptis-specific task types and do NOT match PTE's Milestone-1 task types (`MC_READING_SINGLE`, `READ_ALOUD`, `WRITE_ESSAY`) or `pte-api`'s contract.

**Before starting: confirm with the team lead whether to (a) keep `core/` and rewrite `features/`, or (b) start fresh.** Don't assume — this was an open question the team lead hadn't answered yet at handoff time. If reusing `core/`, read `pte-app/README.md` in full first (it documents the offline-outbox architecture in detail) and update `AppConfig.apiBaseUrl` to point at the gateway (`http://localhost:8080/api` in dev), not `api.aptis.example.com`.

## Contract source of truth

There is no generated OpenAPI spec. Read the actual controller + DTO files per service:
- Auth: `pte-api/services/iam/src/main/java/com/pte/iam/controller/*` — login, refresh, JWKS.
- Attempt flow: `pte-api/services/exam-delivery/src/main/java/com/pte/examdelivery/controller/{AttemptController,TimerController}.java` + their `dto/request`/`dto/response`.
- Media upload: `pte-api/services/media/src/main/java/com/pte/media/controller/MediaController.java` (presigned PUT flow for Read Aloud audio).
- Reports: `pte-api/services/reporting/src/main/java/com/pte/reporting/controller/ReportController.java`.
- All requests route through the gateway (`gateway/src/main/resources/application.yml` lists every service's path prefix, e.g. `/api/exam-delivery/**`).

## Task 1 — Auth

- Login screen → `iam`'s login endpoint → store access+refresh token (never in plain SharedPreferences if avoidable; if reusing `core/network/token_store.dart`, note its current `InMemoryTokenStore` is explicitly marked "NOT production-ready" — fix that).
- Transparent 401 refresh (if reusing `core/`, `token_refresh_interceptor.dart` already has this pattern — verify it still works against iam's actual refresh contract).
- JWT carries `tenant_id` + `roles` claims — decode client-side only for UI branching (student vs host), never trust it for anything security-relevant (server always re-validates).

## Task 2 — Start attempt

- Call exam-delivery's start-attempt endpoint with a `sessionPublicId` (student needs to get this from somewhere — coordinate with Member 3 on whether the student sees a session list, or the host shares a session ID/link for Milestone 1's scope).
- Handle the "already attempted" case (resume in-progress attempt vs. reject a second attempt) — the backend enforces this via a DB unique constraint; the app needs a sane UI response, not a raw 409.

## Task 3 — Task runner UI (3 types)

- **`MC_READING_SINGLE`**: render prompt + options, single-select, submit `orderIndex` as the answer payload (decimal string, e.g. `"2"` — see `SubmitAnswerRequest`'s javadoc for the exact per-task-type payload contract).
- **`READ_ALOUD`**: record audio (the existing `record` package is already a pte-app dependency), upload via media's presigned-PUT flow (`POST /media/objects` → PUT to the returned URL → `POST /media/objects/{id}/complete`), then submit the returned `MediaObject.publicId` as the answer payload — **not raw audio bytes** (ADR-003: binary never flows through the transactional API tier).
- **`WRITE_ESSAY`**: text editor, word count against the pinned item's `minWordCount`/`maxWordCount`, submit raw text as payload.

## Task 4 — Server-authoritative timer

- Poll or subscribe to exam-delivery's timer-state endpoint for `prepDeadline`/`responseDeadline`. The client timer is UX only — never trust it for enforcement; the server auto-expires/auto-submits on its own when the client calls `getNextTask`/`submitAnswer` past the window.
- Auto-advance the UI when the server reports the task as expired (don't just freeze — call the next-task endpoint and follow what it returns).

## Task 5 — Submit & complete

- Submit-answer and submit-attempt calls. If reusing `core/sync` (the offline outbox + `SyncEngine`), route answer submission through the Drift outbox so a killed app / lost connection mid-exam doesn't lose an answer — this is the single most important reliability property for this screen (exam-delivery's whole design exists to protect this).
- Completion screen → poll `reporting` for the published report; before publish, show a "waiting for host to publish" state, not an error.

## Task 6 — Result / report screen

- Render the 10–90 scaled scores per skill, "insufficient data" states clearly (not blank/broken-looking — Milestone 1 will show insufficient data for every skill except Reading until Member 4 wires a real AI vendor).

## Deliverable

- A student can log in, take a full attempt across all 3 task types, survive an app kill mid-exam without losing an answer (if the offline-outbox path is built), and see their report once published.
- `flutter analyze` and `flutter test` clean (per `pte-app/CLAUDE.md` critical rules — no hardcoded strings/colors, dispose all controllers, mounted-check after await, BLoC events as sealed classes).
