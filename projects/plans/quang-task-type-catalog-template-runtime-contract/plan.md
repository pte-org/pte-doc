# Plan: Task-Type Catalog, Versioned Template and Runtime Contract

Status: Ready for implementation — decisions confirmed; local data greenfield
Date: 2026-09-22
Scope: pte-api + pte-web + pte-app + pte-doc
Plan type: Follow-on architecture and compatibility plan; it does not replace or overwrite completed plans.

## Scope challenge

    Exists?     Yes. The current Question Type catalog, score-template editor,
                ExamSnapshot and pte-app dispatcher already exist.
    Minimum?   Add the missing versioned runtime contract and compatibility seams;
               do not rebuild the question bank, exam generator or task screens.
    Complexity? Hard. The change crosses database migrations, modular boundaries,
                API compatibility, template lifecycle, exam snapshots, scoring,
                vendor-web and Flutter delivery.
    Mode:       Hard
    Tests:      Unit tests required for every phase.
    Quality:    Mandatory ck:quality gate for every phase.

This plan is the follow-on for the implemented
quang-question-type-template-admin work. It integrates the existing
phat-score-template-exam-generation, quang-core-question-bank-exam-orchestration
and quang-exam-ui-design-system decisions instead of reimplementing them.

## Objective

Make a PTE task type a stable, data-driven product contract:

1. The existing question_types table and /api/v1/question-types endpoint
   remain compatibility surfaces, but their meaning is made explicit: they are
   a standard PTE task-type catalog, not an arbitrary question-type factory.
2. Standard catalog onboarding is complete and idempotent for all 23 supported
   PTE codes, including unscored PERSONAL_INTRODUCTION, without overwriting
   administrator-curated labels, order or availability.
3. A template can configure count, order, timing and weights for an existing
   supported task type without a pte-app deployment. Activated template versions
   are immutable.
4. A genuinely new interaction or scoring behavior is represented by an
   allowlisted, versioned runtime profile and requires coordinated BE and
   pte-app work.
5. Generated exams and attempts pin template, task behavior, renderer, schema
   and scoring versions. Retiring a catalog row or activating a new template
   cannot change an old exam.
6. A client that cannot render a pinned task is stopped with an actionable,
   user-friendly update message. It is never silently sent to the next task.

## Current data posture

The system is still in the coding phase and there is no business data that
needs to be preserved or transformed. Treat the local database as greenfield:
add a clean, idempotent standard-catalog seed and avoid destructive cleanup or
an elaborate real-data backfill. Compatibility is still required at the
API/code boundary because the endpoint/table already exist and the V40 code
mismatch must be safe. Legacy rows and old snapshots are covered with
fixtures/read adapters; a real-data migration is conditional on finding such
rows during verification.

## Confirmed decisions

- The canonical standard vocabulary is PteTaskType; arbitrary codes are out
  of MVP because Question.pteTaskType, validation and scoring are enum-backed.
- Keep /api/v1/question-types, its existing request/response compatibility and
  question_types during the migration. Add optional runtime fields rather than
  breaking old clients.
- Canonical persisted codes are the current enum names after migration V40:
  FILL_IN_THE_BLANKS_DROPDOWN,
  FILL_IN_THE_BLANKS_DRAG_AND_DROP and
  FILL_IN_THE_BLANKS_TYPE_IN. Old FILL_BLANKS_* values may be read through
  a compatibility adapter, but new rows and canonical `taskTypeCode` fields
  must use canonical codes. The existing `taskType` wire field is not changed
  until the app compatibility release is available; the additive `taskTypeCode`
  is preferred by new clients.
- The catalog contains 23 standard codes: 22 scored types plus unscored
  PERSONAL_INTRODUCTION. An active score template requires the 22 scored
  types; speaking generation may add Personal Introduction as already defined
  by the existing template plan.
- Platform Author may create, edit and submit a template. The current backend
  represents “submitted” as `PENDING_APPROVAL`; Platform Admin may approve,
  reject/return to `DRAFT`, activate and retire it. Drafts are editable;
  `PENDING_APPROVAL`, active and retired versions are not edited in place. A
  correction is made by cloning a new draft; this plan does not add a new
  `SUBMITTED` enum or API state.
- Template and snapshot data are platform-owned. Tenant/host users may consume
  active, compatible templates but cannot create arbitrary task behavior or
  change platform scoring contracts.
