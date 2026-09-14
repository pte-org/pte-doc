# Stitch — PTE Admin Dashboards

Design reference exported from the Stitch project [PTE Admin Dashboards](https://stitch.withgoogle.com/projects/3859337323953452143).

- Project ID: `3859337323953452143`
- Captured: `2026-09-14`
- Device: desktop
- Source of truth for visual implementation: the PNG screenshot in each screen folder
- HTML export is included for inspecting layout, typography and design tokens

## Screen mapping

| Reference | Current route | Screen folder |
| --- | --- | --- |
| Tenants List | `vendor-web /admin/tenants` | `01-tenants-list` |
| V3: Tenant Detail | `vendor-web /admin/tenants/[publicId]` | `02-tenant-detail` |
| V6: Question Bank | `vendor-web /admin/questions` | `03-question-bank` |
| V8: Exam Blueprint Builder | `vendor-web /admin/exams` | `04-exam-blueprint-builder` |
| V4: Licences & Quota | `vendor-web /admin/licenses` | `05-licences-quota` |

The tenant portal reuses the same shared visual system through `@pte/ui`; its organization-specific flows are mapped to the same shell, cards, tables, forms and responsive rules.

## Workflow

1. Read the target Stitch screenshot and HTML export.
2. Map the screen to the existing route and feature components.
3. Implement shared tokens/components first, then screen-specific styling.
4. Capture the implemented route at the same viewport and compare against this folder.
5. Run lint, typecheck, production build and responsive browser checks.
