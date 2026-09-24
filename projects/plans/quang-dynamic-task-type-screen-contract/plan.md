# Follow-on Plan: Dynamic Task Type and Screen Contract

Status: Implemented; awaiting hard completion confirmation. Strict rollout
remains disabled pending authenticated walkthrough and operator review.
Date: 2026-09-22
Scope: pte-api + pte-web + pte-app + pte-doc
Plan type: Hard follow-on/superseding plan; the prior standard-runtime plan is
history and remains intact

## Scope challenge

Exists: yes. The question-type catalog, runtime profile table, score-template
editor, snapshot generation, attempt preflight, vendor-web form, and Flutter
task dispatcher already exist.

Mismatch: the current plan and implementation deliberately define the catalog
as the 23-value PteTaskType enum. The form therefore selects an existing
standard value, while this product request requires a new taskTypeKey that may
reuse an existing screen and runtime contract. This is a contract mismatch,
not a cosmetic modal defect.

Minimum viable change: add a logical string task-type identity and an
allowlisted screen contract while preserving the standard enum adapter. Reuse
existing runtime contracts wherever possible. Do not rewrite every task
renderer or scoring algorithm before the dynamic identity seam is proven.

Complexity: Hard. The change crosses persistence, question authoring, template
policy, runtime negotiation, snapshot/scoring provenance, three clients,
security, migration, and release ordering.

Tests: unit, integration, migration, widget/API, and cross-repository
authenticated walkthroughs are required.

Quality: mandatory ck:quality --gate for every phase.

## Objective

Enable Platform Admin or Platform Author to create a genuinely new task type by
entering a unique machine key and display metadata, selecting an existing
allowlisted screen contract, and using that task type in a custom template.
Preserve existing standard PTE behavior, API/table names, historical
snapshots, and tenant isolation. Make readiness and compatibility explicit so
an unsupported runtime contract blocks activation or delivery with an
actionable message.

## Prior plan and integration points

The completed/history plan is:

pte-doc/projects/plans/quang-task-type-catalog-template-runtime-contract/

Its phases established standard catalog seeding, versioned runtime profiles,
template approval/readiness, snapshot capability fields, Flutter no-silent-skip
behavior, scoring seams, friendly errors, and deployment checks. This plan
must:

- reuse /api/v1/question-types and question_types;
- preserve the 23 standard enum aliases and the 22-scored-task validator;
- extend, not discard, task_runtime_profiles, snapshot runtime fields,
  preflight, and existing error/message conventions;
- remove the standard-only restriction only after the dynamic compatibility path
  is implemented and tested;
- avoid reimplementing approval, session orchestration, or existing screens.

## Current evidence

| Area | Current evidence | Planning consequence |
|---|---|---|
| Catalog entity | pte-api/app/src/main/java/com/pte/itembank/domain/QuestionTypeDefinition.java stores code, section, labels, requirements, and active state. | Extend the existing table/model; do not create a competing catalog API. |
| Catalog service | QuestionTypeService.create calls TaskTypeCodeCompatibility.requireCanonicalCode and derives metadata from PteTaskType. | Create must accept a logical key and resolve requirements from a capability contract. |
| Question identity | Question.java, ItembankService.java, QuestionValidationHelper.java, repository projections, and QuestionFreezeView use PteTaskType. | Add taskTypeKey with a standard enum adapter and migrate reads/queries. |
| Runtime | TaskRuntimeProfileRegistry.java is an EnumMap; TaskRuntimeProfileService.java validates enum-backed descriptors. | Resolve profiles by logical key and screen contract while retaining standard adapters. |
| Templates | ScoreTemplateActivationValidator.java hard-codes 22 scored codes; ScoreTemplateItem.java already stores runtime pins. | Add templatePolicy; keep the standard rule and add custom validation. |
| Snapshot/generation | SnapshotPublishService.java, ExamGenerationService.java, SnapshotItem.java, and PinnedItem.java resolve by enum/task code. | Resolve by task key and pin complete contract, scoring, and label provenance. |
| Scoring | ObjectiveScoringService.java, AnswerPayloadDecoder.java, AiScoringDispatcher.java, and ScoringProfileRegistry.java route by task code/profile. | Make behavior/scoring profile the canonical dispatch seam; standard maps remain adapters. |
| Flutter | pte-app/lib/core/constants/task_type_meta.dart and task_type_dispatcher.dart route by task type; client_capability_manifest.dart already sends semantic capabilities. | Resolve renderers by screen/contract key and use snapshot metadata for custom labels. |
| Vendor web | QuestionTypeEditorModal.tsx filters supportedTypes and says all standard types already exist. | Replace the standard-only form with free key/name plus capability selection and lock/readiness UX. |

