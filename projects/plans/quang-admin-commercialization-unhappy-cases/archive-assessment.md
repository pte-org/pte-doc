# Đánh giá lại Archive: giữ lịch sử, ngừng sử dụng hay xóa?

Ngày: 2026-10-05. Phạm vi khảo sát: archive trong admin và các luồng tenant liên quan. Đây là kết luận từ code hiện tại, chưa thay đổi API/schema hoặc dữ liệu.

Kế hoạch chi tiết sau khi chốt phạm vi: [quang-archive-lifecycle-cleanup](../quang-archive-lifecycle-cleanup/plan.md). User chọn lifecycle-only, soft delete giữ audit và chặn thao tác khi plan còn mã lưu hành; chưa triển khai.

## Kết luận

Không nên dùng Archive làm thao tác mặc định cho mọi tài nguyên. Nhưng cũng không nên bỏ toàn bộ vì một số tài nguyên có lịch sử sử dụng và tham chiếu cần giữ.

Code hiện tại có bốn nhóm thao tác archive: Plan, Question Bank, Program, Class. Hai nhóm đầu là lifecycle; hai nhóm sau là soft delete qua `deleted=true`, không phải trạng thái ARCHIVED riêng.

Đề xuất giảm archive theo **trạng thái và lịch sử sử dụng**, không xóa tính năng theo tên màn:

| Tài nguyên / tình trạng | Có cần Archive? | Thao tác phù hợp |
|---|---|---|
| Plan ACTIVE đã bán hoặc phát mã | Có nhu cầu giữ lịch sử và ngừng phát/bán mới. | Giữ cơ chế retire; có thể gọi “Ngừng cung cấp” cho rõ nghiệp vụ. Phải bảo vệ mã đã phát theo policy snapshot/guard đã đề xuất. |
| Plan DRAFT chưa từng sử dụng | Không cần vòng đời lưu trữ dài hạn chỉ để dọn bản nháp. | Delete draft có guard tham chiếu; không bổ sung Archive cho DRAFT vào UI. |
| Question đã publish hoặc revision từng dùng | Cần. | Archive loại khỏi pool sinh đề mới, giữ nội dung/revision cho đề và kết quả cũ. Không bỏ auto-archive revision bị thay thế. |
| Question DRAFT mới hoàn toàn, chưa tham chiếu | Không cần Archive nếu mục đích là bỏ bản nháp. | Delete/discard draft có guard; khác với draft được phục hồi từ lịch sử hoặc revision liên quan. |
| Question PENDING_APPROVAL | Archive không phải thao tác xét duyệt phù hợp. | Reject trả về DRAFT hoặc Withdraw submission nếu được duyệt nghiệp vụ; không dùng Archive để né review/audit. |
| Program / Class còn dùng | Không cần Archive để tạm dừng. | Inactive hoặc Suspended, giữ trong danh sách. |
| Program / Class cần dọn khỏi danh sách nhưng vẫn giữ tham chiếu | Cần chức năng removal an toàn, không nhất thiết cần nhãn Archive. | Soft delete/remove với guard con/membership hiện có. Không hard delete lịch sử. |
| Applications | Không cần và hiện không có Archive. | Approve/Reject, giữ decision history. |
| License codes | Không cần và hiện không có Archive. | Revoke/Expired/ Redeemed; không giấu mã thay cho thu hồi quyền lợi. |
| Task Type Catalog | Không có archive lifecycle riêng trong luồng được kiểm tra. | Giữ activation/removal theo contract hiện tại; không thêm archive chung. |
| Announcements | Không cần thêm Archive chỉ để bỏ bản nháp. | UI hiện có Delete draft; giữ lifecycle publish/retract theo contract riêng. |

“Không cần archive” không đồng nghĩa “được hard delete”. Phải kiểm tra tham chiếu, quyền sở hữu, audit và lịch sử trước khi cho delete.

## Những điểm đề xuất trước cần sửa lại

1. Rút đề xuất mở thêm **Archive DRAFT plan** trong PLN-07. Sự khác biệt UI/API không bắt buộc phải giải quyết bằng cách mở rộng UI; nên thu hẹp capability thừa.
2. Không xem Archive là giải pháp chung cho Applications, License codes, task types, announcements hoặc settings.
3. Giữ Archive đối với nội dung đã publish và plan đã đưa vào sử dụng; xử lý tác động entitlement thay vì xóa dữ liệu nguồn để né unhappy case.

## Tại sao chưa gỡ nút/API ngay trong lượt đánh giá

