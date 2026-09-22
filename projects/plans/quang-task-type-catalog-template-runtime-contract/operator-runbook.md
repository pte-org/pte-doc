# Operator Runbook: Task-Type Runtime Contract Rollout

Date: 2026-09-22
Verified migration head: V48 (`attempt_score_template_version`)
Environment: local Docker Compose using `.env.local`

This runbook is forward-only. It never requires `docker compose down -v`, a
volume reset, deletion of business rows or editing of an applied migration.

## 1. Validate the local Compose graph

```powershell
docker compose --env-file .env.local `
  -f docker-compose.yml `
  -f docker-compose.services.yml config --quiet

docker compose --env-file .env.local `
  -f docker-compose.yml `
  -f docker-compose.services.yml up --build -d app

docker inspect pte-platform-app-1 `
  --format 'status={{.State.Status}} health={{.State.Health.Status}}'
```

Expected result: the app is `running` and `healthy`. The local verification on
2026-09-22 reached that state after applying V39-V48 to the existing database.

## 2. Verify upgrade and idempotent rerun

The existing local database was at V38. Starting the app applied V39-V48. A
second startup logged that the schema was already up to date; it did not rerun
or alter the applied migrations.

Read-only checks (do not print `.env.local`):

```powershell
docker exec pte-postgres psql -U pte-db -d pte -Atqc `
  "SELECT version, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 5"

docker exec pte-postgres psql -U pte-db -d pte -Atqc `
  "SELECT COUNT(*) FROM question_types WHERE deleted = false"

docker exec pte-postgres psql -U pte-db -d pte -Atqc `
  "SELECT COUNT(*) FROM task_runtime_profiles WHERE deleted = false"

docker exec pte-postgres psql -U pte-db -d pte -Atqc `
  "SELECT COUNT(*) FROM (SELECT code FROM question_types WHERE deleted = false GROUP BY code HAVING COUNT(*) > 1) duplicates"
```

Verified results: catalog `23`, scored catalog rows `22`, runtime profiles
`23`, duplicate active codes `0`, and migration head `V48`.

## 3. Verify a fresh database without touching the local volume

Create a uniquely named disposable database in the running Postgres container,
then run the app once with only `APP_DB_URL` overridden:

```powershell
docker exec pte-postgres psql -U pte-db -d postgres -v ON_ERROR_STOP=1 `
  -c "CREATE DATABASE pte_phase8_fresh"

docker compose --env-file .env.local `
  -f docker-compose.yml `
  -f docker-compose.services.yml run --rm --no-deps `
  -e APP_DB_URL=jdbc:postgresql://postgres:5432/pte_phase8_fresh app
```

Wait for Flyway to report `Successfully applied 48 migrations` and for the
application to start. Remove only the disposable database after the check:

```powershell
docker exec pte-postgres psql -U pte-db -d postgres -v ON_ERROR_STOP=1 `
  -c "DROP DATABASE pte_phase8_fresh"
```

This exact procedure was run successfully on 2026-09-22. It inserted all 23
standard catalog rows (`V44`) and did not modify the persistent `pte` volume.

## 4. Feature flag and rollback

The compatibility switch is:

```text
ATTEMPT_ALLOW_LEGACY_MISSING_MANIFEST=true
```

Keep it `true` while old clients or pre-runtime snapshots remain. After the
dual-read app release and acceptable compatibility telemetry, set it to `false`
and restart the app. This enables the strict preflight/start gate for new
runtime snapshots.

If a rollout must be paused:

1. Set the flag back to `true` and restart the app.
2. Keep V44-V48 columns, profiles and snapshot data in place.
3. Do not roll back or edit a shared Flyway migration.
4. Repair forward with a new migration after the cause is understood.
5. Keep the pte-app dual-read behavior until all snapshot readers are safe.

## 5. Audit and observability checks

Runtime failures use stable audit action `RUNTIME_CONTRACT_FAILURE`; snapshot
mapping rejection uses `RUNTIME_MAPPING_REJECTED`; template lifecycle and
validation actions are recorded as `SUBMITTED_FOR_APPROVAL`, `ACTIVATED`,
`RETIRED` and `VALIDATION_FAILED`. Audit summaries contain identifiers and
machine codes only; they must never contain answer content, credentials or
signed media URLs.

The local database was greenfield for these flows, so `audit_logs` contained no
business events during this verification. The code paths and constants are in
place. The current local actuator exposes `health` and `info`; metrics and
Prometheus endpoints are not exposed in this profile, so production telemetry
must be verified separately before strict enforcement.

## 6. Manual release walkthrough

With approved local test credentials, execute:

1. Platform Admin verifies the 23-row catalog and the 22 scored requirements.
2. Platform Author creates a draft, selects task types, and submits it.
3. Confirm Author cannot activate; Admin approves/activates.
4. Generate and publish a snapshot; confirm runtime provenance is complete.
5. Start the pte-app preflight with its capability manifest.
6. Render one canonical FILL task and one `READ_ALOUD` task.
7. Activate a later template/catalog version and confirm the published
   snapshot still returns the original pinned renderer/schema/scoring data.
8. Try an unsupported renderer, missing capability and tenant/host mutation;
   each must fail closed with friendly guidance.

This walkthrough was not executed in this session because no approved
authenticated credential was available. Public login smoke was executed and
confirmed the vendor login page renders without a raw machine error code.