## Explicit decisions

### Identity and normalization

- taskTypeKey is the canonical machine identity. Accept user input, trim,
  apply Unicode NFKC, remove surrounding Unicode whitespace, normalize to
  uppercase with Locale.ROOT, and validate ^[A-Z][A-Z0-9_]{1,63}$. The
  normalized value is the only value used for uniqueness and persistence.
- Store taskTypeKey separately from compatibility code. Existing standard rows
  initially contain the same canonical value in both. A custom task never gets
  projected into an enum-valued legacy field; it is exposed through the new
  task-type contract only.
- taskTypeKey is hard unique, immutable from creation, and never reusable after
  a row is retired or published.
- Normalize display names with Unicode NFKC, convert every Unicode whitespace
  run to one ASCII space, trim, and lowercase with Locale.ROOT. Validate the
  normalized value after the 128-character limit and persist it in a globally
  unique normalized column. The uniqueness applies to active, inactive, and
  retired rows; names are never silently reusable. DisplayName is not identity.
- shortName is required and bounded but is not the machine identity.

### Runtime contract

The admin chooses only screenKey and a contract version from an allowlist. The
server resolves and persists screenKey, contract/profile version, behaviorKey,
rendererKey, answerSchemaVersion, scoringProfileKey/version,
requiredClientCapabilities, minimum app version, and lifecycle status.

No API accepts Java/Dart class names, scripts, arbitrary JSON formulas,
uploaded code, or client-provided scoring implementation.

### Template policy

- STANDARD_PTE keeps the existing 22-task completeness, structural, weight,
  count, and approval rules.
- CUSTOM validates that selected active task keys are unique, section-valid,
  runtime-resolvable, and question-bank-ready; it does not require all 22
  standard tasks. Common structural rules still apply. Scored status and the
  scoring profile come only from the selected runtime contract: scored items
  require an active scoring profile, unscored items must have zero score
  weight, and a score-producing custom template must contain at least one
  scored item. Mixed scored/unscored templates are valid. `scoringMode` is
  `SCORED` or `NONE`; `NONE` always uses scoring profile `NONE/V1`. Every
  weight is 0.00–100.00 with at most two decimals. For each skill column with
  a positive scored weight, the scored total is exactly 100.00; an
  unrepresented skill totals 0.00. Overall weights only require a positive
  total for a score-producing template and have no fixed-total rule. An
  all-unscored CUSTOM template is rejected with
  TEMPLATE_NO_SCORED_TASKS; a future delivery-only mode is outside this plan.
- The request must state the policy. Do not infer CUSTOM from an unknown key.

### Publication lock

At first publication or activation of any template containing a task type,
write an append-only usage record and mark the task type runtime binding as
historically used. Thereafter lock screenKey, contract/profile version, section,
derived behavior/scoring/schema fields, and the runtime binding. Archive,
retire, reject, or unpublish never clears usage. Labels, shortName, and
displayOrder remain editable only because snapshots contain old values.

Backend enforces the lock and returns HTTP 409 with structured details; web
disables fields and shows the same reason.

## Target domain and persistence contract

### Task type definition

