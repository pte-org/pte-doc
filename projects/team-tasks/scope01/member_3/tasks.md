# Member 3 — Flutter: Host Mini-Console

*[Bản tiếng Việt](tasks.vi.md)*

## Coordinate with Member 2 first

Same open decision applies (reuse `pte-app/core/` vs. fresh start — see Member 2's task file, don't duplicate that discussion, just agree on the same answer). Auth (Task 1 below) should be the **same module** Member 2 builds — don't build two separate login flows. Split the work: whoever gets there first builds it, tag the other as reviewer.

## Contract source of truth

Same caveat as Member 2 — no generated OpenAPI, read the actual controllers:
- `pte-api/services/authoring/src/main/java/com/pte/authoring/controller/{QuestionController,BlueprintController,SnapshotController}.java`
- `pte-api/services/scheduling/src/main/java/com/pte/scheduling/controller/{SessionController,EnrollmentController,ProctorAssignmentController}.java`
- `pte-api/services/scoring/src/main/java/com/pte/scoring/controller/ScoringReviewController.java`
- `pte-api/services/notification/src/main/java/com/pte/notification/controller/NotificationLogController.java`
- `pte-api/services/proctor/src/main/java/com/pte/proctor/controller/{ProctorSessionController,ViolationAuditController}.java` (REST parts only — the STOMP command surface is a stretch goal, see Task 6)

## Task 1 — Auth (shared with Member 2)

- Host login → same token/refresh handling. Host JWT has `HOST_ADMIN`/`HOST_AUTHOR` roles — gate host-only screens/actions on this (server re-validates regardless, this is just UI branching).

## Task 2 — Question & content authoring

- Create question screen per task type (at minimum the 3 Milestone-1 types: `MC_READING_SINGLE` with options, `READ_ALOUD` with a reference audio/text prompt, `WRITE_ESSAY` with a prompt + word-count bounds).
- Blueprint builder: select questions into a blueprint.
- Publish snapshot: one action, makes the blueprint an immutable versioned snapshot other services can reference.
- Remember the visibility split: admin-authored content is tenant-global (`tenant_id=NULL`, host reads it read-only); host-authored content is private to their tenant. Same screen, different scope depending on caller role — don't build two separate screens for this.

## Task 3 — Session composition & enrollment

- Create a session from a published snapshot; full-mock vs. practice-subset composition (select which task types are included, matches `SessionComposition`).
- Enroll students (by lookup — Milestone 1 scope is manual single-add, no bulk import).
- Assign proctors to the session.

## Task 4 — Scoring & publish triggers

- "Score this session" action → `POST /sessions/{id}/score`. This is fire-and-forget from the UI's perspective (async — scoring happens via Kafka/RabbitMQ in the background); show a pending/in-progress state, not a blocking spinner waiting for a synchronous response that will never fully reflect completion.
- Essay review queue: list answers in `AI_SCORED_PENDING_REVIEW`, host reviews and approves via scoring's review endpoint — **this is the human-in-the-loop gate for Write Essay** (ADR-002: Pearson requires human-review-on-top-of-AI for certain task types; nothing reaches the student without this step for those types).
- "Publish" action → `POST /sessions/{id}/publish`. Once published, scores become visible to students; make this action visually distinct from "score" (it's the point of no return for visibility, host should not click it by accident).

## Task 5 — Notification & violation review

- `GET /notifications` (tenant-scoped) — simple list/audit view of what emails went out and their delivery status (`PENDING`/`SENT`/`FAILED`).
- `GET /exam-sessions/{sessionPublicId}/violations` (proctor service) — list flagged violations for a session, tenant-scoped, available to `HOST_ADMIN`/`HOST_AUTHOR`.

## Task 6 — Proctor live console (stretch goal, scope only if time allows)

The full live-proctoring surface (STOMP connect, open a `ProctorSession`, issue `FORCE_SUBMIT`/`EXTEND_TIME`, flag violations, see live broadcasts from other proctors) is real-time and non-trivial in Flutter (needs a STOMP-over-WebSocket client package, e.g. `stomp_dart_client`). Treat this as separate, lower-priority scope from the rest of the host console — a host/proctor can still function for Milestone 1's demo without live WS proctoring (the REST audit views in Task 5 cover post-hoc review). Confirm with the team lead whether this is in scope before investing time here.

## Deliverable

- A host can: author a small question bank, publish a snapshot, create a session, enroll a student, trigger scoring after the student's attempt, approve a pending essay review, publish, and see the violation/notification audit trail.
- `flutter analyze` and `flutter test` clean, same standards as Member 2 (`pte-app/CLAUDE.md`).
