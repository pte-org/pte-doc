# Phase 13: Điểm có trọng số & đình chỉ tenant

## Requirements

Hai việc nhỏ khép lại plan: điểm tổng tính theo `% điểm từng phần` của template, và đình chỉ tenant như một hình phạt có tham số.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §5, §9**

## Design Constraints

### Điểm có trọng số

- **Đọc trọng số từ `ExamSnapshot`, không từ `ExamTemplate`.** Admin sửa template không được làm đổi điểm của kỳ thi đã diễn ra. Phase 10 đã snapshot hoá trọng số — phase này chỉ tiêu thụ.
- Phần thi không có câu nào trong snapshot thì trọng số của nó phải được xử lý rõ ràng (bỏ qua và chuẩn hoá lại, hoặc tính 0) — chọn một và ghi vào code, đừng để ngầm định.

### Đình chỉ tenant

- Đình chỉ là **hình phạt**, không phải tạm dừng dịch vụ. **`Subscription.expiresAt` không gia hạn bù** — thời gian bị treo là thời gian tenant mất, đó chính là nội dung hình phạt.
- **Mặc định `suspendedUntil = 0` nghĩa là không tự hết hạn** — giữ `SUSPENDED` tới khi Admin bấm `reactivate()`.
- **Attempt đang chạy không bị đụng.** Đình chỉ là thao tác control-plane; bất biến #4 của ADR-001 cấm control plane chạm critical path. Sinh viên đang làm bài dở không được mất bài vì quyết định hành chính nhắm vào tổ chức. **Chặn ở điểm *bắt đầu*, không chặn ở điểm *đang diễn ra*.**
- Đình chỉ kéo dài quá `expiresAt` thì gói chết hẳn — đúng ý đồ, nhưng **Admin phải thấy điều đó trước khi bấm**.

## Steps

### Phần A — điểm có trọng số

1. `ScoreAggregationService`: đọc `snapshot_section_weights` của snapshot gắn với attempt, tính `Σ(điểm phần × weightPercent / 100)`.

2. Chốt và ghi rõ cách xử lý section không có câu nào: **bỏ qua section đó và chuẩn hoá lại trọng số các section còn lại về 100**. Lý do: kỳ thi practice chỉ có SPEAKING mà tính điểm trên thang có cả 4 phần thì điểm luôn thấp giả tạo.

3. `AttemptReport` thêm điểm từng phần + trọng số đã áp dụng, để phiếu điểm giải thích được con số tổng.

4. Migration `V25__reporting_section_scores.sql`.

5. Test: snapshot có trọng số 30/20/25/25, điểm phần 80/60/70/90 → tổng = 76.5.

6. Test: kỳ thi chỉ có SPEAKING (trọng số gốc 30) → điểm tổng bằng đúng điểm SPEAKING, không phải 30% của nó.

7. Test: clone template và đổi trọng số → report của attempt cũ **không đổi**.

### Phần B — đình chỉ tenant

8. `Tenant` thêm `suspendedUntil` (Instant, nullable). Migration `V26__tenant_suspension.sql`.

9. `TenantLifecycleService.suspend(publicId, days)`:
   - `days == 0` hoặc null → `suspendedUntil = null` (không tự hết hạn)
   - `days > 0` → `suspendedUntil = now + days`
   - Mặc định lấy từ `PlatformSetting.suspension_default_days` (Phase 3, seed = 0)

10. `TenancyService` (facade) thêm `assertTenantActive(tenantId)` — ném `TenantSuspendedException` (→ **403**) nếu đang bị đình chỉ.

11. Gắn cổng kiểm vào **điểm bắt đầu**, không vào luồng đang chạy:

    | Chặn | Không chặn |
    |---|---|
    | Tạo kỳ thi (`SessionLifecycleService.create`) | `AttemptLifecycleService` — attempt đang chạy |
    | Mở kỳ thi (`open`) | Nộp bài |
    | Enroll sinh viên | Heartbeat |
    | Tạo Order / redeem mã | Đọc report đã publish |
    | Import roster | |

12. Endpoint xem trước cho Admin: `GET /api/admin/tenants/{id}/suspension-impact` — trả số gói đang `ACTIVE`, tổng số ngày sẽ mất, và gói nào sẽ **hết hạn hẳn** trong thời gian đình chỉ. Màn hình đình chỉ phải hiện cái này trước khi bấm.

13. Job quét `suspendedUntil < now` → `reactivate()`. Với mặc định 0 thì job không có việc gì làm — nó chỉ phục vụ các lần đình chỉ có đặt thời hạn.

14. Test: đình chỉ mặc định → tenant giữ `SUSPENDED` sau khi job chạy, chỉ `reactivate()` thủ công mới gỡ.

15. Test: đình chỉ 7 ngày → sau 7 ngày (giả lập thời gian) job tự gỡ.

16. Test: đình chỉ trong lúc có attempt đang chạy → attempt vẫn nộp được, nhưng không mở được kỳ thi mới.

17. Test: gói còn 5 ngày, đình chỉ 10 ngày → hết đình chỉ thì gói đã `EXPIRED`, `expiresAt` **không** được đẩy lùi.

## Success Criteria

- Điểm tổng tính đúng theo trọng số đọc từ snapshot
- Kỳ thi một phần không bị tính điểm trên thang đủ 4 phần
- Sửa template không làm đổi report cũ
- Đình chỉ mặc định không tự hết hạn
- Đình chỉ không làm hỏng bài thi đang diễn ra
- Đồng hồ gói không dừng khi đình chỉ
- Admin thấy được thiệt hại trước khi bấm đình chỉ

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