Keep question_types as the compatibility table and add:

    task_type_key                 VARCHAR(64) NOT NULL UNIQUE
    normalized_display_name       VARCHAR(128) NOT NULL UNIQUE
    screen_key                    VARCHAR(96) NOT NULL
    runtime_profile_key           VARCHAR(96) NOT NULL
    runtime_profile_version       INTEGER NOT NULL
    runtime_behavior_key          VARCHAR(64) NOT NULL
    runtime_renderer_key          VARCHAR(96) NOT NULL
    runtime_answer_schema_version INTEGER NOT NULL
    runtime_scoring_profile_key   VARCHAR(64) NOT NULL
    runtime_scoring_profile_version INTEGER NOT NULL
    runtime_scoring_mode          VARCHAR(16) NOT NULL
    runtime_required_capabilities TEXT[] NOT NULL DEFAULT '{}'
    runtime_min_app_version       VARCHAR(32)
    authoring_contract_key        VARCHAR(96) NOT NULL
    authoring_contract_version    INTEGER NOT NULL
    lifecycle_status              VARCHAR(16) NOT NULL
    first_published_at            TIMESTAMPTZ NULL
    runtime_locked_at             TIMESTAMPTZ NULL

Existing code, display_name, section, scored, active, ordering,
authoring-requirement columns, soft-delete, and public IDs remain readable.
code remains a non-null storage/compatibility alias equal to taskTypeKey for
new rows, but the legacy question-types projection returns standard rows only.
New clients use taskTypeKey; legacy enum-valued projections must never contain
a custom key.

### Capability registry

Add a canonical registry with unique screen_key plus contract_version:

    screen_key
    contract_version
    profile_key
    behavior_key
    renderer_key
    answer_schema_version
    scoring_profile_key
    scoring_profile_version
    scoring_mode (NONE for unscored contracts)
    required_client_capabilities TEXT[]
    authoring_contract_key
    authoring_contract_version
    min_supported_app_version
    status ACTIVE or RETIRED

Multiple task types may bind to one row. Existing task_runtime_profiles rows
remain an adapter/projection for standard codes and are validated against the
canonical registry. The registry is code/release-owned and seeded by Flyway;
Platform Admin may activate or retire a seeded contract but cannot create or
edit renderer/scorer/schema/authoring behavior in the UI. App manifests
are compatibility claims used at preflight, not the authority for scoring.
Semantic versions use strict major.minor.patch comparison; malformed versions,
duplicate capability tokens, or arrays over the declared limit are rejected.

The authoring contract is versioned and allowlisted. It describes the existing
question-authoring requirements (prompt text, audio, image, options, correct
answer, word count, and ordered/single-choice behavior). Requirement flags are
derived from this contract and are never trusted from a create/update request.

### Template and snapshot contract

Template items retain legacy taskType for standard rows and add/use canonical
fields. For custom rows legacy taskType is null; taskTypeKey is required:

~~~json
{
  "taskType": null,
  "taskTypeKey": "READ_ALOUD_PLUS",
  "taskTypeDisplayName": "Read Aloud Plus",
  "section": "SPEAKING",
  "screenKey": "READ_ALOUD_V1",
  "contractVersion": 1,
  "runtime": {
    "profileKey": "PTE.READ_ALOUD",
    "behaviorKey": "RECORD_RESPONSE",
    "rendererKey": "READ_ALOUD_V1",
    "answerSchemaVersion": 1,
    "scoringProfileKey": "AI_SPEECH",
    "scoringProfileVersion": 1,
    "scoringMode": "SCORED",
    "requiredClientCapabilities": ["AUDIO_RECORDING"]
  }
}
~~~

At publish/snapshot time, copy task key, display label, screen/contract pin,
scoring provenance, and capability requirements into snapshot_items and
pinned_items. New snapshots must be complete; old rows remain readable through
existing nullable compatibility fields.

## API contract

### Compatibility catalog APIs

Keep these legacy standard-only compatibility APIs unchanged for existing
clients:

