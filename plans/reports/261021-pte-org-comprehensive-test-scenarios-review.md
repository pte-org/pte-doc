# PTE Org comprehensive test scenario review

Date: 2026-10-21 (Asia/Bangkok)

## Deliverable

- Workbook: [261021-pte-org-comprehensive-test-scenarios.xlsx](./261021-pte-org-comprehensive-test-scenarios.xlsx)
- Generator: [generate-pte-comprehensive-test-workbook.py](../../tools/generate-pte-comprehensive-test-workbook.py)

## Coverage produced

The workbook contains:

- 109 business, security, integration and non-functional test cases.
- 19 backend module coverage rows.
- 329 API endpoint inventory rows extracted from Spring controllers.
- 83 Next.js UI route inventory rows across tenant-web, vendor-web and pte-practice.
- 51 Flutter screen-file inventory rows for pte-app.
- Test data, environment, defect and verification-log sheets.

Every business test case has the requested fields: screen/API, domain or app,
entry steps, preconditions, happy path, unhappy path, expected result,
secondary criteria, permission/tenant boundary, audit/notification/integration,
execution status and evidence placeholders.

## Source areas reviewed

The inventory covers identity, tenancy, enrollment, itembank, media,
scoretemplate, assessment, billing, session, attempt, proctoring, exam staff,
scoring, reporting, practice, notification, support, overview and shared/audit
behavior. It also includes the six human actors and the external PayOS,
Cloudinary, AI-scoring and notification boundaries.

The pte-app section includes one case for every current task type in the
product direction, plus login/session resolution, device check, policy-driven
lockdown, navigation/timer, save/submit and report viewing.

## Read-only checks performed

| Check | Result |
|---|---|
| Workbook ZIP/XML integrity | Pass |
| `https://pte-practice.duckdns.org/` | HTTP 200 |
| `https://pte-practice.duckdns.org/sign-in` | HTTP 200 |
| `https://pte-tenant.duckdns.org/` | HTTP 200 |
| `https://pte-admin.duckdns.org/` | HTTP 200 |
| `https://pte-tenant.duckdns.org/actuator/health` | HTTP 200 |
| Unauthenticated practice catalog | HTTP 401, as expected |

## Execution boundary

The workbook is a complete test baseline and source-derived coverage review;
the 109 business cases are intentionally marked `Not run`. Running all cases
requires controlled fixtures and coordinated accounts for Platform Admin,
Platform Author, Host, Proctor, Examiner and Student. Payment callbacks,
Cloudinary, AI scoring, email OTP and Windows device/lockdown checks should run
in local or staging first. Mutating production tests should be scheduled with
test-only data and an explicit rollback window.

Recommended execution order: P0 identity and tenant isolation, content/template
readiness, billing entitlement, exam generation, pte-app delivery, proctor and
examiner scoring, Host publication, Student report, then P1 integrations and
non-functional checks.
