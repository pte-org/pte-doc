# Phase 4: Clients and login-options removal

## Requirements
Sign-in is username and secret only, on web and Flutter. The organization picker, its API calls and the `POST /auth/login-options` endpoint no longer exist; screen copy tells people to use the username their organization issued.

Objective in one line: delete the "choose an organization" login step everywhere, web first, API last.

## Files (verified to exist unless marked)
Web, under `pte-web/`:
- `apps/tenant-web/features/auth/components/LoginView.tsx` and `apps/vendor-web/features/auth/components/LoginView.tsx` — picker state, options call, "pick an organization" gate on submit, the option list block. Keep the login call and the session save from the token claims.
- `apps/tenant-web/features/auth/api.ts` and `apps/vendor-web/features/auth/api.ts` — the organization-options mutation hook.
- `packages/api-client/src/requests/auth/index.ts` (endpoint constant at ~line 21 and the request function at ~55-60), `packages/api-client/src/types/auth/index.ts` (request and option types at ~37-42), `packages/api-client/src/client/client.ts` (public-path list entry at ~line 210).
- Optional login request field for an organization id: remove from the login request type if present (unverified).
- `apps/tenant-web/features/auth/constants.ts`, `apps/vendor-web/features/auth/constants.ts` — hint and label copy ("Use the username your organization gave you"; platform staff keep e-mail).
- The `tenantId` handling in the api-client token/session code stays: the token still carries `tenant_id`.
- Tests: `packages/api-client/tests/unit/requests/auth/auth.test.ts`, `packages/api-client/tests/unit/client/client.test.ts` (entry at ~line 239), `apps/vendor-web/tests/unit/features/auth/api.test.ts` (~line 57), `apps/tenant-web/tests/unit/features/auth/api.test.ts` (~lines 50, 105).

Flutter, under `pte-app/`:
- `lib/` has no call to the login-options endpoint and no organization picker (verified by search of `lib`). The login page sends the typed value as the username (`features/auth/data/repositories/auth_repository_impl.dart`); the claims reader keeps `tenant_id` (`features/auth/domain/jwt_claims.dart`) and stays.
- `lib/core/constants/app_strings.dart` — the username hint (~line 17-18) says "from your account e-mail or from your organization": reword.
- `lib/features/auth/presentation/pages/login_page.dart` — the field is named for e-mail and uses the e-mail keyboard type (~lines 35, 75): switch to plain text input so usernames such as `center.a7k2m9xq` are comfortable to type. Renaming the e-mail-named parameters in the bloc and repository is optional.
- No reset-by-email screen exists in `lib/` (no file or text match). If one is added later it follows phase 2.
- Tests that exist and mention login/tenant terms (contents unread): `test/widget/features/auth/login_page_test.dart`, `test/widget/app_auth_gate_test.dart`, `test/unit/features/auth/auth_repository_impl_test.dart`, `jwt_claims_test.dart`, `auth_bloc_test.dart`. Likely outcome for Flutter: copy change plus one widget test, otherwise "no change needed".

API, under `pte-api/app/src/main/java/com/pte/`:
- `identity/internal/controller/AuthController.java` (route at ~line 60), `identity/internal/service/AuthService.java` (organization-list method at ~76-95 and its mapper at ~157), `identity/internal/dto/request/auth/LoginOrganizationOptionsRequest.java`, `identity/internal/dto/response/LoginOrganizationOptionResponse.java`.
- `identity/internal/config/SecurityConfig.java` — the open-path entry for the endpoint.
- `tenancy/LoginOrganizationOption.java` and `tenancy/TenancyService.java` (`findLoginOrganization`, ~line 262) — used only by the removed endpoint (verified: the only callers are `AuthService` and tests). Delete both.
- `identity/internal/dto/request/auth/LoginRequest.java` — the optional organization id field; remove it and the "requested organization" branch in login (after phase 3 it only ever matches the single organization of the account).
- Tests: remove the organization-list cases in `AuthServiceTest` (~lines 250-400) and the entry in `tenancy/internal/service/TenancyServiceTest.java`; `AuthServiceMultiOrganizationTest` is already deleted in phase 3. Add a test that a request to the removed route gets 404 or 405.

## Steps
1. Re-verify the Flutter claim: search `pte-app/lib` and `pte-app/test` again for the endpoint, an organization picker and any code that sends an organization id at login; record the result in the Execution Log.
2. Remove the picker, hook, request function, types and public-path entry from the web code (both apps and the api-client) and fix their unit tests.
3. Update sign-in copy on web and Flutter, and make the Flutter username field a plain text field.
4. Run web typecheck, lint, unit tests and build for tenant-web, vendor-web and packages; run Flutter analyze and tests.
5. Ship the web and Flutter changes first (release R4a). Confirm with the user that logins work against the post-phase-3 API.
6. Remove the endpoint, its DTOs, the service method, the tenancy lookup, the open-path entry and the optional organization id on the login request from the API (release R4b), then run the identity and tenancy tests.

