# Phase 4: vendor-web, trải nghiệm "Tạo đề bằng AI"

Đọc trước: `docs/CODING_STANDARDS_WEB.md`. Kiểm tra bằng tsc, eslint, vitest. **Không** dùng Playwright (user tự kiểm tra UI).

## Nguyên tắc UI/UX (ràng buộc cho phase này)

1. **Common trước, feature sau.** Chỉ dựng giao diện từ `@pte/ui` (`packages/ui/src/components`) và các token của design system.
   Không có màu hex hay khoảng cách tùy ý trong feature. Một mẫu UI cần dùng lại ở chỗ khác (ví dụ timeline các bước) thì đặt vào `packages/ui`,
   có story/test, không nằm trong `features/`.
2. **Ở lại trong ngữ cảnh.** Admin không phải rời trang question bank: form mở trong `Drawer`, tiến độ hiện ở một khay cố định,
   duyệt câu hỏi trong một màn split view.
3. **Luôn cho biết đang xảy ra gì.** Mỗi câu hiện bước hiện tại (đang viết → đang review → đang tạo audio/ảnh → đã lưu),
   kèm ước lượng thời gian. Không có spinner "chờ mãi".
4. **AI hỗ trợ, người quyết định.** Kết quả của AI luôn mang nhãn "AI tạo". Phiếu review nằm ngay cạnh nội dung câu hỏi.
   Những việc tốn thời gian (duyệt, xóa, hủy) chỉ cần 1–2 click, có thao tác hàng loạt và `ConfirmDialog`.
5. **Ít chữ, nhiều tín hiệu.** Chip, icon và màu cho trạng thái, nhưng **không chỉ dùng màu**: luôn kèm icon hoặc chữ
   để đảm bảo accessibility. Chi tiết nằm sau tab hoặc collapse, không dồn hết lên một màn (bài học từ màn rubric).
6. **Hiện đại nhưng tiết chế.** Dùng `MotionReveal` và transition ngắn (≤ 200ms) cho các item mới xuất hiện; skeleton thay cho spinner;
   dark mode và responsive (≥ 1280 hiện split view, nhỏ hơn thì xếp chồng).
7. **Accessibility:** điều khiển được hoàn toàn bằng bàn phím; tiến độ dùng `aria-live="polite"`; focus trap trong Drawer và Modal;
   độ tương phản đạt WCAG AA.
8. **Song ngữ:** mọi chuỗi nằm trong `messages/en.ts` và `messages/vi.ts`.

## Luồng người dùng

```
Question bank (list)
  [✦ Tạo bằng AI]  ──►  Drawer "Tạo đề bằng AI"
                           ① Kỹ năng   (TabRailCard: Speaking | Writing | Reading | Listening)
                           ② Dạng bài  (RadioCard grid: tên + mô tả 1 dòng + icon "có audio/ảnh")
                           ③ Cấp CEFR  (Chip segmented B1 B2 C1 C2)
                           ④ Pool      (RadioCard PRACTICE / EXAM)
                           ⑤ Chủ đề    (Input, gợi ý chip: Education, Environment, Technology...)
                           ⑥ Số lượng  (nút − 5 +, giới hạn 1–10)
                           InfoPanel: "≈ 1–2 phút/câu · còn 85/100 câu hôm nay"
                           FormActions [Hủy] [Bắt đầu tạo]
                       ──► Toast "Đã bắt đầu" + Drawer đóng
  Khay "Đang tạo" (DashboardPanel, góc trên danh sách, gập được)
     Job: Read Aloud · B2 · 5 câu  ███████░░ 3/5   ✓3 ✗0   [Hủy]
       └ mở rộng: StepTimeline từng câu (✎ viết → 🔍 review → 🔊 audio → ✓ lưu | ✗ lý do)
     Khi xong: [Duyệt 5 câu →]
  ──► Màn duyệt /admin/question-bank/ai-review?job=...
       Trái: danh sách câu của job (DataTable gọn: #, chủ đề, verdict chip, trạng thái duyệt)
       Phải: Tabs [Xem trước | Review AI | Chỉnh sửa]
              Xem trước = component exam-screen preview đang có (người duyệt thấy đúng như thí sinh)
              Review AI = 6 check + CEFR ước lượng + metrics + keyPoints + media
       Thanh hành động: [Gửi duyệt] [Sửa] [Xóa]  · phím tắt ↑/↓ chuyển câu
       Hàng loạt: "Gửi duyệt tất cả câu PASS" · "Xóa các câu đã chọn"
```

## Thành phần dùng lại từ `@pte/ui`

| Nhu cầu | Component |
|---|---|
| Khung form | `Drawer`, `FormField`, `FormActions`, `InfoPanel` |
| Chọn kỹ năng và dạng bài | `TabRailCard`, `RadioCard` |
| CEFR, chủ đề gợi ý, verdict | `Chip`, `Badge`, `StatusBadge` |
| Tiến độ | `DashboardPanel`, `ProgressBar`, `CollapsibleSection` |
| Danh sách job và câu | `DataTable`, `SectionedTableCard`, `PaginationControls` |
| Chi tiết câu | `Tabs`, `DescriptionList`, `DetailGroup` |
| Trạng thái | `Skeleton`, `EmptyState`, `ErrorState`, `ForbiddenState`, `Toast`, `ConfirmDialog` |
| Hiệu ứng | `MotionReveal` |

