# Practice Exam Anti-Cheat Policy — Master Plan

**Status:** Phases 1–4 implemented and checkpointed; Phase 5 release artifacts
are built, while the authenticated student Windows matrix remains pending.  
**Spec:** [spec.md](./spec.md)  
**Mode:** `ck:plan --hard`  
**Repositories:** `pte-api`, `pte-web`, `pte-app`, `pte-doc`

## 1. Objective

Allow a host to opt a `PRACTICE` exam into the existing controlled desktop
policy without creating a second anti-cheat domain or changing the behavior of
Official exams.

The implementation will make the following mapping authoritative:

| Exam mode | Host UI | Persisted `ExamPolicy.lockdownMode` | Desktop behavior |
|---|---|---|---|
| `PRACTICE` | Anti-cheat off | `NONE` | Windowed; no lockdown activation |
| `PRACTICE` | Anti-cheat on | `STANDARD` | Fullscreen, clipboard/shortcut hooks, warning and audit only |
| `OFFICIAL_EXAM` | No Practice setting | `STRICT` | Existing strict behavior, including configured forbidden-app handling |

The policy is stored on the session, copied into the immutable attempt snapshot,
and read by `pte-app` from the pinned attempt response. A violation is first
stored locally and then delivered through an authenticated student endpoint that
does not pretend the student is a proctor.

## 2. Scope challenge and implementation decision

The capability is partially present: `ExamPolicy.lockdownMode`, the
`lockdown_mode` database columns, attempt snapshot pinning, Flutter activation
ordering, and Windows native fullscreen already exist. This is a **Hard** plan
because the missing path crosses the session API, tenant wizard, attempt/audit
boundary, local Drift storage, Flutter security startup, and the Windows release
artifact. The feature is security-sensitive and a stale binary or stale REST
path can produce a false positive.

The minimum implementation is therefore five ordered phases. It does not
introduce a new anti-cheat boolean column, replace the native lockdown plugin,
or redesign proctoring.

## 3. Contract decisions

### 3.1 Single source of truth and request shape

The canonical draft create/update API will expose the existing enum field
`lockdownMode` rather than adding a persisted `practiceAntiCheatEnabled`
boolean. This keeps the API contract aligned with `ExamPolicy` and allows other
clients to read and write the same policy without a second translation layer.

The tenant UI still presents the requested boolean because that is the correct
host experience. It owns a transient `practiceAntiCheatEnabled` form value and
maps it at submit time:

```text
PRACTICE + false -> lockdownMode = NONE
PRACTICE + true  -> lockdownMode = STANDARD
OFFICIAL_EXAM    -> lockdownMode = STRICT
```

The UI never presents `STRICT` as a Practice option. The backend remains the
authority and rejects an explicit invalid combination instead of trusting the
browser. Source-compatible Java constructors may leave the new request field
nullable for older callers, but canonical new writes must resolve and persist a
non-null value before publication/opening.

Example canonical draft payload fragment:

```json
{
  "examMode": "PRACTICE",
  "lockdownMode": "STANDARD"
}
```

Rules:

- `OFFICIAL_EXAM` with a requested value other than `STRICT` is rejected with a
  stable session validation code; a missing value is derived as `STRICT` for
  compatibility.
- `PRACTICE` with `STRICT` is rejected.
- A new canonical Practice draft with no field is resolved to `NONE`, so an old
  client cannot accidentally turn on enforcement. A new controlled session can
  only be created by explicitly sending `STANDARD`.
- Create and patch null semantics are deliberately different:
  - create: missing/null resolves to the mode compatibility default;
  - draft patch: omitted/null `lockdownMode` means `leave the current policy
    unchanged` when the mode is unchanged;
  - draft patch with a changed mode and no explicit policy derives the default
    for the new mode;
  - policy patch with null keeps the current policy. An explicit value is
    validated against the session mode.
- Existing legacy rows with a null policy are normalized by
  `resolveEffectiveLockdownMode(examMode, persistedLockdownMode, legacyState)`
  before session responses and snapshot pinning:
  `PRACTICE -> NONE`, `OFFICIAL_EXAM -> STRICT`. The legacy
  `ExamPolicy.@PostLoad` path must not pre-fill a null lockdown value with the
  mode-independent `mockTestDefault()` value. The app must not silently
  downgrade a non-null unknown value.
- Once an attempt is pinned, its policy is immutable; changing a still-editable
  session policy must not mutate an existing attempt snapshot.

### 3.2 Student audit endpoint

