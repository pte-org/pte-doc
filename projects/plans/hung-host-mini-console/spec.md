# Spec: Host Mini Console (pte-app) — Milestone 1

**Date:** 2026-07-28
**Created by:** Hung (Member 3)
**Status:** Approved for planning

---

## Problem Statement

`pte-api` already exposes most of the Milestone-1 Host workflow, while
`pte-app/dev` currently implements shared authentication and the student exam
flow only. Member 3 owns the Host-facing mini console: authoring the three
Milestone-1 PTE task types, publishing immutable content snapshots, composing
and operating sessions, enrolling students, assigning proctors, requesting
scoring, reviewing essays, publishing results, and reading operational audit
records.

The implementation must consume the real gateway contracts and extend the
existing Flutter feature-first Clean Architecture without coupling Host code to
Member 2's student BLoCs or repositories. Backend source changes are permitted
only where a required Member 3 flow has no usable contract; direct inspection
identified the pending essay-review list query as the sole confirmed missing
endpoint.

---

## User Stories

- **[P1]** As a Host user, I want to sign in through the shared authentication
  flow and enter a role-appropriate Host workspace, so that Host functions are
  separated from the student exam experience.
  Accepted when: `HOST_ADMIN` and `HOST_AUTHOR` enter the Host console after
  login; non-Host roles do not enter Host routes; backend authorization remains
  authoritative.

- **[P1]** As a Host author, I want to list accessible questions and create
  `MC_READING_SINGLE`, `READ_ALOUD`, and `WRITE_ESSAY` questions, so that I can
  prepare content for practice and full sessions.
  Accepted when: all three task types round-trip through
  `/api/authoring/questions` and task-specific validation is enforced without
  sending student-response media through authoring.

- **[P1]** As a Host user, I want shared content and my tenant's private content
  to appear in one accessible question bank, so that I can reuse platform
  content without seeing another Host's private items.
  Accepted when: the UI renders the backend-filtered result and never supplies
  a tenant override; Host-created content is sent as `PRIVATE`.

- **[P1]** As a Host author, I want to assemble a blueprint and publish it as an
  immutable snapshot, so that an exam session is pinned to a stable definition.
  Accepted when: eligible questions can be composed into a blueprint, publish
  returns a snapshot, and the UI offers no snapshot-edit operation.

- **[P1]** As a Host operator, I want to create a full or practice session and
  configure its snapshot composition, so that students receive the intended
  exam content.
  Accepted when: session creation and composition use the existing scheduling
  contracts and the UI follows backend-owned session state transitions.

- **[P1]** As a Host administrator, I want to enroll students and assign a
  proctor, so that a session has its participants before opening.
  Accepted when: `HOST_ADMIN` can look up eligible users, enroll a student, and
  assign a proctor; `HOST_AUTHOR` is not offered actions the backend forbids.

- **[P1]** As a Host administrator, I want to request scoring, review essays in
  `AI_SCORED_PENDING_REVIEW`, and publish results, so that student reports are
  released only after required human review.
  Accepted when: the score request is acknowledged, the tenant-scoped pending
  review queue is pageable, an individual review can be approved, and publish
  succeeds only when backend gates allow it.

- **[P1]** As a Host operator, I want to inspect notification and violation
  audit records, so that delivery failures and integrity events can be traced.
  Accepted when: notification logs and session violation records render their
  authoritative backend fields with loading, empty, failure, and retry states.

- **[P3]** As a Host operator, I want a live proctor console for an active
  session, so that I can see operational changes without polling.
  Accepted when: authenticated STOMP updates are tenant/session scoped and the
  dashboard recovers after reconnect. This is stretch scope and begins only
  after all P1 phases pass.

---

## Functional Requirements

1. **FR-01:** Reuse the existing `AuthBloc`, token store, refresh interceptor,
   and JWT claim decoder. Add a Host application gate and login entry without
   redesigning Member 2's authentication business logic.
2. **FR-02:** Update `ApiClient` to consume the backend's
   `{success,data,message}` envelope centrally while retaining compatibility
   with already-unwrapped/raw responses and preserving `Response<T>` metadata.