- Plan API hiện cho archive DRAFT nhưng UI chỉ archive ACTIVE. Gỡ API capability DRAFT cần thống nhất Delete draft và tương thích client; không có nút DRAFT archive trong UI để xóa ngay.
- Question UI hiện cho archive DRAFT/PENDING/PUBLISHED; backend archive cũng không kiểm tra state. Tuy có `deleteQuestion` trong API client và text “Delete”, controller hiện tại không có DELETE tương ứng. Đổi nhãn Archive thành Delete sẽ gây hiểu sai; nối vào hàm client cũ có thể gọi endpoint không tồn tại.
- Gỡ Archive DRAFT Question mà chưa có discard có guard sẽ làm mất cách dọn bản nháp. DRAFT cũng không bảo đảm “chưa từng publish”: unarchive trả ARCHIVED về DRAFT.
- Program/Class soft delete có ý nghĩa khác với Inactive. Xóa thao tác sẽ mất cách dọn danh sách; đổi sang hard delete là thay đổi dữ liệu vượt phạm vi review.

Vì vậy lượt này bỏ đề xuất archive dư trong tài liệu, không gỡ mù các chức năng đang phục vụ lịch sử hoặc cleanup. Bước thay đổi chức năng cần lựa chọn rõ: **thu hẹp archive + bổ sung Delete draft an toàn**, hay chỉ **giữ archive cần thiết và sửa nhãn/visibility**. Không triển khai một cơ chế xóa mới khi chưa chốt semantics.

## Hướng triển khai khuyến nghị

1. Giữ Plan ACTIVE retirement và Question published archive; giữ dữ liệu ARCHIVED đang tồn tại.
2. Thêm discard draft chỉ khi có guard được kiểm tra trong transaction: chưa phát hành, không có tham chiếu/revision history cần giữ. Plan kiểm tra orders/subscriptions/license codes; Question kiểm tra lịch sử revision và các tham chiếu template/exam cần thiết qua public API module.
3. Sau khi discard hoạt động, bỏ Archive trên draft chưa sử dụng ở UI và BE; dùng Reject/Withdraw cho pending question.
4. Với Program/Class, giữ soft removal; cân nhắc đổi nhãn thành “Remove” và giải thích dữ liệu lịch sử vẫn giữ, không đổi ngầm thành permanent delete.
5. Không thêm archive ở bất kỳ module nào chỉ để đồng nhất row actions.

## Acceptance criteria

- Draft chưa sử dụng có đường discard; đã sử dụng/referenced không bị xóa chỉ vì đang ở DRAFT.
- API enforce cùng rule với UI; direct call không bỏ qua state/reference guard.
- Archive question không làm đề đã sinh hoặc kết quả cũ mất nội dung; auto-archive revision vẫn giữ.
- Archive plan không âm thầm thu hồi quyền lợi mã/subscription hiện có.
- Program/Class inactive vẫn xuất hiện; removed không xuất hiện list active nhưng lịch sử/tham chiếu không bị xóa.
- Không thay state ARCHIVED legacy thành deleted hoặc xóa hàng loạt bằng migration.

## Căn cứ code

- [PlanService.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/service/PlanService.java): archive cho mọi state chưa ARCHIVED; [PlanCatalogView.tsx](../../../../pte-web/apps/vendor-web/features/commercialization/components/PlanCatalogView.tsx): chỉ mở archive khi ACTIVE.
- [ItembankService.java](../../../../pte-api/app/src/main/java/com/pte/itembank/ItembankService.java): archive, auto-archive superseded revision, unarchive → DRAFT; [_QuestionTable.tsx](../../../../pte-web/apps/vendor-web/features/questionbank/components/_QuestionTable.tsx): action cho draft/pending/published.
- [QuestionController.java](../../../../pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionController.java) và [question client](../../../../pte-web/packages/api-client/src/requests/question/index.ts): cần đối chiếu DELETE, không dựa vào tên helper để kết luận backend đã hỗ trợ.
- [ProgramService.java](../../../../pte-api/app/src/main/java/com/pte/enrollment/internal/service/ProgramService.java): archive setDeleted, guard lớp con; [ClassService.java](../../../../pte-api/app/src/main/java/com/pte/enrollment/internal/service/ClassService.java): archive setDeleted, guard membership, khác deactivate.
- [ProgramRepository.java](../../../../pte-api/app/src/main/java/com/pte/enrollment/internal/repository/ProgramRepository.java), [StudentClassRepository.java](../../../../pte-api/app/src/main/java/com/pte/enrollment/internal/repository/StudentClassRepository.java): list bỏ deleted, khác status inactive.
- [AnnouncementsView.tsx](../../../../pte-web/apps/vendor-web/features/notifications/components/AnnouncementsView.tsx): Delete draft.

Không chạy test runtime hoặc xóa dữ liệu trong lượt đánh giá. Chỉ cập nhật tài liệu; không claim đã gỡ archive trong ứng dụng.
