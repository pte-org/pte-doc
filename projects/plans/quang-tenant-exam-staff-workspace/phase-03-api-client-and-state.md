# Phase 03: API client and query state

**Status:** Completed
**Stories:** US-01..06, US-08, US-09
**Depends on:** Phase02 DTO/contracts

## Goal

Đưa typed requests và request lifecycle vào đúng layer, không dồn fetch/state vào component.

## Work items

1. @pte/api-client thêm staff profile/overview/proctor/examiner DTO và requests với barrels; staff PATCH route separate Student.
2. Feature examStaff thêm query-key constants chứa target ID/filter/page/column/tenant identity theo existing cache conventions; clear/reset auth cache theo app pattern.
3. TanStack Query hooks: detail query trực tiếp ID cho deep link, lazy role/tab work queries; filter update reset paging; draft filters chỉ Apply mới gọi nếu phù hợp UI common.
4. Board independent page state theo status, stable cache keys, retry/refresh và abort/stale protection; không fetch full list để client-filter.
5. Mutations edit/suspend/reactivate/send-email invalidate staff list/detail/overview/work liên quan, không invalidate feature khác vô cớ; guard target switching/unsaved draft.
6. Error mapping constants+i18n, validation errors structured; khi API fail không kết thúc ở skeleton hoặc giả no data.
7. Chuẩn hóa timezone/date conversion utility theo phase01, không dùng new Date(dateOnly) mà vô tình coi ngày local là UTC.

## Design Constraints

Preflight: API requests use typed client.request and shared PageMeta; feature hooks own TanStack Query state; examStaff cache prefix is already invalidated by lifecycle and credential actions; protected session changes clear query cache. Preserve these conventions, pass AbortSignal, omit absent query parameters, never derive server totals from a fetched page, keep role/tab queries disabled when irrelevant. No exceptions.

Execution choices: Standard --no-tests --quality --checks-all-phases; user requested automatic continuation, no new/run tests, independent quality gate and scoped typecheck/build retained.

## Files

pte-web: packages/api-client/src/types/admin/examStaffWorkspace.ts; packages/api-client/src/types/admin/index.ts; packages/api-client/src/requests/admin/examStaffWorkspace.ts; packages/api-client/src/requests/index.ts. apps/tenant-web/features/examStaff/detail/{api.ts,constants.ts,types.ts,utils.ts}; detail/hooks/{useStaffWorkspaceFilters.ts,useStaffDetailText.ts}; detail/messages/{en.ts,vi.ts}. Existing credentials/lifecycle invalidation and auth-cache clearing remain unchanged.

- API types/requests ở package; hooks ở feature; no any/raw errors.
- Không dùng /me hoặc personal examiner hooks cho selected staff.
- Node helper test không được gọi là UI navigation test.
- Giữ existing credential-email semantics và pending/error states.

## Focused verification

- Serialization selected public ID/status/date bounds/page/max size, no absent null params.
- Query enabling dual roles/active tabs, page reset/key isolation/stale ID; mutation invalidation matrix.
- Mock API fail/timeouts và empty vs unavailable mapping; credential secret không persistent cache/localStorage.

## Quality and Testing State

- Implementation: typed requests, DTOs, tenant/target cache scope, abortable hooks, Apply/reset date state and en/vi messages implemented.
- Quality: APPROVED; report `quality/phase-03-api-client-and-state-quality-report.json`, receipt `quality/phase-03-api-client-and-state-receipt.json` verified VALID. One LOW advisory requests an assertion explanation; no blocking findings.
- Testing: not_started; declined by user. API-client and tenant typechecks, scoped ESLint and diff whitespace check passed; production build deferred to integration phase.
- User checkpoint: automatic continuation authorized; UI integration follows in phases 04–06, manual review at end.
- Không ghi completed/approved chỉ từ static review hay phase trước.

## Acceptance / Blocking gate

API-client/tenant typecheck và focused request/state tests đúng scope, không đổi unrelated endpoints.
