# Spec: Làm đẹp UI pte-practice — layout rộng, sóng âm tối giản, toast, dark mode xám

**Date:** 2026-10-25
**Status:** Draft
**Repo:** `pte-practice` (tham khảo `pte-web/packages/ui`)
**Brainstorm:** [../reports/261025-hung-practice-ui-polish-brainstorm.md](../reports/261025-hung-practice-ui-polish-brainstorm.md)

---

## Problem Statement
Giao diện pte-practice bị bó trong cột hẹp (880px; phiên làm bài 760px), để lại nhiều khoảng trống trên màn hình laptop/desktop; chữ và thẻ nhỏ. Sóng âm hiện tại chưa đẹp, thông báo trạng thái ("Practice unlocked") chiếm chỗ cố định ở đầu mỗi trang, và dark mode gần đen (AMOLED) gây chói tương phản.

---

## User Stories

- **[P1]** Là học viên dùng laptop/desktop, tôi muốn nội dung lấp đầy màn hình với chữ và thẻ to hơn để dễ đọc và không thấy trống trải.
  Accepted when: ở 1280px và 1920px, vùng nội dung chiếm ≥ 90% chiều ngang khả dụng (tối đa 1440px, canh giữa); cỡ chữ thân ≥ 16px; Trang chủ/Study-Pack/Luyện đề/Tiến trình chia lưới nhiều cột thay vì 1 cột hẹp.
- **[P1]** Là học viên, tôi muốn thông báo trạng thái hiện dạng toast thay vì băng cố định trong trang.
  Accepted when: không còn `AccessStatusBanner` trong trang; "Practice unlocked" hiện toast 1 lần mỗi lần đăng nhập; trạng thái khoá/không khả dụng hiện toast cảnh báo; lỗi thao tác trong phiên (`notice`, hết giờ) hiện toast.
- **[P1]** Là học viên, tôi muốn dark mode xám tối dịu mắt.
  Accepted when: dark mode dùng nền ~#1e1e1e, bề mặt thẻ ~#252526, lớp nổi ~#2d2d30, đường kẻ ~#3c3c3c, chữ ~#e6e6e6 / phụ ~#a0a0a0; không còn màu nền < #181818; tương phản chữ thân ≥ 4.5:1 (WCAG AA).
- **[P1]** Là học viên, tôi muốn sóng âm kiểu thanh xám tối giản khi ghi âm và nghe lại.
  Accepted when: một component sóng âm chung dùng cho (1) ghi trực tiếp, (2) nghe lại bản ghi, (3) kiểm tra mic; thanh dọc bo tròn, đối xứng quanh trục giữa, màu xám; phần đã phát / đang ghi đổi màu nhấn; có icon mic ở giữa khi đang ghi.
- **[P2]** Là học viên, tôi muốn audio đề bài (Listening, Repeat Sentence…) hiện cùng kiểu sóng âm với nút phát.
  Accepted when: audio đề hiện sóng âm + nút phát/tạm dừng + tiến trình; không đọc được dữ liệu sóng (CORS/lỗi) thì hiện sóng giả lập theo thời lượng, audio vẫn phát được.
- **[P3]** _(ngoài phạm vi)_ Đổi brand/sidebar Pearson, trang admin, animation phức tạp.

---

## Functional Requirements