- GET /api/v1/question-types?activeOnly=false
- GET /api/v1/question-types/supported
- GET /api/v1/question-types/{publicId}
- POST /api/v1/question-types
- PUT /api/v1/question-types/{publicId}
- DELETE /api/v1/question-types/{publicId}, as a soft-retire adapter

Add the canonical dynamic catalog APIs:

- GET /api/v1/task-types?activeOnly=true&cursor=...&limit=...
- GET /api/v1/task-types/{publicId}
- POST /api/v1/task-types
- PUT /api/v1/task-types/{publicId}
- DELETE /api/v1/task-types/{publicId}, as a soft-retire adapter

The legacy question-types list/detail endpoints return standard rows only and
retain enum-safe code/taskType fields. A legacy request that names a custom
key is rejected with a compatibility error; it is never echoed into an enum
field. The new task-types endpoints return all rows using taskTypeKey. The
platform catalog is bounded by a documented maximum and also supports cursor
and limit pagination.

Additive create request:

~~~json
{
  "code": "READ_ALOUD_PLUS",
  "taskTypeKey": "read_aloud_plus",
  "displayName": "Read Aloud Plus",
  "shortName": "RA+",
  "section": "SPEAKING",
  "screenKey": "READ_ALOUD_V1",
  "contractVersion": 1,
  "displayOrder": 24,
  "active": true
}
~~~

taskTypeKey and screenKey are required for the new task-types API. The legacy
question-types POST remains valid only for a standard compatibility value. The
server ignores client-supplied behavior/scoring/authoring fields and derives
them from the selected registry contract.

Response additions include taskTypeKey, screenKey, readiness, and editability:

~~~json
{
  "legacyCode": null,
  "taskTypeKey": "READ_ALOUD_PLUS",
  "displayName": "Read Aloud Plus",
  "section": "SPEAKING",
  "runtime": {
    "screenKey": "READ_ALOUD_V1",
    "contractVersion": 1
  },
  "readiness": {
    "serverReady": true,
    "clientSupport": "MANIFEST_REQUIRED",
    "issues": []
  },
  "editability": {
    "taskTypeKey": false,
    "runtimeFields": true,
    "displayMetadata": true,
    "lockedReason": null
  }
}
~~~

### Capability, availability, and preflight APIs

- GET /api/v1/task-type-capabilities?activeOnly=true&cursor=...&limit=...
  lists selectable semantic contracts for platform roles. It never exposes
  implementation classes.
- GET /api/v1/task-types/availability?taskTypeKey=...&displayName=...&excludePublicId=...
  returns field-level normalized availability without unrelated owner data.
- Extend POST /api/v1/attempts/preflight with appVersion, capabilities, and
  runtimeContracts containing screenKey, contractVersion, rendererKey,
  answerSchemaVersions, and scoringProfileVersions.

Preflight returns canStart, missingCapabilities, and unsupportedTasks with
taskTypeKey, screenKey, contractVersion, reasonCode, and a user-facing
update/configuration message. Unsupported tasks are a start/delivery blocker,
never a next-task condition.

### Error contract

Use stable codes and friendly messages:

    TASK_TYPE_KEY_INVALID
    TASK_TYPE_KEY_ALREADY_USED
    TASK_TYPE_DISPLAY_NAME_ALREADY_USED
    TASK_TYPE_CAPABILITY_NOT_FOUND
    TASK_TYPE_RUNTIME_LOCKED
    TEMPLATE_RUNTIME_NOT_READY
    TEMPLATE_STANDARD_TASK_TYPES_MISSING
    APP_CAPABILITY_MISSING
    UNSUPPORTED_RUNTIME_CONTRACT

Example 409:

~~~json
{
  "code": "TASK_TYPE_RUNTIME_LOCKED",
  "message": "This task type is used by a published template, so its runtime screen and scoring contract cannot be changed.",
  "details": {
    "taskTypeKey": "READ_ALOUD_PLUS",
    "lockedFields": ["screenKey", "section", "runtimeContract"],
    "firstPublishedAt": "2026-09-22T10:00:00Z",
    "publishedTemplateCount": 1
  }
}
~~~

