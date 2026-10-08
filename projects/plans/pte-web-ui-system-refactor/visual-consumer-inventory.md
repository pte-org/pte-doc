# Phase 01 visual consumer inventory

**Status:** PASS (static scan).

| Consumer | Current source | Assigned phase |
|---|---|---|
| Semantic tokens/shell/sidebar/header | `packages/ui/src/styles`, `packages/ui/src/layouts` | 02-04 |
| Cards, stats, tables, fields, dialogs | `packages/ui/src/components` | 04 |
| Charts/status/overlay colors | Feature views plus shared status/badge/alert components | 04 for shared primitives; owning migration wave for feature-only consumers |
| Vendor shell/navigation | `apps/vendor-web/features/auth`, `apps/vendor-web/lib/navigation.tsx` | 05 |
| Vendor commercial/content | `apps/vendor-web/features/commercialization`, `licensing`, `questionbank`, templates | 06 |
| Tenant host operations | `apps/tenant-web/features/classes`, `programs`, `studentSearch`, `examStaff` | 07 |
| Tenant exam/role/public | `apps/tenant-web/features/exams`, `examiner`, `public`, `reports` | 08 |

No new charting or animation dependency is introduced.