- The database may store stable keys and version numbers, but never Java class
  names, Dart class names, scripts, executable expressions or scoring formulas.
- Configuration-only changes use an existing runtime profile. New interaction,
  answer schema, validation rule, media protocol or scoring algorithm requires
  BE and pte-app implementation and a new immutable profile version.

## Current evidence and compatibility gaps

| Area | Evidence | Planning consequence |
|---|---|---|
| Standard vocabulary | PteTaskType contains 23 values; Question stores it as EnumType.STRING. | Do not accept arbitrary catalog codes in MVP. |
| Catalog | QuestionTypeDefinition stores labels, section, active state and authoring flags; QuestionTypeService parses PteTaskType.valueOf. | Preserve endpoint/table and add a lifecycle/profile layer around the enum. |
| V40 | The backend migration renamed the three FILL_BLANKS_* values, while pte-app still contains legacy names. | Normalize app constants, dispatcher, fixtures and tests; retain read compatibility for old data. |
| Onboarding | V37 intentionally did not seed the catalog; an incomplete local catalog produces an empty template dropdown. | Add an idempotent standard backfill that inserts missing rows only. |
| Templates | ScoreTemplateItem keeps taskType/section as strings, and activation validates all 22 scored types. | Keep module boundaries, but pin a runtime profile on template items. |
| Snapshots | ExamSnapshot/SnapshotItem pin template/task type and question data, but not renderer or scoring behavior versions. | Add immutable provenance fields and optional API metadata. |
| pte-app | TaskTypeMeta covers 23 types and TaskTypeDispatcher switches on task type. | Extend this seam into a registry keyed by stable renderer keys; do not replace screens. |
| Errors | Raw machine codes can reach user-facing surfaces. | Centralize friendly messages in owning Constants.java, web constants.ts or app string constants. |

## Target contract

Each supported task type resolves to an immutable runtime profile, conceptually:

    taskTypeCode          READ_ALOUD
    behaviorKey           READ_ALOUD
    rendererKey           READ_ALOUD_V1
    schemaVersion         1
    scoringProfileKey     AI_SPEECH
    scoringProfileVersion 1
    requiredCapabilities  AUDIO_PLAYBACK, AUDIO_RECORDING
    status                ACTIVE | RETIRED

rendererKey, behaviorKey, capability names and scoring profile keys are
allowlisted in BE and pte-app registries. A row in the database can select a
known version; it cannot invent an implementation.

The existing API remains usable. New fields are additive and optional for
legacy clients:

    {
      "taskType": "READ_ALOUD",
      "taskTypeCode": "READ_ALOUD",
      "runtime": {
        "behaviorKey": "RECORD_RESPONSE",
        "rendererKey": "READ_ALOUD_V1",
        "answerSchemaVersion": 1,
        "scoringProfileKey": "AI_SPEECH",
        "scoringProfileVersion": 1,
        "requiredCapabilities": ["AUDIO_PLAYBACK", "AUDIO_RECORDING"]
      }
    }

The task type string remains in all existing response shapes. `runtime` is the
single nested JSON shape for new snapshot/task responses; it is optional/null
only for legacy catalog/task responses during migration. A new app prefers
`taskTypeCode` and `runtime`; it falls back to `taskType` plus the shared alias
mapper when those fields are absent. New snapshots must never have a null
runtime contract.

## Lifecycle and compatibility rules

### Catalog

ACTIVE -> INACTIVE -> ACTIVE is allowed for an unused standard type.
ACTIVE/INACTIVE -> RETIRED is a soft retirement. Retired rows remain readable
for questions, snapshots and audit history but are excluded from new authoring
and template activation. The old delete endpoint maps to retirement while
retaining its response contract. Explicitly existing inactive/retired values are
never re-enabled by a backfill.

### Template

    DRAFT -> PENDING_APPROVAL -> ACTIVE -> RETIRED
      \-> DRAFT (admin reject/return before activation)

The implementation must reuse/extend the approval metadata from migration V41
and the existing `ScoreTemplateStatus` enum instead of creating a second
approval model or a `SUBMITTED` state. Only a new DRAFT can be edited.
Activation retires the prior active version in one transaction and preserves
the existing single-active constraint.

### Snapshot and delivery

The snapshot stores the template version and every task's resolved runtime
profile, timing and scoring data. A retired catalog row is still deliverable if
the pinned runtime profile and question payload are available. A missing or
unsupported profile is a delivery blocker, not permission to skip the task.

