# Phase 6: vendor-web — Publish/Archive/Unarchive UI trong questionbank + sửa path cũ

Covers User Decision 1 phía frontend: nút Publish/Archive/Unarchive thật sự chạy được đòi hỏi sửa path stale của `requests/question` (đang trỏ `/api/authoring/questions`, controller thật là `/questions`), cộng hiển thị đúng 3 trạng thái DRAFT/PUBLISHED/ARCHIVED thay vì chỉ 2 (`draft`/`in_use`) như hiện tại. Đối tượng dùng màn này **không đổi** theo quyết định "chỉ platform thao tác question bank" (2026-09-17) — `vendor-web` vốn đã là UI dành riêng cho platform (`PLATFORM_ADMIN`/`PLATFORM_AUTHOR`, theo `QuestionController` đã khóa ở Phase 1), quyết định mới chỉ xác nhận lại rõ ràng hơn, không mở rộng hay thu hẹp phạm vi UI này.

## Requirements

Platform admin (`PLATFORM_ADMIN`/`PLATFORM_AUTHOR`) thấy đúng trạng thái DRAFT/PUBLISHED/ARCHIVED của mỗi câu hỏi trong bảng questionbank và bấm được Publish (DRAFT→PUBLISHED) / Archive (→ARCHIVED) / Unarchive (ARCHIVED→DRAFT) ngay từ dòng bảng, gọi đúng API thật của `pte-api`.

## Files

**Sửa**
- `pte-web/packages/api-client/src/requests/question/index.ts` — sửa `QUESTION_ENDPOINTS.questions`/`byId` bỏ tiền tố `/api/authoring` (còn `/questions`, `/questions/{id}`); thêm `publishQuestion`/`archiveQuestion`/`unarchiveQuestion` gọi `POST /questions/{id}/publish`/`POST /questions/{id}/archive`/`POST /questions/{id}/unarchive`.
- `pte-web/apps/vendor-web/features/questionbank/types.ts` — `QuestionStatus` đổi từ `"in_use" | "draft"` sang 3 giá trị thật (`"draft" | "published" | "archived"`).
- `pte-web/apps/vendor-web/features/questionbank/api.ts` — `mapStatus()` map đủ 3 giá trị `QuestionResponse.status` (DRAFT/PUBLISHED/ARCHIVED) sang 3 giá trị FE; thêm `usePublishQuestion()`/`useArchiveQuestion()`/`useUnarchiveQuestion()` (mutation + invalidate `QUESTIONS_QUERY_KEY`/`QUESTION_STATS_QUERY_KEY`).
- `pte-web/apps/vendor-web/features/questionbank/constants.ts` — `QUESTION_STATUS_LABELS`/`QUESTION_STATUS_VARIANT`/`QUESTION_STATUS_FILTER_OPTIONS` cập nhật cho 3 giá trị; thêm text cho action Publish/Archive/Unarchive.
- `pte-web/apps/vendor-web/features/questionbank/components/_QuestionTable.tsx` — thêm 3 mục "Publish"/"Archive"/"Unarchive" vào `Dropdown` mỗi dòng, chỉ hiện/enable đúng chuyển hợp lệ: DRAFT → Publish, Archive; PUBLISHED → Archive; ARCHIVED → Unarchive (về DRAFT).

## Steps

1. Sửa `QUESTION_ENDPOINTS` trong `requests/question/index.ts` bỏ tiền tố `/api/authoring` — đây là path duy nhất trong module này bị chạm; không đụng `updateQuestion`/`deleteQuestion` (đã có comment sẵn xác nhận backend không có 2 endpoint này, ngoài phạm vi phase).
2. Thêm `publishQuestion(client, id)`/`archiveQuestion(client, id)`/`unarchiveQuestion(client, id)` vào cùng file, cùng convention `POST` không body như các action khác trong repo (`openSession`, `activateClass`...).
3. Đổi `QuestionStatus` FE thành 3 giá trị thật, sửa `mapStatus()` map thẳng 1-1 với `QuestionResponse.status` (không còn gộp PUBLISHED+ARCHIVED thành `in_use`).
4. Thêm `usePublishQuestion()`/`useArchiveQuestion()`/`useUnarchiveQuestion()` trong `api.ts` theo pattern `useMutation` + `invalidateQueries` đã dùng ở các feature khác trong repo (vd `scoretemplate/api.ts` của Plan A).
5. Cập nhật `constants.ts` cho 3 trạng thái (nhãn, màu badge, filter option).
6. Thêm 3 action Publish/Archive/Unarchive vào `_QuestionTable.tsx`'s `Dropdown`, disable hợp lý theo trạng thái hiện tại của từng dòng, gọi đúng 3 hook mới.

## Tests

- Không có bộ test UI tự động cho bất kỳ trang admin nào trong `vendor-web` hiện tại (đúng tiền lệ đã ghi nhận ở Plan A Phase 6) — không thêm test mới lệch chuẩn, verify bằng:
  - `tsc --noEmit` sạch cho `vendor-web` + `api-client`.
  - `eslint` sạch.
  - `next build` (hoặc build tương đương) thành công.
- Nếu repo có sẵn helper test cho `requests/` (unit test thuần path/shape, không cần server thật) thì thêm 1 test khẳng định `QUESTION_ENDPOINTS.questions === "/questions"` để tránh path stale tái phát — chỉ thêm nếu có tiền lệ test tương tự trong `packages/api-client` (kiểm tra trước khi thêm).

## Success Criteria

- `QUESTION_ENDPOINTS.questions`/`byId` không còn tiền tố `/api/authoring`.
- Bấm Publish trên một câu DRAFT hợp lệ (đủ field) → trạng thái hiển thị đổi thành PUBLISHED sau khi mutation thành công (verify tay qua `next dev` + backend thật, vì không có test UI tự động).
- Bấm Publish trên câu thiếu field → backend trả lỗi (Phase 1), FE hiển thị lỗi rõ ràng (không crash silent).
- Bấm Unarchive trên câu ARCHIVED → trạng thái đổi về DRAFT (không nhảy thẳng PUBLISHED).
- `tsc --noEmit`/`eslint`/build đều sạch cho `vendor-web` và `api-client`.

## Risks

- MEDIUM: `updateQuestion`/`deleteQuestion` trong cùng file gọi endpoint không tồn tại ở backend thật — không sửa trong phase này (đã note sẵn trong code là "kept only as type/stub"), nhưng cần đảm bảo path prefix mới không vô tình làm chúng "trông như đúng" khi vẫn gọi nhầm HTTP method backend chưa hỗ trợ — không có action nào trong Phase 6 gọi 2 hàm này nên rủi ro chỉ là nhận thức, không phải hành vi.
- LOW: Chưa chạy tay được luồng Publish→Archive→Unarchive qua UI thật (cần dựng đủ Postgres+backend+đăng nhập role thật) trong phiên viết plan — ghi rõ đây là giới hạn cần verify thủ công khi implement, giống Plan A Phase 6.