## Tests to write or update
See the test files above. New: login test with username and secret only; route-gone test; web test that submitting the sign-in form issues exactly one request.

## Checkpoints
No migration, no DB write, no backup needed. UI and login checks against a running stack are done by the user (tell them when a UI check is needed).

## Success Criteria
- `grep -rn "login-options\|LoginOrganizationOption" pte-web pte-api/app/src pte-app` (excluding `node_modules`) returns 0 hits after R4b.
- `pnpm` typecheck, lint, tests and build green for `packages/api-client`, `apps/tenant-web`, `apps/vendor-web`.
- `mvn test` for modules identity and tenancy green; Flutter `analyze` and `test` green.
- A call to `POST /api/v1/auth/login-options` returns a not-found style error (test).
- A person with a generated username can sign in on tenant-web, vendor-web and the Flutter app without picking an organization (manual check by the user).

## Rollback
Web and Flutter: redeploy the previous build; it still works against the API until R4b because the endpoint is only removed afterwards. API (R4b): redeploy the previous image; no schema is involved.

## Risks
- Deploying R4b before R4a breaks old web builds still calling the endpoint: strict order, web first.
- Old mobile builds in the field are not covered by this repo; they never called the endpoint (verified in `lib`), so they are unaffected.
- Historic plan `quang-entity-consolidation` phase 2 still describes the picker as a requirement; leave it, mention this plan as the superseding one in the final doc pass (the user decides).

## Not verified
- Contents of the Flutter tests and whether any widget test references an organization choice.
- Whether the web login request type carries an organization id field today.
- Whether any other web screen (for example a staff directory) shows "username = e-mail" copy.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- No functional errors in phase 4. Two tooling notes: `npx eslint` is not found in the web apps (used `pnpm exec eslint`), and `packages/api-client` has no eslint binary, so it was type-checked and unit-tested but not linted.

### Root Cause
- Not applicable (no failure to diagnose).

### Resolution
- Step 1 (Flutter re-verified, 2026-11-15): search of `pte-app/lib/features/auth` finds no call to the endpoint and no organization picker; the login page sends only the typed username and secret (`LoginRequested(email, password)`). The only organization reference left is `jwt_claims.dart`, which reads the `tenant_id` claim from the token (kept on purpose).
- Steps 2-3 (R4a, pte-web and pte-app): picker, `useLoginOrganizationOptions`, `listLoginOrganizations`, the two option types, `tenantId` on the login request types and the public-path entry were removed; copy now says "Use the username your organization sent to your email"; the Flutter username field is plain text (no autocorrect or suggestions). The user ran the UI against the post-phase-3 API and approved.
- Step 6 (R4b, pte-api): removed `POST /auth/login-options` from `AuthController`, `AuthService.loginOrganizations` and its mapper, `TenancyService.findLoginOrganization`, the `SecurityConfig` open-path entry, and the three files `LoginOrganizationOptionsRequest`, `LoginOrganizationOptionResponse`, `tenancy/LoginOrganizationOption`. `LoginRequest` is now `(username, password)`; the "requested organization" branch in `login` is gone. `AuthService` no longer depends on `TenancyService` (constructor changed; two tests updated).
- Tests: deleted the organization-list and `tenantId` cases in `AuthServiceTest` and the `findLoginOrganization` case in `TenancyServiceTest`; added `AuthControllerLoginContractTest` (no `/login-options` POST mapping; `LoginRequest` has exactly `username`, `password`).

### Test Results After Fix
- API (surefire, this run): AuthServiceTest 25/25, AuthTokenLifetimeTest 3/3, AuthControllerLoginContractTest 2/2, AuthControllerPasswordResetTest 4/4, SecurityConfig path tests 2+2, TenancyServiceTest 8/8, TenancyServiceCountOrganizationsTest 3/3, ModuleStructureTest 3/3, SourceFileSizeTest 1/1, PackageDensityTest 1/1; 0 failures, 0 errors.
- Web (R4a): `tsc --noEmit` clean for api-client, tenant-web, vendor-web; vitest api-client 28, tenant-web auth 45, vendor-web auth 31 pass; eslint clean for both apps. Flutter: `flutter analyze` on auth and constants clean, 53 auth tests pass.
- Search `login-options|LoginOrganizationOption|findLoginOrganization|loginOrganizations` over pte-web, pte-api and pte-app source: only the two "endpoint is gone" assertions remain (`auth.test.ts` and `AuthControllerLoginContractTest`).
- Not run: `pnpm build`, full web suites, full API suite after this step, Postgres-only tests, a real HTTP 404 check against a running stack (the route-gone test is a reflection check on the controller). No component test exists for `LoginView`; the "one request" check lives at the api-client level.
