# Spec: Member 3 Host Mini Console

**Date:** 2026-07-28  
**Created by:** Member 3  
**Status:** Approved design

---

## Problem Statement

The backend already exposes most operations required for a Host to author PTE
content, compose and operate sessions, request scoring, review essays, publish
results, and inspect audit data. The Flutter application on `pte-app/dev`
currently focuses on authentication and the student exam flow, so Member 3
needs a Host-facing mini console that uses the existing microservice contracts
without breaking Member 2's work.

This initiative adds only Member 3's scope. It follows the feature-first Clean
Architecture already used by the Flutter application and adds backend behavior
only when an end-to-end Member 3 flow cannot be completed with the current
contract.

---

## Goals

1. Deliver a usable Host mini console for the Member 3 workflow.
2. Preserve the current Flutter architecture, dependency injection, BLoC,
   network, storage, and design-system conventions.
3. Use the gateway as the only Flutter entry point to backend services.
4. Keep tenant and role authorization authoritative on the backend.
5. Split the work into small vertical slices that can be reviewed and verified
   independently.
6. Track the canonical requirements in `pte-doc` and backend contract work in
   a corresponding `pte-api` plan.

---

## User Stories

- **[P1]** As a Host author, I want to create
  `MC_READING_SINGLE`, `READ_ALOUD`, and `WRITE_ESSAY` questions so that I can
  prepare tenant-specific practice content.
- **[P1]** As an authorized Host user, I want to see shared questions together
  with my tenant's private questions without seeing another tenant's content.
- **[P1]** As a Host author, I want to build a blueprint and publish an
  immutable snapshot so that a session uses a stable content definition.
- **[P1]** As a Host user, I want to create a full or practice session and
  configure its composition.
- **[P1]** As a Host administrator, I want to enroll students and assign a
  proctor to a session.
- **[P1]** As a Host administrator, I want to request scoring, review essays in
  `AI_SCORED_PENDING_REVIEW`, and publish results.
- **[P1]** As a Host operator, I want to inspect notification and violation
  audit records for operational follow-up.
- **[P3]** As a Host operator, I want a live proctor console. This is a stretch
  goal and starts only after all required Host flows are complete.

---

## Scope and Delivery Phases

The initiative is an umbrella roadmap. Each phase is a separate implementation
cycle with its own detailed plan and verification evidence.

1. **Phase 00 — API compatibility and Host shell**
2. **Phase 01 — Question list and `MC_READING_SINGLE` creation**
3. **Phase 02 — `READ_ALOUD`, `WRITE_ESSAY`, and media upload**
4. **Phase 03 — Blueprint and immutable snapshot**
5. **Phase 04 — Session and composition**
6. **Phase 05 — Enrollment and proctor assignment**
7. **Phase 06 — Scoring, essay review queue, and result publication**
8. **Phase 07 — Notification and violation audit**
9. **Phase 08 — Live proctor console, stretch only**

The first implementation slice is limited to Phase 00 and Phase 01. Later
phases are not implemented speculatively.

---

## Flutter Architecture

The application retains its current feature-first structure:

```text
lib/
├── core/
│   ├── network/
│   ├── storage/
│   └── widgets/
└── features/
    ├── auth/
    ├── host_console/
    ├── authoring/
    ├── scheduling/
    ├── scoring_review/
    └── host_audit/
```

### Feature ownership

- `auth` remains the shared authentication source for Member 2 and Member 3.
- `host_console` owns Host navigation, route guards, and role-aware menus. It
  contains no authoring, scheduling, scoring, or audit business rules.
- `authoring` owns questions, options, media references, blueprints, and
  snapshots.
- `scheduling` owns sessions, composition, enrollment, and proctor assignment.
- `scoring_review` owns score requests, the essay review queue, review
  approval, and result publication.
- `host_audit` owns notification logs and violation audit views.
- `core` continues to own the API client, token lifecycle, shared failures,
  storage, and shared widgets.

Each business feature uses the existing layers:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

Features do not import another feature's BLoC or repository implementation.
Cross-feature coordination occurs through routing, domain-level inputs, and
registered interfaces.

---

## Backend Ownership

Flutter communicates only through the gateway at `/api/**`.

