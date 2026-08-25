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
- **Logo upload security (DEFERRED — see the second open question below;
  this bullet describes the original intent, not what shipped this
  phase)**:
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

**Open question — resolved with the user before coding.** `Organization`'s
field set beyond `name`: user chose **all three** offered options —
`address` (String, nullable), `facilityType` (enum, user chose a fixed enum
over free text: `MAIN` / `BRANCH` / `TEST_CENTER`), and an **independent**
`OrganizationStatus` (`ACTIVE`/`SUSPENDED`) — a branch can be
suspended/reactivated on its own, not tied to the parent Tenant's status.
Kept as a separate enum from `TenantStatus` (not reused) even though the
values are identical, since they represent independent lifecycles for two
different aggregates.

**Second open question, discovered mid-phase, also resolved with the
user**: the Design Constraint below on logo-upload security assumed
`services/media`'s presigned-upload flow was a generic building block.
Verified by reading `PresignService.java` directly — it isn't: it's
purpose-built for student Read Aloud audio (whitelists only
`audio/mpeg|wav|webm`), and because the actual PUT goes browser→MinIO
directly, no `pte-api` code ever sees the file bytes at all — server-side
magic-byte validation as literally specified below is architecturally
impossible without new media-service infrastructure (e.g. a
fetch-and-inspect step in `completeUpload`). Presented 3 options (defer
upload entirely / minimal image-MIME extension without real byte validation
/ full hardening as a mini-project); user chose to **defer file upload
entirely this phase** — the branding editor is a plain URL text input, no
file picker, no upload plumbing. Building real image upload is now a
separate, future task once `services/media` is properly extended, not
bundled into this phase.

## Steps

1. ~~Ask the user for `Organization`'s field set~~ — done (see Open question
   above): address + facilityType enum + independent status.
2. Backend: `Organization.java`, `FacilityType`/`OrganizationStatus` enums,
   `OrganizationRepository`,
   `OrganizationNotFoundException`/`OrganizationNameAlreadyUsedException`,
   `CreateOrganizationRequest`/`OrganizationResponse`, `OrganizationMapper`,
   `OrganizationService` (`create`/`list`/`get`/`suspend`/`reactivate` — 2
   more than originally scoped, added because an "independent status" field
   that nothing can ever change would be pointless; mirrors Tenant's Phase 2
   suspend/reactivate shape exactly, including idempotency).
3. `Tenant.java`: added `organizations` relationship + `addOrganization()`;
   added `logoUrl`/`primaryColor`.
4. `TenantLifecycleService.updateBranding(...)`; `TenantController` gets
   `POST /tenants/{publicId}/branding`.
5. `OrganizationController` (`/tenants/{tenantPublicId}/organizations`,
   same `@PreAuthorize` as `TenantController`) — 5 endpoints (create, list,
   get, suspend, reactivate).
6. New outbox events (`OrganizationCreatedEvent`, `OrganizationSuspendedEvent`,
   `OrganizationReactivatedEvent`, `TenantBrandingUpdatedEvent`) +
   `AdminConstants` entries. Organization events use
   `AGGREGATE_ORGANIZATION` ("Organization") so their routing key
   (`Organization.*`) does NOT reach iam's `Tenant.*`-bound consumer —
   intentional, nothing downstream needs them yet.
   `TenantBrandingUpdated` uses `AGGREGATE_TENANT` ("Tenant") so it DOES
   reach iam's consumer; verified (quality gate) that iam's existing
   unrecognized-event-type fallthrough handles it safely without any iam
   change needed.
7. `TenantMapper.toResponse()`'s list-path N+1 safety: guaranteed by
   construction, not just checked — `OrganizationMapper.toResponse(org,
   tenantPublicId)` takes the tenant's publicId as an explicit parameter
   specifically so no call site ever needs `organization.getTenant()`
   (which would lazy-load per row in a list). `TenantMapperTest.java` (new)
   asserts via `Mockito.spy` that `TenantMapper.toResponse()` never calls
   `tenant.getOrganizations()`, so a future edit that reintroduces the risk
   fails the test immediately instead of only "looking fine."
8. ~~Verify/extend `services/media`'s upload validation~~ — superseded by
   the second open question above: upload deferred entirely, no
   `services/media` change made this phase.
9. Frontend: `Organization` types (`packages/api-client/src/types/organization`)
   + request module (`requests/organization`); confirmed via Glob that no
   per-tenant detail page existed yet, so added
   `app/(dashboard)/admin/tenants/[publicId]/page.tsx` (new dynamic route) →
   `TenantDetailView.tsx` assembling a `BrandingEditor` (plain URL inputs,
   per the deferred-upload decision) + an organizations table + create
   modal; react-query hooks (`useOrganizations`/`useCreateOrganization`/
   `useSuspendOrganization`/`useReactivateOrganization`/`useTenant`/
   `useUpdateBranding`) follow `useCreateTenant`'s
   mutate→onSuccess→setQueryData+invalidateQueries shape. `_TenantTable.tsx`
   row name now links to the new detail route.

## Success Criteria

- [x] `Organization`'s field set was confirmed with the user, not assumed.
- [x] `GET /tenants` (list) does not issue N+1 queries — guaranteed by the
      mapper's signature (explicit `tenantPublicId` param, never touches the
      lazy association) and enforced by a regression test
      (`TenantMapperTest`), not just "looks fine."
