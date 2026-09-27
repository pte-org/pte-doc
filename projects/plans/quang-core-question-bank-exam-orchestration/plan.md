# Plan: Core Question Bank to Host Exam Orchestration

Status: Completed in the current worktrees — verification and handoff recorded 2026-09-21
Date: 2026-09-21
Mode: Hard
Scope: `pte-api` + `pte-web` + `@pte/api-client` + plan documentation
Primary actors: Platform Admin, Platform Author, Host Admin, Proctor, Student

## Objective

Deliver the main authoring-to-delivery workflow:

```text
Question type catalog
  -> question bank authoring/review/publish
  -> immutable score/exam template
  -> host exam draft
  -> package and schedule validation
  -> individual/class/program audience snapshot
  -> conflict and capacity report
  -> deterministic generated form(s)
  -> publish/open exam
  -> student attempt and immutable audit provenance
```

The plan is deliberately based on the current source tree, not on the historical
completion marks in older plans. It preserves the existing modular-monolith
facades and the current tenant/vendor application split.

## Scope challenge

| Check | Result |
|---|---|
| Exists? | Partial. Question bank, question types, score templates, subscriptions, session windows, class assignment and manual enrollment exist. The end-to-end contract does not. |
| Minimum useful implementation | A host can create a draft, choose a published template and subscription, snapshot an audience, see exclusions/capacity, generate an immutable exam form, and publish it. |
| Complexity | Hard: cross-repository, stateful workflow, tenant isolation, package constraints, concurrent audience changes, deterministic randomization, and immutable assessment provenance. |
| Test direction | Unit-test expansion is enabled per the latest user instruction. Focused unit tests, full backend regression, frontend package tests, compile/typecheck/build checks, and a mandatory `ck:quality` gate are required. |

## Current branch baseline

The following was verified from the current working trees on 2026-09-21:

- `pte-api` is the `quang/feat/users-tenant` branch and has the modular monolith in `app/`.
- `pte-web` is on `dev`; the existing home-page merge is preserved. Vendor and tenant applications already use `@pte/api-client`, TanStack Query, and shared UI.
- Vendor question-bank/question-type screens and request wrappers exist. Questions have draft, approval, published/approved, archived, and revision behavior. Platform authors can author/submit; platform admins approve/publish.
- Vendor score-template CRUD exists, but `ScoreTemplateController` is currently `PLATFORM_ADMIN` only. Draft items can be replaced and active/retired structures are immutable/cloneable.
- Tenant exam creation currently sends `name`, `subscriptionPublicId`, `skills`, `opensAt`, `closesAt`, `examMode`, `lockdownMode`, and `capacity`. The backend immediately uses the active score template, `java.util.Random`, and a synchronous blueprint-to-snapshot transaction.
- `ExamSnapshot` is immutable and pins score-template identity/version, but the current generation path does not persist an explicit generation seed, algorithm version, selected pool policy, or per-student form identity.
- `ExamSession` already validates active subscription, subscription date window, per-session capacity, and has the PostgreSQL `no_overlap_per_subscription` exclusion constraint. Different subscription instances may overlap; one subscription lane may not.
- Tenant session UI currently supports class assignment, manual/bulk student enrollment, proctors, opening and closing. It has no program/individual audience planner, conflict preview, generation job state, or form mode.

## Historical-plan reconciliation

`pte-doc/projects/plans/quang-tenant-commercialization/` and
`quang-question-type-template-admin/` are valuable design evidence, but their
phase status and terminology do not prove the current branch is complete:

- Reuse the existing subscription-lane rule and `Phase 11` lock-ordering ideas.
- Treat the historical `Phase 12` student conflict design as unfinished input,
  not as an implemented contract.
- Do not introduce a second `ExamTemplate` aggregate merely because the old plan
  used that name. On this branch `ScoreTemplate` is the existing template
  aggregate; the target contract extends it and adds exam-generation provenance.
- Do not overwrite the older plans. This plan is the current integration plan
  for the actual `ScoreTemplate`/`ExamSession` code.