| Flutter feature | Backend owner |
| --- | --- |
| `authoring` | `authoring-service`, `media-service` |
| `scheduling` | `scheduling-service`, `iam-service` |
| `scoring_review` | `scheduling-service`, `scoring-service` |
| `host_audit` | `notification-service`, `proctor-service` |

The current backend already supports question creation/listing, media
presign/complete, blueprint creation, snapshot publication, session creation
and composition, enrollment, proctor assignment, score requests, individual
essay review, result publication, notification listing, and violation listing.

### Required backend addition

The required Member 3 flow lacks a read endpoint for the essay review queue.
Phase 06 adds a paginated query to the existing scoring review controller:

```http
GET /api/scoring/answers/reviews
    ?sessionPublicId={sessionPublicId}
    &status=AI_SCORED_PENDING_REVIEW
    &page=0
    &size=20
```

The endpoint:

- derives tenant scope from the authenticated JWT;
- rejects cross-tenant access;
- supports only reviewable answer states;
- filters by session;
- returns a paginated result using the standard backend response envelope; and
- follows the existing scoring controller/service/repository layering.

Enrollment and proctor assignment list endpoints are not added unless the
Phase 05 UI demonstrates that the POST responses cannot support the approved
workflow.

---

## API Response Compatibility

The backend standard response is:

```json
{
  "success": true,
  "data": {},
  "message": "..."
}
```

Existing Flutter repositories commonly expect the inner payload directly.
Phase 00 updates `ApiClient` to unwrap the standard envelope centrally while
preserving the response type currently consumed by repositories.

During migration, the client accepts both wrapped and already-unwrapped
payloads. Raw presigned uploads remain outside envelope handling. This is a
targeted compatibility fix; Member 2's authentication, exam-attempt, and
reporting business logic is not redesigned.

---

## Data Flow

All Member 3 operations follow the same direction:

```text
Page
→ BLoC event
→ Use case
→ Domain repository
→ Repository implementation
→ Remote data source
→ ApiClient
→ Gateway
→ Microservice
```

Backend DTOs remain inside the data layer. Presentation code consumes domain
entities and immutable BLoC states.

### Authoring flow

1. Load the questions visible to the current Host.
2. Choose a supported PTE task type.
3. Validate the form locally.
4. For media-backed questions, presign, upload, and complete the media object.
5. Create the question using the returned media reference.
6. Refresh or update the list from the authoritative backend response.
7. Build a blueprint from eligible questions.
8. Publish the blueprint as an immutable snapshot.

### Session-to-publication flow

```text
Create session
→ Configure composition
→ Enroll students
→ Assign proctor
→ Open session
→ Request scoring
→ Review pending essays
→ Publish results
```

The backend remains authoritative for session and scoring state transitions.
The Flutter client does not manufacture a successful state before a mutation
has been acknowledged.

---

## Authorization

- `HOST_ADMIN` receives all Member 3 capabilities allowed by the backend.
- `HOST_AUTHOR` receives authoring, blueprint, and the session operations
  permitted by the backend.
- User lookup, proctor assignment, scoring requests, and result publication
  are hidden or disabled when the current role cannot perform them.
- Flutter route guards improve navigation and user feedback but do not replace
  backend authorization.
- A `403` response is shown as insufficient permission and does not trigger a
  false logout.
- Tenant isolation is never determined from a tenant identifier supplied by
  the UI when the authenticated backend context can provide it.

---

## Validation and Error Handling

- `401`: attempt the existing token-refresh flow once; log out only when the
  refresh cannot recover the request.
- `403`: retain the session and show an insufficient-permission failure.
- `400` or `422`: show validation feedback and bind field-level failures when
  the backend identifies a field.
- `404`: report that the resource is unavailable or outside the accessible
  tenant scope.
- `409`: report a duplicate operation or invalid state transition and reload
  authoritative state where appropriate.
- Network failure or timeout: preserve form state and expose an explicit retry.
- `5xx`: show a system failure without discarding user input.

Mutation buttons are disabled while a request is in flight. Snapshot
publication, score requests, reviews, and result publication are never retried
automatically. The essay review queue refreshes after approval rather than
using an optimistic score update.

---

## Flutter Engineering Constraints

- No hard-coded user-facing strings or colors; use the project's resource and
  design-system constants.