3. **FR-03:** Map `401` to authentication failure and `403` to a distinct
   insufficient-permission failure; a forbidden Host action must not log the
   user out.
4. **FR-04:** `host_console` owns only the Host shell, navigation, and
   role-aware UI gates. Business capabilities live in separate `authoring`,
   `scheduling`, `scoring_review`, and `host_audit` features.
5. **FR-05:** `authoring` lists accessible questions using
   `GET /api/authoring/questions` and supports loading, empty, failure, retry,
   and success states.
6. **FR-06:** `authoring` creates `MC_READING_SINGLE` with a nonblank title and
   prompt, at least two nonblank options, and exactly one selected correct
   option. The request sends task type `MC_READING_SINGLE` and visibility
   `PRIVATE`.
7. **FR-07:** `authoring` creates `READ_ALOUD` with the title and text prompt
   required by the current backend task mapping. Student response audio remains
   in the exam-attempt media flow and is not Host-authored prompt content.
8. **FR-08:** `authoring` creates `WRITE_ESSAY` with required prompt,
   reference-answer, minimum-word-count, and maximum-word-count fields validated
   before submission.
9. **FR-09:** Blueprint creation/list/detail and
   `POST /api/authoring/blueprints/{id}/publish` are exposed through an
   immutable-snapshot workflow; published snapshots cannot be edited by the
   Flutter client.
10. **FR-10:** `scheduling` creates/lists sessions, configures snapshot
    composition, and exposes only backend-valid open/close transitions for full
    and practice sessions.
11. **FR-11:** `scheduling` enrolls a student and assigns a proctor through the
    existing session child resources. User lookup and proctor assignment are
    restricted to `HOST_ADMIN` in the UI because IAM/backend authorization does
    not permit the equivalent Host-author workflow.
12. **FR-12:** `scoring_review` requests scoring through the scheduling
    service, then queries a pageable tenant/session-scoped essay review queue
    for `AI_SCORED_PENDING_REVIEW`.
13. **FR-13:** The scoring service adds
    `GET /api/scoring/answers/reviews?sessionPublicId={id}&status=AI_SCORED_PENDING_REVIEW&page={n}&size={n}`
    because no read endpoint for the existing review queue currently exists.
14. **FR-14:** `scoring_review` approves an individual pending essay using the
    existing answer review command and refreshes authoritative queue state after
    success; it never applies an optimistic score mutation.
15. **FR-15:** Result publication uses the existing scheduling publish command,
    is visible only to `HOST_ADMIN`, and displays backend conflict/gate failures
    without manufacturing a successful state.
16. **FR-16:** `host_audit` consumes
    `GET /api/notification/notifications` and
    `GET /api/proctor/exam-sessions/{sessionPublicId}/violations`.
17. **FR-17:** Mutations disable duplicate submission while in flight. Snapshot
    publish, score request, essay review, and result publish are never
    automatically retried.
18. **FR-18:** Every new Flutter feature follows
    `pte-app/CLAUDE.md` and `pte-app/docs/CODING_STANDARDS_APP.md`: feature-first
    `data/domain/presentation`, repository abstraction, GetIt module, sealed BLoC
    events, immutable per-case states, no hardcoded strings/colors, controller
    disposal, mounted checks, and file/build-method size limits.

---

## Non-Functional Requirements

- **Security:** Backend role and tenant checks remain authoritative. Flutter
  role checks are UI gates only. Host requests never supply a tenant override
  where the authenticated context can derive it.
- **Reliability:** User-entered form state survives network, validation, and
  server failures. Destructive or publish-like mutations are explicit and not
  automatically replayed.
- **Compatibility:** Phase 00 changes to `ApiClient` must preserve the existing
  auth, exam-attempt, sync, media-upload, and report behavior owned by Member 2.
- **Maintainability:** New code stays within established feature boundaries;
  no Host feature imports another Host feature's BLoC or repository
  implementation.
- **Performance:** Lists use lazy rendering and pageable backend queries where
  the dataset can grow. The first-slice question list uses the current
  non-pageable backend contract without inventing client pagination.