## Target decisions

### 1. Keep `ExamSession` as the first delivery aggregate

Do not add a separate reusable `Exam` table in this scope. `ExamSession` already
owns the tenant, schedule, subscription lane, capacity, policy, and snapshot
reference. Extend it with a draft/generation/publish lifecycle and child
aggregates for audience membership, generation jobs, and forms.

This avoids a risky `Exam` → `Session` split before the product needs multiple
test sittings from one exam definition. If multi-sitting reuse becomes required,
the immutable template/version and audience-source tables can later be lifted
under a reusable `Exam` parent without changing student attempt provenance.

### 2. Template ownership and permissions

Keep templates platform-owned and tenant-readable only through the narrow
assessment facade. Adopt this permission matrix:

| Capability | Platform Author | Platform Admin | Host Admin |
|---|---:|---:|---:|
| Create/edit question draft | Yes | Yes | No |
| Submit question for approval | Yes | Yes | No |
| Approve/reject/publish question | No | Yes | No |
| Create/edit score-template draft | Yes, if policy is enabled | Yes | No |
| Submit template for approval | Yes | Yes | No |
| Activate/publish template | No | Yes | No |
| Choose active template for an exam | No | No | Yes |

The current admin-only score-template controller is preserved as a compatibility
baseline until the author draft/approval endpoints are added. Activation remains
admin-only so an author cannot alter the production contract for all tenants.

### 3. Exam lifecycle

Use explicit, server-owned transitions:

```text
DRAFT -> PREPARING -> READY -> SCHEDULED -> OPEN -> CLOSED
   |         |          |         |
   +---------+----------+---------+--> CANCELLED
```

- `DRAFT`: details, audience sources, policy and package may be edited.
- `PREPARING`: a generation job owns the row; edits and duplicate commands are rejected.
- `READY`: audience and form generation are complete, but the host has not published.
- `SCHEDULED`: published, immutable for template, audience snapshot, package lane, forms and policy fields that affect delivery.
- `OPEN`/`CLOSED`: existing delivery semantics remain.
- `CANCELLED`: only scheduled/preparing drafts may be cancelled according to the existing revocation policy.

The canonical create endpoint is `POST /sessions/drafts`; the web UI uses
create → preflight → generate → publish. The old skills-only `POST /sessions`
remains as a fail-closed compatibility boundary during migration: it returns a
friendly workflow-migration response because its payload cannot express the
required template/audience/form rules, and it cannot create a published
snapshot.

Canonical endpoint shape (all under `/api/v1/sessions` and tenant-scoped):

```text
POST   /sessions/drafts                   create DRAFT
GET    /sessions/{id}                    safe detail/status
PATCH  /sessions/{id}                    edit DRAFT fields
POST   /sessions/{id}/audience-sources   add a STUDENT/CLASS/PROGRAM source
DELETE /sessions/{id}/audience-sources/{sourceId}
POST   /sessions/{id}/audience-preview   resolve/dedupe/report, no publish
POST   /sessions/{id}/preflight          validate template/package/audience
POST   /sessions/{id}/generate           enqueue an idempotent job
GET    /sessions/{id}/generation         poll job progress
POST   /sessions/{id}/publish            materialize audience/forms and schedule
POST   /sessions/{id}/open               existing operation, READY/SCHEDULED only
POST   /sessions/{id}/close              existing operation
POST   /sessions/{id}/cancel             scheduled/preparing cancellation
```

The exact URL can preserve an existing controller naming convention, but the
semantics above are mandatory. `POST /sessions` must not create a published
snapshot as a hidden side effect after the new flow lands.

### 4. Audience and reuse policy

Audience sources are a union of `STUDENT`, `CLASS`, and `PROGRAM` sources,
deduplicated by student public ID. At publish time the server resolves current
membership into an immutable audience snapshot. Later class/program membership
changes do not change a published exam.

The exam stores a policy rather than a permanent student flag:

- `ALLOW`: no previous-exam exclusion.
- `EXCLUDE_STARTED_IN_SERIES`: exclude students with an attempt at least
  `IN_PROGRESS` in the same configured exam series/cycle.
- `EXCLUDE_ASSIGNED_IN_SERIES`: stricter policy, excludes any prior audience
  assignment/enrollment in the series.
- `BLOCK_ON_SCHEDULE_OVERLAP`: reject publication if a student is assigned to a
  time-overlapping exam, with a conflict report.

Default recommendation: practice uses `ALLOW`; official/mock exams use
`EXCLUDE_STARTED_IN_SERIES` when a non-empty `seriesKey` is supplied. A host can
choose a stricter policy. An explicit override is an admin-only action and is
audited. The UI shows eligible, excluded, duplicate, over-capacity, and
cross-exam-conflict counts; it does not mutate class/program membership.

### 5. Forms and randomization

Support two modes:

- `SHARED_FORM`: one immutable form for all enrolled students; recommended for
  practice and low-stakes sessions.
- `UNIQUE_FORM_PER_STUDENT`: one immutable form assignment per student;
  recommended default for official/mock sessions.

Questions may repeat across different forms by default, but never within one
form. A future anti-reuse policy can reserve questions across forms without
changing the provenance model.

Each generated form persists the template public ID/version, question revision
IDs, base/form seed, generator algorithm version, and pool-policy fingerprint.
Generation is deterministic from those values. The seed and answer-bearing
content are never exposed to a host before the exam opens.

### 6. Generation and quota behavior

Preflight is synchronous and returns shortages, invalid slots, excluded
students, capacity, and package-window problems without writing a published
exam. Actual generation is a persistent, idempotent job for large audiences;
small shared-form generations may complete in the request while still using the
same job state machine.

Capacity is evaluated after audience deduplication and exclusions. The
subscription's `maxStudentsPerSession` remains the per-session cap. The session
row lock plus a database uniqueness constraint protects enrollment races. The
existing subscription-lane exclusion constraint remains authoritative for time
overlap; different subscription IDs may overlap.

There is no cross-session aggregate student reservation in this release: the
commercial contract is `maxStudentsPerSession`, not a consumable count shared by
all sessions on a subscription. At publish, eligible audience members are
materialized through the canonical enrollment writer under the locked session;
that actual enrollment count is the capacity claim. A future total-seat quota
must add a separate ledger and cannot be inferred from this per-session cap.

## Current state vs target gap matrix

| Area | Current state | Target gap closure |
|---|---|---|
| Question types | Catalog CRUD exists for platform admin/author | Add capability metadata needed by slot validation and audit; keep DB catalog as source of truth |
| Question bank | Draft/revision/approval/publish/archive exists; shared pool count/random IDs | Add pool metadata/filter contract, revision provenance, deterministic selection facade, and complete friendly error mapping |
| Score template | Admin-only draft CRUD, active/retired immutable | Add author draft/submit path if approved, explicit version contract, slot pool constraints, activation feasibility check |
| Exam generation | Active template + selected skills + `Random` + synchronous publish | Select explicit template, persist seed/algorithm/provenance, preflight all slots, job state, form mode, immutable forms |
| Session lifecycle | Immediate `SCHEDULED` creation; open/close | Add draft/preparing/ready/publish transitions and compatibility adapter |
| Package | Active subscription, window, capacity, same-lane DB overlap | Reuse lane rule; make preflight/publish reserve/recheck atomic and produce actionable conflict details |
| Audience | Class assignment and manual/bulk enroll | Add student/class/program sources, union/dedupe, publish-time roster snapshot, preview and exclusions |
| Student conflicts | Historical unfinished phase; enrollment history read-only | Add series/time-overlap policy, one-batch conflict query, reasons, override audit |
| Frontend | Tenant create modal uses skills; detail has classes/manual roster | Add stepper, template/package selection, audience planner, preview, job progress, form/audience summary |
| API client | Session/class/enrollment wrappers | Add typed exam draft, audience, preflight, generation, publish, conflict and form endpoints |
| Errors | Machine codes can reach UI | Stable backend codes/details plus feature-level friendly FE constants; no raw code rendered |
| Verification | Existing historical tests/quality receipts vary by branch | Run current-branch compile/typecheck/manual integration and `ck:quality` per phase |

