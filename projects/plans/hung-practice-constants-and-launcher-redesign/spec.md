# Spec: Tối ưu UI/UX Launcher Modal, Carousel Animation và Chuẩn hóa Hằng số (Constants) trong pte-practice

**Date:** 2026-10-26  
**Status:** Completed  
**Owner:** Hung — `hung-practice-constants-and-launcher-redesign`  
**Repo:** `pte-practice` (nhánh `hung/feat/practice-revamp`)  
**Scope:** Frontend `pte-practice`  

---

## 1. Problem Statement

Trong quá trình hoàn thiện trải nghiệm luyện tập (`pte-practice`), hệ thống bộc lộ 3 nhóm vấn đề chính:

1. **Trải nghiệm Launcher Modal bị lặp hành vi (UX redundancy):**
   - Khi học viên bấm vào một dạng bài tập đã có phiên làm dở hoặc đã hoàn thành, modal hiển thị nhiều nút "Tiếp tục" trùng lặp gây khó hiểu. Người dùng cần một giao diện tường minh, chọn lựa chọn trước rồi ấn một nút CTA hành động rõ ràng.
   - Việc gọi `useRouter()` bên trong component cấp nhỏ gây crash trong môi trường test/SSR static render (`invariant expected app router to be mounted`).

2. **Thiếu hiệu ứng thị giác trên Carousel Đề cử (Recommendation Carousel):**
   - Carousel trượt ngang thiếu phản hồi trực quan khi bấm nút lùi/tiến (next/prev), chuyển động bị giật do `scrollSnapType` giữ cứng trong suốt quá trình scroll.

3. **Giá trị Hardcode và Magic Numbers rải rác:**
   - Các khóa lưu trữ trình duyệt (`localStorage`/`sessionStorage`) mang tiền tố `pte.practice.*` bị viết cứng trực tiếp tại 6+ file khác nhau (`session-storage.ts`, `useAccessToast.ts`, `mode-preference.ts`, `device-check.ts`, `useDeviceChecks.ts`).
   - Các tham số animation ripple, transition duration, easing, mã màu (`#1e1e1e`, `#F7F7F7`), fallback URL (`http://localhost:8080`), số câu mặc định (`10`), thời hạn cache (`10_000ms`, `7 days`) bị hardcode.
   - Các chuỗi hướng dẫn cấp quyền Microphone cho Chrome bị copy-paste hardcode trong JSX của `DeviceCheckDialog.tsx` và `SpeakingRecorder.tsx` thay vì dùng hệ thống i18n.

---

## 2. User Stories

### [P1] Lựa chọn chế độ làm bài trực quan (Task Launcher Modal)
- **Là học viên**, khi tôi bấm vào một bài tập có phiên làm dở hoặc đã hoàn thành, tôi muốn nhìn thấy 2 tùy chọn rõ ràng dạng thẻ lựa chọn (Radio Choice) và 1 nút bấm "Bắt đầu ngay" duy nhất.
- **Tiêu chí chấp nhận (AC):**
  - Khi có phiên dở: Option 1 = "Tiếp tục phiên làm dở" (có badge nổi bật, tóm tắt tiến độ câu), Option 2 = "Bắt đầu phiên làm mới".
  - Khi đã hoàn thành: Option 1 = "Xem lại kết quả & phân tích" (badge Hoàn thành, điểm số), Option 2 = "Làm bộ câu hỏi mới".
  - Người dùng có thể click chọn thẻ, radio check indicator cập nhật tức thì. Nút CTA thực thi hành động tương ứng với thẻ đang được chọn.

### [P1] Trượt Carousel mượt mà có hiệu ứng phản hồi
- **Là học viên**, khi tôi bấm nút lùi hoặc tiến trên thanh Đề xuất bài luyện tập, tôi muốn carousel có chuyển động trượt mượt mà (smooth glide) và phản hồi nút bấm sinh động.
- **Tiêu chí chấp nhận (AC):**
  - Khi bấm Next/Prev: Nút bấm có hiệu ứng scale/directional bounce; danh sách trượt mượt nhờ cơ chế tạm gỡ `scrollSnapType` trong lúc transition và tự khôi phục sau khi hoàn tất.

