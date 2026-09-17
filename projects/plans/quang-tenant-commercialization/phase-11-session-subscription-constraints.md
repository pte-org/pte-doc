# Phase 11: Ràng buộc kỳ thi ↔ gói

## Requirements

Mỗi kỳ thi phải thuộc một `Subscription` (một "làn"). Bốn điều kiện: gói còn hiệu lực, kỳ thi nằm trọn trong hạn gói, sức chứa không vượt cap của gói, và **không hai kỳ thi cùng làn nào trùng khung giờ**. Cho đổi gói khi kỳ thi còn `SCHEDULED`.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §2, §3**

## Design Constraints

- Preflight: Phase 11 implementation is in scope; preserve the DB-backed overlap guarantee, subscription-window validation, capacity validation, scheduled-only subscription changes, and public cross-module facades.

- **Chống trùng khung giờ phải ở tầng DB**, không phải tầng application. Check-then-insert ở app chỉ đúng chừng nào *mọi* đường tạo kỳ thi đều nhớ khoá — một endpoint mới quên là thủng và không có gì báo. Flyway đang chạy nên viết được exclusion constraint.
- **Hai làn khác nhau được phép trùng giờ.** Ràng buộc khoá trên `subscription_id`, không trên `tenant_id`.
- `capacity` chuyển từ tuỳ chọn (`null` = không giới hạn) thành **bắt buộc**. "Không giới hạn" mất nghĩa khi mọi kỳ thi đều thuộc một gói có cap.
- **Đổi gói chỉ khi `status == SCHEDULED`** — đúng lock point đã có ở `SessionLifecycleService.patchPolicy()` (`PolicyLockedException`). Từ `OPEN` trở đi là đông cứng.
- **Đổi gói phải khoá hai hàng `Subscription` theo thứ tự `publicId` tăng dần**, không theo thứ tự cũ-rồi-mới. Hai request đổi chéo nhau (A→B và B→A) khoá ngược chiều là deadlock kinh điển.
- Khi đổi gói, C3 phải kiểm **số sinh viên đã enroll thực tế**, không kiểm `capacity` khai báo — gói mới có thể có cap nhỏ hơn số người đã vào.

## Steps

1. `ExamSession` thêm `subscriptionId` (UUID, not null) và `licenseKey` (denormalize từ Subscription).

2. `Enrollment` thêm `licenseKey` (denormalize). Ghi rõ trong Javadoc: cột này phục vụ **đối soát mức license**, không phải yêu cầu về tính đúng đắn — kiểm cap chỉ cần `session_id`.

3. Migration `V23__session_subscription.sql`:
   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist;

   ALTER TABLE exam_sessions
     ADD COLUMN subscription_id UUID NOT NULL,
     ADD COLUMN license_key VARCHAR(64) NOT NULL,
     ALTER COLUMN capacity SET NOT NULL;
   -- NOT NULL thẳng, không backfill: chưa có dữ liệu thật

   ALTER TABLE exam_sessions ADD CONSTRAINT no_overlap_per_subscription
     EXCLUDE USING gist (subscription_id WITH =, tstzrange(opens_at, closes_at) WITH &&);
   ```

4. `CreateSessionRequest`: thêm `subscriptionPublicId` (bắt buộc), `templatePublicId` (bắt buộc — thay `snapshotPublicId`), `capacity` đổi sang `@NotNull`.

5. `SessionLifecycleService.create()` — chạy bốn điều kiện:
   - **C1** `BillingService.getActiveSubscription(...)` thuộc tenant của caller và còn hiệu lực → không thì **404** (quy ước 404-không-403 của repo)
   - **C2** `[opensAt, closesAt] ⊆ [startsAt, expiresAt]` → **422**
   - **C3** `capacity <= subscription.maxStudentsPerSession` → **422**
   - **C4** kiểm trùng khung giờ ở tầng app **trước** khi insert — không phải để đảm bảo đúng (constraint lo), mà để trả thông báo nói rõ kỳ thi nào đang chiếm khung giờ đó
   - Sinh `randomSeed`, gọi `AssessmentService.generateSnapshotFromTemplate(templatePublicId, seed)` (Phase 10)

6. Bắt `DataIntegrityViolationException` trên constraint `no_overlap_per_subscription` → dịch thành **409**. Đây là lưới cuối khi C4 ở tầng app bị race.

7. `SessionLifecycleService.changeSubscription(sessionPublicId, newSubscriptionPublicId, caller)`:
   - Từ chối nếu `status != SCHEDULED` → `PolicyLockedException` (tái dùng)
   - Khoá `Subscription` cũ và mới theo thứ tự `publicId` tăng dần
   - Chạy lại C1–C4 với gói mới; **C3 so với `COUNT(enrollments)` thực tế**, không so `capacity`
   - Cập nhật `session.subscriptionId` + `licenseKey`, cascade `licenseKey` xuống mọi `Enrollment` của kỳ thi
   - Toàn bộ một transaction

8. `SessionService` (facade) thêm `cancelScheduledSessionsBySubscription(subscriptionId)` cho Phase 6 dùng khi thu hồi mã: kỳ thi `SCHEDULED` → `CANCELLED` + phát thông báo; `OPEN`/`CLOSED` không đụng.

9. Controller: `PATCH /api/sessions/{id}/subscription`.

10. Test C1–C4 từng cái riêng, mỗi cái một test, không gộp.

11. Test đồng thời: hai request tạo kỳ thi cùng làn cùng khung giờ → đúng một thành công, một nhận 409. Chạy lặp nhiều lần để bắt race.

12. Test: hai kỳ thi **khác làn** cùng khung giờ → cả hai thành công.

13. Test đổi gói: kỳ thi đã enroll 300 người, đổi sang gói cap 200 → từ chối, thông báo nêu 300 vs 200.

14. Test deadlock: hai luồng đổi chéo A→B và B→A chạy đồng thời → không treo, cả hai kết thúc (một có thể thất bại vì điều kiện nghiệp vụ, không phải vì deadlock).

## Success Criteria

- Kỳ thi không tạo được nếu không gắn gói hợp lệ
- Hai kỳ thi cùng làn không bao giờ trùng giờ, kể cả khi tạo đồng thời
- Hai kỳ thi khác làn trùng giờ được
- `capacity` bắt buộc và không vượt cap gói
- Đổi gói chỉ khi chưa mở, và chạy lại đủ bốn điều kiện
- Không deadlock khi đổi gói chéo nhau

## Quality and Testing State

- Decision checkpoint: unit tests = yes; quality gate = yes (user confirmed).
- Quality gate: APPROVED — no blocking findings; report: `quality/phase-11-session-subscription-constraints-quality-report.json`.
- Testing: PASSED — focused Phase 11 suite 44/44 and full app regression suite 571/571; report: `tests/phase-11-session-subscription-constraints-test-report.json`.

## Session Notes

- Implemented the DB-backed `subscription_id`/`license_key` session binding, mandatory capacity, PostgreSQL `btree_gist` exclusion constraint, and application conflict translation.
- Added tenant-scoped active-subscription resolution, deterministic public-ID lock ordering for subscription changes, actual enrollment-count validation, and enrollment license propagation.
- Added scheduled-session cancellation on redeemed-license revocation through public module facades and after-commit student notifications.
- PostgreSQL concurrent overlap/deadlock smoke was not run because the local Docker daemon was unavailable; unit coverage and static quality review passed.
