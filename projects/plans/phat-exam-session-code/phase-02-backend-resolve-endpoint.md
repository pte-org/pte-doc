# Phase 2: Backend — student resolve endpoint

Repo: pte-api. Depends on Phase 1.

## Requirements
An authenticated STUDENT can exchange an exam code for the session's `publicId` when the code belongs to their tenant, the session is not soft-deleted, and they are enrolled; every other case returns the same 404.

## Steps
1. Add a repository lookup that finds a non-deleted session by code within a tenant: `findBySessionCodeAndTenantIdAndDeletedFalse`. (Other session queries don't filter `deleted`; this one must, so a deleted session with a surviving enrollment doesn't resolve.)
2. Extract the enrollment-only check from the entitlement logic into a reusable private step (no OPEN requirement), keeping `checkEntitlement` behavior byte-for-byte unchanged (still requires OPEN, still 403 `NOT_ENTITLED`).
3. Add the resolve operation to `EntitlementService`: normalize input (trim + uppercase), take the tenant only from `CurrentUser.tenantId()` (never a request parameter; a null tenant gets the same 404), look up by code + tenant, require enrollment, and raise `SessionNotFoundException` (404) for every failure; expose it through `SessionService` as the module facade.
4. Add `StudentSessionController` in `session/internal/controller` with `@PreAuthorize("hasRole('STUDENT')")` at `GET /api/v1/student/exam-sessions/resolve?code=...`, returning the project `ApiResponse` wrapper around a small `{ sessionPublicId }` record; reject blank/oversized input with a 400 validation error.
5. Write the tests below and run them.

## Files to Create or Modify (relative to `app/src/`)

| File | Action |
|---|---|
| `main/java/com/pte/session/internal/repository/ExamSessionRepository.java` | Modify — `findBySessionCodeAndTenantIdAndDeletedFalse` |
| `main/java/com/pte/session/internal/service/EntitlementService.java` | Modify — extract enrollment check; add resolve method |
| `main/java/com/pte/session/SessionService.java` | Modify — delegate resolve |
| `main/java/com/pte/session/internal/controller/StudentSessionController.java` | Create |
| `main/java/com/pte/session/internal/dto/response/SessionResolveResponse.java` | Create — `{ sessionPublicId }` |
| `test/java/com/pte/session/internal/service/EntitlementServiceTest.java` | Modify — resolve cases |
| `test/java/com/pte/session/internal/controller/StudentSessionControllerTest.java` | Create |

## Design Notes
- URL convention: there is no student-facing session controller today; student routes live under `/api/v1/attempts`. The new route follows the user's chosen `/api/v1/student/exam-sessions/resolve`.
- Why a 404 and not `NotEntitledException`: `NotEntitledException` is HTTP 403 and means "not open/not enrolled" for attempt operations. For resolution the contract is "all failures look identical", using `SessionNotFoundException` (404, existing).
- Why not reuse `checkEntitlement`: it requires status OPEN. A student entering a valid code before the exam opens must still get the `sessionPublicId` back so the real gate (preflight) decides.
- End-to-end behavior for a non-OPEN session today: `POST /api/v1/attempts/preflight` calls `checkEntitlement`, which throws `NotEntitledException` -> HTTP 403 `NOT_ENTITLED` for any non-OPEN session (DRAFT, SCHEDULED, CLOSED, CANCELLED) and for non-enrolled students alike — it does not tell the two apart. So: code resolves (200) -> preflight 403 -> the app shows its generic permission error. Distinguishing "not open yet" would be a separate change to the attempt/preflight contract (out of scope).
- Information exposure: resolve returns the `publicId` for any status to an enrolled student of that tenant; the UUID itself grants nothing without enrollment, and it is the same UUID they were previously given by the host.
- No dedicated rate limit (do NOT touch `SecurityConfig` or `application.yml`). `RateLimitFilter` (lines 61-65) keys a route bucket as `tenantId + "|route:" + URI`, with no user dimension and an initial burst equal to the per-second limit. A low per-route limit would be shared by the whole class and 429 most students when an exam starts. Enumeration gains nothing because a hit only returns a session the caller is enrolled in. The route stays on the default tenant bucket (`rate-limit.per-second`, 40), like preflight/start.

