# Quang host exam app preview — Phase 2 contract

Date: 2026-10-29
Plan: `quang-host-exam-app-preview`
Scope: additive read-only preview contract and implementation verification.

## Existing endpoint and authorization

`GET /api/v1/sessions/{sessionPublicId}/exam-preview` is already exposed by
`SessionController` under `@PreAuthorize("hasRole('HOST_ADMIN')")` and returns
the shared `ApiResponse<ExamPreviewResponse>` envelope. The service calls
`SessionLifecycleService.findOwned(sessionPublicId, caller)`, so the request
must remain tenant-scoped to the authenticated caller. The client may use the
existing session list/detail GET routes, but must never generate, publish, open,
close, cancel, create an attempt, or submit an answer for preview.

`session.getExamVersionPublicId() != null` is the authoritative readiness check.
If it is absent, the service returns the existing `GenerationNotReadyException`
(`409`, code `EXAM_GENERATION_NOT_READY`); the app must show a common error and
keep the preview action disabled for a draft without a snapshot.

## Response envelope and nullability

The response remains additive and answer-stripped. Existing fields keep their
current wire names and meaning:

| Path | Type / nullability | Contract |
|---|---|---|
| `data.snapshotPublicId` | UUID, required | Frozen snapshot identity; app key includes this value. |
| `data.name` | string, required by current DTO | Snapshot display name. |
| `data.version` | integer, required | Frozen snapshot version. |
| `data.items` | array, required and ordered | Do not reorder or deduplicate. |
| `data.items[].snapshotItemPublicId` | UUID, required (new) | Maps from `SnapshotContentResponse.Item.itemPublicId`; stable within the same snapshot. |
| `data.items[].orderIndex` | integer, required | Presentation order; not a cross-snapshot response key. |
| `data.items[].section` | string, required | Existing section value. |
| `data.items[].taskType` | string, required for existing data | Existing display/legacy task type. |
| `data.items[].taskTypeCode` | string, required | Canonical task code used for registry lookup. |
| `data.items[].taskTypeKey` | string, required for canonical runtime items | Additive runtime identity; legacy mapping must be explicit, not guessed. |
| `data.items[].taskTypeDisplayName` | string, nullable only for legacy source | Preserve current fallback behavior if the source has no display name. |
| `data.items[].title` | string, nullable as current source permits | Prompt title. |
| `data.items[].promptText` | string, nullable as current source permits | Prompt content. |
| `data.items[].audioUrl` | string, nullable | Signed GET URL only; never an upload URL. |
| `data.items[].audioUrlExpiresAt` | UTC ISO instant, nullable | Present when the signing response has a positive expiry. |
| `data.items[].imageUrl` | string, nullable | Signed GET URL only. |
| `data.items[].imageUrlExpiresAt` | UTC ISO instant, nullable | Present when the signing response has a positive expiry. |
| `data.items[].minWordCount` / `maxWordCount` | integer, nullable | Preserve current writing constraints. |
| `data.items[].options` | array, required, may be empty | Preserve source order and all labels. |
| `data.items[].options[].orderIndex` | integer, required | Original option order. |
| `data.items[].options[].blankIndex` | integer, nullable | Preserve grouped blank position. |
| `data.items[].options[].text` | string, required | Never include correctness metadata. |
| `data.items[].runtime` | object, required for canonical allowlisted items; nullable only for explicit legacy mapping | Runtime metadata needed by the existing registry; it is not an answer key. |
| `data.items[].runtimeMappingVersion` | string, required for canonical items; legacy value otherwise | Must be validated against the existing runtime contract. |
| `data.items[].runtimeMappingStatus` | string, required for canonical items; legacy value otherwise | Must be validated before dispatch. |
| `data.items[].prepSeconds` | integer, required after resolver succeeds | Resolved preparation budget; no guessed 30/40-second fallback. |
| `data.items[].responseSeconds` | integer, required after resolver succeeds | Resolved response budget. |
| `data.items[].preListenSeconds` | integer, nullable | Required only for audio-prompt speaking types. |
| `data.items[].preRecordSeconds` | integer, nullable | Required only where the runtime contract has a record preparation phase. |
| `data.items[].audioDurationSeconds` | integer, nullable | Required for audio-prompt timing calculation when audio exists. |
| `data.items[].sourceQuestionPublicId` | UUID, nullable | Provenance only; never use as the RAM response key. |

