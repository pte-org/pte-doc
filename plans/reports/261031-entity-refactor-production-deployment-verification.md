# Entity refactor production deployment and exam catalog seed

Date: 2026-10-31 (Asia/Bangkok).

## Backend transition

- API main: `8cafecd0a903659512f395e9ec8ee0a52b04aab5`.
- The original production DB had the old Flyway history through V116.
- The new image failed Flyway checksum validation against that history, as expected.
- Rehearsed the current SQL migrations from V1 through V14 in an isolated database
  on the production PostgreSQL instance. All 13 files succeeded; there is no V12
  file in this migration sequence.
- Waited for the shared deployment lock before stopping the app and recreating
  only database `pte`. PostgreSQL roles/volumes, TLS volumes and environment files
  were retained. RabbitMQ application queues and DLQs were empty.
- The new backend applied all 13 migrations through V14, passed Hibernate schema
  validation and started successfully. Docker reports healthy and internal
  actuator reports `UP`.
- API workflow attempt 2 succeeded:
  https://github.com/pte-org/pte-api/actions/runs/41106191864

## Recoverable backups on VPS

- `/home/ubuntu/pte-db-backups/pte-before-entity-refactor-20261030T181816Z.dump`
- `/home/ubuntu/pte-db-backups/pte-final-before-reset-20261030T183546Z.dump`
- `/home/ubuntu/pte-db-backups/pte-v14-before-catalog-seed-20261030T183744Z.dump`

These are custom-format PostgreSQL dumps checked with `pg_restore --list`.
The old production data was removed from the active DB and remains recoverable
from the pre-reset dumps. A full restore rehearsal of those dumps was not run.

## Requested admin and reusable exam seed

- SQL: [production-admin-exam-seed.sql](../../data/production/production-admin-exam-seed.sql)
- Manifest: [production-admin-exam-seed.manifest.json](../../data/production/production-admin-exam-seed.manifest.json)
- Instructions: [README](../../data/production/README.md)
- Exporter: [export-production-exam-seed.py](../../tools/export-production-exam-seed.py)

Read all six catalog tables from the local DB using a repeatable-read snapshot.
Exported 23 task types, 96 shared questions, 264 options, 55 referenced media
objects, 7 templates and 54 template items. The requested Platform Admin is
`admin@gmail.com`; the seed stores its requested demo password only as BCrypt.
Local authors and media owners are mapped to this admin. Destination identity
IDs are generated and option/template-item foreign keys are remapped by UUID.

Applied the seed twice to the isolated rehearsal database, with stable counts.
An independent read-only review found no concrete introduced blockers. Applied
the seed to production in one transaction after taking the V14 pre-seed backup.
All six production table counts match the manifest. Exactly one active template
and the requested admin's `PLATFORM_ADMIN` role were verified.

Existing V1 demo records remain. Local organizations, users, payments, scheduled
exams, historical snapshots, student attempts, answers and scores were not
exported. Cloudinary asset binaries are referenced rather than copied.

## Authenticated and public verification

- Requested admin login succeeded with the configured credentials.
- Authenticated `/api/v1/auth/me`, `/api/v1/questions`, `/api/v1/task-types` and
  `/api/v1/exam-definitions` returned HTTP 200.
- `/api/v1/exam-definitions/active` returns HTTP 403 for Platform Admin by design:
  the current controller restricts that endpoint to `HOST_ADMIN`.
- Tenant, vendor and practice roots and public tenant health returned HTTP 200.
- No complete student exam, scoring/publication or practice journey was executed.

### Follow-up: admin login routing

After the deployment, Nginx still held addresses resolved before the web
containers were recreated. Public admin `/login` matched the tenant container's
HTML checksum, while public tenant `/login` matched the vendor container's HTML.
The API itself accepted the requested admin's credentials.

Validated Nginx configuration with `nginx -t` and performed a graceful
`nginx -s reload`. Public admin and tenant checksums then matched their correct
containers. A real browser login through the vendor UI returned HTTP 200 for
both auth POST requests and reached `https://pte-admin.duckdns.org/admin`.
No login source code or password-handling contract was changed. A deployment
script reload or dynamic upstream resolution remains needed to prevent stale
addresses on future container recreations.

### Follow-up: AI chat configuration activation

Confirmed the six requested chat/practice environment entries existed locally
but were absent from the VPS environment file. Copied only those entries under
the shared deployment lock, preserved mode 600 and saved an external env backup.
No values or API keys were printed. Compose configuration validation passed.

On explicit request, rebuilt `web-practice` with the enabled chat build flag,
recreated only `app` and `web-practice`, validated and gracefully reloaded Nginx.
Both containers became healthy and the backend actuator returned `UP`. Verified
the three backend feature switches were enabled, key/model were nonempty and
the practice image contained the enabled build flag.

The authenticated admin chat usage endpoint changed from HTTP 404 to HTTP 200.
Reloading the actual browser page removed the report-load error. All three
portal roots returned HTTP 200. This verifies activation and report access;
no student prompt was sent to Gemini and provider response quality was not tested.

## Other workflows

- Web validation passed. Its first deploy failed because the backend was
  unhealthy before the DB transition. Attempt 2 passed validation and deployment:
  https://github.com/pte-org/pte-web/actions/runs/41106253998
- Practice lint and build passed, but unit tests failed in
  `tests/unit/features/chat/chat-api-contract.test.ts`: the suite's callback
  eagerly reads the sibling API contract file even when `describe.skipIf` is
  true. The single-repository Actions checkout lacks that file. No practice
  source change or push was performed in this deployment operation:
  https://github.com/pte-org/pte-practice/actions/runs/41106293606

## Desktop artifact

Built pte-app commit `5c06a6f` using:

```powershell
flutter build windows --release --dart-define=PTE_API_BASE_URL=https://pte-tenant.duckdns.org
```

Packaged the entire Release directory, including DLLs and data, at
`pte-app/build/distributions/pte-app-windows-production-20261031.zip`.
Build succeeded; no desktop login/device/exam walkthrough was performed.
