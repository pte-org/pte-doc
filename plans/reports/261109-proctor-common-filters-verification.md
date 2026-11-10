# Proctor common table filters and fixture data

Date: 2026-11-09. Local tenant-web and the existing local Docker database only.

## UI

- Incidents uses shared `DataTable.filters` with shared `Select`; its report
  button uses `DataTable.toolbarActions`. The separate filter card is removed.
- Attendance uses shared `DataTable` search, filters and pagination. The status
  dropdown includes counts. Host attendance uses the same table/filter component.
- Proctor search updates locally while typing and commits after 300 ms using
  `router.replace`, preserving current filters and avoiding history per keystroke.
  Host API search uses the existing shared debounced-search hook.
- Closed-session blocking messages and attempt activity labels are presented
  as readable Vietnamese rather than raw `SESSION_CLOSED` / `SUBMITTED` values.
- No backend API contract, session state, assignment or edit-permission changes.

## Data

The fixture `UI-WEEK-3`, public ID `6d9c9766-1516-4fc1-bf52-4463b86a3e72`, now has:

- Six incidents: two NEW, one IN_PROGRESS, one ESCALATED, one RESOLVED, one CLOSED.
- Linked students, varied severity/category, owner, resolution and sample history.
- Four attendance rows: one PRESENT/VERIFIED, one LATE/FAILED, one ABSENT/UNVERIFIED,
  one UNMARKED/UNVERIFIED. Sample attendance history is available for updated rows.

The session remains CLOSED, so attendance editing is intentionally unavailable.
Use the existing OPEN `UI-WEEK-1` to exercise actual attendance writes.

Seed source: `pte-api/scripts/seed/seed-local-role-ui-incidents.sql`. It is
transactional, scoped to `UI-WEEK-3` in `e2e`, guarded by the fixture Proctor
membership, skips already edited attendance versions and existing incident titles.
Rerunning kept six incidents and preserved the attendance state. These records
and histories are synthetic UI fixtures, not evidence of real incident handling.

## Verification

- Scoped ESLint and tenant-web TypeScript passed.
- Focused Proctor/exam verification: 23 test files, 167 tests passed.
- Final full tenant-web suite: 99 files, 999 tests passed.
- Final tenant-web production build passed. Existing relative `turbopack.root`
  warning remains nonblocking.
- Diff whitespace verification passed with `core.whitespace=cr-at-eol` to match
  the existing CRLF locale catalog; its diff remains one label change.
- Independent read-only review found no remaining actionable issues.

Browser checks: incident status filter reduced six rows to one; detail and
history loaded; attendance filter reduced four rows to one; email search matched
the intended student. Typing at 25 ms per character produced one attendance
search request and no extra browser-history entry. Mobile document fits 375 px.

Screenshots:

- [Incidents with common toolbar](assets/261109-proctor-common-filters/incidents.png)
- [Attendance with common toolbar](assets/261109-proctor-common-filters/attendance.png)

Boundary: no production seed/deployment or provider calls; actual Host attendance
mutations were not re-exercised. Existing closed-session restrictions remain intact.