## Phases

1. [Phase 1: Contract freeze, permissions and compatibility boundary](phase-01-contract-permissions-and-compatibility.md)
2. [Phase 2: Question bank and template readiness](phase-02-question-bank-and-template-readiness.md)
3. [Phase 3: Exam draft, audience sources and lifecycle](phase-03-exam-draft-audience-lifecycle.md)
4. [Phase 4: Entitlement, capacity and student-conflict publish gate](phase-04-entitlement-capacity-conflict-gate.md)
5. [Phase 5: Deterministic generation, jobs and immutable forms](phase-05-deterministic-generation-and-forms.md)
6. [Phase 6: API client and host/vendor workflows](phase-06-api-client-and-web-workflows.md)
7. [Phase 7: Friendly errors, security, audit and migration hardening](phase-07-errors-security-audit-and-migration.md)
8. [Phase 8: End-to-end verification and release handoff](phase-08-verification-and-release.md)

## Dependency graph

```text
P1 ──> P2 ──> P3 ──> P4 ──> P5
                    │       │
                    └──────>P6
P1 ─────────────────────────>P7
P2 + P3 + P4 + P5 + P6 + P7 ──> P8
```

P2 can start after the permission/contract decisions in P1. P3 must not land
without the lifecycle contract. P4 is the publish gate and must precede actual
generation. P5 owns immutable form provenance. P6 may build UI skeletons in
parallel, but its API integration is blocked until P3–P5 contracts stabilize.

## Cross-cutting design constraints

- Cross-module calls use public facades such as `AssessmentService`,
  `ItembankService`, `BillingService`, and a public enrollment/audience query
  surface. Session code must not reach into another module's repositories.
- All tenant-owned reads/writes carry the tenant from `CurrentUser`; global
  question/template content remains read-only to hosts. Preserve 404 behavior
  for resources outside a tenant where that is the existing convention.
- Add new Flyway migrations after the current latest version; never rewrite
  already-applied migrations on a shared environment. Exact next numbers must be
  rechecked immediately before implementation because branches can add migrations.
- All state-changing operations are idempotent by public ID/request key. Job
  retries cannot create a second form set, audience snapshot, reservation, or
  notification.
- Use row locks in deterministic order for mutable session/subscription/job
  records. Keep the PostgreSQL exclusion constraint as the final overlap guard;
  application prechecks only improve the message.
- Backend user-facing code/message pairs belong in the owning module's
  `*Constants.java`. Frontend alerts, button labels, and error mappings belong
  in feature constants/formatters; TSX files call constants rather than defining
  literal messages.
- Never expose answer keys, generation seed, pool internals, or unpublished
  question content to hosts. Do not log credentials, tokens, or full exam
  content.

## Out of scope

- Student self-service payment or student-owned packages.
- Reusable multi-session exam definitions; revisit after this single-session
  aggregate is stable.
- Cross-tenant student identity or membership; current identity model is
  tenant-scoped.
- Permanent no-repeat question reservation across all forms/tenants.
- AI scoring, proctor websocket redesign, mobile delivery redesign, and a new
  media-storage provider.
- Production data deletion, seed-account creation, deployment, commit, or push.