### [P1] Chuẩn hóa toàn bộ hằng số & không hardcode chuỗi hiển thị
- **Là kỹ sư phát triển**, tôi muốn tất cả storage keys, magic numbers, animation config và chuỗi song ngữ được tập trung vào các file `constants.ts` và từ điển `i18n`.
- **Tiêu chí chấp nhận (AC):**
  - Không còn `pte.practice.*` viết cứng phân tán trong các module code logic.
  - Toàn bộ transition/timing của Theme & Carousel định nghĩa qua `constants.ts`.
  - Các bước cấp quyền Microphone được đưa vào `deviceCheck.micStep1` & `deviceCheck.micStep2` (en/vi).
  - Toàn bộ TypeScript check (`tsc --noEmit`) và Vitest unit test (49 test files) đều passed.

---

## 3. Functional Requirements

### FR-01: Redesign Task Launcher Modal (Radio Choice)
- Thành phần: [`TaskActionButtons.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/TaskActionButtons.tsx), CSS [`task-launcher.css`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/task-launcher.css).
- Thay thế toàn bộ cụm nút kép cũ bằng cấu trúc:
  - Form radio group gồm các thẻ `.pte-option-card` với trạng thái active `.is-selected`.
  - Icon radio circle `.pte-radio-circle` hiển thị dấu check SVG khi được chọn.
  - Nút CTA duy nhất `.pte-btn-primary-glow` hiển thị nhãn hành động tương ứng ("Bắt đầu ngay" / "Xem lại ngay").
- Loại bỏ phụ thuộc vào `useRouter()` runtime của Next.js trong component này; sử dụng thẻ `<Link>` cho các điều hướng trang và `<button>` cho hành động mở modal/bắt đầu.

### FR-02: Smooth Sliding & Bounce Animation trên Carousel
- Thành phần: [`RecommendationCarousel.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/home/RecommendationCarousel.tsx), CSS [`app/globals.css`](file:///d:/GitHub/PTE-org/pte-practice/app/globals.css).
- Áp dụng animation trượt `slide-left` / `slide-right` kết hợp vô hiệu hóa snap tức thời (`scrollSnapType = "none"`) khi cuộn bằng nút bấm, sau đó khôi phục `scrollSnapType = "x mandatory"` sau `CAROUSEL_SNAP_RESTORE_DELAY_MS`.
- Drag threshold: lọc chuyển động chuột qua `CAROUSEL_DRAG_THRESHOLD_PX` để phân biệt click thẻ và drag cuộn.

### FR-03: Centralized Practice Storage Keys
- Thành phần: [`features/practice/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/constants.ts).
- Export object hằng số đóng băng `PRACTICE_STORAGE_KEYS`:
  ```ts
  export const PRACTICE_STORAGE_KEYS = {
    session: "pte.practice.session",
    draftPrefix: "pte.practice.draft.",
    unlockedToast: "pte.practice.unlocked_toast_shown",
    modePrefix: "pte.practice.mode.",
    deviceCheckPrefix: "pte.practice.device-check.",
    readingSize: "pte.practice.reading-size",
    deviceCheckEvent: "pte.practice.device-check-changed",
  } as const;
  ```
- Cập nhật các module tiêu thụ: [`session-storage.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/session-storage.ts), [`useAccessToast.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/useAccessToast.ts), [`mode-preference.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/mode/mode-preference.ts), [`device-check.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/device-check.ts), [`useDeviceChecks.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/useDeviceChecks.ts).

### FR-04: Theme Transition & Ripple Constants
- Thành phần: [`common/providers/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/constants.ts).
- Export:
  - `THEMES = { DARK: "dark", LIGHT: "light" } as const`
  - `THEME_STORAGE_KEY = "pte-practice-theme"`
  - `THEME_ATTRIBUTE = "data-theme"`
  - `DEFAULT_THEME = THEMES.DARK`
  - `THEME_TRANSITION_CONFIG`: thời lượng `450ms`, `switchDelayMs: 350`, `fadeDelayMs: 100`, `removeDelayMs: 300`, easing `cubic-bezier(0.2, 0.9, 0.3, 1)`, ripple colors (`#1e1e1e`, `#F7F7F7`).
- Cập nhật [`theme-init.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/theme-init.ts) và [`ThemeProvider.tsx`](file:///d:/GitHub/PTE-org/pte-practice/common/providers/ThemeProvider.tsx).

### FR-05: Home Carousel & General Practice Constants
- Thành phần: [`features/home/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/home/constants.ts) & [`features/practice/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/constants.ts).
- Export các hằng số:
  - `CAROUSEL_ANIMATION_DURATION_MS = 450`
  - `CAROUSEL_SNAP_RESTORE_DELAY_MS = 400`
  - `CAROUSEL_DEFAULT_CARD_WIDTH = 300`
  - `CAROUSEL_GAP = 16`
  - `CAROUSEL_DRAG_THRESHOLD_PX = 4`
  - `DEFAULT_PRACTICE_QUESTION_COUNT = 10`
  - `DEFAULT_API_BASE_URL = "http://localhost:8080"`
  - `ENTITLEMENT_STALE_THRESHOLD_MS = 10_000`
  - `SCORE_TONE_THRESHOLDS = { LOW: 40, HIGH: 70 } as const`
  - `SKILL_SHORT_NAMES`: song ngữ `vi`/`en` cho Speaking, Writing, Reading, Listening.
  - `CHECK_VALID_DAYS = 7`, `CHECK_VALID_MS = CHECK_VALID_DAYS * 24 * 60 * 60 * 1000`.

### FR-06: Chuẩn hóa Hướng dẫn Cấp quyền Mic sang i18n
- Thành phần: [`common/i18n/types.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/i18n/types.ts), [`common/i18n/en.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/i18n/en.ts), [`common/i18n/vi.ts`](file:///d:/GitHub/PTE-org/pte-practice/common/i18n/vi.ts).
- Thêm keys:
  - `deviceCheck.micStep1`: Hướng dẫn click icon Cài đặt / Ổ khóa bên trái thanh địa chỉ trình duyệt Chrome.
  - `deviceCheck.micStep2`: Hướng dẫn chuyển Microphone sang Cho phép (Allow) và quay lại trang.
- Thay thế JSX inline trong [`DeviceCheckDialog.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/deviceCheck/DeviceCheckDialog.tsx) và [`SpeakingRecorder.tsx`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/renderers/SpeakingRecorder.tsx).

---

## 4. Non-Functional Requirements
- **Performance:** Carousel gliding không gây drop frame, giữ mượt mà 60fps trên màn hình chuẩn và thiết bị cảm ứng/chuột.
- **Resilience / SSR:** Không gây lỗi mount App Router khi render server-side hoặc trong Vitest environment.
- **Maintainability:** Tập trung toàn bộ keys vào constants giúp tránh xung đột key hoặc thay đổi phân tán khi refactor.
- **Localization (i18n):** Tuân thủ tuyệt đối quy định không hardcode chuỗi người dùng trong JSX.

---

## 5. Verification & Acceptance Criteria
- [x] Modal chọn chế độ hiển thị 2 thẻ Radio Choice chuẩn, chọn được bằng click thẻ, 1 nút CTA duy nhất.
- [x] Carousel có hiệu ứng trượt êm mượt, không bị khựng giữa chừng.
- [x] Kiểm tra grep toàn bộ repo: không còn raw `pte.practice.` storage key độc lập trong component.
- [x] `pnpm typecheck` đạt 0 error.
- [x] `pnpm test:unit` đạt 49/49 test files passed (240/240 tests passed).
- [x] Code đã commit và push lên branch `hung/feat/practice-revamp`.
