# Phase 05 — Windows Release Verification, Rollout, and ADR

**Depends on:** Phases 1–4  
**Outcome:** Release evidence and durable architecture decision  
**Stories:** all P1 stories, P2 policy visibility

## Objective

Prove the feature on a newly built Windows release binary, record the exact
policy/activation/audit behavior, and document the decision so future changes
do not reintroduce a second anti-cheat flag or a proctor-only student path.

## Exact files/packages likely to change

Documentation/checklist files:

- `pte-doc/projects/architecture/ADR-011-practice-anti-cheat-policy.md` (new)
- `pte-app/test_manual/lockdown_platform_test.md`
- this plan bundle's rollout notes if observed evidence changes an assumption

Release-validation fixture sources (kept behind the compile-time define and
never enabled in the distributable build):

- `pte-app/lib/core/security/lockdown_activation_failure_fixture.dart` (new)
- `pte-app/lib/core/di/security_module.dart`
- `pte-app/lib/core/security/lockdown_service.dart`

Build/runtime artifacts are generated outside the source plan and are not
committed as source unless the repository already tracks release metadata. The
following source files should be inspected, not modified by default:

- `pte-app/windows/runner/CMakeLists.txt`
- `pte-app/windows/runner/flutter_window.cpp`
- `pte-app/windows/runner/lockdown_plugin.cpp`
- `pte-app/lib/app.dart` for release configuration and the absence of
  `DEV_SKIP_AUTH`

## Implementation steps

1. Confirm Phases 1–4 are merged into the working trees used for the build and
   capture the source commit IDs. Do not use a pre-change installed binary.
2. Build a Windows release artifact with production-like authenticated
   configuration. Do not pass `DEV_SKIP_AUTH=true` or any debug-only bypass.
   Record the app version/commit and backend environment identifier without
   recording credentials.
3. Prepare three authenticated host/student scenarios from the tenant UI:
   - Practice with anti-cheat off (`NONE`);
   - Practice with anti-cheat on (`STANDARD`);
   - Official (`STRICT`), with the checkbox absent/irrelevant.
4. Verify policy at each boundary: host create response, exam detail, pinned
   attempt response, and app startup log/test evidence. The app must not infer
   policy from the exam mode.
5. Run the Windows matrix:

   | Scenario | Expected result |
   |---|---|
   | Practice `NONE` | Windowed; task 1 opens; no lockdown hooks |
   | Practice `STANDARD` | Fullscreen and standard hooks complete before task 1 |
   | Standard activation failure | Task screen does not open; retryable error is shown |
   | Fullscreen exit | Warning, local audit row, server audit row; attempt continues |
   | Blocked shortcut | Warning, local/server audit; attempt continues |
   | External clipboard change/paste | Warning, local/server audit; attempt continues |
   | Official `STRICT` forbidden app configured | Existing strict behavior and critical audit; no regression |
   | Offline then reconnect | Local row first, one server row after reconnect |

6. Verify host read access to the normalized audit endpoint and confirm that
   `clientEventId` duplicate replay does not produce a second row. Capture
   request/response status and UI evidence without storing tokens or passwords.
7. Exercise activation failure with a controlled, non-production fixture:
   build a non-distributable release artifact with the exact define
   `--dart-define=PTE_LOCKDOWN_ACTIVATION_FAILURE_FIXTURE=true`. The fixture is
   implemented by `lib/core/security/lockdown_activation_failure_fixture.dart` and
   injected by `security_module.dart` only when that compile-time define is true;
   it makes the fullscreen activation call fail deterministically. A mocked
   unit test alone is not release evidence.
   Build the production artifact again without that define, verify the
   generated release configuration reports the fixture disabled, and record
   both artifact commands and hashes. The fixture artifact is never used for
   distribution.
   The injected failure runs before the real fullscreen call for STANDARD or
   STRICT and must surface the existing retryable activation error before the
   task screen is rendered.
8. Verify non-goals explicitly: no Practice pause, force-submit, invalidation,
   termination, timer change, navigation change, scoring/report change, or
   skill/template change.
9. Update the manual checklist with prerequisites, binary version, policy value,
   expected result, observed result, and failure evidence location.
10. Write ADR-011 with the decision, alternatives rejected, trust boundaries,
   migration/rollback strategy, and the fact that Practice Standard is
   warning/audit-only. Record the selected Flyway version and the fixed
   retention policy: 180 days from detectedAt, Platform Operations owns the
   setting, and the daily job marks rows deleted without hard deletion.

## Rollout data flow

```text
Backend additive contract/migration
  -> tenant web policy control
  -> authenticated Windows release
  -> local canary sessions
  -> host audit review
  -> controlled wider rollout
```

Roll out backend before the clients. If the UI is rolled back, leave the
additive backend table and endpoint in place. If the app is rolled back, do not
delete pinned policies or audit data.

## Acceptance criteria

- [x] A fresh Windows release is identified by version and source commit.
- [ ] Practice `NONE` is windowed and opens task 1.
- [ ] Practice `STANDARD` enters fullscreen before task 1.
- [ ] Controlled activation failure blocks task rendering and is retryable.
- [x] The controlled failure fixture is absent from the production release
  configuration; a mocked unit test is not used as the only evidence.
- [ ] Four controlled violation cases are visible locally and in host audit,
  with the expected warning/critical severity based on pinned policy.
- [ ] Offline/reconnect creates exactly one server event per client event ID.
- [ ] Official remains `STRICT` independently of Practice UI state.
- [ ] No out-of-scope exam behavior changes are observed.
- [x] ADR and manual checklist identify the verified contract and rollback path.
- [ ] The audit page is bounded; student audit rows retain for 180 days from
  detectedAt, Platform Operations owns the setting, and daily cleanup marks
  rows deleted without hard deletion.

**Status:** Release artifacts and controlled-failure fixture are built; the
interactive authenticated student matrix remains pending. Host/proctor manual
walkthrough is explicitly deferred outside the current scope.

## Design Constraints

- Release evidence must come from the newly built Windows binary, not debug
  mode, a browser, or an older installation.
- Do not expand the release to macOS/Linux/mobile or add continuous recording,
  screen capture, VM, or multi-monitor controls.
- Do not redesign proctor/host workflows; only verify policy display and the
  existing/additive audit read path.
- Never include access tokens, passwords, private keys, or `.env` values in the
  checklist, ADR, screenshots, or logs.
- A failed release gate blocks wider rollout; it is not reclassified as a
  successful local test.

## Quality and Testing State

**Quality:** Source/release review in progress; no production-code blocker has
been found. Final release approval is pending the interactive student matrix.
**Testing:** Partial. The failure fixture test, scoped analyzer, production
release build, and controlled-failure release build passed. The authenticated
Windows scenarios and offline/reconnect evidence have not been executed in
this non-interactive pass.

Evidence so far:

- `pte-app/test_manual/lockdown_platform_test.md`
- `pte-doc/projects/architecture/ADR-011-practice-anti-cheat-policy.md`

Required verification after implementation:

- `pte-api`: focused contract/integration tests plus production compile.
- `pte-web`: typecheck/lint and authenticated host browser walkthrough.
- `pte-app`: focused Flutter tests/analyzer and a real Windows release build.
- Manual Windows matrix above, including offline/reconnect and activation
  failure.
- Final code-review/release review that checks the plan's out-of-scope list and
  confirms no claim is made without captured evidence.
