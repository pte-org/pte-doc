# Phase 01 density audit

**Status:** PASS (static classification and implementation backlog).

The rubric is `J/S/I/M/A/C` from the master plan. File length is not used as a
classification signal.

| Priority | Surface | Classification signal | Treatment |
|---|---|---|---|
| P1 | Vendor `LicenseCodesView` | Function-heavy: issue/recovery, lookup, list, reveal, revoke | In-route Issue/Lookup/Issued work areas; reveal/revoke drawer/dialog |
| P1 | Vendor `PlanCatalogView` | Function-heavy: catalog, CRUD, lifecycle, conflict | Stable list plus create/edit drawer/modal |
| P1 | Vendor score-template list/editor | Function-heavy: CRUD, ordering, diagnostics, activation | Editor sections/tabs |
| P1 | Tenant `StudentSearchView` | Function-heavy: filter, roster, import, credentials, status | Filter/table plus management/details drawers |
| P1 | Tenant `SessionDetailView` | Function-heavy: lifecycle, participants, staff, scoring, publication | In-route tabs |
| P1 | Tenant `CreateExamWizard` | Function-heavy: setup, audience, policy, review | Common stepper while preserving current two-step behavior |
| P2 | Vendor question bank/editor | Function-heavy/content-heavy: authoring, media, scoring, preview | List/detail plus editor sections and preview |
| P2 | Tenant assignment/review panels | Function-heavy subflows | Feature-owned panels; no common business logic |
| P2 | Tenant classes/programs | Function-heavy: roster/import/merge/assign | Summary/members/actions sections |
| P2 | Tenant `ExaminerWorkView` | Function-heavy: queue/detail/scoring | Master-detail; mobile drawer |
| P2 | Vendor `TenantDetailView` | Function-heavy: identity/account/branding/organizations | Route-preserving tabs (implemented in this cook) |
| P3 | Tenant `HomeView` | Content-heavy narrative | Hierarchy/anchors; no route split |

All remaining routes are normal until a later evidence scan promotes them. A
route-level split remains out of scope.
