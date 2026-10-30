# Phase 4: Frontend — Luyện đề

Status: Not started
User stories: danh sách + làm đề (P1), tiếp tục (P1), điểm ước lượng (P2), làm lại (P2)
FR: FR-07 (đề) · Spec §4.2–4.4

## Requirements

- `/practice-tests` thay catalog theo dạng bài bằng **danh sách đề** (`GET /api/v1/student/practice/mock-tests`):
  - Mỗi hàng: icon (`practice`), title, chip `{itemCount} câu` (icon `responses`), chip ước tính `2h 15m` từ `estimatedMinutes` (icon `timer`), nút theo `latestAttempt`:
    - không có / DISCARDED → **Bắt đầu**;
    - OVERVIEW/IN_PROGRESS → **Tiếp tục** + `ProgressRing` x/total;
    - COMPLETED → **Làm lại** + điểm tổng ước lượng (nếu có).
  - Trạng thái: đang tải (skeleton như catalog), lỗi (thông báo + thử lại), trống "Chưa có đề luyện".
- Bấm Bắt đầu/Tiếp tục → `/practice-tests/session?mockTest=<publicId>`; Làm lại → thêm `&restart=1` (xác nhận bằng `Modal` trước khi bỏ lượt dở nếu có). Không có dialog chế độ.
- Phiên MOCK_TEST: tiêu đề phiên = title đề; mọi câu chạy TIMED (theo `timing` từng item); counter x/65; thoát = save-and-exit như hiện có.
- Review page: phiên MOCK_TEST hiển thị khối **Điểm ước lượng** (overall + 4 kỹ năng, thang 10–90, nhãn "Điểm tham khảo, không phải điểm chính thức"; `pending` → "Đang chấm"; `excludedItemCount > 0` → ghi chú số câu bị loại) phía trên danh sách câu.
- Trang chủ và Tiến trình không đổi hành vi; các link "Practice tests" vẫn trỏ `/practice-tests`.

## Design Constraints

- Feature mới ở `features/mockTests/` (`MockTestListView.tsx`, `mock-test-contracts.ts` + test parser, `mock-test-row.ts` + test trạng thái nút, `EstimatedScores.tsx`).
- API client: thêm `listMockTests()` cạnh các hàm practice hiện có; parser kiểm tra kiểu như `contracts.ts` (không tin dữ liệu server).
- `useSessionLifecycle`: thêm nhánh `mockTest` (+`restart`) gửi `mockTestId`/`restart`; `requestKey` gồm cả hai.
- Dùng lại `ProgressRing`, `Modal`, `AppIcon`, `LockBadge`, `CountdownTimer` không cần; CSS token sẵn có, tiền tố `mock-test-`.
- i18n `mockTests.*` (en/vi) cho mọi chuỗi mới.
- `CatalogGrid` không còn dùng ở `/practice-tests` → xoá nếu không nơi nào dùng (kiểm tra bằng grep), cùng key i18n thừa.

## Related files

- `pte-practice/features/catalog/PracticeTestsView.tsx` (thay bằng danh sách đề), `features/catalog/CatalogGrid.tsx` (có thể xoá)
- `features/mockTests/*` (mới)
- `features/practice/api/*` hoặc nơi đang định nghĩa client practice (thêm `listMockTests`)
- `features/practice/session/useSessionLifecycle.ts`, `features/practice/mode/practice-url.ts`
- Review: `app/(student)/practice-tests/session/review/page.tsx` và view review trong `features/practice/`
- `features/practice/session-contracts.ts` (`estimatedScores` trong review), `common/i18n/{types,en,vi}.ts`, `app/globals.css`

## Steps

1. Contract + parser đề và `estimatedScores`; test parser (thiếu trường, sai kiểu, null).
2. `mock-test-row.ts`: trạng thái nút/nhãn từ `latestAttempt`; `formatEstimatedDuration(minutes)` → `2h 15m`/`45m`; test.
3. `MockTestListView` + thay `PracticeTestsView`; CSS hàng như ảnh.
4. URL + `useSessionLifecycle` nhánh mockTest/restart; test `practice-url`.
5. Modal xác nhận Làm lại khi còn lượt dở.
6. `EstimatedScores` trên review page.
7. Dọn `CatalogGrid` và i18n thừa.
8. Build gate: tsc, eslint, vitest.

## Success Criteria

- `/practice-tests` liệt kê đúng số đề đã generate, chip 65 câu + thời lượng ước tính.
- Bắt đầu đề → câu 1 Speaking, TIMED; trả lời 5 câu, thoát, quay lại → hàng "Tiếp tục 5/65", vào câu 6.
- Đề đã xong → "Làm lại" + điểm; review hiện 4 điểm kỹ năng + nhãn tham khảo.
- tsc sạch, eslint 0 lỗi, vitest xanh.

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