- Follow the existing GetIt feature-module registration pattern.
- Use sealed BLoC events and immutable, distinct state classes.
- Keep files and widget build methods within the limits defined by the current
  Flutter project guidance.
- Dispose controllers and subscriptions.
- Check `mounted` after asynchronous UI work where required.
- Prefer `BlocSelector` when only a portion of state drives a widget.
- Avoid unrelated refactoring and preserve the Member 2 flow.

---

## Testing and Verification

The Flutter repository currently contains 37 test files: 28 unit tests, 8
widget tests, and 1 integration test. Member 3 therefore continues the existing
testing convention.

### Flutter tests

- Model and entity mapping tests.
- Repository tests using the real backend envelope shape.
- BLoC tests for loading, success, empty, validation, and failure states.
- Widget tests for Host role guards, the question list, and create form.
- Regression tests for existing repositories affected by `ApiClient`
  compatibility behavior.

### Backend verification

The backend declares `spring-boot-starter-test` but currently has no Java test
source convention. Member 3 does not introduce a broad backend unit-test suite.
Backend additions require:

- successful compile/package of the affected service;
- contract verification for request, response, pagination, role, and tenant
  behavior; and
- a documented manual or integration-level API verification.

Every phase records the exact commands and their outputs. A timeout or command
without a successful result is not evidence that the phase passes.

---

## First Slice Acceptance Criteria

Phase 00 and Phase 01 are accepted when:

- [ ] `HOST_ADMIN` and `HOST_AUTHOR` can enter the Host console after login.
- [ ] A non-Host role cannot enter Host routes.
- [ ] The question list supports loading, empty, error, retry, and success
      states.
- [ ] A Host can create a valid `MC_READING_SINGLE` question.
- [ ] The form requires the correct option structure and exactly one correct
      answer.
- [ ] Invalid input is rejected before an API request.
- [ ] The created question is rendered from the backend response.
- [ ] Wrapped backend responses are consumed correctly.
- [ ] Existing auth, exam-attempt, and report behavior remains compatible.
- [ ] New Flutter unit, BLoC, and widget tests pass.
- [ ] `flutter analyze` completes successfully.
- [ ] Source files comply with the established project structure and size
      guidance.

---

## Full Initiative Success Criteria

- [ ] Host users can complete question authoring for all three Member 3 task
      types.
- [ ] Shared and tenant-private visibility follows backend authorization.
- [ ] A blueprint can be published to an immutable snapshot.
- [ ] A Host can create and compose a full or practice session.
- [ ] An authorized Host administrator can enroll a student and assign a
      proctor.
- [ ] Scoring can be requested, pending essays can be reviewed, and results can
      be published.
- [ ] Notification and violation audits can be inspected.
- [ ] Required flows operate through the gateway without direct microservice
      URLs in Flutter.

---

## Documentation Ownership

The canonical specification and cross-repository roadmap live in:

```text
pte-doc/projects/plans/member3-host-mini-console/
```

After this spec is reviewed, detailed phase plans are created in the same
directory. Backend-impact tracking lives in:

```text
pte-api/plans/member3-host-mini-console/
```

The `pte-api` plan records only backend contracts, affected files, migrations,
verification, and phase status. It links back to this canonical spec instead of
redefining product requirements.

---

## Out of Scope

- Student exam-delivery implementation owned by Member 2.
- Redesigning authentication or the existing student features.
- Adding backend endpoints merely for UI convenience without a demonstrated
  Member 3 requirement.
- Vendor moderation or AI-assisted question generation.
- Editing an already-published snapshot.
- Cross-session live proctor operations in the required delivery phases.
- A broad retrofit of Java unit tests across existing microservices.

---

## Resolved Decisions

- Use vertical slices instead of one large `host_console` business feature.
- Keep `host_console` limited to shell, navigation, and role-aware routing.
- Fix response-envelope compatibility centrally in `ApiClient`, with
  regression coverage for existing Flutter features.
- Add only the missing paginated essay-review query to the backend contract.
- Treat the backend as authoritative for state transitions and mutation
  results.
- Implement only Phase 00 and Phase 01 in the first trial slice.
- Continue Flutter unit/BLoC/widget testing because the current application
  already relies on those patterns.
- Do not establish a broad backend unit-test convention as part of Member 3.
- Keep live proctor work as Phase 08 stretch scope.

