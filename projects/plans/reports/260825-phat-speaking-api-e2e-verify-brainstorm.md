# Brainstorm: Speaking screens ↔ pte-api end-to-end verification

**Date:** 2026-08-25

## Ideas Explored

- **Premise as stated by the developer:** "wire the Speaking screens to pte-api so they can call the backend" — implied this was net-new integration work.
- **Scout finding (pte-api):** all backend pieces already exist and match a coherent contract — `POST /attempts`, `GET /attempts/{id}/next-task`, `POST /attempts/{id}/answers`, `POST /attempts/{id}/submit` (exam-delivery), plus a presigned-upload media flow (`POST /objects` → PUT → `POST /objects/{id}/complete`). `READ_ALOUD` and the other Speaking task types are first-class in `PteTaskType`.
- **Scout finding (pte-app):** `ReadAloudScreen` and all 5 other Speaking screens are already fully wired into `TaskTypeDispatcher`'s real production path (`app.dart` → `StudentExamGate` → real `AttemptInProgress`), driven by a real `TaskView`, using the shared `AutoRecordCubit` → `MediaUploadCoordinator` → `AnswerOutboxDao`/`SyncEngine` pipeline that calls the real endpoints above. Every `plans/phat-speaking-*-ui/plan.md` confirms dispatcher wiring was completed as part of that screen's own plan.
- **Conclusion: the original premise was false.** No FE↔API wiring work remains to be written — it was already done, screen by screen, across several earlier plans.
- **Re-scoped direction:** the developer has never actually run pte-app against a live pte-api and confirmed the calls succeed — code being wired doesn't guarantee it works (auth, base URL, contract drift, media upload flow are all unverified in practice). Redirected the brainstorm toward **end-to-end integration verification**, not new wiring code.
- **Backend runnability (pte-api scout):** `docker compose -f docker-compose.yml -f docker-compose.services.yml up --build` brings up the full stack behind a single gateway (`localhost:8080`). No seed data and no self-registration endpoint exist — the very first account must be inserted via one manual SQL bootstrap (a `PLATFORM_ADMIN` user + BCrypt password hash), after which everything else (tenant onboarding, host/student creation, authoring, scheduling, session composition/open/enrollment) is normal REST calls.
- **Seed strategy options considered:**
  - Manual curl/Postman sequence each time — zero new code, but ~10 sequential calls to redo on every reset.
  - A profile-gated `CommandLineRunner` seed script (pattern already established by `services/authoring/.../seed/ReadingTaskSeedRunner.java`) extended to also create the tenant/host/student/session/enrollment, not just questions — chosen direction, since verification will likely need several re-runs while debugging.
- **Verification scope options considered:** all 6 Speaking screens at once, vs. Read Aloud only first (simplest — no media-prompt upload needed) to validate the gateway/auth/contract chain before spending more effort on the media-upload-heavy types. Read Aloud first was chosen.
- **Side finding, not in scope:** `pte-web/docs/FE-08-flutter-handoff.md` documents a stale/incorrect API contract (`/api/v1/auth/...`) left over from an earlier "Aptis"-named iteration before the microservice rewrite — does not match the current gateway routes (`/api/iam/auth/...`). Flagged to the developer but not addressed here.

## User's Direction

Verify, end-to-end and for real, that the already-wired Read Aloud screen in `pte-app` can successfully talk to a locally-running `pte-api`: real login through the app's own `LoginPage` (not a token injected around it), a real seeded STUDENT account and session with a `READ_ALOUD` question, a real attempt started, task fetched, recording submitted through the real media-upload pipeline, and an answer row landing in the database. The seed data must be creatable via a re-runnable (idempotent) script so the developer isn't stuck re-typing ~10 API calls every time the local stack is reset during debugging.

## Open Questions

- Exact idempotency mechanism for the seed script (check-by-email/check-by-name before insert vs. some other dedupe key) — left for `/ck:plan` to design against the actual entity constraints.
- Whether the seed script should also cover the other 5 Speaking task types now (setting up their media-upload prerequisites) or stay Read-Aloud-only until this first round is proven out — leaning toward Read-Aloud-only per the narrowed scope, but not explicitly locked.
- Whether `pte-app`'s `ApiClient` base URL is already configurable per-environment (dev/local vs. prod) or hardcoded — not scouted this round, `/ck:plan` should confirm before assuming a `--dart-define` or config file exists.
- Whether the known media-ownership-validation gap (server never checks a submitted answer's media `publicId` is `UPLOADED` and owned by the submitting student) matters for this verification pass, or is purely a separate follow-up — treated as out of scope here.

## Risks

- **Bootstrap fragility:** the one manual SQL insert (BCrypt hash generation, correct snake_case columns) is easy to get wrong and has no API-level fallback if it fails — worth double-checking column/constraint names against the actual current entity definitions (not just this scout's read) before relying on it in a plan.
- **Session timing constraints:** `scheduling`'s `opensAt` must be strictly in the future (`@Future` validation) and the session must be explicitly `open`ed and the student explicitly enrolled, or `exam-delivery`'s entitlement check rejects the attempt regardless of timing — three separate, easy-to-forget steps that a seed script must get right in the correct order.
- **Contract drift risk:** this scout read controllers/DTOs directly (the most reliable source), but actually running the flow could still surface real mismatches (e.g. field naming, validation nuances) that static reading can't catch — this is precisely why the developer wants a real run, not another code review.
