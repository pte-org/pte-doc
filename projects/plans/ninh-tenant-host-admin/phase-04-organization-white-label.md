# Phase 4: Organization Hierarchy + White-Label

## Requirements

Business rules 3 and 4: a Host (`Tenant`) can have multiple Organizations
(branches/facilities), and the admin can configure a Logo + Primary Color
per Host. Neither exists in the schema today — `Tenant` is flat, with no
child entity and no branding fields. This phase also closes a gap already
on record from the original review: there is no update endpoint on `Tenant`
at all (only onboard/suspend/get/list) — `updateBranding` is the first one.

Maps to: **Business rules 3 (Organization hierarchy) and 4 (white-labeling).**

## Design Constraints

- Depends on Phases 0–3 (extend the corrected, consolidated admin surface,
  not the pre-cleanup duplicate).
- Mirror `PinnedExamSnapshot`/`PinnedItem` (`exam-delivery`) exactly for the
  `Tenant`→`Organization` relationship: `@OneToMany(mappedBy="tenant",
  cascade=CascadeType.ALL, orphanRemoval=true, fetch=FetchType.LAZY)
  @OrderBy("createdAt ASC")` + `addOrganization()` back-reference helper on
  `Tenant`; `@ManyToOne(fetch=LAZY) @JoinColumn(name="tenant_id",
  nullable=false)` + an indexed FK column on `Organization`.
  `Organization` extends `BaseEntity` (its own `publicId` — it's referenced
  independently, not only nested under `Tenant`).
- **N+1 query risk (real, must be actively avoided, not just noted)**:
  because `organizations` is lazy, `GET /tenants` (list) must never trigger
  its lazy-load per row. If the list response doesn't need
  organization data, ensure `TenantMapper.toResponse()` simply never calls
  `tenant.getOrganizations()` on the list path (only on the single-tenant
  `get(publicId)` path, if there). If the list genuinely needs org counts,
  use `@EntityGraph(attributePaths = {"organizations"})` on
  `TenantRepository.findAll()` for a single JOIN — never a manual per-row
  lazy access in the mapper.
- `logoUrl`/`primaryColor` live on `Tenant` (business rule 4 says "per
  Host"), never duplicated onto `Organization`.
- Check `services/media` (already routed in the gateway) before assuming
  `logoUrl` is just a plain string the FE sets directly — if a presigned
  upload flow already exists there, the FE calls it to get a URL, then only
  passes that URL to `Tenant.logoUrl`; don't build new upload plumbing.
- **Logo upload security (real requirement, not optional hardening)**:
  never trust a client-declared file extension or `Content-Type` alone
  (trivially spoofed). FE: block before sending — max size (2MB) and a MIME
  whitelist (`image/jpeg`, `image/png`, `image/svg+xml`) at the
  input/dropzone, with a clear inline error, not a silent rejection. BE
  (`services/media` or whatever layer receives the file before storage):
  validate the file's actual magic bytes/header, and enforce the size limit
  server-side too — if `services/media` doesn't already do this, that's
  where it needs to be added, not bypassed with a shallow check inside
  `admin`.
- `Organization.name` unique **within** a tenant, not globally — enforce at
  the service layer (a composite DB unique constraint is more awkward to
  evolve under `ddl-auto: update`).
- Adopt the `CurrentUser caller` service-parameter convention in
  `OrganizationService` now (even though this phase may not strictly need
  the actor for anything), so Phase 5 isn't the only place introducing it —
  cheap to do consistently.
- Action-suffix REST style for the new branding endpoint (`POST
  /tenants/{publicId}/branding`), matching `/suspend`/`/reactivate` from
  Phase 2 — not a PATCH-on-resource, to stay consistent with the rest of
  `TenantController`.
- `ddl-auto: update` handles the new table/columns automatically — no
  Flyway migration.

**Open question — must be resolved with the user before coding, not
assumed**: `Organization`'s exact field set beyond `name` (address? facility
type? its own active/inactive status independent of the parent Tenant's?).
The business rules only say "branches/facilities" — that's not enough to
design a schema against without guessing.

## Steps

1. Ask the user for `Organization`'s field set (blocking — see Open
   question above) before writing the entity.
2. Backend: `Organization.java`, `OrganizationRepository`,
   `OrganizationNotFoundException`/`OrganizationNameAlreadyUsedException`,
   `CreateOrganizationRequest`/`OrganizationResponse`, `OrganizationMapper`,
   `OrganizationService` (`create`/`list`/`get`, `CurrentUser caller`
   threaded through).
3. `Tenant.java`: add `organizations` relationship + `addOrganization()`;
   add `logoUrl`/`primaryColor`.
4. `TenantLifecycleService.updateBranding(...)`; `TenantController` gets
   `POST /tenants/{publicId}/branding`.
5. `OrganizationController` (`/tenants/{tenantPublicId}/organizations`,
   same `@PreAuthorize` as `TenantController`).
6. New outbox events (`OrganizationCreatedEvent`,
   `TenantBrandingUpdatedEvent`) + `AdminConstants` entries.
7. Confirm `TenantMapper.toResponse()`'s list-path N+1 safety (or add the
   `@EntityGraph`) per the Design Constraint above — write the mapper test
   that would catch a regression here, not just eyeball it.
8. Verify/extend `services/media`'s upload validation per the security
   constraint above.
9. Frontend: `Organization` types + request module; a panel/route to manage
   a Host's organizations (check via Glob whether a per-tenant detail page
   already exists before assuming one needs to be added); a branding editor
   (logo + color) on the "edit" flow, not creation time; react-query hooks
   following `useCreateTenant`'s shape.

## Success Criteria

- [ ] `Organization`'s field set was confirmed with the user, not assumed.
- [ ] `GET /tenants` (list) does not issue N+1 queries — verified (e.g. via
      a logged/counted query assertion), not just "looks fine."
- [ ] Creating an Organization under a Host is visible in the UI
      immediately.
- [ ] Setting branding (logo + color) persists and renders.
- [ ] Logo upload rejects an oversized or wrong-MIME file both client-side
      (immediate UI feedback) and server-side (even if the client check is
      bypassed).
- [ ] `OrganizationServiceTest.java`, extended `TenantLifecycleServiceTest.java`
      (covering `updateBranding`), `OrganizationMapperTest.java` all pass.

## Quality and Testing State

- Not started — blocked on the Organization field-set question above.
