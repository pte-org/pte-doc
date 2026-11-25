# Phase 2: Học viên bị tạm ngưng không xem được practice

Preflight: Unit tests created and run: no (skipped_by_user) · ck:quality gate: skipped_by_user
Status: **Đã hoàn tác (2026-11-25)** — không còn trong PR · Bug: "Học viên đã bị tạm ngưng vẫn xem được đề và lịch sử luyện tập trong lúc còn đăng nhập"

> **Quyết định:** giữ đúng như `dev`. Hợp đồng của Quang (`quang-pte-practice-student-web`) cho phép xem lịch sử sau khi thu hồi gói hoặc vô hiệu hoá học viên, nên các endpoint đọc không bị chặn. Phần dưới ghi lại những gì đã làm trước khi hoàn tác: `fdb05bcc` đã bị `a4ce1b85` hoàn tác ở `pte-api`, `a056da3` đã bị `dab3ff6` hoàn tác ở `pte-practice`. Xem R6 và R7 ở `plan.md`.

## Requirements

- Sau khi Host tạm ngưng học viên, học viên đang mở sẵn trình duyệt không xem được phiên luyện tập, bài xem lại, bản ghi âm và lịch sử nữa, không phải chờ access token hết hạn (tối đa 15 phút).
- Mục Lịch sử ở trang Tiến độ không còn nút "Tiếp tục" và "Xem lại" khi practice bị khoá.
- Không cần đăng xuất tức thì: refresh token đã bị thu hồi lúc tạm ngưng nên học viên tự bị đẩy ra khi access token hết hạn.

## Design Constraints

- Trước đây chỉ các thao tác ghi gọi `assertUnlocked`. Giữ nguyên chúng, chỉ thêm chặn cho các thao tác đọc.
- Chặn ở controller bằng `unlockedCaller()` để không phải đổi constructor và test của năm service.
- `/student/practice/entitlement` và `/student/practice/catalog` **không** chặn: màn hình "Đã khóa" cần hai endpoint này để hiện đúng thay vì trang lỗi.
- Trả lỗi có sẵn `PRACTICE_NOT_ENTITLED` (403).
- **Chưa khớp hợp đồng cũ:** `quang-pte-practice-student-web` quy định lịch sử vẫn đọc được sau khi thu hồi gói hoặc vô hiệu hoá học viên, và `assertUnlocked` chặn mọi trạng thái khác `UNLOCKED` chứ không riêng tạm ngưng. Xem R6 ở `plan.md`.

## Related files

`pte-api`: `practice/internal/controller/PracticeSessionController.java` (thêm `PracticeEntitlementService`, `unlockedCaller()` dùng cho `get`, `result`, `recording`, `review`, `discard`, `finish`), `…/controller/PracticeProgressController.java`, `PracticeSessionControllerReviewTest.java` (chỉ thêm đối số mock để còn biên dịch).

`pte-practice`: `features/progress/{HistorySection.tsx,ProgressView.tsx}`, `features/workspace/WorkspaceProgressProvider.tsx`, `features/practice/constants.ts` (`NOT_ENTITLED_ERROR_CODE`).

## Steps

1. Backend: `unlockedCaller()` kiểm tra entitlement rồi trả `CurrentUser`; thay `CurrentUserContext.required()` ở sáu endpoint đọc; `PracticeProgressController` kiểm tra trước khi trả lịch sử.
2. Frontend: `HistorySection` nhận `unlocked`, khi khoá thì hiện `LockBadge` và văn bản thường thay cho hai link.
3. `WorkspaceProgressProvider` coi 403 `PRACTICE_NOT_ENTITLED` là lịch sử rỗng ở trạng thái `ready` chứ không phải `error`, để trang Tiến độ và Trang chủ không biến thành trang lỗi.

## Success Criteria

- Học viên làm dở một phiên, Host tạm ngưng, học viên tải lại trang Tiến độ: lịch sử hiện nhãn khoá, không bấm được; mở thẳng URL phiên thì nhận 403.
- Trang Tiến độ và Trang chủ không hiện màn hình lỗi.
- `/entitlement` vẫn trả 200 để màn hình "Đã khóa" hiện.

## Quality and Testing State

- Quality: skipped_by_user
- Testing: skipped_by_user. `compile` đạt, `tsc` và `eslint` sạch.
