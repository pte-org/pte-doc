# Plan: PTE Practice Student Web

**Status:** Draft for user review
**Date:** 2026-10-07
**Mode:** `ck:plan --hard`
**Scope:** `pte-api` + isolated `pte-practice` + `pte-doc`
**Implementation rule:** planning only; no production code, migration, commit, push or deployment is included in this plan.

## Scope challenge

### Problem and minimum viable boundary

The product needs a student-facing practice web in `pte-practice`. An authenticated student may see the normal product shell and catalog, but only an imported active student whose organization has an eligible active plan may start practice. The minimum safe implementation is therefore not a visual clone alone. It is:

1. a canonical student identity/session contract;
2. a server-authoritative entitlement contract;
3. a practice catalog and standalone practice-session facade;
4. a reusable session lifecycle and answer contract;
5. interaction-family renderers for the agreed task milestone;
6. read-only Progress with historical-data semantics.

The existing attempt/runtime/media infrastructure remains the implementation foundation. This plan does not create a second question engine or a second renderer registry.

### Explicitly out of scope for this plan

- Leaders, More, Redeem and navigation outside Home, Practice tests, Study-Pack and Progress.
- Payment, checkout, subscription purchase, upgrade CTA, invite-code onboarding and lock-reason modal copy.
- Replacing the canonical roster import, billing, membership or capacity flows owned by `pte-api`.
- Rebuilding `TaskRuntimeProfileRegistry`, question authoring, template lifecycle, snapshot pinning or official exam scoring.
- Full Pearson visual/asset/code parity or copying private third-party runtime behavior.
- Arbitrary tenant-defined task types, uploaded renderer scripts, dynamic code execution or client-defined scoring.
- Claiming `WRITE_EMAIL` or video support when the current canonical backend contract does not define them.
- Full AI scoring parity; this plan carries answer and confidence contracts and uses the existing scoring seam where available.
- Production rollout or deployment. Rollout evidence is planned, not implied.

### Assumptions used to make the plan executable

- `pte-api` remains the source of truth for identity, organization membership, import status, plans, capacity, practice authorization and Progress.
- A student is automatically eligible after a valid active import only when the organization has the agreed eligible plan/capacity state. No per-student activation flag is introduced.
- Progress is owned by the student/practice history and remains read-only after current entitlement is revoked.
- The shell shows locked catalog cards without detailed reason/upgrade copy in the first release.
- Entitlement refresh is required on initial load, app focus and practice-session start; real-time push is not required for this release.
- Failed entitlement resolution fails closed for practice mutations and protected content, while the basic shell may remain visible.
- Local fixtures may represent task content that cannot be inspected from the authorized reference account, but they must use the same typed task contract as canonical content.

### Decisions still requiring user confirmation after plan review

The plan uses the recommendations at the end of this document so implementation can be sequenced. The user should confirm the choices before cooking Phase 01 because they change API, security and migration shape:

1. verified email authentication: passwordless OTP/magic link, or an explicit username/password compatibility flow;
2. eligible-plan rule: `EXAM_PACKAGE` subscription only, or another named active-plan policy including capacity;
3. practice aggregate: a new `PRACTICE` source/session type reusing attempt infrastructure, or another approved aggregate;
4. whether `WRITE_EMAIL` and video are deferred gaps or require a separate contract before runtime delivery;
5. whether objective-task correctness is displayed immediately in MVP or only raw response/confidence is persisted until scoring ownership is confirmed.

The following behavior is fixed from the product direction: an unknown email
may establish a shell-only identity after the approved email verification flow,
but it has no organization membership, plan entitlement or practice access.
An imported email is linked to the canonical organization student membership;
unverified, suspended, removed or ambiguous memberships are not granted
practice access. Shell-only identity provisioning is not an organization
membership or an entitlement bypass.

## Current evidence and architectural constraints

### Repository evidence

