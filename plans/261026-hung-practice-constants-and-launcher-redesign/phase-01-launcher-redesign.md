# Phase 1 & 2: Tối ưu Carousel Animation & Thiết kế lại Task Launcher Modal

**Status:** Completed  
**Owner:** Hung  
**Commits:** `0900c27`, `16dc35c`  
**Files:**
- [`features/home/RecommendationCarousel.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/home/RecommendationCarousel.tsx)
- [`app/globals.css`](file:///d:/GitHub/PTE-org/pte-practice/app/globals.css)
- [`features/practice/TaskActionButtons.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/TaskActionButtons.tsx)
- [`features/practice/task-launcher.css`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/task-launcher.css)

---

## 1. Mục tiêu & Vấn đề giải quyết

1. **Recommendation Carousel Smooth Transitions:**
   - Thêm directional sliding animations mượt mà (`slide-left`, `slide-right`) và hiệu ứng bounce trên nút khi nhấn.
   - Tránh hiện tượng giật do `scrollSnapType` bằng cách tạm ngắt `scrollSnapType = "none"` khi bắt đầu animation cuộn và khôi phục `scrollSnapType = "x mandatory"` sau `400ms`.
   - Bổ sung tương tác kéo chuột (drag-to-scroll) với cơ chế lọc click (`DRAG_THRESHOLD_PX = 4`).

2. **Task Launcher Modal Redesign (Khắc phục lặp nút "Tiếp tục"):**
   - Vấn đề cũ: Modal hiển thị đồng thời nút hành động chính và phụ đều ghi chữ "Tiếp tục" hoặc gây hiểu nhầm về flow.
   - Giải pháp: Chuyển đổi thành mô hình **Radio Choice Cards**:
     - Thẻ 1 (Mặc định được chọn): Hành vi tiếp diễn (Tiếp tục phiên đang làm dở / Xem lại phiên đã xong).
     - Thẻ 2: Bắt đầu bài mới (Bắt đầu phiên mới / Làm bộ câu hỏi mới).
     - Indicator: Radio circle dạng tròn hiện dấu check SVG sắc nét khi active.
     - Action: Một nút CTA duy nhất ở chân modal ("Bắt đầu ngay" / "Xem lại ngay").

3. **Khắc phục lỗi SSR Router Context trong Vitest:**
   - Thay thế việc dùng `useRouter()` trong `TaskActionButtons.tsx` bằng thẻ Next.js `<Link>` cho các trường hợp điều hướng URL và `<button>` cho mở modal. Nhờ đó, các test render bằng `renderToStaticMarkup` vượt qua mà không cần mock App Router.

---

## 2. Chi tiết Thiết kế Giao diện (CSS Design)

```css
/* Card tùy chọn Radio Choice */
.pte-option-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 18px;
  border-radius: 14px;
  background: var(--pte-surface-2, rgba(255, 255, 255, 0.04));
  border: 1.5px solid var(--pte-border, rgba(255, 255, 255, 0.08));
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.pte-option-card:hover {
  background: var(--pte-surface-hover, rgba(255, 255, 255, 0.07));
  border-color: var(--pte-border-hover, rgba(255, 255, 255, 0.16));
}

.pte-option-card.is-selected {
  background: rgba(14, 165, 233, 0.08);
  border-color: #0ea5e9;
  box-shadow: 0 0 0 1px #0ea5e9, 0 4px 16px rgba(14, 165, 233, 0.15);
}

/* Radio circle với check mark */
.pte-radio-circle {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 2px solid var(--pte-border, rgba(255, 255, 255, 0.2));
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.2s ease;
}

.pte-option-card.is-selected .pte-radio-circle {
  border-color: #0ea5e9;
  background: #0ea5e9;
  color: #fff;
}
```

---

## 3. Verification
- `pnpm test:unit features/practice/task-action-buttons.test.tsx` -> 8/8 passed.
- Giao diện modal hiển thị đúng 2 thẻ, 1 radio, 1 CTA, hoạt động chuẩn xác ở cả 2 chế độ (in-progress & completed).