The existing `/api/proctor/violations` path is not a student contract. It is not
to be reused or merely renamed in the client. The attempt module will own an
authenticated student endpoint:

```http
POST /api/v1/attempts/{attemptPublicId}/security-violations
Authorization: authenticated STUDENT
Content-Type: application/json
```

Request fields:

```json
{
  "clientEventId": "uuid-generated-by-the-app",
  "violationType": "LOCKDOWN_FULLSCREEN_EXIT",
  "clientOccurredAt": "2026-09-27T10:20:00Z",
  "detail": "optional bounded JSON or text"
}
```

The server derives the student, tenant, attempt ownership, pinned policy,
severity, and authoritative receive timestamp. The client cannot submit a
different student, tenant, attempt, severity, or server timestamp. A unique
constraint on `(attempt_id, client_event_id)` makes retries idempotent.

Student lockdown events are stored in a dedicated attempt audit table rather
than creating a fake `ProctorSession`. The existing proctor STOMP and legacy
violation endpoint remain available and unchanged.

Hosts/proctors receive this additive combined read contract:

```http
GET /api/v1/exam-sessions/{sessionPublicId}/security-audit
```

The response is a paged `SecurityAuditPageResponse` with `entries` and `nextCursor`.
Each normalized entry contains `publicId`, `source`
(`STUDENT_LOCKDOWN` or `PROCTOR`), `attemptPublicId`, `studentPublicId`,
`violationType`, `severity`, `detectedAt`, nullable `clientEventId`, and
bounded `detail`. The default page size is 50 and the hard maximum is 100;
the cursor is ordered by server `detectedAt` plus `publicId`.

`HOST_ADMIN` access requires session tenant ownership. `PROCTOR` access
requires the existing `SessionService.checkProctorAssignment` authorization
for that session; a proctor role alone is insufficient. The existing
`/api/v1/exam-sessions/{sessionPublicId}/violations` response remains
unchanged.

### 3.3 Enforcement semantics

`STANDARD` keeps the existing activation order and hooks. It does not pause,
force-submit, invalidate, or terminate a Practice attempt after a violation.
`STRICT` keeps its existing additional forbidden-app behavior. The audit
transport is observational and must not introduce a new command path.

## 4. Dependency map and phase order

```text
Phase 1: backend policy contract/invariants
       ├──> Phase 2: tenant wizard/API client
       ├──> Phase 3: student audit persistence/host read model
       └──> Phase 4: pte-app policy + audit adapter
Phase 2 ───────────────────────────────────────────────┘
Phase 3 ───────────────────────────────────────────────┘
Phase 4 ───────────────────────────────────────────────┘
                         └──> Phase 5: Windows release verification/rollout/ADR
```

Phase 1 must land first because both the web UI and the app depend on a stable
policy response. Phase 3 may be implemented in parallel with Phase 2 after the
policy contract is frozen, but Phase 4 must wait for the authenticated audit
endpoint and response semantics. Phase 5 is the only release acceptance gate;
debug or previously installed binaries are not evidence.

## 5. Phase index

| Phase | File | Outcome | Depends on |
|---|---|---|---|
| 1 | [phase-01-backend-policy-contract-and-invariants.md](./phase-01-backend-policy-contract-and-invariants.md) | Canonical draft policy contract, mode invariants, legacy compatibility and pinned response | Spec |
| 2 | [phase-02-tenant-web-policy-setting-and-detail.md](./phase-02-tenant-web-policy-setting-and-detail.md) | Practice checkbox, request mapping, review/detail display | Phase 1 |
| 3 | [phase-03-authenticated-student-security-audit.md](./phase-03-authenticated-student-security-audit.md) | Student audit endpoint, database idempotency, host read model | Phase 1 |
| 4 | [phase-04-pte-app-policy-activation-and-audit-adapter.md](./phase-04-pte-app-policy-activation-and-audit-adapter.md) | Fail-closed policy parsing, canonical audit delivery, retry and warning-only behavior | Phases 1 and 3 |
| 5 | [phase-05-windows-release-verification-rollout-and-adr.md](./phase-05-windows-release-verification-rollout-and-adr.md) | Fresh Windows release verification, rollout checklist and ADR | Phases 1–4 |

## 6. Functional requirement coverage

