# Production exam catalog seed

`production-admin-exam-seed.sql` is exported from the current local PostgreSQL
database. Its manifest records row counts and the SQL file SHA-256.

It installs the requested demo Platform Admin (`admin@gmail.com`) with a BCrypt
password hash, plus reusable global content:

- 23 task types (`question_types` after entity consolidation).
- 96 shared questions and 264 answer options.
- 55 media objects referenced by those questions.
- 7 exam/scoring templates and 54 template items (`exam_definitions` and
  `exam_definition_items` after consolidation).

The local author/owner IDs are mapped to the requested admin. Identity primary
keys are allocated on the destination, and child rows are mapped through public
UUIDs. The seed does not copy local users, organizations, payment data, scheduled
exams, snapshots, student attempts, answers or results. Existing V1 baseline demo
records are retained; this file is not a complete database backup.

## Apply

Apply only after the V1 baseline and subsequent migrations through V14 have
completed. The seed refuses to run when student attempts exist. It uses a single
transaction and table locks, updates matching catalog records, replaces the
imported parents' option/template-item lists and selects the local active
template. Reapplying it also resets the requested demo admin's password to the
same configured demo password.

From the VPS, after transferring the SQL file:

```bash
db_role=$(docker exec pte-postgres printenv POSTGRES_USER)
docker exec -i pte-postgres psql -X -v ON_ERROR_STOP=1 \
  -U "$db_role" -d pte < /absolute/path/production-admin-exam-seed.sql
```

Back up the destination before import. The referenced Cloudinary assets are not
embedded in the SQL; production must use the corresponding Cloudinary account.

## Re-export from local

```powershell
python -B pte-doc/tools/export-production-exam-seed.py
```

Docker and Python `bcrypt` must be available. The exporter reads all six catalog
tables in one repeatable-read snapshot and fails on tenant-private questions
that would require an explicit ownership decision.

## Verification performed

The SQL was applied twice successfully to the isolated VPS rehearsal database
created from V1 through V14. Counts remained 96 questions, 23 task types and
7 templates after both applications. Production execution and authenticated
checks are recorded separately in the deployment report.
