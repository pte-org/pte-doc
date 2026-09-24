# Dynamic task-type rollout runbook

This runbook covers the additive `taskTypeKey` and `(screenKey,
contractVersion)` contract. It is a verification and release checklist; it
does not authorize production data mutation, workflow dispatch, or deployment.

## Safe defaults

Keep these settings until the authenticated walkthrough and metrics review are
complete:

```text
TASK_TYPES_CUSTOM_CREATION_ENABLED=false
TASK_TYPES_CUSTOM_TEMPLATE_ACTIVATION_ENABLED=false
ATTEMPT_STRICT_PRE_FLIGHT_ENABLED=false
ATTEMPT_ALLOW_LEGACY_MISSING_MANIFEST=true
```

The normalization fixture used by API/client contract checks is
`pte-doc/projects/plans/quang-dynamic-task-type-screen-contract/fixtures/task-type-normalization.json`.

The old `/api/v1/question-types` projection remains available and standard-only.
The canonical `/api/v1/task-types` read path may be enabled before custom
creation. No flag can make a database value executable: renderer, answer
schema, authoring and scoring behavior must come from the release-owned
registry.

## Local verification

Run from the relevant repository roots without printing `.env` values:

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app test
.\mvnw.cmd -pl app -DskipTests compile
docker compose --env-file .env.local -f docker-compose.yml config

cd ..\pte-web
pnpm exec tsc --noEmit -p apps/vendor-web/tsconfig.json
pnpm --filter vendor-web lint
pnpm --filter vendor-web build

cd ..\pte-app
flutter analyze
flutter test
```

For a fresh local database, use the project Compose instructions and inspect
migration/container health. Do not run `docker compose down -v` unless local
data deletion has been explicitly requested.

## Authenticated walkthrough

Use approved platform-author, platform-admin, and host/student accounts. Never
put credentials in this document or command history.

1. Confirm the legacy catalog returns the standard rows and no custom key.
2. Confirm `/task-types/capabilities` lists only active released contracts.
3. With custom creation still off, confirm a custom create attempt receives the
   friendly rollout message; standard compatibility reads still work.
4. In a non-production environment, enable custom creation. Create
   `READ_ALOUD_PLUS` using the existing `READ_ALOUD_V1` screen contract.
   Entering a case/Unicode-padded duplicate key or display name must show the
   availability warning before submit and return HTTP 409 if raced.
5. Create two custom keys that reuse one screen contract. Author and publish
   approved questions for both keys.
6. Create a `CUSTOM` draft, add the two task keys, and save it while the
   question pool or runtime contract is incomplete. The draft must persist and
   readiness must remain visible.
7. Verify submit/activation returns all actionable readiness failures. After
   the pool and contract are ready, activate it as Platform Admin only.
8. Publish a snapshot and start a host/student attempt. The snapshot, pinned
   item, task response and score resolver must use `taskTypeKey` plus the
   pinned runtime contract; changing a display label later must not change the
   historical snapshot label.
9. Use a deliberately unsupported screen/schema/version. Draft save remains
   possible, activation/preflight stops with a friendly message, and the app
   shows a terminal update state without a next-task transition.
10. Retire the template and attempt to edit the task type's runtime fields.
    The API returns structured HTTP 409 and the web form shows those fields as
    locked. Display metadata remains editable.
11. Verify a tenant/host caller can consume an active template but cannot
    create, update, retire task types, change runtime contracts, or activate a
    template.

## Metrics and audit review

In observe-only mode, inspect bounded counters and audit rows for the review
window:

```text
dynamic_task_type_create_total
dynamic_task_type_duplicate_total
template_readiness_failure_total
unsupported_runtime_preflight_total
legacy_task_type_adapter_total
snapshot_runtime_contract_failure_total
```

Review that audit summaries contain identifiers and reason codes only. They
must not contain answer content, correct answers, signed URLs, tokens,
passwords, or raw request payloads. Investigate any unsupported-runtime or
snapshot-contract event before enabling strict preflight.

## Enabling strict behavior

Only an operator with explicit release approval may change the flags. Enable
custom creation first, then custom activation, then strict preflight after the
production metrics/audit review and mixed-version matrix check. If any
historical compatibility check fails, leave strict enforcement off and repair
through a new contract/release. Rollback is flag-only: disable custom creation,
custom activation, and strict preflight; retain migrations, audit history and
published snapshots.