### V40 code compatibility

All new canonical writes use the V40 names. A single shared BE compatibility
mapper translates legacy names when reading old request/snapshot data. It must
be used by template validation, snapshot mapping, scoring and API responses;
there must be no second business mapping in pte-app. The app may contain a
read-only alias table so it can consume both wire versions. During rollout the
app compatibility release ships before any BE response-value change; the
additive `taskTypeCode`/`runtime` shape avoids a BE-before-app break. A
migration report must list unrecognized legacy values rather than guessing.

## Phases

- [x] 1. [Phase 1 — Canonical Codes, Catalog Lifecycle and Idempotent Backfill](phase-01-canonical-codes-catalog-backfill.md)
- [x] 2. [Phase 2 — Allowlisted Runtime Profiles and Template Pinning](phase-02-runtime-profiles-and-template-pinning.md)
- [ ] 3. [Phase 3 — Template Approval Lifecycle and Readiness Validation](phase-03-template-lifecycle-and-readiness.md)
- [ ] 4. [Phase 4 — Snapshot Provenance and Capability Negotiation](phase-04-snapshot-capability-contract.md)
- [ ] 5. [Phase 5 — pte-app Runtime Registry and No-Silent-Skip Delivery](phase-05-pte-app-runtime-registry.md)
- [ ] 6. [Phase 6 — BE Behavior/Scoring Seam and Future Custom Extension Boundary](phase-06-be-behavior-scoring-extension-seam.md)
- [ ] 7. [Phase 7 — Vendor-Web Catalog, Template UX and Friendly Errors](phase-07-vendor-web-catalog-template-ux.md)
- [ ] 8. [Phase 8 — Rollout, Observability, Cross-Repo Verification and ADR Handoff](phase-08-rollout-verification-and-adr.md)

## Dependency graph

    Phase 1 (canonical data + V40 + seed)
        ├── Phase 2 (runtime profiles + template item pin)
        │       └── Phase 3 (approval + readiness/activation)
        │               └── Phase 4 (snapshot + preflight contract)
        │                       ├── Phase 5 (pte-app registry)
        │                       └── Phase 6 (BE behavior/scoring seam)
        └── Phase 7 (web UX; can begin after contract DTOs are frozen)
    Phase 5 + Phase 6 + Phase 7
        └── Phase 8 (rollout and final verification)

The existing exam-generation and exam-UI plans remain prerequisites where they
own generation, attempt timing, answer submission or screen implementation.
This plan must not delete or duplicate those flows.

## Cross-cutting design constraints

- Module ownership: itembank owns canonical task/profile validation;
  scoretemplate owns template versions; assessment owns snapshots; attempt owns
  student delivery; scoring owns scoring strategies; pte-app owns client
  renderers. Cross-module calls use public module services.
- API compatibility: preserve existing paths, HTTP semantics and legacy fields.
  Add the one nested `runtime` object plus `taskTypeCode` and explicit
  compatibility adapters. Do not expose
  database IDs, random seeds, correct answers or future exam content to clients
  before the existing access window.
- Tenant/security boundary: catalog, profiles and score templates are
  platform-owned. Every read/write remains behind the existing platform role
  matrix. Runtime manifests reveal capability metadata only, never question
  content. Audit records include actor and tenant context where applicable.
- Immutability: activation and snapshot publication are transactionally pinned.
  No in-place update may change the behavior, schema, timing or scoring data of
  an active template or published snapshot.
- Error UX: machine codes remain stable for API clients and telemetry, but
  user-facing messages are friendly and centralized in owning Constants.java,
  web constants.ts or app string constants. Raw codes are not rendered as the
  primary message.
- Performance: profile resolution and capability checks must be batched or
  cached; no per-question registry query during attempt delivery; migration must
  use indexed lookups and be safe to rerun in a throwaway local Postgres.
- Observability: emit audit/metric events for catalog backfill, code
  normalization failures, template activation failures, unsupported renderer
  preflight and legacy-adapter use. Never log answer content, credentials or
  signed media URLs.
- Migration safety: migrations are additive and forward-only in shared
  environments. Rollback disables a new profile/feature flag and keeps the
  compatibility columns; it does not drop columns or delete snapshot data.
