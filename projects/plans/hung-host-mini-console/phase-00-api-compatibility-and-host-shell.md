# Phase 0: API Compatibility & Host Shell

## Requirements

Make the existing Flutter networking layer consume the real backend
`ApiResponse<T>` envelope, distinguish forbidden access from expired/invalid
authentication, and provide the shared login/root application flow that routes
Host roles into a minimal Host workspace without redesigning Member 2's auth or
student features.

Maps to: **P1 Story #1 (shared Host login and workspace) | FR-01, FR-02, FR-03,
FR-04, FR-18**

## Design Constraints

- `ApiClient` remains the only transactional HTTP boundary. Repositories still
  receive `Response<T>` with the inner payload in `response.data`.
- Dio requests JSON as `dynamic`, then `ApiClient` recognizes an envelope only
  when `success`, `data`, and `message` keys are all present. Already-unwrapped
  payloads remain valid during migration.
- Reconstructed responses preserve request options, headers, status,
  redirects, and extra metadata. Raw presigned PUT remains outside this path.
- `401` maps to `AuthException`; `403` maps to a new
  `ForbiddenException`. A permission failure never triggers a false logout.
- `JwtClaims` drives UI branching only. `HostAccessPolicy` checks exact
  `HOST_ADMIN`/`HOST_AUTHOR` membership but is never treated as authorization.
- Existing `AuthBloc`, repositories, token storage, proactive refresh, and
  interceptors are reused unchanged unless a regression test proves a required
  compatibility fix.
- Root rendering moves from the placeholder in `main.dart` to a focused
  `app.dart`; no third-party routing package is introduced.
- `host_console` owns shell/navigation only. Phase 0 must not add authoring or
  scheduling business dependencies.
- User-facing login/Host copy is added to `AppStrings`; colors and dimensions
  come from shared constants/theme.
- All changes remain uncommitted until Hung approves the complete Phase 0–1
  slice.

## Steps

1. Add wrapped-map, wrapped-list, null-data/void, and already-unwrapped response
   cases to `test/unit/network/api_client_test.dart`, using Dio mocks that return
   `Response<dynamic>`.
2. Refactor `ApiClient.get<T>`, `post<T>`, and `put<T>` so Dio reads dynamic JSON
   and one private response converter unwraps standard envelopes into a typed
   `Response<T>`.
3. Preserve the current `submitAnswer` public contract and its endpoint-specific
   typed 409 mapping; run all network tests after the generic transport change.
4. Add `ForbiddenException` to the public API exception hierarchy and split
   `_mapError`: 401 authentication, 403 permission, existing 400/404/409/429/5xx
   behavior unchanged.
5. Run focused auth and report repository regression tests, then the full
   existing network/auth/report suites, before adding Host UI.
6. Add pure `HostAccessPolicy.canEnterHostConsole`, `isHostAdmin`, and
   `isHostAuthor` predicates plus unit cases for Host admin, Host author,
   student, and platform roles.
7. Add shared login labels, validation copy, Host title/welcome/logout copy, and
   the unchanged student-placeholder label to `AppStrings`.
8. Build `features/auth/presentation/pages/login_page.dart` over the existing
   `AuthBloc`: email/password validation, loading-disabled submit, error
   feedback, controller disposal, and no repository call from the widget.
9. Build `features/host_console/presentation/pages/host_console_page.dart` with
   Host title, logout event, and a Phase-0 welcome body; create
   `host_console_module.dart` as the stable feature registration entry point.
10. Create `app.dart` with `PteApp` and an exhaustive authentication-state gate:
    unauthenticated/idle/error → login, authenticating → loading,
    authenticated Host → Host console, authenticated non-Host → existing
    student placeholder.
11. Reduce `main.dart` to dependency setup plus `runApp`, preserving the existing
    auth/storage/exam-attempt/report registration order and adding the Host
    module.
12. Run `dart format`, `flutter analyze`, focused Phase 0 tests, and the full
    `flutter test` suite; record timeout or environment blocks as unresolved
    rather than passing.

## Success Criteria

- [x] Wrapped map/list responses expose only their inner `data` to existing
      repositories, while raw/unwrapped responses remain compatible.
- [x] `Response<T>` metadata and `Response<void>` behavior survive envelope
      conversion.
- [x] Existing typed answer-conflict behavior and all Member 2 network/auth/report
      tests remain green.
- [x] `403` produces `ForbiddenException`, not `AuthException`, and does not
      log the user out.
- [x] `HOST_ADMIN` and `HOST_AUTHOR` enter `HostConsolePage`; non-Host claims do
      not.
- [x] Login validation dispatches exactly one `LoginRequested` for a valid form
      and none for invalid input.
- [x] Controllers are disposed, strings/colors are not hardcoded, and new Dart
      files comply with the project size rules.
- [x] `flutter analyze` and the full `flutter test` command exit successfully.

## Quality and Testing State

- Quality gate: approved after independent review; all findings are resolved.
  Report and receipt are stored under
  `pte-app/plans/hung-host-mini-console/quality/`.
- Testing: passed (`flutter analyze`, 98 focused tests, and 241 full-suite
  tests). The local gateway runtime check remains explicitly not run; details
  are stored under `pte-app/plans/hung-host-mini-console/tests/`.

## Risks

- **HIGH:** Asking Dio for `List<dynamic>` before unwrapping a map-shaped
  envelope can fail during transformation, before repository code runs.
  Mitigation: request `dynamic` at the Dio boundary and cast only the inner
  payload.
- **HIGH:** `ApiClient` is shared by every existing feature. Mitigation: complete
  all transport regression tests before Host UI work and stop Phase 0 if any
  Member 2 behavior changes.
- **MEDIUM:** The root app currently has no production login screen, so adding
  one also exposes pre-existing auth states to real widget lifecycle behavior.
  Mitigation: keep the page a thin event/view layer and cover every auth state
  in widget tests.
- **LOW:** The current app title is student-specific. Mitigation: leave the
  global title unchanged in Phase 0 and use a Host-specific page title; a
  product-wide rename is outside Member 3 scope.