| Requirement | Planned phase(s) | Evidence required |
|---|---|---|
| FR-01 existing `lockdown_mode` | 1, 2 | Draft create/update and response contract use `LockdownMode`; no anti-cheat boolean column |
| FR-02 Practice `NONE`/`STANDARD` | 1, 2 | Backend invariant tests and wizard review/payload inspection |
| FR-03 `STRICT` only Official | 1, 2, 5 | Direct API negative cases, UI mode switch, Official release start |
| FR-04 session policy pinned into attempt | 1, 4 | Snapshot/attempt response and app startup trace |
| FR-05 Standard activation before task 1 | 4, 5 | Bloc/service test and Windows release walkthrough |
| FR-06 warning/audit only | 3, 4, 5 | Violation warning, local row, no attempt state transition |
| FR-07 authenticated audit path | 3, 4, 5 | API contract test, auth/ownership negative cases, online/offline delivery |
| FR-08 host policy visibility | 1, 2 | Session response and detail/review UI walkthrough |
| FR-09 Windows release verification | 5 | Versioned release artifact and test matrix |
| FR-10 no changes to exam flow semantics | 2, 4, 5 | Regression checks for skills, retries, timer, navigation, generation, scoring and reports |

## 7. Non-functional coverage

| NFR | Plan treatment |
|---|---|
| Security authority/pinning | Backend derives and validates policy; attempt reads pinned snapshot; app rejects unknown policy |
| Compatibility | Additive request/response fields, source-compatible constructors, legacy read defaults, unchanged old proctor endpoint |
| Windows | Fresh `flutter build windows --release`; no debug bypass; native activation is verified before task rendering |
| Audit reliability | Local-first insert, retry coordinator, server-side idempotency, bounded detail, observable terminal errors |
| Audit retention | Student events are retained 180 days from detectedAt, owned by Platform Operations, soft-deleted by a daily job, and excluded from reads after expiry |
| UX | Practice-only checkbox, explicit review label, existing warning UI, no pause/force-submit path |

## 8. Repository/file map

### `pte-api`

- Existing policy contract and validation:
  - `app/src/main/java/com/pte/session/internal/dto/request/CreateExamDraftRequest.java`
  - `app/src/main/java/com/pte/session/internal/dto/request/PatchExamDraftRequest.java`
  - `app/src/main/java/com/pte/session/internal/dto/request/PatchExamPolicyRequest.java`
  - `app/src/main/java/com/pte/session/internal/service/ExamOrchestrationService.java`
  - `app/src/main/java/com/pte/session/internal/service/SessionLifecycleService.java`
  - `app/src/main/java/com/pte/session/domain/ExamPolicy.java`
  - `app/src/main/java/com/pte/session/domain/enums/LockdownMode.java`
  - `app/src/main/java/com/pte/session/internal/constant/SessionConstants.java`
  - `app/src/main/java/com/pte/session/internal/dto/response/SessionResponse.java`
  - `app/src/main/java/com/pte/session/dto/response/ExamPolicyResponse.java`
- New student audit boundary, expected under the public attempt service and
  internal implementation packages:
  - `app/src/main/java/com/pte/attempt/internal/controller/AttemptController.java`
  - `app/src/main/java/com/pte/attempt/AttemptService.java`
  - `app/src/main/java/com/pte/attempt/internal/service/AttemptSecurityAuditService.java` (new)
  - `app/src/main/java/com/pte/attempt/internal/dto/request/RecordSecurityViolationRequest.java` (new)
  - `app/src/main/java/com/pte/attempt/internal/dto/response/SecurityViolationReceipt.java` (new)
  - `app/src/main/java/com/pte/attempt/dto/response/AttemptSecurityEventView.java` (new)
  - `app/src/main/java/com/pte/attempt/domain/AttemptSecurityEvent.java` (new)
  - `app/src/main/java/com/pte/attempt/domain/enums/LockdownViolationType.java` (new)
  - `app/src/main/java/com/pte/attempt/internal/repository/AttemptSecurityEventRepository.java` (new)
  - `app/src/main/java/com/pte/attempt/internal/constant/AttemptConstants.java`
  - `app/src/main/java/com/pte/proctoring/internal/controller/ViolationAuditController.java`
  - `app/src/main/java/com/pte/proctoring/internal/service/SecurityAuditQueryService.java` (new)
  - `app/src/main/java/com/pte/proctoring/internal/dto/response/SecurityAuditEntryResponse.java` (new)
  - `app/src/main/java/com/pte/proctoring/internal/dto/response/SecurityAuditPageResponse.java` (new)
  - `app/src/main/java/com/pte/proctoring/internal/service/ViolationService.java`
- Additive database migration, only for the student audit table:
  - `app/src/main/resources/db/migration/V<next-unique>__attempt_security_events.sql`
    (the concrete version is selected by the Phase 3 Flyway preflight; `V69`
    is valid only if the repaired chain proves it is the next unique version)
