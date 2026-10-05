# Phase 4: App — exam code resolver

Repo: pte-app (`d:\FPT\9thSemester\pte\pte-app`, Flutter). Depends on Phase 2 for end-to-end.

## Requirements
A student types an exam code at login; after authentication the app exchanges it for the session UUID via the new endpoint (UUIDs still pass straight through), and all student-facing text says "exam code".

## Steps
1. Create a new `SessionEntryRepository` implementation that: trims; rejects empty input with `SessionResolutionException`; returns the trimmed input unchanged if it parses as a UUID; otherwise normalizes it (remove all whitespace, map en dash `–`, em dash `—`, and other Unicode hyphens to `-`, uppercase) and calls the resolve endpoint through `ApiClient`, returning `sessionPublicId` from the response. Codes typed without hyphens are not reconstructed; there is one canonical form.
2. Map a not-found response from the endpoint to `SessionResolutionException` with a friendly message (e.g. "We couldn't find that exam code. Check the code from your host and try again."); let other API errors (network, rate limit, auth) propagate as they already do.
3. Add the resolve path to `AppConfig` alongside `examAttemptsPath` (overridable like the others) and register the new implementation in `exam_attempt_module.dart` in place of `ManualSessionEntryRepository`, injecting `ApiClient` as the other repositories do; remove or retire the old class and update the seam doc comments.
4. Reword strings from "session ID" to "exam code": `app_strings.dart` (`loginSessionIdLabel`, `loginSessionIdRequiredLabel`, hint/required messages ~lines 19-27), `friendly_error_message.dart:15`, `exam_attempt_strings.dart:37`, and the empty-input message in the repository.
5. Make the login field uppercase-friendly (text capitalization characters, keyboard hint); keep the pasted UUID path working (do not strip or reject hyphens/lowercase UUIDs).
6. Write the unit tests below, update any tests that reference the old class, and run the app test suite and analyzer.

## Flow (verified in `lib/app.dart`)
1. `LoginPage(requireSessionId: true)` collects the credentials and the code; `_rememberSessionId` stores the trimmed raw text (line ~175).
2. After login succeeds (`AuthAuthenticated`), `AppAuthGate` builds `StudentExamGate(initialSessionId: ...)` (line ~218; doc at ~228).
3. `StudentExamGate.initState` dispatches `SessionResolutionRequested(rawInput)` (line ~255), so resolution happens authenticated, which the resolve endpoint requires (STUDENT JWT).
4. `ExamAttemptBloc` calls `SessionEntryRepository.resolveSessionPublicId`, then preflight/start with the UUID; any `SessionResolutionException` or `ApiException` lands in the bloc's generic catch and becomes `AttemptError`, shown on the existing error UI (the line-366 comment confirms there is no second entry screen).

## Files to Create or Modify (relative to `pte-app/`)

| File | Action |
|---|---|
| `lib/features/exam_attempt/data/repositories/exam_code_session_entry_repository.dart` | Create |
| `lib/features/exam_attempt/data/repositories/manual_session_entry_repository.dart` | Delete (or keep unused; no other lib reference besides the module) |
| `lib/features/exam_attempt/exam_attempt_module.dart` | Modify — registration (line ~37) and import |
| `lib/core/config/app_config.dart` | Modify — resolve path constant |
| `lib/features/exam_attempt/domain/repositories/session_entry_repository.dart` | Modify — empty-input wording and docs |
| `lib/core/constants/app_strings.dart` | Modify — login labels/hints |
| `lib/core/network/friendly_error_message.dart` | Modify — line ~15 wording |
| `lib/features/exam_attempt/constants/exam_attempt_strings.dart` | Modify — line ~37 wording |
| login page widget under `lib/features/auth/` | Modify — uppercase text capitalization on the field (locate it via `loginSessionIdLabel` usages) |
| `test/unit/features/exam_attempt/exam_code_session_entry_repository_test.dart` | Create |

Existing tests: grep of `test/` found no direct reference to `ManualSessionEntryRepository`; the bloc tests use `_MockSessionEntryRepository` / `_AlternativeSessionEntryRepository` against the interface only, so they should be unaffected. Also grep `test/` for the old wording strings (e.g. "session ID", "Exam session ID") and update assertions or widget tests that match them.

## Success Criteria
- From `d:\FPT\9thSemester\pte\pte-app`: `flutter test test/unit/features/exam_attempt/` passes, `flutter test` full suite passes, and `flutter analyze` is clean.
- Manual (with Phases 1-2 running): login as an enrolled student with `fpt-261010-k7qm` (lowercase) reaches preflight; a pasted UUID still works; a wrong code shows the friendly message.
- No remaining "session ID" wording in student-facing strings (`grep -ri "session id" lib/`).

