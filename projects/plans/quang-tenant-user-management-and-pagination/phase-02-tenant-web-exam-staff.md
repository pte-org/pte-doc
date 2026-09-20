# Phase 02: Tenant-web Exam Staff workflow

## Goal

Give Host users one screen to manage Proctor and Examiner accounts.

## Implemented work

1. Added the `features/examStaff` feature module with constants, types, API
   hooks, list view, and create modal.
2. Added `/host/exam-staff` inside the authenticated dashboard shell.
3. Added search, role/status filters, sort selection, page-size selection,
   first/last navigation, loading state, error state, and empty state.
4. Added Suspend and Reactivate actions using the existing user lifecycle API.
5. Added the role selector and create form. Email and full name are required;
   temporary password remains required by the current API contract.
6. Invalidated Exam Staff and tenant-user caches after create/suspend/reactivate.
7. Added the Exam Staff item to the host navigation.

## Student compatibility

- The Students page and its Excel import modal were not replaced.
- The existing student-roster pagination remains in place.
- Student create/import fields remain optional at the frontend bulk boundary.