1. FR-01: `main-content` rộng tối đa 1440px (canh giữa), padding ngang 32px desktop / 16px mobile. Phiên làm bài tối đa 1100px; đoạn văn đọc giới hạn ~75 ký tự/dòng để dễ đọc.
2. FR-02: Tăng thang cỡ: chữ thân 16px (hiện ~13–14px), tiêu đề trang ≥ 28px, thẻ có padding ≥ 20px, nút cao ≥ 44px; icon thẻ 24px.
3. FR-03: Lưới responsive: Trang chủ (thẻ kỹ năng 4 cột ≥ 1280px, 2 cột tablet, 1 cột mobile); Study-Pack và danh sách đề 2 cột ≥ 1280px; Tiến trình chia 2 cột (vòng tổng quan | lịch sử).
4. FR-04: Port `Toast` (`ToastProvider`, `useToast`, `showToast(message, { tone, title, durationMs, dismissible })`, tối đa 3 toast, tự ẩn 5s) từ `pte-web/packages/ui/src/components/Toast.tsx` vào `pte-practice/common/components/Toast.tsx`, giữ nguyên API; style bằng CSS token của practice (không Tailwind), icon bằng `AppIcon`, chữ qua i18n practice. Ghi nguồn trong comment.
5. FR-05: Bỏ `AccessStatusBanner` khỏi Home, Study-Pack, Luyện đề, Tiến trình; thay bằng một hook gọi toast khi trạng thái quyền thay đổi (unlocked → success một lần mỗi phiên đăng nhập; locked/unavailable → warning).
6. FR-06: Chuyển sang toast: `notice` lỗi trong `SessionTaskView`, "Hết giờ" của `TimedTaskFrame`, lỗi tải danh sách đề (kèm giữ nút thử lại trong trang). Giữ trong trang: trạng thái trống ("Chưa có đề luyện"), ghi chú tĩnh (`quiet-note`).
7. FR-07: Token dark mode thay theo kiểu VS Code/Figma (FR giá trị ở user story); light mode giữ nguyên.
8. FR-08: Component `VoiceWaveform` mới thay `AudioWaveform`: props `peaks`, `progress`, `live`, `onSeek`, `label`; vẽ SVG thanh bo tròn đối xứng, ~48 thanh, khoảng cách đều; trạng thái live có icon mic ở giữa và thanh nảy theo mức âm.
9. FR-09: Audio đề bài (`PromptMedia`) dùng `VoiceWaveform` + nút phát; tính đỉnh sóng bằng `fetch` + `AudioContext.decodeAudioData` một lần, cache theo URL; lỗi → sóng giả lập.
10. FR-10: Mọi chuỗi mới qua i18n (en, vi).

---

## Non-Functional Requirements

- Performance: decode audio đề ≤ 1 lần mỗi URL mỗi phiên; trang không tăng quá 10% thời gian render (đo Lighthouse dev ở Trang chủ).
- Accessibility: toast dùng `role="status"` (info/success) / `role="alert"` (warning/error); sóng âm có `aria-label`; tương phản AA ở cả light và dark.
- Responsive: không cuộn ngang ở 390px, 1280px, 1920px.

---

## Success Criteria

- [ ] Ở 1920px, vùng nội dung rộng 1440px (canh giữa); ở 1280px, nội dung chiếm ≥ 90% chiều ngang trừ sidebar.
- [ ] 0 chỗ dùng `AccessStatusBanner`; "Practice unlocked" hiện đúng 1 toast sau khi đăng nhập.
- [ ] Dark mode: nền `#1e1e1e`, không màu nền nào tối hơn `#181818`.
- [ ] Sóng âm mới dùng ở 4 chỗ (ghi trực tiếp, nghe lại, kiểm tra mic, audio đề).
- [ ] `tsc` sạch, eslint 0 lỗi, vitest xanh; ảnh chụp 3 mốc chiều rộng × 2 theme để so sánh trước/sau.

---

## Out of Scope
- Thay brand/sidebar Pearson, đổi màu nhấn, trang admin, thêm thư viện UI mới, đưa `@pte/ui` thành dependency.

---

## Decisions
- **[Đã chốt]** Giãn rộng tối đa ~1440px canh giữa; chữ và thẻ to hơn.
- **[Đã chốt]** Toast: port từ pte-web (cách A).
- **[Đã chốt]** Dark mode kiểu VS Code/Figma.
- **[Đã chốt]** Sóng âm ở cả 4 chỗ.
- **[Quyết định của Claude]** "Practice unlocked" toast 1 lần mỗi lần đăng nhập; trạng thái trống và ghi chú tĩnh vẫn ở trong trang.
- **[Quyết định của Claude]** Audio đề không đọc được sóng → sóng giả lập theo thời lượng.