`pte-practice` is an isolated npm Next.js 16.4 scaffold with only `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, package scripts and no API client, auth state, route structure or test setup. Its `AGENTS.md` requires reading the installed Next.js guides before implementation.

The relevant existing backend ownership is:

| Concern | Existing canonical area | Planning consequence |
|---|---|---|
| Auth/session | `pte-api/app/src/main/java/com/pte/identity/internal/controller/AuthController.java`, `AuthService.java`, `LoginRequest.java` | Existing contract is username/password; email login requires an explicit identity design. |
| Student import | `StudentRosterImportController.java`, `StudentRosterImportService.java`, `UserBulkCreateWriter.java` | Import and generated usernames already exist; email mapping/verification must be reconciled, not duplicated. |
| Tenant/plan/capacity | `pte-api/app/src/main/java/com/pte/tenancy/TenancyService.java`, billing `Subscription.java` and `SubscriptionController.java` | `STUDENT_CAPACITY` and `EXAM_PACKAGE` are different concepts; eligibility needs one named policy. |
| Official exam entitlement | `pte-api/app/src/main/java/com/pte/session/internal/service/EntitlementService.java`, `StudentSessionController.java` | It is session/enrollment-specific and cannot be used as the entire self-practice contract. |
| Attempt runtime | `AttemptController.java`, `AttemptLifecycleService.java`, `HeartbeatController.java`, `TaskView.java`, `SubmitAnswerRequest.java` | Reuse pinning, navigation, timing, media and answer seams through a practice facade; extend additively for practice semantics. |
| Runtime registry | `pte-api/app/src/main/java/com/pte/itembank/TaskRuntimeProfileRegistry.java` and related task contract services | Reuse allowlisted profiles and interaction families; do not create a second registry. |
| Official reports | `pte-api/app/src/main/java/com/pte/reporting/internal/controller/ReportController.java`, `ReportService.java` | Official published reports do not model practice history; Progress needs a dedicated read model/adapter. |
| Media | `pte-api/app/src/main/java/com/pte/media/internal/controller/MediaController.java` and existing media services | Bind recordings to student/attempt/item and define readiness, MIME, size, retry and retention behavior. |
| Web convention | `pte-web/packages/api-client` and existing tenant/vendor apps | `pte-practice` is isolated; sharing/extracting a client is a contract decision, not an assumption. |

### Task coverage boundary

The backend canonical enum has 23 values: `PERSONAL_INTRODUCTION`, `READ_ALOUD`, `REPEAT_SENTENCE`, `DESCRIBE_IMAGE`, `RE_TELL_LECTURE`, `ANSWER_SHORT_QUESTION`, `RESPOND_TO_A_SITUATION`, `SUMMARIZE_GROUP_DISCUSSION`, `SUMMARIZE_WRITTEN_TEXT`, `WRITE_ESSAY`, `MC_READING_SINGLE`, `MC_READING_MULTIPLE`, `RE_ORDER_PARAGRAPHS`, `FILL_IN_THE_BLANKS_DRAG_AND_DROP`, `FILL_IN_THE_BLANKS_DROPDOWN`, `SUMMARIZE_SPOKEN_TEXT`, `MC_LISTENING_SINGLE`, `MC_LISTENING_MULTIPLE`, `FILL_IN_THE_BLANKS_TYPE_IN`, `HIGHLIGHT_CORRECT_SUMMARY`, `SELECT_MISSING_WORD`, `HIGHLIGHT_INCORRECT_WORDS`, and `WRITE_FROM_DICTATION`.

The reference catalog also exposes `WRITE_EMAIL`, and the inspected media showed video-like playback. Current research found no canonical `WRITE_EMAIL` enum/runtime or explicit video capability. These are explicit compatibility gaps:

- do not silently map `WRITE_EMAIL` to `WRITE_ESSAY`;
- do not silently map video to audio;
- expose catalog availability separately from runtime readiness;
- use a local fixture only where the fixture conforms to an existing contract and the task is explicitly marked as fixture-backed;
- block or defer a task whose contract is missing, with no silent skip.

Reference-verified first-question families include dropdown, checkbox single/multiple choice, reorder, drag-to-blank, typed text, transcript marking, audio readiness/playback and countdown. Speaking microphone flows, premium Writing/Speaking flows, `WRITE_EMAIL` and video remain unverified from the authorized account.

## Target architecture

```text
student browser (pte-practice)
  ├─ authenticated shell: Home / Practice tests / Study-Pack / Progress
  ├─ locked preview state (no client-only unlock)
  ├─ practice session shell and family renderers
  └─ typed API/media client
          |
          v
pte-api student-facing facade
  ├─ identity/email session boundary
  ├─ practice entitlement policy
  ├─ catalog + practice-session orchestration
  ├─ existing attempt pinning/timing/answer/media seams
  ├─ confidence persistence and practice progress projection
  └─ audit/metrics/error contract
          |
          v
