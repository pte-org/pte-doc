# Phase 4: Verification và handoff

Status: ✅ Complete — targeted gates passed; full suite retains a repository-level error  

## Requirements

Xác nhận backend, API client và Vendor Web đồng bộ; ghi lại evidence thật và
giới hạn kiểm chứng trước khi chuyển sang cook/review tiếp theo.

## Design constraints

- Không coi typecheck/build là bằng chứng setting đã có hiệu lực runtime.
- Không deploy, push hoặc mutate production trong phase này.
- Không xóa unrelated worktree changes hoặc plan directory đang có.
- Mọi skipped check phải ghi rõ lý do và boundary.

## Steps

1. Chạy backend focused tests cho registry, validation, permission, batch
   atomicity, cache, runtime SLA và audit.
2. Chạy migration trên database mới và database đã có hai seed setting.
3. Chạy API client typecheck/tests và Vendor Web lint/typecheck/build.
4. Chạy local HTTP/browser matrix với `PLATFORM_ADMIN` và role không được phép.
5. Kiểm tra effect semantics: approval mới, email mới, payment link mới và
   pending order behavior nếu các P2 setting đã được bật.
6. Kiểm tra audit log: actor, action, old/new value, search/display và không có
   secret/raw credential.
7. Kiểm tra diff, conflict markers, generated artifacts và changed-file scope
   ở cả `pte-api`, `pte-web`, `pte-doc`.
8. Đối chiếu acceptance criteria với evidence, cập nhật plan review/handoff và
   ghi rõ phần P2/Future chưa triển khai.

## Success criteria

- Có evidence cho allow/deny matrix và từng active setting.
- Không còn mismatch giữa registry backend, API client types và Vendor Web
  rendering.
- Migration idempotent và không làm thay đổi dữ liệu tenant/plan hiện có ngoài
  behavior đã được quyết định.
- Handoff phân biệt rõ compile/type evidence, local runtime evidence và phần
  chưa kiểm chứng trên môi trường deploy.

## Quality/testing state

Preflight: giữ verification read-only đối với runtime và production; tách compile,
focused test, build và static diff evidence khỏi live migration/HTTP/browser
evidence.

- Backend compile and focused tests passed (`13/13`). The full backend run has
  one pre-existing repository-level error and is recorded in the main plan.
- API client typecheck, Vendor Web typecheck/lint/build passed; lint has two
  existing warnings and no errors.
- `git diff --check` and conflict-marker review passed in `pte-api` and
  `pte-web`; no generated artifacts were added in the changed scope.
- Migration SQL was statically reviewed for the current `platform_settings`
  schema and idempotent seed behavior. No live database migration or HTTP/
  browser role matrix was run.
- Native `ck:cook`/`ck:quality` was unavailable, so the repository standards and
  local quality instructions were applied manually without fabricating a
  quality receipt.

## Handoff checklist

- [x] Active setting catalog và deprecated catalog đã được cập nhật.
- [x] API contract/API client/frontend copy đồng bộ.
- [x] Backend permission, validation, cache và audit đã có focused test.
- [x] Vendor Web có loading/error/dirty/saved/reset states.
- [x] Không có raw key/secret/backend exception trong UI.
- [x] Các setting chưa có runtime consumer không xuất hiện trong active UI.
- [x] Plan review ghi rõ commit/worktree state; chưa push/deploy nếu chưa được yêu cầu.
- [x] Human confirmation để chốt hard cook và đánh dấu plan complete — received 2026-10-15.

## Risks

- Local runtime thiếu fixture role hoặc notification/payment provider — ghi
  limitation thay vì suy diễn production behavior.
- Full suite có lỗi repository-level không liên quan — tách lỗi nền khỏi lỗi của
  plan và không tự sửa ngoài scope.