## Tests to Write
- UUID passthrough: a valid UUID (any case, padded with spaces) is returned trimmed and the API client is never called.
- Code normalization: `"  fpt-261010-k7qm "`, `"FPT – 261010 – K7QM"` (en dash + spaces), and `"fpt—261010—k7qm"` (em dash) each call the endpoint once with `FPT-261010-K7QM` and return the `sessionPublicId` from the response.
- 404 mapping: the API client throws `NotFoundException` -> `SessionResolutionException` with the friendly message.
- Empty / whitespace-only input -> `SessionResolutionException`, no API call.
- Other errors (e.g. `RateLimitException`, `NetworkException`) are not swallowed into a not-found message.
- Mock `ApiClient` the same way `exam_attempt_repository_impl_test.dart` does (follow that file's conventions).

## Risks
- A UUID check that is too loose misroutes codes: use a strict 8-4-4-4-12 hex pattern.
- Not-yet-open exam: resolve succeeds, then preflight returns 403 and the app shows the generic permission message; acceptable for now, noted for a later UX improvement.
- Old app builds keep sending UUIDs and are unaffected; the new build against an old backend (no endpoint) would fail for codes only — deploy Phase 2 first.

## Execution Log
<!-- Filled by /ck:cook at the end of this phase — leave placeholders when planning -->

### Errors Encountered
- None from the Phase 4 changes. The full suite and the analyzer show failures that were already there:
  - `flutter test`: 65 failures in 14 files. Two are unit tests (`audio_recorder_service_impl_test`, `auto_record_cubit_test`); the rest are widget tests for the speaking/audio screens, `task_type_dispatcher_test`, `task_advance_button_test`, `exam_ui_preview_screen_test` and `section_completed_screen_test`.
  - `flutter analyze`: 4 errors in `test/widget/features/exam_attempt/section_completed_screen_test.dart:10` (missing required `attemptNumber`, `canRetry`, `onRetry` and `remainingRetries`), plus 1 `unnecessary_cast` warning in `exam_attempt_repository_impl.dart:63`.

### Root Cause
- The failures come from earlier audio/recorder and retry work, not from this phase. None of the failing files reference the session-entry seam, `AppConfig`, or the reworded strings (grep).
- Baseline check: a clean copy of `HEAD` (extracted with `git archive` into the scratchpad) fails the same 65 tests in the same 14 files (+532 −65).

### Resolution
- Left the existing failures untouched.
- Implemented steps 1–6:
  - New `ExamCodeSessionEntryRepository`:
    - Trims the input. Empty input throws `SessionResolutionException`.
    - A strict 8-4-4-4-12 hex UUID (any case) is returned without an API call.
    - Anything else is normalized: whitespace removed, Unicode hyphens/dashes (U+2010–2015, U+2212, U+FE58, U+FE63, U+FF0D) mapped to `-`, then uppercased. It then calls `GET AppConfig.sessionCodeResolvePath?code=...` and returns `sessionPublicId`.
  - Error mapping:
    - `NotFoundException` becomes `SessionResolutionException("We couldn't find that exam code. ...")`.
    - Addition to the plan: `ValidationException` (the API's 400 `INVALID_SESSION_CODE` for input over 24 characters) is mapped the same way. Otherwise the student would see the raw "Request rejected (400)".
    - Rate-limit, network and auth errors propagate unchanged.
  - `AppConfig.sessionCodeResolvePath` (`PTE_SESSION_CODE_RESOLVE_PATH`, default `/api/v1/student/exam-sessions/resolve`).
  - The DI registration now uses `ExamCodeSessionEntryRepository(apiClient: getIt<ApiClient>())`. `ManualSessionEntryRepository` was deleted. The seam docs were updated (repository interface, module, event and state docs, `app.dart` comments).
  - Wording:
    - Login label, hint and required messages now say "Exam code".
    - `ALREADY_ATTEMPTED` message says "exam code".
    - `sessionResolutionFailureMessage` now reads "We couldn't find that exam code. ...". This is the text the student actually sees: the bloc routes every `SessionResolutionException` to this constant, not to the exception's own message.
    - The "Use a different session" button now reads "Use a different exam code".
  - The login field uses `TextCapitalization.characters`. Pasted UUIDs are not altered.
  - Kept the internal names `loginSessionId*`, `_sessionIdController` and `requireSessionId`, so the diff stays strings-only.
- Tests:
  - New `exam_code_session_entry_repository_test.dart` (13 tests).
  - The old-wording messages in `exam_attempt_bloc_test`, `exam_attempt_error_message_test`, `app_auth_gate_test` and `friendly_error_message_test` were updated.

### Test Results After Fix
- Run from `d:\FPT\9thSemester\pte\pte-app`:
  - `flutter test test/unit/features/exam_attempt/exam_code_session_entry_repository_test.dart`: 13/13 pass. They cover:
    - UUID passthrough, lowercase and padded, with no API call.
    - A 32-hex string without hyphens goes to resolve.
    - Three normalization inputs, each resolved to `FPT-261010-K7QM`.
    - Empty and whitespace-only input, with no API call.
    - 404 → friendly message.
    - 400 → `SessionResolutionException`.
    - `RateLimitException`, `NetworkException` and `AuthException` propagate as the same instance.
  - `flutter test` (full suite): +545 −65. That is the baseline's 532 passing tests plus the 13 new ones, and the same 65 failures as the baseline listed above. Login, auth-gate and friendly-message tests all pass.
  - `flutter analyze`: no issues in the changed or new files. The only findings are the 4 errors and 1 warning that already existed.
  - `grep -ri "session id" lib/`: no matches.
- Manual check (user, 2026-10-05, after a compose rebuild): the web shows the exam code, and the app opens the exam when the code is typed at login.
- Cook Step 3 (tester) added 1 widget test to `test/widget/features/auth/login_page_test.dart`, checking that the session field uses `TextCapitalization.characters`.
  - Full `flutter test`: +546 −65. The 65 failures are the same ones that fail on a clean HEAD.
  - `flutter analyze`: unchanged; only the 5 issues that were already there.