- Tests:
  - `app/src/test/java/com/pte/session/internal/service/ExamOrchestrationServiceTest.java`
  - `app/src/test/java/com/pte/session/internal/service/SessionLifecycleServiceTest.java`
  - `app/src/test/java/com/pte/attempt/internal/service/SnapshotPinServiceTest.java`
  - new attempt controller/service/repository contract tests
  - new proctoring security-audit query and authorization tests

No policy migration is planned: `lockdown_mode` already exists on session and
pinned snapshot persistence. The new audit migration is needed only because
student events are a different ownership and idempotency model from
`violation_events`, whose `proctor_session_id` is mandatory. The version must
be chosen only after resolving the repository's duplicate `V68` scripts and
checking `flyway_schema_history`; never rename an already-applied migration.

### `pte-web`

- `packages/api-client/src/types/scheduling/index.ts`
- `packages/api-client/src/requests/scheduling/examOrchestration.ts`
- `apps/tenant-web/features/exams/types/index.ts`
- `apps/tenant-web/features/exams/api/index.ts`
- `apps/tenant-web/features/exams/constants/index.ts`
- `apps/tenant-web/features/exams/utils/validateCreateExamWorkflow.ts`
- `apps/tenant-web/features/exams/components/CreateExamWizard.tsx`
- `apps/tenant-web/features/exams/components/SessionDetailView.tsx`
- relevant API-client/component tests where the repository's existing test
  conventions cover these modules

### `pte-app`

- `lib/core/security/lockdown_mode.dart`
- `lib/core/security/models/violation_event.dart`
- `lib/core/security/violation_reporter.dart`
- `lib/core/security/lockdown_service.dart` only if the final adapter needs a
  narrowly scoped warning/audit change; do not add enforcement escalation
- `lib/core/security/violation_retry_coordinator.dart` (new) or the equivalent
  existing security lifecycle owner
- `lib/core/di/security_module.dart`
- `lib/core/storage/app_database.dart`
- `lib/core/storage/tables/local_violations_table.dart`
- `lib/core/storage/dao/local_violation_dao.dart`
- `lib/features/host_audit/domain/host_audit_types.dart`
- `lib/features/host_audit/data/models/host_audit_models.dart`
- `lib/features/host_audit/data/repositories/host_audit_repository_impl.dart`
- host-audit repository/model tests
- generated Drift files `app_database.g.dart` and `local_violation_dao.g.dart`
  regenerated by the repository command, never hand-edited
- `lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart`
- `lib/features/exam_attempt/domain/task_view.dart` only if the normalized
  policy response requires a type-safe contract change
- existing security/attempt tests and new reporter/audit contract tests
- `test_manual/lockdown_platform_test.md`

The existing `windows/runner/lockdown_plugin.cpp` and registration files are
not expected to change. Phase 5 will verify and rebuild them; they are not
replaced.

### `pte-doc`

- `projects/plans/quang-practice-anti-cheat-policy/` — this plan bundle
- `projects/architecture/ADR-011-practice-anti-cheat-policy.md` (Phase 5)

## 9. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Mode change resets or weakens policy | Resolve policy in one backend helper and test every mode/policy pair, including direct patch calls |
| Legacy null policy is confused with a new controlled session | Normalize legacy reads, persist explicit policy for new canonical drafts, and deploy backend before the new app |
| Patch null accidentally disables Practice anti-cheat | Use separate create, same-mode patch, mode-change patch, and policy-patch resolution paths; test that unrelated patches preserve STANDARD |
| Legacy PostLoad assigns the wrong lockdown default | Remove the mode-independent lockdown assignment and normalize with session mode before response and snapshot pin |
| Duplicate Flyway migration version blocks startup | Perform the Phase 3 history/file preflight, select a unique next version, run flyway validate before migrate, and never rename an applied script |
| Invalid app value silently becomes `NONE` | Replace unknown-value fallback with a startup/attempt error; only an explicitly normalized legacy default can become `NONE` |
| Student sends to proctor-only endpoint | Add a student-only attempt endpoint and change app transport; leave old proctor route untouched |
| Duplicate audit on retry | Require a client event ID and unique `(attempt_id, client_event_id)` constraint; test same payload twice |
| Student spoofs severity or identity | Derive tenant/student/attempt/policy/severity/timestamp on the server |
| Offline row never retries | Start a dedicated reporter retry coordinator from the existing connectivity canary and verify a periodic fallback |
| Old Windows binary hides the fix | Record build version/commit and reject manual evidence from a pre-change binary |
| Release accidentally includes dev auth bypass | Release checklist explicitly forbids `DEV_SKIP_AUTH` and checks the packaged configuration |
| Anti-cheat work changes exam semantics | Regression gate explicitly covers skills, retries, timer, navigation, generation, scoring and reporting |
| New host audit endpoint becomes a proctor redesign | Keep it additive and read-only; only adapt the existing audit reader/model as required |