The response must never serialize `referenceAnswerText`, `correctAnswerText`,
option correctness flags, scoring profiles, or other secret answer metadata.
The app response key is `(snapshotPublicId, snapshotItemPublicId)`.

## Timing and content source

`AssessmentService.resolveExamItems` now owns the shared read-only resolver. It
loads the pinned definition and shared task timing resource, validates the
runtime contract, signs media with a 300-second TTL, and returns a trusted
in-process `ResolvedExamItemResponse`. `ExamItemLoader` adapts that result to
the answer-bearing attempt cache view; `SessionExamPreviewService` adapts it
to the answer-free host DTO. The session module has no `attempt.internal`
dependency.

The student and host paths resolve timing from the exam definition referenced
by the snapshot plus `TaskTimingConfig`, with special audio-speaking preparation:

```text
prepSeconds = preListenSeconds + actual audio duration + preRecordSeconds
```

The implementation must extract a read-only resolver/facade owned by an
appropriate public assessment boundary and adapt both the student loader and
host preview to it. The session module must not import package-private
`attempt.internal` classes. Preserve current student timing and section-budget
semantics; do not silently fix legacy definition-version behavior. If the
referenced definition version can be loaded, use the same pinned source for
both callers and document any remaining discrepancy in the implementation
report.

Required media/timing failures remain typed/common errors. Existing relevant
codes are `MISSING_AUDIO_PROMPT`, `MISSING_AUDIO_DURATION`,
`MISSING_IMAGE_PROMPT`, `TASK_TIMING_NOT_CONFIGURED`, and
`EXAM_CONFIGURATION_NOT_COMPATIBLE`; do not replace missing media with fixture
content or guessed timings. An expired signed URL may be re-fetched once by the
app after validating the same snapshot; no infinite retry is allowed.

## Role and tenant matrix

| Caller | Session list/preview | Allowed session states | Required behavior |
|---|---:|---|---|
| `HOST_ADMIN`, own tenant | yes | `READY`, `SCHEDULED`, `OPEN`, `CLOSED`, `CANCELLED` when snapshot exists | Host preview only; no write side effects. |
| `HOST_ADMIN`, own tenant, `DRAFT` without snapshot | list yes / preview no | none | Disabled UI action; direct GET returns common not-ready error. |
| `HOST_ADMIN`, other tenant ID | no data | none | Existing not-found/forbidden tenant policy; no leak. |
| `HOST_ADMIN + STUDENT` | yes | same as host | Explicit host-preview context; never route into student attempt from host home in v1. |
| `STUDENT` | denied by server/client boundary | none | Existing student flow and security enforcement unchanged. |
| `PROCTOR`, `EXAMINER`, platform-only | denied by this client | none | Existing access-denied behavior. |
| unauthenticated/forged role | denied | none | `401/403`; no preview content. |

## Notification recipient decision

The current `ExamSession`/`BaseEntity` model has no `createdBy`. The recipient
is therefore the authenticated `HOST_ADMIN` actor that successfully performs
the first `DRAFT -> READY` generation in that tenant. The event must carry the
actor public ID, session/snapshot identifiers, code/name, tenant ID and
occurred-at value. It must not invent a creator lookup or add a creator column
for this feature.

## Verification anchors

- Contract test proves the new fields serialize and secret answer fields do not.
- `HostExamPreviewReadOnlyTest` proves the endpoint envelope includes stable
  identity/timing/options and excludes answer keys; it also verifies no status
  mutation calls are made.
- Existing `SessionLifecycleService.findOwned` remains the tenant/role
  ownership boundary; controller authorization remains `HOST_ADMIN`.
- `ExamItemRuntimeResolverTest` and the existing `ExamItemLoaderTest` compare
  the host/student resolver inputs,
  including audio duration and definition/config fallback.
- Existing app security/auth baseline in the Phase 1 preflight report passed:
  49 mocked unit/widget tests, all exit 0.

## Phase 2 verification

| Check | Result |
|---|---:|
| `mvnw.cmd -pl app -DskipTests compile` | PASS, exit 0 |
| Focused resolver/preview/timing tests | PASS, 53 tests, exit 0 |
| Timer/Assessment regression tests | PASS, 11 tests, exit 0 |
| `pnpm --filter @pte/api-client typecheck` | PASS, exit 0 |
| `pnpm --filter tenant-web typecheck` | PASS, exit 0 |
| `pnpm --filter vendor-web typecheck` | PASS, exit 0 |
