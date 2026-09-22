# Phase 10 — Rollout, Audit/Metrics, Compatibility Verification, and ADR Handoff

## Goal

Release the dynamic contract safely across backend, vendor-web, and pte-app;
verify migrations and historical behavior; add audit/metrics; and document the
final operating procedure before strict custom-template enforcement.

## Dependencies

- Phases 1–9 implemented and individually quality-gated, including the
  vendor-web task-type/readiness UX in Phase 9.
- Existing deployment workflows and local Docker/Postgres topology.
- Approved authenticated test accounts for platform author/admin and a tenant
  host, supplied outside the repository.

## Exact files/modules likely affected

Backend observability and rollout:

- pte-api/app/src/main/java/com/pte/audit
- pte-api/app/src/main/java/com/pte/itembank/internal/constant/ItembankConstants.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/constant/ScoreTemplateConstants.java
- pte-api/app/src/main/java/com/pte/attempt/internal/constant/*Constants.java
- pte-api/app/src/main/java/com/pte/itembank/QuestionTypeService.java
- pte-api/app/src/main/java/com/pte/scoretemplate/internal/service/ScoreTemplateAdminService.java
- pte-api/app/src/main/java/com/pte/attempt/internal/service/CapabilityNegotiationService.java
- feature-flag/configuration files under pte-api/app/src/main/resources

Web/app observability:

- pte-web/apps/vendor-web/features/questiontemplate/errorMessage.ts
- pte-web/apps/vendor-web/features/scoretemplate/errorMessage.ts
- pte-app/lib/features/exam_attempt/constants/exam_attempt_error_message.dart
- pte-app/lib/features/exam_attempt/domain/client_capability_manifest.dart

Documentation and verification:

- pte-doc/projects/architecture/ADR-010-dynamic-task-type-screen-contract.md
- pte-doc/projects/plans/quang-dynamic-task-type-screen-contract/plan.md
- all phase files in this bundle
- new migration/readiness/audit runbooks under pte-doc/projects/runbooks
- sanitized cross-repo verification checklist

## Implementation steps

1. Add audit events for task create/update/retire, duplicate conflicts,
   runtime-lock conflicts, capability changes, template readiness failure,
   publication usage, preflight unsupported contract, and legacy adapter use.
2. Add metrics with bounded labels:
   dynamic_task_type_create_total,
   dynamic_task_type_duplicate_total,
   template_readiness_failure_total,
   unsupported_runtime_preflight_total,
   legacy_task_type_adapter_total,
   snapshot_runtime_contract_failure_total.
   Never label metrics with display names, answer content, tokens, or secrets.
3. Add a feature flag with safe defaults:
   standard compatibility on; custom task creation and CUSTOM activation off
   until all cross-repo checks pass.
4. Roll out in this order:
   pte-app screen/manifest compatibility, backend additive read paths,
   migrations/backfill, backend dynamic catalog behind flag, vendor-web form,
   custom question authoring, CUSTOM draft/readiness, strict activation.
5. Verify fresh local migration and an existing compatibility fixture. Confirm
   23 standard catalog entries, 22 scored standard template activation, and
   V40 aliases.
6. Verify a two-key/one-screen custom task path end to end:
   create, duplicate warning, question authoring, custom draft, readiness,
   activation, snapshot, preflight, delivery, and scoring.
7. Verify a missing/unsupported screen path: draft remains saveable, activation
   blocks, preflight blocks, app shows terminal state, and no next transition
   occurs.
8. Verify lock path: publish template, retire it, attempt runtime edit, receive
   structured 409, see disabled fields, and confirm historical snapshot still
   displays its old label.
9. Review production metrics/audit in observe-only mode before enabling strict
   enforcement. Production mutation requires a separate operator approval.
10. Update ADR and close the prior plan by reference; do not rewrite its
    completed phase history.

11. Verify the mixed-version matrix before enabling strict behavior:

    | Backend | Database | Client/app | Allowed result |
    |---|---|---|---|
    | Old | New additive schema | Old web/app | Standard legacy projection works; custom flag remains off |
    | New | New schema | Old web/app | Standard rows/legacy snapshots remain readable; custom is not sent to old clients |
    | New | New schema | New web/app | Custom flow allowed only after manifest/contract checks |
    | New | New schema | New app + legacy snapshot | Legacy adapter or terminal update state; never guessed mapping |
    | Old | Old schema | New web/app | Not an allowed rollout state |

    Rollback is allowed only to a matrix row explicitly marked safe; a failed
    historical compatibility check blocks strict enforcement.

## API/DB contract

The rollout must preserve:

- old question-types endpoint and response fields;
- standard enum wire aliases;
- old snapshots and attempts;
- old app manifests containing only capabilities;
- standard template policy default.

New strict behavior is feature-flagged and observable. A rollback turns off
custom creation/activation and new strict preflight checks while preserving
data and legacy reads.

Legacy consumer matrix must be verified and documented: the old
/api/v1/question-types projection contains standard rows only; the new
/api/v1/task-types projection carries custom keys; old question-bank exports
and pte-app clients receive a compatibility error/terminal state for custom
keys; new snapshots, scoring, reporting, and vendor-web use taskTypeKey.

## Error UX

Production-facing messages remain the friendly constants from previous phases.
Audit/metrics may retain machine codes, but logs and dashboards must not expose
credentials, response payloads, correct answers, signed URLs, or personal data.

## Security and ownership

- Verify platform role separation with authenticated requests.
- Verify tenant/host can consume but cannot mutate catalog, registry, or
  template policy.
- Keep deployment tracking read-only unless a separate request authorizes
  deploy/push.
- Do not print .env values, tokens, private keys, or test passwords in logs.

## Design Constraints

- No production data deletion or volume reset is part of this phase.
- Do not dispatch/rerun production workflows as part of a plan-only handoff.
- Do not enable strict enforcement until app compatibility and metrics are
  verified.
- A historical incompatibility is a blocker to strict enforcement, not a
  reason to delete data.

## Quality and Testing State

Quality: not evaluated.
Testing: not started.

Required tests and checks:

- Full backend migration, unit, integration, and security suite.
- Full vendor-web lint, typecheck/build, API tests, and authenticated UI
  walkthrough.
- Flutter analyze, unit/widget/integration tests, manifest/preflight checks.
- Cross-repo contract fixtures for old/new DTOs and V40 aliases.
- Fresh local database migration and idempotent rerun.
- Standard 22-task activation regression.
- Custom two-key/one-screen end-to-end flow.
- Unsupported-runtime terminal-state flow.
- Published-lock-after-retirement flow.
- Audit event and bounded metric assertions.

Mandatory gate:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-10-rollout-observability-compatibility-and-adr.md

## Acceptance criteria

- All previous phases have a quality-gate receipt and focused test result.
- Fresh and compatibility databases migrate safely.
- Standard API/template/app behavior is unchanged.
- Custom task type can complete the approved end-to-end path.
- Unsupported runtime and published-lock paths are proven.
- Metrics/audit are visible without sensitive data.
- Strict enforcement remains off until an operator explicitly approves the
  rollout decision.
- ADR and runbooks accurately describe registry, manifest, compatibility,
  locking, rollback, and ownership.

## Verification commands

Backend:

    .\mvnw.cmd -pl app test
    .\mvnw.cmd -pl app -DskipTests compile

Vendor web:

    pnpm --filter vendor-web lint
    pnpm --filter vendor-web build

Flutter:

    cd pte-app
    flutter analyze
    flutter test

Local migration/compose:

    cd ../pte-api
    docker compose --env-file .env.local -f docker-compose.yml config
    docker compose --env-file .env.local -f docker-compose.yml up -d postgres

Run authenticated walkthroughs with approved credentials, inspect audit/metric
events, then run the mandatory quality gate and the all-phases check:

    /ck:quality --gate D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\phase-10-rollout-observability-compatibility-and-adr.md
    /ck:test --all-phases D:\GitHub\pte-org\pte-doc\projects\plans\quang-dynamic-task-type-screen-contract\plan.md

## Risks and rollback

Risk: app and backend release order creates an unreadable active template.
Mitigation: app compatibility first, feature flag, preflight, then strict
activation.

Risk: production audit shows legacy rows or unsupported contracts. Keep strict
enforcement disabled, repair through a planned migration/contract release,
and do not delete history.

Risk: a workflow or deployment command mutates production unexpectedly. Keep
this phase verification-only by default and require an explicit operator
request for any dispatch, deploy, or data mutation.

Rollback: turn off custom creation/activation and strict preflight, leave
additive schema/data/audit intact, and continue serving standard/legacy paths.
