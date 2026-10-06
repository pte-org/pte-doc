# Spec: Archive lifecycle cleanup

Ngày: 2026-10-05. Status: Ready for plan review — người dùng đã chốt phạm vi và ba lựa chọn nghiệp vụ; chưa cho phép bắt đầu code trong lượt này.

## Problem Statement

Archive đang phục vụ cả retirement, bỏ bản nháp và soft removal. Cần tách đúng nghiệp vụ, giảm action dư mà không mất cleanup hoặc làm hỏng lịch sử đề thi/quyền lợi billing.

## User Stories

- [P1] Admin có thể bỏ draft chưa sử dụng qua Delete draft; accepted when API kiểm tra trạng thái, nguồn gốc, tham chiếu và quyền trong transaction, giữ audit.
- [P1] Admin archive tài nguyên đã sử dụng mà không xóa lịch sử; accepted when question revision/snapshot và plan subscription/order không mất dữ liệu, mã lưu hành được bảo vệ theo policy đã chọn.
- [P1] Author không thể dùng Archive để né approval; accepted when pending không archive/delete trực tiếp, admin vẫn Reject về DRAFT.
- [P2] Host hiểu Remove khác Inactive; accepted when Program/Class giữ soft removal và guard hiện tại, text không hứa permanent delete hoặc restore không có.

## Functional Requirements

1. FR-01: Plan chỉ archive ACTIVE; DRAFT có Delete draft khi không có bất kỳ order/subscription/license tham chiếu. ARCHIVED giữ nguyên dữ liệu legacy.
2. FR-02: Question đã publish/history dùng archive; pending dùng review hiện có, không thêm Withdraw trong đợt này.
3. FR-03: Question delete chỉ khi DRAFT và chứng minh chưa từng publish, không revision/reference cần giữ. UNKNOWN legacy bị chặn, không coi DRAFT là đủ điều kiện.
4. FR-04: Delete draft mặc định đề xuất soft delete bằng `deleted=true`, không khôi phục từ UI đợt này; API public không đọc/sửa/publish lại bản đã xóa.
5. FR-05: Server trả capabilities và lý do bị chặn cho UI; capabilities chỉ hỗ trợ hiển thị, server phải kiểm tra lại lúc mutation.
6. FR-06: Archive/edit entitlement plan có mã ISSUED chưa hết hạn được chặn trong đợt guard tối thiểu; snapshot issuance là phương án thay thế cần duyệt riêng.
7. FR-07: Program/Class chỉ đổi text Archive → Remove; giữ route/guard/audit/data semantics hiện tại để tránh mở rộng breaking API.
8. FR-08: Confirmation/pending/error/refetch đúng action; success không đóng form mới, conflict tải lại capabilities.

## Non-Functional Requirements

- Không hard delete hoặc tự chuyển state legacy; không xóa media Cloudinary khi delete draft.
- Guard và write cùng transaction; concurrency tests dùng PostgreSQL và đọc sau commit bằng transaction mới.
- Cross-module reference checks qua public facade; không import repository của module khác.
- Audit/error codes thuộc constants của owning module; không token/credential trong evidence.

## Success Criteria

- [ ] Tất cả transition trong bảng plan có UI/API test, direct call không bypass.
- [ ] 0 delete thành công khi provenance UNKNOWN/published hoặc còn tham chiếu.
- [ ] Race delete/publish/revision và issue/archive không làm mất dữ liệu hoặc phát mã trái guard.
- [ ] Existing snapshots và subscription còn đọc được; không đổi historical entitlement.
- [ ] Program/Class giữ guard và persistence, chỉ thay text.
- [ ] Gates theo từng phase có receipt; full regression không bỏ qua lỗi dirty worktree.

## Out of Scope

- Toàn bộ 45 unhappy cases; email delivery, approval concurrency, redeemed revoke, snapshot license nếu không chọn mở rộng.
- Hard-delete, Restore/Trash UI, bulk archive/delete, Withdraw submission, đổi enrollment API routes.
- Redesign, commit/push/deploy hoặc production mutation.

## Các lựa chọn đã xác nhận

1. Phạm vi chỉ là vòng đời Archive/Delete draft/Remove, không toàn bộ 45 case.
2. Delete draft là soft delete, giữ audit, không Restore UI trong đợt này.
3. Đợt này chặn Archive/sửa quyền lợi khi còn mã lưu hành, chưa làm issuance snapshot.

Người dùng đã xác nhận cả ba lựa chọn ngày 2026-10-05. Plan được lập để review trước code; bất kỳ thay đổi scope nào cần cập nhật spec trước implementation.
