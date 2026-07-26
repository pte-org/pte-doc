# Phase 1: Core Networking, Auth & Secure Session

## Requirements

Build the `ApiClient` (Dio-based) that every later feature's repository calls through, a single-flight `TokenRefreshInterceptor` that transparently refreshes an expired access token and retries the failed request, a `flutter_secure_storage`-backed `TokenStore` for persisting the refresh token (never plain `SharedPreferences`, never in-memory-only), and an `AuthBloc` implementing login, proactive pre-expiry token refresh, and logout. 429 responses must be surfaced as a distinct, explicitly-typed retryable error — never conflated with an auth failure or a validation failure.

Maps to: **P1 Story #1 ("log in and stay authenticated across a 15-minute access-token lifetime") | FR-01, FR-02, FR-11**

## Design Constraints

- Rebuild `TokenRefreshInterceptor` from the Phase 0 reference copy of `pte-app/lib/core/network/interceptors/token_refresh_interceptor.dart`: a second, un-intercepted `Dio` instance (`refreshDio`) handles both the refresh call and the retried original request, so the interceptor can never recurse into itself; concurrent 401s across multiple in-flight requests share one `Future<String>? _refreshInFlight` rather than each independently calling `/api/iam/auth/refresh`.
- Reactive 401-triggered refresh (the interceptor) is a safety net, not the primary mechanism — FR-01 requires *proactive* refresh before the 900-second access-token TTL expires, so `AuthBloc`/`TokenStore` must track token-issued-at (or decode `expiresInSeconds` at login/refresh time) and schedule a refresh ahead of expiry, not only react to a 401 after it already happened mid-request.
- Refresh token rotates on every `/api/iam/auth/refresh` call (7-day TTL) — `TokenStore.saveTokens()` must overwrite both tokens atomically on every refresh; a partial write (new access token saved, old refresh token left stale) would silently break the next refresh cycle.
- JWT `roles`/`tenant_id` claims are decoded client-side for UI branching only (e.g. student vs host layout) per FR-02 — no authorization/permission decision may be made from the decoded claims; the server re-validates every request regardless of what the client believes its own role is.
- Refresh tokens are persisted via `flutter_secure_storage` exclusively — access tokens may be held in memory (short TTL, not worth the secure-storage round-trip cost) but the refresh token must never touch `SharedPreferences` or any non-secure store, per the spec's Non-Functional Requirements.
- 429 (Redis rate-limit, 20/s burst 40) must map to its own exception type (e.g. `RateLimitException`) distinct from `AuthException`/`ValidationException`, carrying enough info for a caller to backoff-and-retry (FR-11) — this interceptor/exception design is consumed later by Phase 2's `SyncEngine` and Phase 7's hardening work, so the type must be public/exported from `core`, not buried as a private detail of this phase's auth flow.
- `AuthBloc` events are a sealed class, states are separate immutable classes (no `isLoading`/`isError` boolean flags) — logout must be reachable from every authenticated state, not just a "happy path" state.
- No `BuildContext` inside `AuthBloc` — expired-session/logout side effects (e.g. navigating to a login screen) are driven by the UI listening to `AuthBloc` state changes, never by the bloc itself.

## Steps