## Lifecycle and migration posture

Task type lifecycle is ACTIVE -> INACTIVE -> ACTIVE before publication, with
RETIRED as a soft terminal catalog state. Retired rows remain readable for
questions, snapshots, and audit history but are blocked for new authoring and
templates. Retired keys are never reused.

Retain the existing template lifecycle:
DRAFT -> PENDING_APPROVAL -> ACTIVE -> RETIRED, with Platform Author creating,
editing, and submitting and Platform Admin approving, returning, activating,
and retiring.

Backfill standard rows with taskTypeKey = code. In the additive migration,
first add nullable task_type_key columns to questions, snapshot_items, and
pinned_items, backfill all existing standard rows from the legacy enum/code
using the single compatibility mapper, verify there are no unresolved values,
then make task_type_key non-null. Only after that do the legacy
questions.pte_task_type, snapshot_items.pte_task_type, and equivalent pinned
enum columns become nullable so custom rows can leave them null. Phase 8 adds
remaining provenance fields; it must not postpone the task-key backfill.
New standard rows dual-write both values; custom rows write only the logical
key and leave legacy enum fields null behind an explicit adapter. Legacy
enum-only APIs project standard rows only and return a friendly compatibility
error for custom requests. The canonical task-types/question APIs carry custom
keys explicitly.

Migrations are additive and forward-only. Rollback disables custom creation or
activation by feature flag and retains additive data; it never drops columns or
rewrites published snapshots.

## Dependency graph

~~~text
Phase 1 domain/compatibility contract
  -> Phase 2 additive database/model migration
       -> Phase 3 capability registry and dynamic runtime resolver
            -> Phase 4 dynamic catalog API, ownership, availability, lock
                 -> Phase 5 question-bank logical task identity
                      -> Phase 6 template policy and readiness
                           -> Phase 7 pte-app screen dispatch and manifest
                                -> Phase 8 generation, snapshots, scoring
                                     -> Phase 10 rollout/observability/ADR
Phase 4 + Phase 6 DTOs + Phase 8 snapshot/runtime DTOs
  -> Phase 9 vendor-web task-type and template UX
Phase 5 + Phase 6 + Phase 7 + Phase 8 + Phase 9
  -> Phase 10 cross-repo verification and strict-enforcement rollout
~~~

The app registry/manifest work can start after the contract is frozen, but
activation enforcement waits for the server registry and app compatibility
path.

## Cross-cutting design constraints

- Use public module services/facades across the modular monolith.
- Keep platform task catalog and runtime registry separate from tenant content.
- Never store implementation classes, source paths, secrets, scripts,
  arbitrary formulas, correct answers, or future exam content in a runtime
  contract.
- Resolve profiles in batches and snapshot them; do not query a registry per
  question during delivery.
- Centralize messages in owning Java Constants classes, web constants, and
  Flutter string constants. Raw codes are telemetry identifiers, not primary
  UI messages.
- Preserve no-content-before-open and tenant-scoping rules.
- A missing capability is terminal with recovery instructions.
- Publication usage is owned by itembank. Scoretemplate activation calls the
  public itembank usage service in the same transaction; the usage table has a
  unique (task_type_key, template_version_id) constraint so retries are
  idempotent and publication/edit races cannot bypass the lock.
- Audit actor, role, task key, before/after contract values, correlation ID,
  and result; never answer payloads or secrets.

## Phases

- [x] Phase 1 — Domain contract, compatibility policy, and ADR delta
- [x] Phase 2 — Additive schema and model migration
- [x] Phase 3 — Capability registry and dynamic runtime resolver
- [x] Phase 4 — Dynamic task-type API, uniqueness, ownership, and locks
- [x] Phase 5 — Question-bank logical task identity
- [x] Phase 6 — Template policy, composition, and readiness enforcement
- [x] Phase 7 — pte-app screen registry, manifest, and unsupported state
- [x] Phase 8 — Generation, snapshot provenance, scoring, and history
- [x] Phase 9 — Vendor-web authoring and template readiness UX
- [x] Phase 10 — Rollout, audit/metrics, compatibility verification, and ADR handoff

