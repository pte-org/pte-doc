# Phase 7: Enforce hạn mức sinh viên

## Requirements

`Tenant.studentLimit` hiện chỉ được ghi, **chưa có chỗ nào đọc để chặn**. Biến nó thành ràng buộc thật: không tạo được sinh viên vượt hạn mức, và kiểm theo lô chứ không theo từng dòng.

Maps to: **[ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §4**

## Design Constraints

- **Hai tầng giới hạn khác nhau, đừng lẫn.** Tầng này là *tổng số sinh viên tồn tại trong tổ chức* (`Tenant.studentLimit`, nguồn = free limit + gói `STUDENT_CAPACITY`). Tầng kia là *số sinh viên trong một kỳ thi* (`subscription.maxStudentsPerSession`) — thuộc Phase 11, **không** làm ở đây.
- **Kiểm theo lô, không theo dòng.** Import 500 sinh viên khi còn 100 chỗ phải bị từ chối **trước khi tạo dòng nào**, không phải tạo 100 rồi lỗi ở dòng 101. `UserBulkCreateWriter` hiện chạy mỗi row một transaction `REQUIRES_NEW` — đúng kiểu sẽ tạo nửa vời.
- Đếm sinh viên là `COUNT(*)` user có role `STUDENT` trong tenant, **không** đếm từ ledger. Ledger là nguồn của *hạn mức*, không phải của *mức đã dùng*.
- Kiểm hạn mức phải nằm trong cùng transaction với việc tạo, nếu không hai request đồng thời cùng lọt qua.
- Endpoint xem trước (dry-run) là yêu cầu của Phase 8 — xây ở đây để Phase 8 dùng lại.

## Steps

1. `TenancyService` (facade) thêm:
   - `getStudentLimit(tenantId)` — trả `Tenant.studentLimit`
   - `assertCanAddStudents(tenantId, count)` — ném `StudentLimitExceededException` kèm số hiện tại / hạn mức / số đang xin

2. `StudentLimitExceededException` trong `tenancy/internal/exception/` → map sang **409**, thông báo nêu rõ ba con số.

3. `UserRepository.countByTenantIdAndRole(tenantId, STUDENT)`. Index trên `(tenant_id)` đã có; kiểm xem có cần index phụ cho lọc role không — bảng `user_roles` là `@ElementCollection` nên câu đếm phải join, đo trước khi tối ưu.

4. `UserService.create()`: nếu role chứa `STUDENT` → gọi `assertCanAddStudents(tenantId, 1)` **trước khi** insert, trong cùng transaction.

5. `UserBulkCreateWriter`: đổi sang kiểm **một lần cho cả lô** trước khi bắt đầu ghi. Nếu quá hạn mức → từ chối toàn bộ, không ghi dòng nào. Giữ nguyên `REQUIRES_NEW` per-row cho phần lỗi dữ liệu từng dòng, nhưng cổng hạn mức đứng ngoài vòng lặp.

6. Khoá hàng `Tenant` (pessimistic) trong lúc kiểm + ghi để hai lô đồng thời không cùng lọt. Dùng lại pattern `findWithLock...` đã có ở `SessionLifecycleService`.

7. `POST /api/students/import/preview` — nhận số lượng dự định thêm, trả về:
   ```json
   { "current": 487, "limit": 1000, "adding": 500, "remaining": 13, "allowed": false }
   ```
   Không ghi gì. Phase 8 gọi endpoint này.

8. `GET /api/tenant/quota` — tenant xem hạn mức và mức đã dùng.

9. Test: tenant có hạn mức 100, đã có 100 sinh viên → tạo thêm 1 bị 409.

10. Test: tenant còn 10 chỗ, import lô 50 → từ chối toàn bộ, `COUNT` sinh viên **không đổi**.

11. Test đồng thời: hai lô cùng 60 sinh viên trên tenant còn 100 chỗ → đúng một lô thành công.

12. Test: mua gói `STUDENT_CAPACITY` (Phase 4) → hạn mức tăng, lô vừa bị từ chối giờ chạy được.

## Success Criteria

- Không tạo được sinh viên vượt hạn mức qua bất kỳ đường nào (tạo lẻ, bulk)
- Lô quá hạn mức bị từ chối trọn vẹn, không để lại dữ liệu nửa vời
- Hai lô đồng thời không cùng lọt qua
- Endpoint xem trước trả đúng bốn con số và không ghi gì
- Mua thêm gói capacity làm tăng hạn mức ngay, không cần restart

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