canonical identity + tenancy/billing + itembank/runtime + attempt/media
```

The practice facade owns student-facing orchestration and policy. It calls public services from identity, tenancy/billing, itembank, attempt, media and reporting/progress owners. It must not reach into another module's repositories or duplicate identity/membership rows.

## API and domain contract target

Names below are contract concepts, not permission to invent an implementation path. Exact controller/service class names are selected after Phase 01 repository inspection.

### Identity

- `POST /api/v1/auth/practice/request` (or the approved canonical email-login endpoint): accepts a normalized email and returns a non-enumerating challenge response.
- `POST /api/v1/auth/practice/verify`: consumes a one-time challenge and establishes the canonical student session/tokens.
- `GET /api/v1/auth/me`: remains the session identity source.
- A verified email must resolve to exactly one explicit organization context. Multiple active memberships require an explicit organization selection/token context; the system must never merge private data or unlock from ambiguity.
- Unknown email may create a shell-only identity with an empty organization
  context after verification. It receives the normal shell and a locked
  practice state, but cannot create or reach a practice session. Challenge
  requests remain rate-limited and non-enumerating.
- Imported, unverified, suspended, removed or multi-organization records are
  resolved through explicit membership/context rules; they are never silently
  merged or granted entitlement from email alone.
- OTP/magic-link values are one-time, hashed at rest, rate limited, short-lived and absent from logs/telemetry.
- Phase 01 must also freeze the isolated-app auth transport: cookie versus
  bearer token, refresh-token storage, CORS origins and CSRF protection. The
  recommended default is an HttpOnly Secure cookie with an explicit CSRF
  strategy when the deployment topology allows it; existing username/password
  login remains intact.

### Entitlement

`GET /api/v1/student/practice/entitlement` returns a stable additive shape such as:

```json
{
  "student": {"publicId": "...", "status": "ACTIVE"},
  "organizationContext": {"publicId": "...", "displayName": "..."},
  "practice": {"state": "UNLOCKED|LOCKED|AMBIGUOUS|UNAVAILABLE"},
  "refreshAt": "..."
}
```

The response must not expose private tenant data, capacity internals or secrets. The server recalculates the effective state from student status, canonical membership/import, the explicitly approved eligible plan, and capacity/seat policy. Client cache is presentation only.

### Catalog and session

Conceptual student-facing boundaries:

- `GET /api/v1/student/practice/catalog`: visible catalog, availability/readiness, section, task type, runtime profile/capabilities and locked/unavailable state.
- `POST /api/v1/student/practice/sessions`: idempotent start/resume request for a selected practice product/task set; server checks entitlement, content readiness and client/runtime compatibility.
- `GET /api/v1/student/practice/sessions/{id}`: overview/current draft metadata and safe saved state.
- `POST /api/v1/student/practice/sessions/{id}/answers`: save/submit one response plus optional confidence according to task policy.
- `POST /api/v1/student/practice/sessions/{id}/skip`: records a skipped item without requiring confidence.
- `POST /api/v1/student/practice/sessions/{id}/exit`: applies empty-discard/non-empty-resume policy.
- `POST /api/v1/student/practice/sessions/{id}/heartbeat`: reuses or adapts existing heartbeat/timer ownership.
- `GET /api/v1/student/practice/sessions/{id}/media/{itemId}` or the existing protected media boundary: returns authorized, short-lived media access.

Every mutation supports an idempotency key/request identity and optimistic version/lease semantics. A retry must not duplicate an answer, create a second session or overwrite a newer tab silently.

### Answer and confidence

```json
{
  "pinnedItemPublicId": "...",
  "payload": {},
  "confidence": "LOW|MEDIUM|HIGH|null",
  "clientVersion": 3,
  "idempotencyKey": "..."
}
```

Answered items require confidence before advance/submit. Skipped items may omit it. Confidence is persisted independently of correctness and does not alter scoring. The server validates the answer schema from the pinned runtime profile and never returns correct/reference answers during practice delivery.

### Progress

`GET /api/v1/student/practice/progress` is a read-only, student-scoped projection. It must distinguish no history, in-progress draft, completed practice and historical results. It must preserve historical records after entitlement revocation and return an empty state rather than fabricated zero/score metrics when no history exists.

The minimum response state vocabulary is `NO_HISTORY`, `IN_PROGRESS`,
`COMPLETED_PENDING_SCORE`, `COMPLETED_SCORED` and `SCORING_FAILED`. A draft,
skipped-only/empty exit or scoring failure must not be presented as a completed
score. Final correctness fields are nullable and their display is governed by
the scoring decision in Phase 01.

### Mutation, lifecycle and media rules

- A session is empty when no answer-bearing payload or completed recording is
  persisted. A skip-only/untouched session is discarded on explicit exit and
  creates no report or fabricated zero score. Any answer-bearing response or
  completed recording makes an unfinished session resumable.
- Browser close, pending autosave, offline transition or media failure follows
  the same draft/exit policy; the client cannot mark an unpersisted response as
  answered. Recovery is explicit on the next load.
- Mutations that can be retried carry `Idempotency-Key`. The server stores the
  key, request hash, operation/resource scope, resulting status/response and a
  recommended 24-hour expiry. Same key with a different request is
  `409 IDEMPOTENCY_KEY_REUSED`; a safe retry replays the original result. A
  stale `clientVersion` is `409 STALE_SESSION_VERSION`; the UI reloads rather
  than silently overwriting another tab.
- Recording delivery must be bound to student, practice session, pinned item,
  purpose, MIME, byte size and duration. Phase 01 must choose the canonical
  browser format against the existing media service; the initial
  recommendation is to preserve the existing WAV contract with a client-side
  encoder rather than introduce an unreviewed transcoding pipeline.

## Dependency graph

```text
P0 Contract freeze / mapping / ADR decisions
 ├── P1 Identity + membership + entitlement policy
 │    ├── P2 Practice catalog + standalone session facade
 │    │    ├── P4 Session lifecycle + objective interaction runtime
 │    │    └── P5 Text + audio/video boundary + speaking media runtime
 │    └── P3 pte-practice shell + locked four-route UX
 └── existing task-runtime/template/snapshot contracts (read-only prerequisite)

