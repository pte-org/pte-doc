# Phase 6: WF-04 luyện tập

**Owner gợi ý:** Hùng · **Ưu tiên:** P1 (FR-11, FR-12), P2 (entitlement reason) · **Phụ thuộc:** phase 01; phần retry/chấm lại dùng công tắc ở phase 05

## Overview

Practice session có hạn và chuyển EXPIRED; progress chỉ đếm phần COMPLETED; finish/discard/ký upload kiểm khóa; màn bị khóa hiện lý do. Công tắc AI và lỗi retryable đã chuyển sang phase 05.

## Spec stories covered

- P1: session luyện tập quá hạn thành Expired; progress chỉ đếm hoàn thành (FR-11, 4-1, 4-5).
- P1: finish, discard, upload-sign kiểm `assertUnlocked` (FR-12, 4-3).
- P2: lý do khóa luyện tập (FR-14, DS-04b).

## Files to modify/create

Đọc trước: `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`. Đường dẫn dưới `pte-api/app/src/main/`:

- `resources/db/migration/V65__practice_session_deadline.sql` — tạo mới (kiểm lại số): cột/ràng buộc cho deadline và trạng thái EXPIRED nếu chưa có (xác minh `practice/internal/domain/PracticeSession.java`); seed setting mới nếu có (setting AI nằm ở V64).
- `java/com/pte/practice/internal/service/session/PracticeSessionService.java` (dòng ~126 đặt `deadlineAt=null`) và `PracticeSessionStarter.java` — đặt deadline khi begin theo thời lượng session/mock cộng đệm.
- `java/com/pte/practice/internal/service/session/` — sweeper mới chuyển session quá hạn sang EXPIRED (dùng `Clock`, mẫu `itembank/internal/generation/batch/BatchPausedExpiry.java`); package gần đầy, đặt vào package con `expiry`. Xem cách dùng `practice/internal/exception/PracticeSessionExpiredException.java` hiện có.
- `java/com/pte/practice/internal/service/PracticeProgressService.java` (dòng ~56) — chỉ đếm COMPLETED, bỏ DISCARDED và OVERVIEW.
- `java/com/pte/practice/internal/service/session/PracticeSessionFinishService.java`, `PracticeSessionDiscardService.java` và nơi ký upload (xác minh bằng Grep "sign" trong `practice/` và `media/`) — gọi guard khóa dùng chung của practice; poll kết quả không dispatch lại job AI khi bị khóa.
- `java/com/pte/practice/internal/dto/response/PracticeEntitlementResponse.java` — thêm `reason` (enum); service tạo entitlement trong `practice/internal/service/` (xác minh).
- `java/com/pte/practice/internal/constant/*Constants.java` — mã lỗi/thông điệp hết hạn, khóa.
- `pte-practice/features/practice/access-state.ts` và `pte-practice/tests/unit/features/practice/access-state.test.ts` — hiện lý do; chữ trong file messages; tìm component khóa luyện tập bằng Grep "locked" khi làm.

## Implementation steps

1. Migration và entity: bảo đảm deadline và trạng thái EXPIRED hợp lệ ở DB.
2. Đặt `deadlineAt` lúc begin; thêm sweeper chuyển session quá hạn sang EXPIRED; finish sau hạn trả lỗi nghiệp vụ.
3. Sửa progress: chỉ tính COMPLETED.
4. Thêm kiểm khóa ở finish, discard, ký upload; poll kết quả không dispatch lại job AI khi khóa.
5. P2: thêm `reason` vào entitlement và hiển thị ở pte-practice.
6. Kiểm DS-04a/DS-04c cùng công tắc phase 05: tắt công tắc, chấm lỗi, bật lại, Retry ra điểm.

## Tests

Dưới `pte-api/app/src/test/java/com/pte/`:
- Mở rộng `practice/internal/service/session/PracticeSessionServiceTest.java` — deadline được đặt; sweeper chuyển EXPIRED; finish sau hạn.
- Mở rộng `practice/internal/service/PracticeProgressServiceTest.java` — DISCARDED/OVERVIEW không được đếm.
- Test finish/discard/upload-sign khi tổ chức suspend trả lỗi đúng.
- Test entitlement reason cho từng nguyên nhân khóa.
- pte-practice: mở rộng vitest `access-state.test.ts` cho reason; chạy `tsc` và `eslint`.

## Design Constraints

- Migration additive V65 (kiểm số cao nhất, hiện V60 và các phase trước dự kiến V61-V64); setting mới seed cùng migration.
- Thông điệp/mã lỗi ở `*Constants.java` của `practice`; giữ envelope/mã lỗi cũ.
- Cross-module qua public service API (practice không đọc entity scoring/billing trực tiếp).
- File ≤ 300 dòng, `internal/**` ≤ 15 lớp (ratchet architecture); `practice/internal/service` cần tách package con.
- `Clock` inject cho deadline và sweeper.
- `CODING_STANDARDS_WEB.md` cho pte-practice (messages, component ≤ 150 dòng).
- Restart docker app local sau backend.

## Risks

- Strict entitlement làm học viên thật bị khóa khi thêm guard: kiểm env prod ở phase 08, test với tổ chức active.
- Sweeper chuyển nhầm session đang làm bài: deadline từ begin cộng đệm, test ranh giới.
- Package `practice` vượt 15 lớp: tách package con từ đầu.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: passed (2026-11-28: 308 practice/architecture tests, clean build; pte-practice vitest+tsc OK). Known limit: progress counts derive from the latest 100 sessions.

## Todo

- [ ] V65 schema deadline/EXPIRED
- [ ] Deadline + sweeper + progress COMPLETED
- [ ] assertUnlocked ở finish/discard/upload-sign
- [ ] Entitlement reason + pte-practice UI
- [ ] tsc/eslint/vitest pte-practice, ratchet architecture, restart docker
- [ ] Thử DS-04a/DS-04b/DS-04c với công tắc phase 05

## Bổ sung sau red-team (2026-11-27)

- **[H5] Không expire hàng loạt khi deploy:** sweeper chỉ quét `deadline_at IS NOT NULL AND deadline_at < now()`. Migration **không backfill** deadline
  cho session cũ. Deadline = thời lượng + đệm rộng (mặc định 24 giờ cho practice tự do, thời lượng template + 30 phút cho mock).
  Session EXPIRED vẫn xem lại được (read-only).
- **[L2] Ghi chú runbook:** sau FR-12, học viên của tổ chức bị suspend không finish được session đang làm. Đây là hành vi đúng; phải nói trước khi demo DS-04b.
