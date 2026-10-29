# Quang host exam app preview — Phase 1 preflight

Date: 2026-10-29 (Asia/Bangkok)
Plan: `quang-host-exam-app-preview`
Phase: 1 — `preflight-and-discard`
Status: baseline recorded; discard and implementation are not yet complete.

## Session and instruction check

- The session-memory hook was invoked for `D:/GitHub/pte-org/pte-app`.
- Result: no previous session was found for this project.
- Root `AGENTS.md` and the nearest `pte-web/AGENTS.md` were read. No
  `pte-app/AGENTS.md` or `pte-api/AGENTS.md` exists in the current checkout.

## Standards and supporting documents read

The complete applicable documents were read before source changes:

- `docs/CODING_STANDARDS_APP.md`
- `docs/CODING_STANDARDS_API.md`
- `docs/CODING_STANDARDS_WEB.md`
- `docs/API_RESPONSE_SETUP.md`
- `docs/COMMON_EXCEPTION_SETUP.md`
- `docs/TEST_SCENARIOS_IAM.md`
- `pte-web/AGENTS.md`

Relevant rules carried into this phase are: preserve nested-repository changes;
keep the temporary discard surgical; keep host authorization server-enforced;
preserve API envelopes and tenant boundaries; do not expose secrets; and keep
Flutter security/resource lifecycle changes explicit and testable.

## Repository baseline

The following read-only commands were run from `D:/GitHub/pte-org`:

```text
git -C <repo> branch --show-current
git -C <repo> rev-parse HEAD
git -C <repo> status --short
git -C <repo> diff --cached --name-status
git -C <repo> diff --name-status
git -C <repo> diff --stat
git -C <repo> ls-files --others --exclude-standard
```

| Repository | Branch | HEAD | Staged | Unstaged / untracked |
|---|---|---|---|---|
| `pte-app` | `quang/maintain-v2` | `35ed2ca90e83b6cf24170975c234e3649938fa96` | none | 5 modified tracked files; 75 insertions, 2 deletions; no untracked |
| `pte-api` | `quang/feat/maintain-v2` | `60ea3043504cf47b934ec5f58d2ed10115abd68e` | none | 2 modified tracked files and 8 untracked paths, including local seed/migration scripts |
| `pte-web` | `quang/feat/maintain-v2` | `3275bb2a5133babc8b518ad976dc8f2e496ea1be` | 1 added test file | 20 modified tracked files and 3 untracked paths |
| `pte-doc` | `quang/feat/maintain-v2` | `9aa81cec5eb90a8160ecd01045ff7425a8891eab` | none | this plan bundle and report are untracked |

The complete current status remains the source of truth; no unrelated path was
staged, reset, restored, or deleted by this step.

## Convention samples checked

- `pte-app/lib/core/config/app_config.dart`: compile-time configuration is
  centralized in `AppConfig`; security changes must not silently become a
  release-wide default.
- `pte-app/lib/features/auth/domain/exam_access_policy.dart`: the current app
  gate is a UI-only policy and currently recognizes the `STUDENT` role; backend
  authorization remains authoritative.
- `pte-api/app/src/main/java/com/pte/session/internal/controller/SessionController.java`:
  session routes use `@PreAuthorize("hasRole('HOST_ADMIN')")`, resolve the
  authenticated caller through `CurrentUserContext`, and return the shared
  `ApiResponse` envelope.
- `pte-web/apps/tenant-web/features/notifications/components/NotificationBellContainer.tsx`:
  the existing common notification bell routes `SESSION` targets to the host
  exam detail route and reports failures through the shared toast.

## Settled role and data boundary

| Caller | Host preview | Student attempt from host home | Native exam enforcement |
|---|---:|---:|---:|
| `HOST_ADMIN` | allowed for own-tenant snapshot-backed sessions | not exposed in v1 | disabled only while in host preview |
| `HOST_ADMIN` + `STUDENT` | host preview is the default | not exposed in v1 | disabled only while in host preview |
| `STUDENT` | denied | existing student flow only | existing enforcement remains active |
| `PROCTOR`, `EXAMINER`, platform-only | denied by existing client boundary | not changed | not changed |

The preview is read-only: no attempt, enrollment, answer persistence/outbox,
upload, grading, quota debit, or session-status mutation. Tenant ownership and
role checks remain server-enforced; JWT decoding is not an authorization source.

## Phase 1 source boundary

Before coding, only the following existing temporary flag changes may be
discarded, and only after the binary backup step succeeds:

```text
pte-app/README.md
pte-app/lib/core/config/app_config.dart
pte-app/lib/core/di/security_module.dart
pte-app/lib/core/security/lockdown_service.dart
pte-app/test/unit/core/security/lockdown_service_test.dart
```

The reviewed purpose is the temporary global `PTE_EXAM_SECURITY_ENABLED` false
default and its test/documentation support. Any additional hunk in these files
must be preserved. Files outside this list are out of scope for discard.

## Recoverable backup before discard

The complete staged+unstaged diff against `pte-app` HEAD was reviewed. All five
paths contain only the temporary security flag/default and its test/documentation
support; no unrelated hunk was found.

- Staged paths before backup: none.
- Unstaged paths included in backup: the five paths listed above.
- Backup: [`pte-app-security-flag-before-discard.patch`](assets/261029-quang-host-exam-app-preview-preflight/pte-app-security-flag-before-discard.patch)
- Backup size: 7,819 bytes.
- SHA-256: `BD0651A6D73AEB9E45D6290B3E053D9711F78E83597AA30A0DD4D4CA7F0A6601`.
- `git apply --stat`: exit 0; 5 files, 75 insertions, 2 deletions.
- `git apply --check --reverse`: exit 0 against the current worktree.

Recovery command, if needed after confirming the target worktree is unchanged:

```powershell
git -C D:/GitHub/pte-org/pte-app apply --binary `
  D:/GitHub/pte-org/pte-doc/plans/reports/assets/261029-quang-host-exam-app-preview-preflight/pte-app-security-flag-before-discard.patch
```

The patch is deliberately stored outside `pte-app`; it does not contain
credentials, environment files, or private data.

## Surgical discard result

The backup patch was applied in reverse with `git apply --reverse --binary`.

| Check | Result |
|---|---|
| Reverse apply | exit 0 |
| Target `git diff --exit-code HEAD -- <five paths>` | exit 0 |
| Target paths remaining in `git diff HEAD --name-status` | none |
| Staged paths before / after | none / none |
| Non-target status before / after | empty / empty |
| Executable rebuild | not run; the old executable was not modified |

The temporary global security-disable flag and its test/documentation changes
are therefore removed from the working tree, while the recovery patch remains
available at the path above. No other `pte-app` path was discarded.

## Mocked security/auth baseline

Commands were run from `D:/GitHub/pte-org/pte-app`; all four exited 0:

```text
flutter test test/unit/core/security/lockdown_service_test.dart       exit 0 — 20 tests
flutter test test/unit/features/auth/domain/exam_access_policy_test.dart exit 0 — 8 tests
flutter test test/unit/features/auth/auth_bloc_test.dart               exit 0 — 5 tests
flutter test test/widget/app_auth_gate_test.dart                       exit 0 — 16 tests
```

These are mocked/unit/widget tests. No Windows native fullscreen, process
termination, clipboard/shortcut guard, Docker service, database, or release
executable was launched or changed.

## Current evidence boundary

- This report proves the read-only preflight and baseline only.
- The recoverable binary patch, surgical discard, baseline test command, and
  contract/file-manifest artifacts are still pending in Phase 1.
- No source code, database, Docker service, executable, commit, push, or deploy
  was changed by this report.
