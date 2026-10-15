# Phase 10 (OPTIONAL, P3): Tenant Province for the Map

## Requirements
Tenants carry a province captured through the real creation path, and the admin dashboard map section returns tenant counts by province (plus an unmapped count) so the existing Vietnam map shows real data. Priority: P3; Phases 4 and 8 already ship the map with an empty-state fallback.

## Design Constraints
- Additive and nullable everywhere; existing tenants and clients remain valid and legacy tenants count as unmapped; no automatic backfill.
- Tenants are only created through the application approval path, so the province must flow end to end: the PUBLIC application submission (organisations submit it unauthenticated through the public applications endpoint from the tenant-web register-organisation form), application entity and migration, application request/response objects, tenant creation in the tenancy service, tenant response, and the vendor approve/create UI.
- Because submission is public, the closed province code list is validated server-side on the public submit endpoint as well as on approval; client-side validation is only a convenience.
- Depends on Phase 3 (admin gating, cache bucket) and Phase 8 (vitest installed in vendor-web, map consumer).
- Province values come from a closed code list: the frontend list in the vendor tenancy constants is the source and must be mirrored in the backend with a validation that rejects unknown codes; the two lists are kept in sync by a test or a single documented source.
- Map section requires tenant-read permission, goes through the Phase 3 gating and cache bucket, and is portable JPQL/derived.
- Migration is V98 (recheck at merge time); the frontend never renders fake locations.

## Steps
1. Add the migration (V98) adding nullable province columns on tenants and tenant applications, and update both entities.
2. Extend the application request/response objects and the approval path so the province travels from the application into tenant creation in the tenancy service; extend the tenant response and any tenant update path.
3. Mirror the province code list in the backend with validation, and add a test that compares it with the frontend list or documents a single source.
4. Add the tenant-by-province aggregation with unmapped count and wire the map section into the admin dashboard service with its permission check.
5. Extend api-client types and add an optional province field (copy in vi/en message files) to the tenant-web register-organisation form (the public submit form), and to the vendor application approval/create forms; feed the map widget from the new section.
6. Add tests: backward compatibility without province, invalid code rejected on the public submit endpoint and on approval, unmapped counting, role gating, Postgres-gated migration run (through V98), and frontend mapper tests.

## Success Criteria
- `mvnw -pl app test -Dtest='com/pte/overview/**/*Test,com/pte/tenancy/**/*Test,com/pte/billing/**/*Test' -Dsurefire.failIfNoSpecifiedTests=true` passes.
- `mvnw -pl app test -Dtest=OverviewMigrationPostgresIntegrationTest -Dlifecycle.test.db.url=jdbc:postgresql://localhost:5432/<db> -Dsurefire.failIfNoSpecifiedTests=true` passes with V98.
- Architecture test diff versus the Phase 1 baseline shows no new violations.
- Frontend, each separately: `pnpm --filter @pte/api-client test`, `pnpm --filter vendor-web lint`, `pnpm --filter vendor-web typecheck`, `pnpm --filter vendor-web test`, `pnpm --filter vendor-web build` pass.
- Tenant-web, each separately: `pnpm --filter tenant-web lint`, `pnpm --filter tenant-web typecheck`, `pnpm --filter tenant-web build` pass (register-organisation form changed).
- Browser: submitting a public application with a province, then approving it with a province then loading `/admin` shows the tenant on the map; legacy tenants appear in the unmapped count.

## Quality and Testing State
- Quality gate: not evaluated (Cook runs `/ck:quality --gate` after implementing this phase)
- Testing: not started

## Risks
- Under-scoped change touching billing (applications), tenancy and vendor forms: keep every field optional and verify the full approval flow manually.
- Backend and frontend province lists drift: enforce with the comparison test.
- Optional phase may be skipped: the map stays in its empty-state mode, which is acceptable for this task.