## Red-team risks and mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Old direct create path generates a different template than the new UI | High | Compatibility adapter accepts explicit template/version or rejects stale skills-only requests after migration; add contract telemetry and deprecation response |
| Two publish/generate requests create duplicate forms or consume capacity twice | Critical | Idempotency key, locked session/job row, unique constraints on session/form/student, and state transition checks |
| Class/program membership changes between preview and publish | High | Always re-resolve and revalidate under publish transaction; preview is advisory, published audience is immutable |
| UI hides a conflicting student but backend still enrolls them through a legacy endpoint | Critical | Enforce policy in the canonical publish/enrollment service and make legacy enrollment call the same gate |
| Java random output cannot be audited | High | Persist base/form seed, algorithm version, exact selected question revision IDs, and pool-policy fingerprint |
| Template/question edited after a session is published | Critical | Snapshot template/version and question revision content; active template structure is immutable; no live joins during delivery |
| Different package overlap accidentally becomes tenant-wide exclusion | High | Keep `subscription_id` as the DB exclusion key and add cross-package overlap acceptance verification |
| Capacity checked before exclusions, causing false rejection or over-enrollment | High | Deduplicate/filter first, then reserve/enroll under session lock; count actual enrollments and return per-reason totals |
| Platform author receives activation power accidentally | High | Method-security matrix tests/manual checks; author can submit only, admin activates |
| Friendly message mapping hides actionable details | Medium | Stable code + safe parameterized details; FE maps known codes and has a generic fallback without displaying raw code |
| Audience/form payload becomes too large for synchronous request | High | Persistent job, bounded batch processing, progress polling, and no giant request/response body |

## Acceptance criteria for the complete capability

- A platform-author workflow can create/submit a question and a template draft;
  only an authorized platform admin can approve/publish/activate them.
- A host can create a draft exam without seeing question content, choose an
  active template and valid subscription, add student/class/program sources,
  select a reuse policy/form mode, and run a preflight.
- Preflight reports all shortages, package-window/capacity violations,
  duplicate students, and conflict exclusions in one response; it does not
  create a scheduled exam.
- Publish rechecks all rules transactionally. Same subscription overlap is
  rejected even under concurrent requests; different subscriptions may overlap.
- The published audience is a deduplicated immutable snapshot. Later roster
  changes do not alter it. Excluded students have a reason and prior-exam
  reference.
- Generation is idempotent and reproducible from persisted seed/algorithm/
  template/question revision data. No form contains duplicate questions.
- Official/mock unique-form mode maps every eligible student to exactly one
  immutable form; shared mode maps all eligible students to one form.
- Existing attempt/delivery APIs can consume the selected form/snapshot without
  answer-key leakage or template drift.
- Tenant and vendor screens show friendly Vietnamese/English product messages,
  never raw values such as `PLAN_ARCHIVED_NOT_EDITABLE`.
- Every phase has a passing mandatory quality gate and documented compile,
  typecheck, migration, unit-test, manual/integration verification results.

## Decision record

The following product decisions are accepted for implementation:

1. Official/mock defaults to `EXCLUDE_STARTED_IN_SERIES`; the host must provide
   a non-empty `seriesKey` such as `HK1-2026`. The server must not silently
   downgrade to `ALLOW` when the key is missing. Practice defaults to `ALLOW`.
2. `UNIQUE_FORM_PER_STUDENT` is mandatory for official/mock in the first
   release. `SHARED_FORM` remains available for practice. Generation must be
   asynchronous for large audiences, questions may repeat across different
   forms, and a form may not contain duplicate questions.
3. Platform Author may create, edit and submit template drafts. Platform Admin
   remains the only role allowed to approve/activate a template for production
   use. Existing admin-created templates remain compatible.
4. Keep the old skills-only `POST /sessions` as a temporary compatibility
   boundary for one migration window. New tenant-web code must not call it. The
   endpoint is fail-closed with a friendly migration message because the legacy
   payload cannot satisfy the canonical template/audience/form rules; remove it
   after all clients migrate.

## Handoff

All eight phases are implemented in the current worktrees. Unit tests, frontend
checks/builds, and mandatory quality receipts are recorded under `tests/` and
`quality/`. The remaining runtime-only checks and accepted debts are listed in
Phase 8; no commit, push, deployment, or production data mutation was performed.

```text
Canonical next step: run local Docker/Flyway and authenticated browser smoke with approved seed data.
```