P2 + P3 ──> P4 ──> P5 ──> P6 Confidence + Progress
P1..P6 ──> P7 Cross-repo hardening, accessibility, observability and rollout
```

### First releasable slice

The first release gate is deliberately smaller than the full catalog: Phase 04
must provide the four-route shell and locked/unlocked states, and Phase 05 must
prove one production-supported objective interaction family end to end before
Phase 06 expands text, playback and speaking media. The remaining canonical
rows are not considered shipped until their coverage status is
`production-supported` and their first-question/skip/submit evidence exists.

## Ownership by repository

| Repository | Owns in this plan | Must not own |
|---|---|---|
| `pte-api` | Email identity boundary, entitlement policy, practice facade/session lifecycle, confidence persistence, progress projection, protected media/answer authorization, migrations and server telemetry | UI unlock decisions as the security boundary, duplicate question/runtime registries, client scoring authority |
| `pte-practice` | Four-route shell, locked/unlocked presentation, typed API adapter, session UX, family renderers, media/device UX, responsive/accessibility behavior | Plan/membership inference, answer correctness authority, direct repository/API bypass, arbitrary renderer execution |
| `pte-web` | Only an explicitly approved shared API/client package extraction or contract reuse; otherwise unchanged | Becoming an accidental dependency of isolated `pte-practice` |
| `pte-doc` | This plan, phase evidence, ADR/contract matrix, fixture/coverage matrix and rollout notes | Credentials, real tokens, production data |

## Migration and rollback strategy

1. Add additive schema/DTO fields and new practice tables/columns only after Phase 01 contract review.
2. Backfill only deterministic identity/ownership links where canonical data is sufficient; never infer cross-tenant membership from email alone.
3. Keep existing username/password and official attempt/report contracts backward compatible during rollout.
4. Gate new email practice auth, practice start, new runtime profiles and strict entitlement enforcement behind server-side feature flags where the existing deployment convention supports flags.
5. Roll forward on shared environments. Rollback disables the practice feature/strict enforcement flag and keeps additive columns and historical practice rows; it does not drop migrations or delete attempts/progress.
6. If a migration is not safely reversible, provide a forward repair migration and an operator runbook entry before enabling the dependent feature.
7. Historical data remains readable after plan revocation, student deactivation or feature rollback. New practice starts fail closed when the policy cannot be evaluated.

## Security, tenant isolation and privacy

- Require authenticated student authority for all protected practice endpoints.
- Re-evaluate entitlement at session start, task/content access and answer/media mutation boundaries; never trust a client `unlocked` flag.
- Scope every query by canonical student and explicit organization context. Reject ambiguous multi-organization requests rather than merging data.
- Prevent IDOR by using public identifiers plus server ownership checks for session, item, answer, media and progress resources.
- Do not expose correct answers, scoring keys, signed media URLs, OTPs, passwords or raw answer content in logs.
- Rate limit email challenge requests, verification attempts, login refresh and answer/session mutations. Use constant-time/non-enumerating responses for unknown email.
- Validate media MIME, size, duration, ownership and binding to the pinned attempt item. Expired signed URLs are refreshed through the protected API, not logged.
- Enforce server deadline/status/version. Client timer is only a display aid.
- Audit entitlement denials, ambiguous context, session start/exit, answer conflict, media failure and auth abuse with actor/org/session identifiers that do not include secrets or answer text.

## Observability and NFR baseline

- Track p50/p95 for entitlement and catalog reads, practice start, answer save/submit and progress reads; target entitlement availability p95 < 500 ms after dependencies respond.
- Metrics: email challenge requested/verified/denied/rate-limited; entitlement state counts; catalog unavailable reasons; session double-start/idempotency conflicts; answer conflicts/retries; media readiness/upload failures; empty discard/non-empty resume; confidence-missing rejects; Progress empty/history reads.
- Correlate a request/attempt/session ID without logging credentials, raw responses or signed URLs.
- Record feature flag state and contract/profile version in safe telemetry.
- Accessibility baseline: keyboard/focus/labels for locked controls, choices, confidence buttons, drag/drop alternatives, text inputs, media controls and recording states.
- Responsive review at 390x844, 1024x768 and 1440x900; retain the reference desktop capture only as a visual reference.
- Browser/media support and audio payload/retention limits must be recorded in Phase 01; no silent browser fallback.
- Phase 01 must name the feature-flag owner and default-off rollout controls,
  the supported browser matrix, media retention limit and alert thresholds. A
  rollback disables practice entry/strict enforcement and keeps additive data;
  it does not drop migrations or delete history.

## Risk register

| Risk | Severity | Mitigation / owner |
|---|---:|---|
| Email login conflicts with generated username/password and tenant-scoped non-unique email | HIGH | P0 identity decision; P1 canonical challenge/context flow; identity owner |
| Wrong plan type unlocks a student or capacity is bypassed | HIGH | Named eligibility policy through tenancy/billing public services; P1 authorization matrix |
| Existing official attempt API is mistaken for self-practice API | HIGH | P2 practice facade with explicit source/session type; reuse only internal seams |
| Empty exit creates misleading 0% report or draft is lost | HIGH | P2 lifecycle contract: empty discard, non-empty resume, no fabricated report |
| Two tabs/retries duplicate session or overwrite answers | HIGH | Idempotency key + optimistic version/lease + conflict response; P2/P4 |
| Confidence is kept only in React state or changes score | HIGH | Additive persisted enum and scoring-independent tests; P6 |
| `WRITE_EMAIL`/video is silently approximated | HIGH | Coverage matrix and explicit blocked/fixture status; P0/P5/P7 |
| Media permission/upload failure submits an empty response | HIGH | Readiness state, server media binding, retry/abandon semantics; P5 |
| Client timer allows work after deadline/revocation | HIGH | Server deadline/status enforcement and heartbeat; P2/P4 |
| Progress leaks after organization switch or disappears on revoke | HIGH | Student/org ownership projection and historical retention tests; P1/P6 |
| New isolated app drifts from web API client conventions | MEDIUM | P0 package boundary decision; typed contract tests; P3/P7 |
| Runtime renderer key from API becomes arbitrary code execution | HIGH | Allowlisted registry/profile keys and client mapping; P2/P4 |
| Premium reference content cannot be inspected | MEDIUM | Approved local fixtures with provenance and replacement criteria; P0/P5 |

## Research and red-team disposition

The two read-only research passes reached the same architectural conclusion: the current scaffold cannot safely implement this as a frontend-only clone. The following findings are accepted into the plan:

- username/password and generated student usernames conflict with the requested verified-email entry; this is a Phase 01/02 contract, not a UI alias;
- `STUDENT_CAPACITY` and `EXAM_PACKAGE` must not be conflated;
- official `ExamSession`/enrollment entitlement is not a self-practice session API;
- existing attempt delivery lacks the required saved-answer/confidence/abandon semantics;
- official published reports are not a complete practice Progress model;
- media ownership/readiness, server deadline and idempotency need explicit contracts;
- `WRITE_EMAIL` and explicit video are gaps and must not be silently approximated.

The following are intentionally noted rather than expanded into this first scope:

- full premium-reference inspection is deferred to an authorized account or canonical fixture; local fixtures may unblock renderer development but do not prove production content parity;
- real-time entitlement events are deferred; initial load, focus and session-start refresh are the first-release boundary;
- Leaders, More, Redeem, payment and upgrade flows remain P3/out of scope.

Phase 01 must also emit the package/module owner table, migration ownership and
naming convention, API controller/service ownership, frontend route/feature
tree, backend JUnit/Maven commands, isolated-app Vitest/RTL commands and
Playwright commands. Later phases may fill exact class names only after that
evidence is written; they may not leave the transport, test framework or
deployment boundary undefined.

No finding was rejected as irrelevant to the security or runtime boundary. The user decisions listed in `Decisions still requiring user confirmation after plan review` remain the hard handoff questions.

## Phases

- [x] 1. Contract freeze, coverage matrix and architecture decisions (`phase-01-contract-freeze-and-coverage.md`) — quality: APPROVED; testing: PASSED
- [x] 2. Student identity, membership and server-authoritative entitlement (`phase-02-identity-membership-and-entitlement.md`) — quality: APPROVED; testing: PASSED
- [x] 3. Practice catalog and standalone session facade (`phase-03-practice-catalog-and-session-api.md`) — quality: APPROVED; testing: PASSED
- [x] 4. `pte-practice` shell, four routes and locked state (`phase-04-student-shell-and-locked-routes.md`) — quality: APPROVED; testing: PASSED
- [ ] 5. Session lifecycle and objective interaction families (`phase-05-session-lifecycle-and-objective-runtime.md`)
- [ ] 6. Text, playback and speaking media runtime (`phase-06-text-playback-and-speaking-media.md`)
- [ ] 7. Confidence persistence and Progress read model (`phase-07-confidence-and-progress.md`)
- [ ] 8. Cross-repo hardening, accessibility and rollout evidence (`phase-08-hardening-and-rollout.md`)

## Completion gate

The plan is ready to cook when the user confirms the five decisions above or explicitly accepts the recommendations. During cooking, each phase must separately run the chosen unit/integration/E2E checks and `ck:quality` gate; this plan records both as `Not started` and `Not evaluated`.

Completion must report separately: passed local checks, blocked external/reference checks, deferred task-contract gaps, unrelated dirty-worktree failures, and deployment status. No compile, mocked route or unauthenticated request is evidence of production readiness.

## Recommended decisions and impact

1. **Use passwordless verified email OTP/magic link with explicit organization context.** This matches the product request and avoids exposing generated student passwords to the new app, but requires identity tables/endpoints, rate limits and an email delivery path. Keep existing username/password unchanged for compatibility.
2. **Define eligibility as an active imported student plus an explicitly named active `EXAM_PACKAGE` entitlement and valid capacity policy.** Treat `STUDENT_CAPACITY` as seat capacity, not by itself as a practice product. This prevents accidental unlock from a capacity-only purchase.
3. **Create a practice facade with a clearly marked `PRACTICE` source/session type while reusing attempt pinning, runtime profiles, timing, answer validation and media seams.** This avoids host-created session/enrollment coupling and avoids a second exam engine.
4. **Defer `WRITE_EMAIL` and explicit video until their canonical runtime/content contracts exist.** Show them in the catalog only with an explicit unavailable/fixture status; never map them to a different task.
5. **Persist raw responses and confidence first; expose correctness only where the existing scorer contract is authoritative.** This keeps Progress honest while allowing objective scoring to be added without changing confidence semantics.

## Handoff

No production source, database or deployment has been changed by this plan. After user review, the intended implementation command is:

```text
/ck:cook --hard --tests --quality D:\GitHub\pte-org\pte-doc\projects\plans\quang-pte-practice-student-web\plan.md
```