## Red-team and risk register

| Risk | Severity | Required mitigation/proof |
|---|---:|---|
| Custom key reaches enum-only query or switch | BLOCKER | Task-key tests for create, list, count, random, freeze, generate, score, and delivery; enum remains only a standard adapter. |
| Case/whitespace duplicates bypass uniqueness | HIGH | Normalized columns plus DB unique indexes; concurrent insert test and 409 mapping. |
| Same screen duplicated per task key | HIGH | Registry keyed by screen/contract; task key is metadata. Test two custom keys resolving to one renderer. |
| Database claims unsafe renderer/scorer | BLOCKER | Server allowlist, immutable versions, platform-only writes, activation/preflight validation. |
| Backend pretends to scan an installed app | HIGH | Registry readiness plus manifest preflight; document limitation. |
| Standard validator weakened | HIGH | Isolated STANDARD_PTE policy with exact 22-task tests. |
| Published history changes | BLOCKER | Snapshot/pinned-item provenance after label, contract, and retirement changes. |
| Retirement unlocks runtime fields | BLOCKER | Append-only publication usage and ACTIVE -> RETIRED regression test. |
| Flutter silently skips unsupported task | BLOCKER | Terminal unsupported state and state-machine test; no default next transition. |
| Legacy field removed too early | HIGH | Fixture, dual-read/dual-write, API contract tests, staged release. |
| Availability endpoint leaks internals | MEDIUM | Platform-role security tests and field-level responses only. |
| Registry joins slow delivery | MEDIUM | Batch resolution, denormalization, query-count/performance checks. |

## Out of scope

- Tenant-authored executable scoring formulas or scoring code.
- Dynamic Dart/Java loading, uploaded renderer scripts, or APK/IPA inspection.
- New behavior without a coordinated backend and pte-app release.
- Deleting or renaming the 23 standard enum adapters.
- Rebuilding existing PTE screen implementations.
- Changing subscription, overlap, session, or commercial policy.
- Guessing mappings for unknown historical task codes.
- Production migration or deployment in this planning turn.

## Completion acceptance

- Custom key and display name use normalized hard uniqueness with friendly 409
  race handling.
- Create form selects an allowlisted screen contract and accepts no executable
  behavior or scoring formula.
- Two custom keys can reuse one existing screen/profile without pte-app code.
- Standard and custom template policies coexist; standard 22-task activation
  remains green.
- Draft readiness diagnostics are complete and activation blocks with all
  actionable issues.
- Questions, snapshots, pinned attempts, answer decoding, and scoring resolve
  from task key/profile rather than enum-only branching.
- Published use permanently locks runtime fields, including after retirement.
- Historical labels and scoring provenance remain unchanged after edits.
- pte-app manifest/preflight and unsupported screen state are implemented.
- Security, audit/metrics, compatibility adapters, migration verification, and
  friendly errors are covered.
- Every phase has focused tests and a passing mandatory ck:quality --gate.

## Verification handoff

All ten phases are implemented and have an approved quality receipt plus a
test report under `quality/` and `tests/`. The final automated gates are:

- Backend: clean compile and 786 tests passed with 0 failures, errors, or
  skips.
- Vendor web: API client 273 tests passed; TypeScript, lint, and production
  build passed. Lint retains one existing `<img>` optimization warning.
- Flutter: analyze passed and 553 tests passed.
- Diff hygiene: `git diff --check` passed in all three source repositories.

Authenticated browser walkthrough and production metrics/audit inspection are
explicitly pending approved credentials/operator authorization. The rollout
flags remain off by default; no production deployment, data mutation, commit,
or push was performed.

After review, run:

~~~text
/ck:cook --hard --tests --quality --checks-all-phases D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\plan.md
~~~

The cook run outcomes are recorded in each phase's Quality and Testing State
section and in the corresponding quality/test artifacts.