1. Implement `TokenStore` (`lib/core/storage/token_store.dart` or similar) wrapping `flutter_secure_storage`: `saveTokens({accessToken, refreshToken, expiresInSeconds})`, `readAccessToken()`, `readRefreshToken()`, `clear()` (for logout), and an internal notion of "access token expires at" derived from `expiresInSeconds` captured at save time.
2. Implement `ApiClient` wrapping a primary `Dio` instance configured with base URL `http://localhost:8080` — **not** `http://localhost:8080/api` — (via an `AppConfig`-level constant, not hardcoded inline, consistent with the old scaffold's `apiBaseUrl` pattern noted in spec.md Assumptions), an auth-header interceptor that attaches the current access token, and error-mapping to typed exceptions (`AuthException`, `ValidationException`, `RateLimitException`, generic `ApiException`/`NetworkException`). Every call site across every phase (this one and all later phases) passes the **full** gateway-relative path starting with `/api/...` (e.g. `/api/iam/auth/login`, `/api/exam-delivery/attempts`) — the base URL intentionally excludes `/api` so that concatenation never double-prefixes it. Document this convention in a code comment on `ApiClient` itself, since it's easy for a call site to assume the base URL already includes `/api` and write a path missing it (or vice versa).
3. Implement `TokenRefreshInterceptor` per the Design Constraints above: separate `refreshDio` (no interceptors), single-flight `_refreshInFlight`, calling `POST /api/iam/auth/refresh` with `{refreshToken}`, saving the rotated token pair via `TokenStore`, and retrying the original failed request with the new access token.
4. Implement proactive refresh: a scheduled check (timer or on-app-resume hook) that refreshes the access token when it is within a safety margin of its 900-second expiry, run independently of any request actually failing with 401 — this must be demonstrably triggered by elapsed time, not only by a 401 response.
5. Implement `AuthRepository`/`AuthBloc`: `login(email, password)` → `POST /api/iam/auth/login`, `logout()` → `POST /api/iam/auth/logout` with `{refreshToken}` then `TokenStore.clear()`, and internal state for "authenticated"/"unauthenticated"/"authenticating"/"auth error" as separate immutable state classes.
6. Implement JWT claim decoding (`roles`, `tenant_id`) as a pure, side-effect-free utility used only for UI branching; add a code comment or test asserting it is never referenced from any authorization-decision code path.
7. Test: unit-test `TokenRefreshInterceptor` with a mocked 401 response, verifying the retried request carries the new token and that two concurrent 401s produce exactly one refresh call (single-flight).
8. Test: unit-test proactive refresh scheduling with an injectable/fake clock (not real `Duration` sleeps) to verify a refresh fires before the 900s boundary without waiting 900 real seconds.
9. Test: unit-test `RateLimitException` is thrown (not `ApiException`) when the mocked response is a 429, and that it's distinguishable via `is`/pattern-matching from auth/validation exceptions.
10. Test: unit-test `TokenStore` persists and clears both tokens correctly using a fake secure-storage backend (via `mocktail`), including that `clear()` on logout removes the refresh token entirely (not just the access token).

## Success Criteria

- [ ] A single concurrent burst of 401s across multiple requests triggers exactly one `/api/iam/auth/refresh` call, and all failed requests are retried with the refreshed token.
- [ ] A token refresh occurs proactively before the 900-second access-token TTL expires, verified without waiting real wall-clock time in tests.
- [ ] Refresh token is persisted only via `flutter_secure_storage`; no code path writes it to `SharedPreferences` or holds it exclusively in memory.
- [ ] 429 responses produce a distinct `RateLimitException` (or equivalent), never mapped to an auth or validation exception type.
- [ ] `AuthBloc` states are separate immutable classes; no boolean-flag state shape exists anywhere in the auth feature.
- [ ] JWT claim decoding is demonstrably unused in any authorization-decision code path (server re-validates every request).
- [ ] Logout clears both tokens and transitions `AuthBloc` to an unauthenticated state reachable from any prior authenticated state.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started.

## Risks

- **MEDIUM**: A naive proactive-refresh timer that fires only while the app is in the foreground could miss a refresh window if the app is backgrounded across the 900-second boundary, leaving the reactive 401-interceptor as the sole fallback for that case. Mitigation: verify the reactive interceptor path independently (Step 7) so it remains a correct fallback even if proactive refresh is foreground-only in this phase; revisit background-refresh scheduling only if Phase 7's kill/cold-restart testing surfaces it as an actual gap.
- **LOW**: Milestone 1 targets desktop (Windows primary) — `flutter_secure_storage`'s Windows backend is Credential Locker via DPAPI, a materially different (and less-mobile-tested) code path than Android Keystore/iOS Keychain that most of this package's documentation/examples assume. Confirm early (Phase 0/1 smoke test, not deferred to Phase 9) that `flutter_secure_storage` actually works as expected on Windows for this app's use case (persisting the refresh token across app restarts) — don't assume parity with the package's mobile-oriented docs.
