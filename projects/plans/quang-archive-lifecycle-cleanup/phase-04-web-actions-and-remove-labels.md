# Phase 04: Web actions và Remove text

Status: completed (contract/browser/typecheck/lint/build gates). Stories: P1 actions, P2 clarity. Depends on: phase02 + phase03 endpoints/contracts.

## Tasks

- [x] Đọc `pte-web/AGENTS.md` và docs Next cục bộ theo yêu cầu trước implementation; giữ nguyên brand/layout, không dựng mockup mới.
- [x] Add `deletePlan` API client; reuse `deleteQuestion` helper có sẵn sau controller support. Add capabilities DTO và endpoint tests; không xóa độc lập exports đang dùng ở phần khác.
- [x] Add vendor query hooks/mutation: success invalidate list/detail/stats đúng module;409 refetch capabilities, preserve confirmation/error context. Catch mutateAsync hoặc dùng mutate callbacks, reset error theo operation.
- [x] Plan row DRAFT có Delete draft nếu capability cho phép; ACTIVE giữ Archive/label retirement rõ; ARCHIVED read-only. Reason tooltip/helper khi guard chặn, không hiện action khi chưa load capabilities.
- [x] Question new eligibleDRAFT có Delete draft thay Archive; pending không Archive/Delete; published giữ Archive; known-history DRAFT có Archive theo rule server. UNKNOWN có blocker, không giả định cleanup là delete.
- [x] Confirm Delete draft nói rõ bỏ khỏi authoring, không khôi phục trong UI hiện tại, vẫn giữ audit; không nói xóa vĩnh viễn DB. Archive nói ngừng sử dụng mới, không hủy lịch sử đề.
- [x] Disable actions/Cancel/X/Escape theo pending hoặc operation guard; nếu request fail giữ dialog và data; tránh callback success cũ tác động dialog khác.
- [x] Program detail + Class row text Archive→Remove; giữ existing mutation names/routes và active children/member guards. Sửa confirmation/help/load-error text phù hợp removed vs permission/load fail, không viết “archived” cho mọi404.
- [x] Rà thông báo merge/split liên quan Class; text nói source classes không bị remove tự động, không thay merge behavior.
- [x] Check toast/a11y label/filter wording. Giữ state enum ARCHIVED của Plan/Question, không đổi thành deleted ở tất cả badge.

## Files / surfaces

`packages/api-client/src/requests/billing/plans.ts`, question request helper, response types và contract tests; vendor `features/commercialization` hooks/constants/PlanCatalogView; `questionbank` hooks/constants/_QuestionTable/QuestionEditorView; tenant `programs` constants/ProgramDetailView và `classes` constants/ClassesSection/merge-split text.

Chỉ sửa shared Modal/ConfirmDialog nếu đúng nhu cầu close-guard và compatibility tests; không refactor toàn @pte/ui.

## Design Constraints

Preflight: tests=yes and quality=yes for all phases by explicit user consent. Reuse existing @pte/ui ActionMenu/Modal/ConfirmDialog, React Query hooks and module text constants. Additive optional capabilities fail closed for older servers; backend remains authoritative. Modal dismissal guard defaults false, preserving existing callers; ConfirmDialog guards while confirming. Scope is action wiring and wording, not layout/style redesign. Next local use-client documentation read. Public request barrel already wildcard-exports billing/plans, so no export rewrite is needed.

- UI capability không thay authorization/state checks backend.
- Missing capability fail closed; server mới deploy trước/same release, không gọi DELETE vào server cũ.
- Delete/Archive/Remove có text riêng, không dùng Trash icon để ám chỉ permanent erase khi thực tế retirement.
- Program/Class đổi text, không đổi persistence hoặc routes. Không thêm archive vào module khác.

## Tests to Write First (đề xuất)

- API client đúng DELETE URL/method và204 parsing; existing archive/unarchive contract không đổi.
- Browser fixtures cho mọi state/capability: new/known-history/unknownDRAFT, pending/published/archived/deleted.
- Confirmation pending, failed mutation, conflict refetch, repeated click; console không unhandled rejection.
- Tenant Remove vẫn blocked khi Program còn lớp/Class còn membership; inactive vẫn visible.
- Snapshot view historical content không bị thông báo liveQuestion404 làm mất đề đã pin.

## Verification / exit

```powershell
# cwd: pte-web
pnpm --filter @pte/api-client typecheck
pnpm --filter @pte/api-client test
pnpm --filter vendor-web lint
pnpm --filter tenant-web lint
pnpm --filter vendor-web build
pnpm --filter tenant-web build
```

Các app hiện không có script test riêng; không invent `pnpm --filter vendor-web test`. Browser testing dùng Playwright skill khi triển khai, tách mockedUI evidence khỏi realAPI evidence.

## Quality and Testing State

- User test choice: yes, all phases.
- Quality: APPROVED, inline audit; [report](quality/phase-04-web-actions-and-remove-labels-quality-report.json), [receipt](quality/phase-04-web-actions-and-remove-labels-receipt.json).
- Testing: 381 API-client unit tests and 21 mocked browser checks passed. Both apps typecheck/lint/build passed (existing warnings documented). No authenticated live API E2E claim.
- Enrollment remains wording-only. No new Class confirmation flow or membership/concurrency behavior is introduced; existing guards are covered by Program/Class service regression.