- Runtime profile ownership: itembank owns the canonical task/profile
  descriptor and public catalog facade; scoring owns executable scorer
  implementations and validates the descriptor through its public service at
  scoring time. Scoretemplate consumes the itembank facade and stores
  `scoringProfileKey` plus version; it does not import scoring internals.
- Authoring requirements: the old update request fields remain accepted for
  compatibility, but the server re-derives and persists canonical requirement
  flags from `PteTaskType`. Clients cannot change validation requirements by
  editing catalog metadata; any future change requires a versioned profile.

## Explicit future custom-task seam (out of scope for MVP)

Do not implement arbitrary tenant-defined task codes, arbitrary JSON scoring
formulas, uploaded renderer scripts or dynamic class loading. The extension seam
is a future versioned TaskTypeDefinition/profile registry with:

- a globally unique immutable code and owner scope;
- an allowlisted behaviorKey, rendererKey, schema and scoring versions;
- explicit authoring schema, delivery schema and capability requirements;
- server-side validation and scoring strategy registration;
- pte-app capability negotiation and a versioned renderer;
- snapshot pinning and retirement rules identical to standard PTE types.

Until that feature is designed and secured, only PteTaskType values may be
created or activated.

## Red-team risks and mitigations

| Risk | Severity | Mitigation |
|---|---:|---|
| V40 canonical code differs from pte-app legacy code | HIGH | Ship the app dual-read compatibility patch first; then expose canonical `taskTypeCode`/runtime and only later change any legacy wire value. Round-trip tests cover both. |
| Backfill re-enables an intentionally inactive type | HIGH | Insert missing only; preserve lifecycle and admin fields; migration audit counts. |
| DB row claims a renderer/scorer that code does not support | HIGH | Allowlisted BE/app registries, activation/preflight checks, no class/script names. |
| Active template changes old exam scoring | HIGH | Immutable template/profile/snapshot versions and regression test after a new activation. |
| Unknown renderer is silently skipped | HIGH | Preflight/start blocker and explicit unsupported-task screen; no dispatcher default-to-next. |
| Approval state conflicts with V41 metadata | MEDIUM | Reuse `PENDING_APPROVAL` and existing approve/reject-to-DRAFT behavior; do not add `SUBMITTED`. |
| Retired profile makes historical exam unreadable | HIGH | Keep profile rows and snapshot payload immutable; retirement blocks only new templates. |
| New error code leaks to non-technical users | MEDIUM | Centralized friendly message maps and UI tests asserting code is not rendered raw. |
| Cross-repo release order exposes unsupported templates | HIGH | Release app dual-read capability support before changing BE wire values; then release additive BE contract, web UX and finally strict enforcement. |
| Extra profile joins slow attempt delivery | MEDIUM | Snapshot denormalization, batch loading and query-count/performance checks. |

## Completion acceptance criteria

- All 23 standard catalog entries can be read after a clean migration; rerunning
  the migration is a no-op and existing labels/order/inactive state remain.
- V40 canonical codes are the only new persisted/written codes; legacy codes
  are handled by one tested compatibility boundary.
- An active template contains the required 22 scored task types, has immutable
  runtime/profile pins, and can only be activated by Platform Admin.
- Platform Author can create/edit/submit a draft but cannot activate it; active
  and retired versions require clone-to-edit.
- Generated snapshots retain template version, task runtime profile, timing and
  scoring provenance independent of later catalog/template changes.
- pte-app dispatches by allowlisted renderer profile and gives an actionable
  update-required state for unsupported profiles; it never silently advances.
- Configuration-only template changes require no pte-app code change; a new
  interaction/scoring profile is blocked until BE and app capability support is
  present.
- Tenant/platform authorization, no-content-before-open rules, audit events and
  friendly error messages are covered by tests.
- Every phase has focused unit tests and a passing mandatory ck:quality --gate
  receipt. Final verification includes backend tests/compile, web tests,
  typecheck/lint/build, Flutter analyze/tests, migration verification and
  documentation/ADR review.

## Handoff and cook command

No production code, database or deployment has been changed by this plan.
Worktrees must remain uncommitted until the user explicitly asks for commits.

Recommended next command after reviewing the unresolved risks:

    /ck:cook --hard --tests --quality D:\GitHub\pte-org\pte-doc\projects\plans\quang-task-type-catalog-template-runtime-contract\plan.md

ck:cook must confirm tests and the quality gate before each phase and record
the result in that phase's Quality and Testing State section.