## Success Criteria
- From `d:\FPT\9thSemester\pte\pte-api`: `./mvnw -pl app test -Dtest=EntitlementServiceTest,StudentSessionControllerTest` passes; `./mvnw -pl app test` full suite passes (incl. `ModuleStructureTest`).
- Manual: `GET /api/v1/student/exam-sessions/resolve?code=fpt-261010-k7qm` as an enrolled student returns 200 with the session UUID; wrong tenant, unknown code, and not-enrolled all return identical 404 bodies; HOST_ADMIN token returns 403.
- `checkEntitlement` tests unchanged and green.

## Tests to Write
- `EntitlementServiceTest` (Mockito, as existing): resolve success; lowercase/padded input is normalized; unknown code -> 404 exception; code of another tenant (repository returns empty for caller tenant) -> same exception; soft-deleted session (repository returns empty) -> same exception; null caller tenant -> same exception, repository never called; not enrolled -> same exception; non-OPEN (SCHEDULED) session still resolves for an enrolled student.
- `StudentSessionControllerTest` (plain Mockito calling the controller, same style as `PlanControllerTest`): delegates with the current user's tenant and id; wraps in `ApiResponse`. For role enforcement (non-STUDENT -> 403) add a security slice test only if the codebase has an existing `@WebMvcTest` pattern; otherwise assert the `@PreAuthorize("hasRole('STUDENT')")` annotation by reflection and cover the 403 in the manual check above (no controller test in this repo exercises Spring Security today — verify before choosing).

## Risks
- Leak via differing responses: use the one exception type for all failures, and keep validation errors (400) independent of data existence.
- Facade method on `SessionService` has no other module caller yet: keep it thin; delete if reviewers prefer the controller to call the internal service directly (like `EnrollmentController`).

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- None at compile or test time.
- Design gap found before coding: no controller uses `@Validated` method validation, and `GlobalExceptionHandler` has no handler for `HandlerMethodValidationException` or `MissingServletRequestParameterException`. Both fall into the catch-all `Exception` handler and return 500, so `@RequestParam @NotBlank @Size` (or a required `code`) would give 500 instead of 400.

### Root Cause
- The shared handler only maps `MethodArgumentNotValidException` (request bodies), `HttpMessageNotReadableException`, `DomainException` and `AccessDeniedException` to non-500 statuses.

### Resolution
- `code` is declared `@RequestParam(required = false)`. The shape check lives in `EntitlementService#normalizeSessionCode`: it runs before any lookup and treats null, blank or longer than 24 characters (the column length) as invalid.
- Invalid input throws the new `InvalidSessionCodeException`: 400 with code `INVALID_SESSION_CODE` (`SessionConstants.INVALID_SESSION_CODE`).
- The shared handler (`shared` module) was left untouched.
- Other implementation choices:
  - `EntitlementService#isEnrolled` is the extracted private enrollment step. `checkEntitlement` still throws `NotEntitledException` from it, so its behavior is unchanged.
  - `resolveSessionCode(rawCode, tenantId, studentPublicId)` returns a `UUID`. `SessionService` has a thin delegate.
  - `StudentSessionController` calls the facade and wraps the result in `SessionResolveResponse`. The tenant and student come only from `CurrentUserContext.required()`.
  - The repository method is `findBySessionCodeAndTenantIdAndDeletedFalse`.

### Test Results After Fix
- Command: `./mvnw -pl app test -Dtest=EntitlementServiceTest,StudentSessionControllerTest,SessionCodeGeneratorTest`. All pass:
  - `EntitlementServiceTest`: 22/22. This covers the 10 existing tests unchanged, 8 new resolve tests, and a parameterized invalid-input test with 4 cases: null, empty, blank, and 28 chars.
  - `StudentSessionControllerTest`: 2/2. One test checks the delegate call with the JWT tenant and subject. The other checks `@PreAuthorize("hasRole('STUDENT')")` by reflection, because no controller test in this repo exercises Spring Security.
  - `SessionCodeGeneratorTest`: 6/6.
- Full suite `./mvnw -pl app test`: 989 run, 5 failures and 6 errors.
  - These are the same 11 pre-existing failures recorded in Phase 1: `ModuleStructureTest` module count ("support"), `ExamGenerationServiceTest`, `AttemptLifecycleCapabilityTest` ×2, and `AttemptLifecycleServicePlayAudioTest` ×7.
  - No session test fails.
- Manual HTTP check not run yet. The compose app container was built before this phase, so it needs `up --build` first.
  - Data for the check: `SEEDPTEL-260929-99LA` (OPEN), enrolled student `aff6c6db-decc-4abe-b73a-576164cbafdb`.