**Component common mới** (đặt trong `packages/ui`, có test):
- `StepTimeline`: danh sách các bước theo chiều ngang hoặc dọc, mỗi bước có trạng thái `pending|active|done|failed`, kèm icon và chữ.
  Sau này dùng lại được cho import học viên, publish đề...
- `QuantityStepper`: nút − số + có min/max, hỗ trợ bàn phím. Không dùng ô nhập số tự do (theo memory "drag-drop over numeric input").
  Trước khi viết mới, kiểm tra `TableNumberInput` xem có mở rộng được không.

## Trạng thái và thông điệp

- **Rỗng:** `EmptyState` "Chưa có lượt tạo nào", kèm minh họa và nút mở Drawer.
- **Đang chạy:** item mới hiện bằng `MotionReveal`. Bước `active` có animation pulse nhẹ (tắt khi bật `prefers-reduced-motion`).
- **Câu thất bại:** chip đỏ kèm lý do đã dịch, ví dụ "Reviewer: đáp án không duy nhất". Không hiện mã lỗi thô.
- **Job lỗi provider:** `Alert` kèm hướng dẫn "Thử lại sau vài phút", không lộ chi tiết kỹ thuật.
- **Tính năng tắt** (`GENERATION_DISABLED`): nút vẫn hiện nhưng bị disable, kèm tooltip giải thích.
- **Hết lượt trong ngày:** `InfoPanel` cảnh báo trước khi submit, không đợi submit xong mới báo lỗi.

## Thay đổi kéo theo ở backend (bổ sung cho phase 1 và 3)
- Mỗi item trong `items_json` có thêm `stage`: `QUEUED|GENERATING|VALIDATING|REVIEWING|RENDERING_MEDIA|SAVED|FAILED`.
  Worker cập nhật stage (cùng heartbeat) để FE dựng `StepTimeline`.
- `GET /question-generation/quota` → `{usedToday, dailyLimit}` cho `InfoPanel`.
- `GET /question-generation/task-types` trả thêm `section`, `needsAudio`, `needsImage` và `estimatedSecondsPerItem`.

## Test (vitest)
- api/mapper: job, item stage, quota.
- hook: poll mỗi 3 giây và dừng khi job ở trạng thái kết thúc.
- `StepTimeline` và `QuantityStepper` (trong `packages/ui`): render các trạng thái, bàn phím, `aria-*`.
- Form: chọn kỹ năng thì lọc dạng bài; giới hạn số lượng; cảnh báo quota.
- Màn duyệt: chuyển câu bằng phím ↑/↓; thao tác hàng loạt chỉ chọn câu PASS; render panel review khi có và không có meta.

## Phase 4 Implementation Status

### Completed
- ✅ API types: Added `GenerationMetaResponse` with nested types (metrics, media, review verdict) to `packages/api-client/src/types/question/index.ts`
- ✅ API client: Updated `listQuestions()` to support `aiGenerated` query parameter
- ✅ Question type: Added `generationMeta` to Question interface in questionbank feature
- ✅ AI source filter: Implemented 3-way filter (All/AI/Manual) in QuestionBankView using `aiGenerated` param to backend
- ✅ AI badge: Added "AI Generated" badge to question content cell when `generationMeta != null`
- ✅ Review page tabs: Updated `_ReviewPanelTabs.tsx` with 3 tabs (Preview | Review AI | Edit)
  - Preview tab: Uses `ExamScreenPreview` component with question data converted via `buildQuestionPreviewDraft()`
  - Review AI tab: Displays real `GenerationMetaResponse` via `ReviewPanel` component showing checks, metrics, key points
  - Edit tab: Link to question edit route with note that editing marks as human-edited
- ✅ GenerationDrawer refactor: Split 338-line component into 7 focused sub-components (SkillStep, TaskTypeStep, CefrStep, PoolStep, TopicStep, CountStep) each ≤70 lines
- ✅ Type checking: `pnpm exec tsc --noEmit` passes for both vendor-web and packages/api-client

### Ready for
- Tests: Real test coverage needed (vitest) per test section above
- ESLint: Run vendor-web linter
- UX verification: User manual testing in browser

## Done khi
- tsc, eslint, vitest của `vendor-web` và `packages/ui` đều xanh.
- Checklist UX ở trên được tự kiểm tra lại trong báo cáo phase 8 (user kiểm tra trên trình duyệt).

## Design Constraints
- Giữ các ratchet (300 dòng/file, 15 class/package `internal`, `Clock`, constants) và áp dụng các quyết định red-team của phase này trong plan.md.

## Quality and Testing State
- Chưa cook. Test theo mục Test của phase; cổng `ck:quality` bắt buộc trước khi đóng phase.
