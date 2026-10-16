# Phase 4: Verification and handoff

## Requirements

Xác nhận backend, API client và Vendor Web đồng bộ; ghi rõ test/build/runtime
evidence và giới hạn kiểm chứng trước khi chuyển sang cook/review tiếp theo.

## Design Constraints

- Không coi typecheck/build là bằng chứng của live authorization.
- Không deploy, push hoặc mutate production trong phase này.
- Không xóa unrelated worktree changes hoặc secret-bearing artifacts.
- Mọi skipped check phải ghi rõ lý do và boundary.

## Steps

1. Chạy focused backend authorization, lifecycle, password, audit và regression tests.
2. Chạy API-client typecheck/tests và Vendor Web typecheck, lint, build.
3. Kiểm tra diff, conflict markers, generated artifacts và changed-file scope.
4. Chạy local HTTP/browser matrix nếu runtime fixture sẵn sàng.
5. Đối chiếu acceptance criteria với evidence thật, không suy diễn từ static output.
6. Ghi quality/review limitations và cập nhật handoff trong plan directory.

## Success Criteria

- Có evidence cho allow/deny matrix và mọi acceptance criterion quan trọng.
- Không còn mismatch giữa API client, backend endpoint và Vendor Web action.
- Handoff nêu rõ phần đã kiểm tra, chưa kiểm tra và command cook tiếp theo.

## Quality and Testing State

- Quality gate: completed through the hard-cook review. The callable native
  `ck:cook`/`ck:quality` command was not available in this session, so the
  repository standards and the local hard-cook checks were followed manually.
- Testing: backend compile passed; focused backend suite passed with 27 tests;
  backend suite excluding the unrelated `ModuleStructureTest` passed with 2082
  tests, 0 failures, 0 errors and 56 skipped. API client typecheck and 605 tests,
  Vendor Web typecheck/lint/build and 66 tests, and tenant-web typecheck passed.

## Verification Evidence

- Contract alignment: backend endpoints, API-client requests/types and Vendor Web
  mutations share the same profile/reset/archive/restore contract.
- Security: server-side `PLATFORM_ADMIN` policy, self/admin protection, archived
  login/refresh exclusion, refresh-token revocation and safe response coverage are
  covered by the focused identity tests.
- Worktree: `git diff --check` passed for the changed repositories; no merge
  conflict markers or generated artifacts were added by the implementation.
- Runtime boundary: no live HTTP/browser authorization matrix was run in this
  cook because a configured runtime fixture was not part of the requested session.
  The implementation is therefore verified by compile, type, unit, contract and
  production-build checks, not by a deployed environment.

## Handoff

- Changes are intentionally uncommitted and unpushed.
- The unfiltered backend suite remains red only because `ModuleStructureTest`
  detects existing attempt/session/enrollment/reporting dependency cycles; this
  task did not touch those module boundaries.

## Risks

- Local runtime không có đủ role fixture — tách static evidence khỏi live evidence
  và ghi limitation thay vì đánh dấu pass.
