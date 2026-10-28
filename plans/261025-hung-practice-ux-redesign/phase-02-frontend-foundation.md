# Phase 2: Frontend nền tảng

Status: Not started · Tasks: 3, 4, 5, 13, 14 (phần `createLatestGate` + `useLatestRequest`) · Design §3, §6.2, §8.2, §8.5

## Requirements
- Lớp CSS chung (cột 840px, `.card`, `.chip`, `.hint-strip`, `.score-badge`, `.carousel`, `.button-outline`) + token màn làm bài (`--exam-*`).
- `presentation.ts` (màu điểm, định dạng điểm, tên kỹ năng/trạng thái, tên phiên).
- Contract đọc trường mới của Phase 1.
- `refreshOnce` single-flight cho làm mới token.
- `createLatestGate` / `useLatestRequest`.

## Design Constraints
- Tái sử dụng trước: kiểm `common/components` và `pte-web/packages/ui/src` (hooks, utils) trước khi viết mới.
- Hàm thuần có test vitest; `api.ts` giữ < 300 dòng (tách `token-refresh.ts`).

## Steps
Task 3 → 4 → 5 → 13 → 14 (phần gate) trong `tasks.md`.

## Success Criteria
- tsc sạch, eslint 0 lỗi, vitest xanh.

## Quality and Testing State
- Quality: not evaluated
- Testing: not started
