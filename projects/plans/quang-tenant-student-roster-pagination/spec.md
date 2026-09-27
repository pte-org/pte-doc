# Spec: Tenant student roster pagination

**Date:** 2026-09-15  
**Status:** Revised after codebase review

## Problem

The tenant Students page currently loads the tenant user list and class
memberships, hides the table until a search query is entered, and filters only
by full name or phone. It cannot provide reliable default ordering, Program/
Class filters, or server-side pagination. A student can exist in IAM while the
page appears empty or while a free-text `class_name` is mistaken for a real
Class assignment.

## User stories

- **P1** As a host admin, I can open Students and see the first page of every
  student account in my tenant, newest first, with suspended accounts marked
  rather than hidden.
- **P1** As a host admin, I can move between pages without loading the whole
  tenant roster into the browser.
- **P1** As a host admin, I can search by name, email, phone, or student code.
- **P1** As a host admin, I can filter by Program, Class, and assigned/unassigned
  status, with tenant isolation enforced by the API.
- **P2** As a host admin, I can change the sort field/direction and receive a
  stable result across page requests.
- **P2** As a host admin, I can create a student and see the roster update after
  the read model catches up, without a full browser reload.
- **P2** As a host admin, I can suspend a student from the roster and reactivate
  them later, instead of suspension being a one-way door.
- **P3** As an operator, I can rebuild the roster projection idempotently for
  users that existed before this feature was deployed.

## Scope

### In scope

- A server-side paged tenant-roster query.
- Program/Class/assignment filters sourced from Admin domain data.
- Newest-first default sort and selectable sort options.
- A local Admin read projection for the non-authoritative IAM student fields.
- Admin-side inbound messaging infrastructure (processed-event idempotency,
  listener container factory, queue + DLQ bound to `outbox.iam.exchange`), which
  does not exist today — Admin is currently publish-only.
- An extended `UserCreatedEvent` payload carrying the roster display fields.
- An internal IAM user-export endpoint and an idempotent existing-data backfill.
- IAM user reactivate — the missing inverse of the existing `suspend`, plus the
  client functions and row actions for both, which have no frontend today.
- Tenant-scoped API authorization, input bounds, and manual/API verification.

### Out of scope

- A separate Grade field. In the current model, Program is the parent level of
  Class and is the closest existing domain concept to Khối/Khóa.
- Replacing the existing create/import or class-assignment workflows.
- Full-text search infrastructure or cursor pagination.
- Automatic git commit, push, or deployment from this plan.

## Proposed API contract

```text
GET /api/admin/student-roster
  ?page=0
  &size=20
  &search=
  &programPublicId=
  &classPublicId=
  &assignmentStatus=ALL|ASSIGNED|UNASSIGNED
  &sort=CREATED_AT|FULL_NAME|STUDENT_CODE
  &direction=ASC|DESC
```

Rules:

- Tenant comes from the authenticated JWT; a tenant id is never accepted from
  the query string.
- `page` is zero-based; negative values resolve to 0.
- Default `size=20`; maximum `size=100`.
- Default `sort=CREATED_AT`, `direction=DESC`.
- Every sort has a deterministic `publicId` tie-breaker.
- `programPublicId` and `classPublicId` are validated against the caller's
  tenant. A class filter must also belong to the selected Program when both
  are supplied.
- `UNASSIGNED` means no `class_memberships` row exists for the student. There is
  no active/inactive flag on membership — assignment is row presence, and a
  student can hold at most one membership (`student_public_id` is globally
  unique). The IAM `class_name` profile field does not affect assignment status.
- There is no `status` filter parameter. Suspended accounts are returned with
  `status: SUSPENDED` and rendered with a badge — the roster is where a host
  finds a suspended account in order to reactivate it.

Response shape, inside the existing `ApiResponse.data` envelope:

```json
{
  "data": [
    {
      "studentPublicId": "...",
      "email": "...",
      "fullName": "...",
      "studentCode": "...",
      "phone": "...",
      "status": "ACTIVE",
      "createdAt": "2026-09-15T10:00:00Z",
      "programPublicId": "...",
      "programName": "...",
      "classPublicId": "...",
      "className": "..."
    }
  ],
  "meta": {
    "page": 0,
    "size": 20,
    "totalElements": 0,
    "totalPages": 0,
    "first": true,
    "last": true,
    "hasNext": false,
    "hasPrevious": false
  }
}
```

## Measurable success criteria

- Opening Students renders a table without requiring a search term.
- With 45 roster records and `size=20`, pages contain 20, 20, and 5 records;
  `totalElements=45` and no record appears on two adjacent pages.
- Default ordering is `createdAt DESC, studentPublicId DESC`.
- Search matches full name, email, phone, and student code.
- Program/Class/assignment filters return only matching records and preserve
  correct `totalElements`.
- A student without a `class_memberships` row appears as `Unassigned`.
- A suspended student still appears in the roster, marked as suspended, and can
  be reactivated from the row; login is blocked while suspended and works again
  after reactivation.
- A host cannot retrieve another tenant's roster, Program, Class, or membership
  by changing query ids.
- `size > 100` is capped or rejected consistently; no endpoint returns an
  unbounded tenant roster.
- Creating/importing a student invalidates the query and the new account becomes
  visible after projection synchronization, without a full page reload.
- Quality audit passes with no BLOCKER/HIGH findings; no unit-test command is
  run unless the user changes the existing `unitest: ko` decision.
