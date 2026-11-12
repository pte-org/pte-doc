# Login connectivity and toast verification

Date: 2026-11-07

## Confirmed causes

Practice at http://localhost:3014 could not complete login preflight. Both the
direct backend on 8091 and local edge on 8080 returned HTTP 403, with no
Access-Control-Allow-Origin, for this origin. The same preflight succeeded
for tenant and vendor origins 3000/3001. The live app's CORS environment
omitted 3014.

Added 3014 to the existing CORS assignment in the ignored API .env.local,
preserving existing origins. Recreated only the local app container with
the existing image and no build/pull. The app is healthy; both backend
health endpoints return HTTP 200. Preflights for 3000, 3001 and 3014 return
200; an untrusted external origin still returns 403.

Practice also attached a stored bearer token to public credential exchange.
Its login call now opts out of authentication and token refresh; protected
requests retain their existing bearer/refresh behavior. A regression test
covers login with an expired stored bearer.

## Frontend changes

Tenant, vendor/admin and Practice now use their existing ToastProvider for
login API errors, role refusal and invalid login responses. Field-level
required/format validation remains inline. Form-level failure banners were
removed, so an API failure produces only a toast.

Error messages distinguish invalid credentials, unavailable connection, rate
limiting and server unavailability. The frontend does not show raw server
diagnostics or reveal account existence. Vendor uses translated error copy
in VI mode; Practice has matching VI/EN messages.

The standards reviewed were docs/CODING_STANDARDS_WEB.md, the pte-web copy
and its API-error-boundary additions, docs/TEST_SCENARIOS_IAM.md, and API
response/exception reference documents. No tracked backend code was changed.
Existing question-generation and Practice visual-parity changes were preserved.

## Automated verification

| Area | Result |
| --- | --- |
| Tenant tests | 100 files / 1017 tests passed |
| Vendor tests | 63 files / 496 tests passed |
| Practice tests | 77 files / 681 tests passed |
| Tenant/vendor typechecks | Passed after regenerating stale Next route types |
| Practice typecheck | Passed |
| Tenant/vendor scoped lint | Passed |
| Practice full lint | Passed with two existing unused-locale warnings |
| Production builds | All three passed |
| Whitespace checks | Passed |
| Independent review | APPROVED; no scoped findings |

Commands included pnpm filtered test/typecheck/build for tenant and vendor,
Next typegen, scoped ESLint, and npm run test:unit/typecheck/lint/build in
Practice. Route-type failures initially referenced removed auth/proctor
locations in generated .next files; type regeneration resolved them without
changing application routes.

## Browser verification

Verified all three login pages against the real local API using a deliberately
nonexistent diagnostic account: HTTP 401 shows the same invalid-credentials
toast. Practice sends no Authorization header, even with a synthetic stale
session present. This is a rejection-path check, not a real user's login.

Intercepted 401, 429, 503 and network failures produce the expected contextual
toast on each app. Vendor VI mode translates the network error. No raw
diagnostic text or duplicate inline failure banner was displayed; no page
errors were recorded. All 15 app/scenario combinations plus the additional
Vendor VI check passed.

Screenshots:

- [Practice invalid credentials](assets/261107-login-toast-fix/practice-invalid-credentials.png)
- [Tenant invalid credentials](assets/261107-login-toast-fix/tenant-invalid-credentials.png)
- [Vendor invalid credentials](assets/261107-login-toast-fix/vendor-invalid-credentials.png)
- [Vendor network error in Vietnamese](assets/261107-login-toast-fix/vendor-network-vi.png)

## Boundary

No password guessing, password reset, account unlock or real-account login was
performed. The admin failure shown in the user's original screenshot was not
independently reproduced with that account; current diagnostic rejection paths
now give specific toast feedback. No production changes, push or deployment.