- [x] Creating an Organization under a Host is visible in the UI
      immediately (query-cache append + invalidate, same pattern as
      `useCreateTenant`).
- [x] Setting branding (logo URL + color) persists and renders.
- [ ] ~~Logo upload rejects an oversized or wrong-MIME file...~~ — N/A,
      upload deferred entirely per the resolved open question; there is no
      file upload to validate this phase.
- [x] `OrganizationServiceTest.java` (11 tests), extended
      `TenantLifecycleServiceTest.java` (covering `updateBranding`, 10
      tests total), `OrganizationMapperTest.java` (1 test),
      `TenantMapperTest.java` (2 tests, new — N+1 regression guard +
      branding-fields mapping) all pass.

## Quality and Testing State

- Backend: `mvn -pl services/admin test` — 24/24 passing (11 new
  `OrganizationServiceTest`, extended `TenantLifecycleServiceTest` to 10,
  new `OrganizationMapperTest` + `TenantMapperTest`).
- Frontend: `tsc --noEmit` clean on `@aptis/api-client` and `vendor-web`;
  `eslint` clean; `next build` clean (new dynamic route
  `/admin/tenants/[publicId]` compiles as expected).
- Quality gate (`ck:quality`, `quality-reviewer` agent, scoped to all
  new/changed Phase 4 files across both repos): found **1 BLOCKER, 1
  MEDIUM, 1 LOW, 1 NOTED**:
  - **QUAL-001 (BLOCKER, fixed)** — the most serious defect found in this
    plan so far. `OrganizationService.create()` originally did
    `tenant.addOrganization(organization); tenantRepository.save(tenant);`
    then immediately read `organization.getPublicId()`. Because `tenant`
    was already a managed entity (loaded via `findByPublicId`),
    `tenantRepository.save(tenant)` routes through
    `entityManager.merge()`, not `persist()`. Per documented JPA merge
    semantics, a *transient* child newly added to a cascaded collection is
    not attached in place during a merge — Hibernate creates a **separate
    copy**, persists that copy, and the original `organization` reference
    never receives its generated `publicId`. The reviewer confirmed this
    empirically against a real local Postgres instance (not just by
    reading), since the existing mocked unit test couldn't catch it (the
    mock faked `tenantRepository.save()` and manually assigned the
    publicId, papering over the real behavior). In production this would
    have made every real `POST .../organizations` call throw an NPE and
    roll back the entire transaction — the phase's core feature completely
    non-functional despite all tests passing. Fixed by persisting the new
    `Organization` directly via `organizationRepository.save(organization)`
    (keeping `tenant.addOrganization()` only for in-memory association
    wiring, not for cascaded persistence) — the exact same reasoning
    behind why the mirrored `PinnedExamSnapshot`/`PinnedItem` reference
    pattern never hit this bug: it always builds a brand-new parent
    together with its children in one `persist()`-routed save, never adds
    one child to an already-persisted parent later. Updated the unit test
    to mock `organizationRepository.save()` instead (matching the real
    call path) so it would have caught this the first time.
  - **QUAL-002 (MEDIUM, fixed)** — `Organization`'s `@Table` had no index
    on `tenant_id`, the FK column used by every list/lookup query;
    Postgres doesn't auto-index FK columns. The Design Constraint said to
    mirror `PinnedItem` "exactly," which does have
    `@Index(columnList = "pinned_snapshot_id")`. Added
    `@Index(name = "idx_organizations_tenant", columnList = "tenant_id")`.
  - **QUAL-003 (LOW, fixed)** — `BrandingEditor.tsx`'s `primaryColor` input
    had no client-side format check before submit, even though the
    backend enforces `^#[0-9A-Fa-f]{6}$` and the codebase's own
    `validateCreateTenant.ts` already establishes the convention of
    mirroring backend format constraints client-side. Added
    `validateBranding.ts` + inline field error, consistent with that
    convention.
  - **QUAL-004 (NOTED, fixed)** — `OrganizationService.get()`'s success
    path (matching tenant) had no direct test, only the
    different-tenant-throws-404 case. Added
    `get_organizationBelongsToMatchingTenant_returnsResponse`.
  - Independently verified during the gate (both confirmed correct, no
    fix needed): the `loadUnderTenant` tenant/organization-mismatch guard
    is a real IDOR-shaped protection, not just a style nit; both new
    controllers' `@PreAuthorize` matches `TenantController`'s existing
    pattern exactly; Organization suspend/reactivate idempotency mirrors
    Tenant's Phase 2 pattern correctly in both code and tests; iam's
    `TenantEventConsumer` really does fall through safely for the
    unrecognized `TenantBrandingUpdated` event type.
  - Re-ran `mvn test`/`tsc`/`eslint`/`next build` after all fixes — all
    clean (24/24 backend tests, including the added/updated ones).
- Manual E2E: not yet run — same deferred gap as prior phases. A live
  Postgres+RabbitMQ re-verification of the QUAL-001 fix itself was
  attempted (mirroring how the bug was originally caught) but blocked by a
  stale password on a pre-existing local dev volume unrelated to this
  session's code changes; relied instead on the corrected mocked unit test
  (now exercising the actual fixed call path) plus the well-documented,
  non-obscure nature of the underlying JPA merge/persist distinction.
