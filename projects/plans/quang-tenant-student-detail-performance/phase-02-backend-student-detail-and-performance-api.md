# Phase 02: Backend student detail and performance API

**Status:** Implemented; backend compile passed; tests/quality skipped by user request
**Surface:** `pte-api` identity/enrollment/attempt/reporting boundaries
**Depends on:** Phase 01 contract and permissions
**Blocks:** Frontend API-client integration

## Goal

Implement the server-owned detail, profile mutation, attempt-history, and performance capabilities required by the new tenant student workspace without violating module boundaries or score semantics.

## Work items

1. Implement the approved composite student detail read or equivalent public query facade.
2. Add the approved identity profile update contract with strict field allowlist and validation.
3. Reuse existing scoped suspend/reactivate and credential-generation behavior; repair only contract gaps discovered in Phase 01.
4. Implement a tenant-scoped, paginated attempt-history query with an allowlisted sort/filter set and bounded page size.
5. Implement the performance aggregate query for overall and four communicative skills.
6. Add batch/read projection methods across public service boundaries where session/report metadata is needed. Do not import another module's repository directly.
7. Ensure history/performance reads do not call a side-effectful per-attempt report path.
8. Return explicit report/score states and sample counts. Preserve `sufficientData` and omit missing values instead of zero-filling.
9. Add focused unit and API tests for authorization, validation, empty pages, date/status filters, score aggregation, tenant isolation, and the absence of an unsupported detail-page program filter.

## Proposed backend responsibilities

### Detail read

Return only data needed for the page header/account context and capability flags. Current class/program values must come from the authoritative membership/enrollment source. Identity display fields may come from the identity public service.

### Profile update

The baseline allowlist is `fullName`, `email`, `phone`, and `dateOfBirth`. Email is editable. Username, roles, password, student code, class, and program are excluded from the mutation. Validate email uniqueness and domain rules through the existing identity contract.

### Attempt history

Return a compact row projection containing IDs, session/name context, attempt number, lifecycle timestamps/status, report visibility/state, overall summary only when it is from a published immutable report, and navigation metadata. Do not return a full report snapshot for every row or invent historical program context.

### Performance

Aggregate only published, immutable reports with sufficient data. Include attempt count, latest-attempt context, overall average when the defined data suffices, and one entry for each of Listening, Reading, Speaking, and Writing. Include sample counts and availability state so the UI can explain why a value is absent. History may separately expose live/unpublished report state.

## Design Constraints

- All browser-facing endpoints use explicit tenant and role authorization.
- New student-workspace endpoints are `HOST_ADMIN`-only and limited to the current tenant.
- Reuse `UserService.findScoped` or its approved equivalent for identity scope and hierarchy checks.
- Do not expose password hashes, reset tokens, or stored credentials.
- Do not allow profile PATCH to alter class/program membership.
- Do not use direct cross-module repository access.
- Do not issue unbounded `size` values or accept arbitrary sort columns.
- Do not turn missing/untested skills into zero.
- Avoid N+1 database/service calls; use batch queries or read projections.
- Preserve existing report publication and immutable-snapshot rules.
- Keep unpublished/live reports out of official performance aggregates.
- Do not add a detail-page program filter or program snapshot migration in V1.

## Quality and Testing State

Implementation evidence: `./mvnw.cmd -pl app -DskipTests compile` passed. The following planned checks were skipped by explicit user request:

- focused service/controller tests;
- focused API tests for tenant isolation, pagination, date/status filters, absence of detail-page program filtering, and report scope;
- query/request-count review for history and performance;
- static checks appropriate to `pte-api`;
- explicit note of any behavior not proven against production PostgreSQL or deployed HTTP infrastructure.

## Blocking gate

Phase 03 cannot consume the API until the response DTOs, errors, page metadata, filters, authorization outcomes, and report-state semantics are stable and tested.

## Acceptance criteria

- An authorized host can load a student in its own tenant.
- A cross-tenant or unauthorized request cannot reveal the student.
- Profile update rejects unsupported fields and validates the approved fields.
- Attempt history is paginated and all filters are applied by the server.
- Performance values match the defined report scope and missing-data rules.
- The implementation does not fan out to one report generation/read call per attempt and does not create report records on a read.
- V1 detail history does not expose a misleading program filter; the existing roster filter remains separate.