## 10. Rollout and rollback

1. **Migration preflight:** inspect both migration files and
   flyway_schema_history in every target environment. If neither duplicate
   V68 has been applied, rename/resequence only the unapplied scripts
   according to repository chronology; if one is applied, preserve its exact
   filename/checksum and align the other unapplied script plus the new audit
   migration to the next unique version. Record the decision, then run
   flyway validate and a disposable local flyway migrate before any
   application rollout. Do not repair or rename an applied migration
   automatically.
2. **Backend additive release:** deploy policy validation/response changes and
   the student audit endpoint/migration. Verify health, migration completion,
   authorization, and legacy session reads. Do not enable any global strictness
   switch.
3. **Tenant web release:** release the Practice checkbox and policy review/detail
   display. Confirm unchecked Practice still sends `NONE` and Official sends
   `STRICT`.
4. **Desktop release:** build and distribute a new Windows release after the
   endpoint is available. Confirm the binary version and commit before testing.
5. **Canary walkthrough:** run one Practice `NONE`, one Practice `STANDARD`,
   and one Official `STRICT` session with authenticated accounts. Review local
   and host audit rows before wider use.
6. **Observation window:** monitor audit acceptance/rejection, duplicate
   acknowledgements, activation failures, and legacy-session fallback. No
   production enforcement change is inferred from a local debug run.

Rollback is additive: hide/disable the new UI checkbox and stop creating new
`STANDARD` Practice sessions, while keeping the backend endpoint and migration.
Do not remove the audit table or downgrade existing pinned attempts. If the new
app must be rolled back, retain the backend endpoint so unsent events from the
released client do not fail solely because of a server rollback.

## 11. Acceptance gates

### Gate A — policy contract

- All supported combinations of exam mode, requested policy, and missing policy
  (plus invalid permutations) are deterministic and tested.
- Official cannot become `NONE`/`STANDARD`; Practice cannot become `STRICT`.
- New canonical sessions persist a non-null policy and responses expose it.
- Existing legacy sessions remain readable with documented compatibility rules.

### Gate 0 — migration chain

- The duplicate V68 situation is documented against the actual
  flyway_schema_history of each target environment.
- No two migration files share a version after the preflight decision.
- The selected audit migration version passes flyway validate and a
  disposable local migrate before the application is started.

### Gate B — host configuration

- Practice-only checkbox maps to the correct enum and is visible in review.
- Exam detail shows the persisted policy, not only local form state.
- The UI cannot claim controlled enforcement when the response is `NONE`.

### Gate C — audit contract

- Authenticated student can record only their own attempt's event.
- Unauthenticated, wrong-student, wrong-tenant, invalid-type, and disabled-policy
  cases are rejected without a new audit row.
- Repeating the same `clientEventId` returns an idempotent receipt and exactly
  one row.
- Host read returns student and existing proctor entries without breaking the
  old proctor endpoint.
- Response is cursor-paged (default 50, max 100), and the 180-day retention
  policy is enforced by the daily soft-delete job.

### Gate D — student app

- Activation occurs before task 1 is rendered.
- `STANDARD` violations show the existing warning and remain warning/audit only.
- Local persistence precedes network delivery; offline/reconnect delivers once.
- Missing/unknown non-normalized policy blocks the attempt instead of falling
  back to `NONE`.

### Gate E — Windows release

- Fresh Windows release: Practice `NONE` is windowed and opens normally.
- Fresh Windows release: Practice `STANDARD` is fullscreen before task 1.
- A controlled activation failure blocks task opening and offers retry.
- Official `STRICT` retains existing strict behavior.
- Four violation cases and online/offline delivery are evidenced by local and
  host audit records.

## 12. Handoff

After the open planning questions are answered, the recommended implementation
command is:

```text
/ck:cook --hard --tests --quality --plan D:\GitHub\pte-org\pte-doc\projects\plans\quang-practice-anti-cheat-policy\plan.md
```

Current evidence is recorded in the phase-specific plans and reports. Phase 5
has built production and controlled-failure Windows artifacts, but no wider
rollout is claimed until the authenticated student matrix is executed.
