# Session record: Vendor/Tenant commercial and authoring workflow

**Date:** 2026-09-19  
**Status:** Implemented; frontend locally verified  
**Repository scope:** `pte-api`, `pte-web`, `pte-doc`  
**Created by:** Codex

## Purpose

This folder records the implementation and local validation completed during
the session. It is a delivery record for the current working tree, not a new
feature plan that should be started from zero.

## Delivery summary

1. Clarified the commercial boundary between the admin **Plan catalog** and
   tenant **subscriptions/access**. No separate `Active subscriptions` or
   `Active access` screen was added.
2. Connected the tenant public plan home to active plans returned by the API,
   grouped by exam packages and student-capacity add-ons, instead of seed cards.
3. Improved vendor plan catalog behavior: the create form opens only after
   `Add plan`, the catalog has an `All` filter, and plan lifecycle/status data
   remains API-driven.
4. Reworked question-type and score-template authoring around server-owned
   PTE task metadata, empty editable drafts, explicit add/edit/delete flows,
   activation, cloning, and JSON export.
5. Reorganized tenant navigation and platform/admin scope: tenant hosts run
   exams; platform admins manage catalog/content; the old admin exam-blueprint
   entry is not used.
6. Added a shared accessible Collapse/Expand section and applied it to every
   current statistics-card group in vendor and tenant screens.

## Phase map

| Phase | Outcome | Status |
|---|---|---|
| 1 | Plan catalog, tenant API-driven plan home, and local admin/host test flow | Implemented |
| 2 | Question-type catalog and score-template authoring workflow | Implemented in working tree |
| 3 | Admin/tenant navigation and exam-organization boundary | Implemented |
| 4 | Shared collapsible statistics sections and compact question overview | Implemented and browser-verified |
| 5 | Local verification, build, review, and session handoff | Recorded |

## Key implementation areas

### Backend (`pte-api`)

- Question-type catalog service/controller/repository changes.
- Supported PTE task-type endpoint and canonical section/scoring metadata.
- Soft deletion for question types so existing question references remain
  valid.
- Score-template create-empty-draft and draft-delete endpoints.
- Score-template replacement accepts an empty draft while the editor is being
  built.
- Migration `V37__question_type_catalog.sql` adds the persisted question-type
  catalog and question foreign-key alignment.

### Frontend/API client (`pte-web`)

- Vendor question-type create/edit/delete modal and supported-type lookup.
- Vendor score-template create, edit, add/remove item, save, activate, clone,
  delete-draft, and JSON-export flows.
- Vendor/tenant commercial plan catalog and public plan presentation.
- Shared `CollapsibleSection` UI component and statistics wrappers.
- Tenant logo/brand navigation behavior and role-aware host navigation.

## Local roles used

- `admin@test`: local platform-admin account supplied for the session.
- `host@test`: local host-admin account supplied for the session.
- Passwords were intentionally not copied into this repository record.

## Decisions captured

- `Plan catalog` describes purchasable catalog definitions; it is clearer than
  using `Subscription` for the admin screen.
- Plans shown publicly/tenantly are active API plans only.
- Platform admin does not create or organize tenant exams; tenant host roles
  operate exam delivery within their organization.
- Statistics sections are expanded by default and can be collapsed to reclaim
  vertical space.
- The question-bank overview keeps a compact 3-column/2-row arrangement with
  Total questions and Draft in the first column and skills distributed across
  the remaining columns.

## Known limitations

- The tenant Programs detail route had no seeded program for `host@test`, so
  its collapse interaction was covered by typecheck/build but not by a live
  detail-page click in Playwright.
- Vendor lint still reports one pre-existing `@next/next/no-img-element`
  warning in `QuestionEditorForm.tsx`; no lint errors were introduced.
- No deploy, commit, or push was performed by this session.

See the phase notes and verification report for the detailed file-level and
test-level record.
