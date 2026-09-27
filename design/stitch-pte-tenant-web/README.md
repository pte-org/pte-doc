# Stitch — PTE Tenant Dashboard

Design reference exported from the Stitch project [PTE Tenant Dashboard](https://stitch.withgoogle.com/projects/2518511518052928179).

- Project ID: `2518511518052928179`
- Captured: `2026-09-14`
- Source of truth for visual implementation: the PNG screenshot in each screen folder
- HTML export is included for inspecting layout, typography and design tokens
- The project contains 16 desktop reference screens, including responsive and state references

## Screen mapping

| Reference | Current route / scope | Screen folder |
| --- | --- | --- |
| T1 — Dashboard (Overview) | `tenant-web /host/dashboard` | `01-dashboard-overview` |
| T2 — Learners | `tenant-web /host/students` | `02-learners` |
| T3 — Programmes | `tenant-web /host/programs` | `03-programmes` |
| T4 — Programme Detail | `tenant-web /host/programs/[publicId]` | `04-programme-detail` |
| T5 — Class Detail | `tenant-web /host/programs/[publicId]/classes/[classPublicId]` | `05-class-detail` |
| T6 — Exam Sessions | `tenant-web /host/exams` | `06-exam-sessions` |
| T7 — Session Detail | `tenant-web /host/exams/[publicId]` | `07-session-detail` |
| T8 — Create / Edit Exam Session | session create/edit flow | `08-create-edit-exam-session` |
| T9 — Scoring Review | session scoring review flow | `09-scoring-review` |
| T10 — Audit Log | `tenant-web /host/audit-log` | `10-audit-log` |
| T11–T14 | Staff, roles, settings and branding references | `11-staff-roles` – `14-settings-branding` |
| T15 | Empty, loading and error state reference | `15-state-pack-empty-loading-error` |
| T16 | Tablet and mobile responsive reference | `16-responsive-views-tablet-mobile` |

## Workflow

1. Read the target Stitch screenshot and HTML export.
2. Map the screen to the existing tenant-web route or feature flow.
3. Implement shared tokens/components first, then screen-specific styling.
4. Capture the implemented route at the reference viewport and compare against this folder.
5. Run lint, typecheck, production build and responsive browser checks.