- **Quality:** Flutter unit/BLoC/widget tests follow the existing repository
  convention. `flutter analyze` and `flutter test` must exit successfully before
  a phase is marked complete. The backend has no established Java test-source
  convention, so a new backend endpoint requires compile/package plus documented
  role/tenant/status/pagination contract verification.
- **Process:** Work remains uncommitted until Hung reviews the completed
  approved slice. No push, merge, rebase, or branch switch occurs without
  explicit instruction.

---

## Success Criteria

- [ ] `HOST_ADMIN` and `HOST_AUTHOR` can enter the Host console through shared
      authentication; a non-Host role remains in the non-Host application flow.
- [ ] Flutter correctly consumes wrapped backend responses without regressing
      Member 2's existing tests and behavior.
- [ ] A Host can list accessible questions and create all three Milestone-1 task
      types with task-specific validation and media handling.
- [ ] Shared and tenant-private question visibility follows backend filtering;
      no cross-tenant content appears.
- [ ] A blueprint can be published into an immutable snapshot and used to
      compose a full or practice session.
- [ ] A `HOST_ADMIN` can enroll a student, assign a proctor, request scoring,
      review pending essays, and publish results through the gateway.
- [ ] Notification and violation audit views render authoritative records and
      operational empty/error states.
- [ ] Each completed phase has a phase file, Flutter test evidence where
      applicable, and a quality/testing state recorded in the same format as the
      existing team plans.
- [ ] `flutter analyze` and `flutter test` pass at required-scope handoff.

---

## Out of Scope

- Student exam-taking screens, timer, answer outbox, speaking response upload,
  and student report rendering owned by Member 2.
- Vendor/platform authoring and moderation workflows.
- AI-assisted question generation or AI vendor scoring implementation.
- Editing or replacing an already-published snapshot.
- Adding enrollment/proctor list endpoints before Phase 5 proves the existing
  POST responses cannot support the approved workflow.
- A broad Java unit-test retrofit across existing microservices.
- Live multi-session proctor operations before required P1 phases pass.
- Push, merge, release, or deployment automation.

---

## Assumptions

- `pte-app/dev` is the integration baseline because it contains Member 2's
  rebuilt student flow; `pte-app/main` remains an older scaffold and is not the
  source baseline for this work.
- `pte-api/main` contracts inspected on 2026-07-28 remain authoritative until a
  runtime contract check proves otherwise.
- Local Flutter gateway base URL remains `http://localhost:8080`, with every
  call site supplying a full `/api/...` path.
- Milestone 1 targets desktop with Windows as the primary Flutter platform,
  matching the existing student-flow plan.
- Hosts create `PRIVATE` questions. `SHARED` write access remains a
  platform-user capability even though Hosts can read shared questions.
- The current enrollment and proctor-assignment POST responses are sufficient
  for the first approved management workflow; additional read endpoints require
  evidence and a plan revision.
- The live STOMP backend code exists, but its runtime behavior has not been
  verified and therefore remains stretch scope.

---

## Resolved Decisions

- **Implementation strategy:** vertical slices, not one large
  `host_console` feature and not a backend-first rewrite.
- **Feature boundaries:** `host_console`, `authoring`, `scheduling`,
  `scoring_review`, and `host_audit` have separate ownership.
- **First implementation slice:** Phase 00 (API compatibility/Host shell) and
  Phase 01 (`MC_READING_SINGLE` authoring) only.
- **Response compatibility:** unwrap the standard backend envelope centrally in
  `ApiClient`, with a transition-compatible path for unwrapped responses.
- **Authorization UX:** distinguish `403` from `401`; admin-only actions are
  hidden or disabled for `HOST_AUTHOR`.
- **Backend delta:** the only confirmed missing contract is the paginated
  pending essay-review query in the scoring service.
- **Testing:** continue Flutter unit/BLoC/widget testing because the current app
  has 37 test files; do not create a broad backend unit-test convention within
  Member 3 scope.
- **Documentation:** `pte-doc` is canonical. `pte-api` mirrors backend contract,
  verification, and quality artifacts only.
- **Git handling:** keep new work uncommitted until Hung explicitly approves
  the completed slice.
