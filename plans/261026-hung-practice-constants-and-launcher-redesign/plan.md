# Plan: Tối ưu UI/UX Launcher Modal, Carousel Animation và Chuẩn hóa Hằng số (Constants) trong pte-practice

**Status:** Completed  
**Date:** 2026-10-26  
**Owner/slug:** Hung — `261026-hung-practice-constants-and-launcher-redesign`  
**Scope:** Frontend `pte-practice`  
**Related:** [spec.md](./spec.md) · [phase-01-launcher-redesign.md](./phase-01-launcher-redesign.md) · [phase-02-constants-standardization.md](./phase-02-constants-standardization.md)  
**Nhánh Git:** `hung/feat/practice-revamp`  

---

## 1. Phases Overview

- [x] **Phase 1: Carousel Smooth Glide & Directional Bounce** — [phase-01-launcher-redesign.md](./phase-01-launcher-redesign.md)
  - Thêm animation `slide-left` / `slide-right` và dynamic bounce khi bấm nút điều hướng.
  - Tạm thời gỡ bỏ `scrollSnapType` trong lúc transition để trượt êm mượt (silky glide), khôi phục sau khi cuộn xong.
  - Bổ sung drag-to-scroll với bộ đệm `DRAG_THRESHOLD_PX`.
  - Commit: `0900c27`.

- [x] **Phase 2: Redesign Task Launcher Modal (Radio Choice)** — [phase-01-launcher-redesign.md](./phase-01-launcher-redesign.md)
  - Khắc phục tình trạng lặp nút "Tiếp tục" dư thừa gây bối rối.
  - Thiết kế lại modal dạng Radio Choice cards (`pte-option-card`, `pte-radio-circle`) + 1 nút CTA duy nhất "Bắt đầu ngay" (`pte-btn-primary-glow`).
  - Hỗ trợ cả 2 trạng thái: Có phiên làm dở (Tiếp tục vs Bắt đầu mới) và Đã hoàn thành (Xem lại vs Làm bộ mới).
  - Sửa lỗi SSR / Vitest (`invariant expected app router to be mounted`) bằng cách chuyển sang thẻ Next.js `<Link>`.
  - Commit: `16dc35c`.

- [x] **Phase 3: Rà soát & Chuẩn hóa Toàn bộ Hằng số (Constants Standardization)** — [phase-02-constants-standardization.md](./phase-02-constants-standardization.md)
  - Gom toàn bộ storage keys và custom events vào `PRACTICE_STORAGE_KEYS` trong `features/practice/constants.ts`.
  - Chuẩn hóa cấu hình Theme transition, easing, duration, ripple colors vào `common/providers/constants.ts`.
  - Tạo mới `features/home/constants.ts` cho các thông số timing và kích thước Carousel.
  - Chuẩn hóa magic numbers (`DEFAULT_PRACTICE_QUESTION_COUNT`, `DEFAULT_API_BASE_URL`, `ENTITLEMENT_STALE_THRESHOLD_MS`, `SCORE_TONE_THRESHOLDS`, `CHECK_VALID_DAYS`, `CHECK_VALID_MS`).
  - Chuẩn hóa chuỗi hướng dẫn cấp quyền Micro Chrome vào từ điển i18n (`deviceCheck.micStep1`, `deviceCheck.micStep2`).
  - Commit: `42eca04`.

- [x] **Phase 4: Sửa lỗi hiển thị trạng thái khi kiểm tra Micro thất bại (Device Check Red X)**
  - Thêm trạng thái `failed` vào `DeviceCheckStatus` ("passed" | "failed" | "not-checked").
  - Khi micro bị chặn quyền (permission denied), ghi âm lỗi hoặc im lặng (silent): lập tức gọi `markFailed("mic")`.
  - Proactive sync: Tự động lắng nghe `navigator.permissions.query({ name: "microphone" })` để đánh dấu `failed` ngay khi mở trang nếu Chrome đang chặn micro.
  - Hiển thị trên thẻ kỹ năng (Speaking tile): `✗ Failed` (en) / `✗ Không đạt` (vi) với màu đỏ `color: var(--red)` và class `.device-status-failed`, loại bỏ hoàn toàn việc hiển thị nhầm tích xanh `✓ Checked`.
  - Commit: `b443955`.

- [x] **Phase 5: Kiểm chứng & Đẩy nhánh (Verification & Delivery)**
  - Chạy `pnpm typecheck` kiểm tra TypeScript (`0 errors`).
  - Chạy `pnpm test:unit` chạy toàn bộ test suite (`49/49 test files passed`, `241/241 tests passed`).
  - Push toàn bộ commit lên remote branch `hung/feat/practice-revamp`.

---

## 2. Phase → Functional Requirements Mapping

| Phase | Files sửa đổi chính | FR đáp ứng |
| :--- | :--- | :--- |
| **Phase 1** | `RecommendationCarousel.tsx`, `globals.css` | FR-02 |
| **Phase 2** | `TaskActionButtons.tsx`, `task-launcher.css` | FR-01 |
| **Phase 3** | `constants.ts` (practice, providers, home), `session-storage.ts`, `useAccessToast.ts`, `mode-preference.ts`, `device-check.ts`, `useDeviceChecks.ts`, `api.ts`, `presentation.ts`, `DeviceCheckDialog.tsx`, `SpeakingRecorder.tsx`, `i18n/*` | FR-03, FR-04, FR-05, FR-06 |
| **Phase 4** | Toàn bộ repo `pte-practice` | NFR, Acceptance Criteria |

---

## 3. Architecture Decisions

- **AD-01 (Single-Action Launcher):** Tách biệt rõ ràng giữa khâu *Chọn ý định* (Selection qua Radio Choice Cards) và khâu *Kích hoạt hành động* (Action qua nút Primary CTA duy nhất). Điều này loại bỏ hoàn toàn việc phân vân giữa 2 nút bấm cùng nhãn trên một modal.
- **AD-02 (Centralized Storage Keys in Domain Constants):** Các storage keys liên quan đến luồng bài tập, chế độ, và kiểm tra thiết bị đều được đặt trong [`features/practice/constants.ts`](file:///d:/GitHub/PTE-org/pte-practice/features/practice/constants.ts) dưới object `PRACTICE_STORAGE_KEYS` để đảm bảo single source of truth, dễ dàng thay đổi namespace hoặc phiên bản lưu trữ mà không bỏ sót module nào.
- **AD-03 (Strict i18n & Zero Hardcoded User Strings):** Tất cả các câu hiển thị đến học viên (kể cả các câu hướng dẫn chi tiết về trình duyệt Chrome) đều phải đi qua `useTranslation` và được gõ trong `LocaleDict` để hỗ trợ đa ngôn ngữ hoàn chỉnh và dễ bảo trì.
- **AD-04 (No Router Hook in Static-Renderable Action Blocks):** Tránh sử dụng `useRouter().push()` trong các component con có thể được render bằng `renderToStaticMarkup` hoặc SSR thuần túy; ưu tiên dùng thẻ semantic `<Link>` của Next.js.

---

## 4. Verification Checklist & Kết quả

- [x] `pnpm typecheck` (tsc --noEmit): **PASSED** (0 errors)
- [x] `pnpm test:unit` (vitest run): **49 passed (49)**, **240 passed (240)**
- [x] Git diff: Không còn biến số hoặc storage key dạng literal chưa qua chuẩn hóa.
- [x] Push branch: Đã đồng bộ với `origin hung/feat/practice-revamp`.
