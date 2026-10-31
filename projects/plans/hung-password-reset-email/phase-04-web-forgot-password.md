# Phase 04 — Trang Forgot/Reset password + nhận token mới khi đổi mật khẩu

**Stories:** P1 #2 (UI), P1 #4 (client) · **FR:** 12, 13
**Status:** [ ]
**Depends on:** contract của Phase 01, 02
**Repos:** pte-web (tenant-web, vendor-web, `@pte/api-client`), pte-practice

## Overview

Làm hai trang công khai cho cả hai portal web. Đồng thời cập nhật mọi client web để gửi kèm `refreshToken` khi gọi `change-password`, nhờ đó các máy khác bị đăng xuất.

## Files

- `packages/api-client/src/requests/auth/*`: thêm `requestPasswordReset(email)`, `confirmPasswordReset(token, newPassword)`; thêm `refreshToken?` vào body của `changePassword`.
- `apps/tenant-web/app/(auth)/forgot-password/page.tsx`, `apps/tenant-web/app/(auth)/reset-password/page.tsx` (mới, route mỏng).
- `apps/tenant-web/features/auth/components/ForgotPasswordView.tsx`, `ResetPasswordView.tsx` (mới); thêm chuỗi vào `features/auth/constants.ts`.
- Làm tương tự ở `apps/vendor-web/app/(auth)/…` và `apps/vendor-web/features/auth/…`.
- `LoginView.tsx` ở cả hai app: đổi `href="#"` → `/forgot-password`.
- `ChangePasswordView.tsx` ở cả hai app: gửi `refreshToken` của session hiện tại.
- `pte-practice/features/auth/ChangePasswordForm.tsx` / `SignInView.tsx`: gửi `refreshToken` của session hiện tại.

## Steps

1. **ForgotPasswordView:** một ô email + nút gửi. Sau khi submit (thành công hoặc 429/5xx đều vậy) luôn hiện cùng một thông báo "Nếu email có trong hệ thống, chúng tôi đã gửi link đặt lại. Link hết hạn sau 30 phút." Có link quay về đăng nhập.
2. **ResetPasswordView:** đọc `token` từ query. Không có token → báo link không hợp lệ. Form mật khẩu mới + nhập lại (≥ 8 ký tự, khớp nhau). Thành công → toast và chuyển về `/login`. 400 → thông báo "Link không hợp lệ hoặc đã hết hạn" kèm nút "Yêu cầu link mới".
3. Hai view giống nhau giữa hai app. Nếu đủ chung thì đưa vào `@pte/ui` theo quy tắc "dùng ở 2+ app", nhận chuỗi và API qua props; nếu không thì giữ ở từng app. Quyết định khi làm, theo `AGENTS.md`.
4. Kiểm tra `RequireAuth` và middleware không chặn hai route mới khi chưa đăng nhập.
5. Change-password ở 3 client: gửi kèm `refreshToken` hiện tại; sau khi thành công giữ nguyên session và tắt `mustChangePassword`.

## Design Constraints

- Theo `pte-web/CLAUDE.md`: dynamic route không bắt buộc ở đây, nhưng page phải có `loading.tsx`/`error.tsx` nếu theo pattern hiện có của `(auth)`; không hardcode chuỗi; dùng `next/link`; gọi API qua TanStack Query (`useMutation`).
- Đọc `node_modules/next/dist/docs` về `useSearchParams`/Suspense của Next 16 trước khi viết `ResetPasswordView`.
- Không log token ra console. Sau khi đặt lại thành công, xoá token khỏi URL (`router.replace`).

## Tests

- Vitest: Forgot luôn hiện cùng thông báo cho cả 200 lẫn lỗi; Reset validate độ dài/khớp; 400 hiện nút yêu cầu link mới; ChangePasswordView gửi `refreshToken` (cả 3 client).

## Quality and Testing State

- Quality: not evaluated
- Testing: not started
