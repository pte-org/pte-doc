# Phase 01 — Đối chiếu domain và kiến trúc

**Status:** planned. **Depends on:** spec.md, audit kiến trúc. **Story:** US-02.

## Mục tiêu

Tạo baseline có bằng chứng cho toàn bộ entity/relationship trước khi đổi notation; phân biệt yêu cầu SRS với code hiện hành và đề xuất chưa được chốt.

## Tasks

- [ ] Ghi revision và working-tree changes liên quan cho SRS, guide và các source dùng để đối chiếu.
- [ ] Lập entity inventory theo sáu domain; ghi ID, tên nghiệp vụ, owner, lifecycle, page, source path và vị trí.
- [ ] Lập relationship inventory: hai endpoint, động từ, min/max hai chiều, loại reference và evidence.
- [ ] Đối chiếu Tenant/Organization trong `TenantLifecycleService`, entity và migration: target 1:1, điều kiện khởi tạo, unique constraint và độ optional trước onboarding hoàn tất.
- [ ] Đối chiếu `Role` enum/catalog và `UserRole`; không coi enum là bảng Role persisted nếu source không có bảng.
- [ ] Xác nhận package/entitlement của organization và question bank của platform; ghi quyền sáu role và giới hạn dữ liệu tổ chức.
- [ ] Đối chiếu exam setup, enrollment, attempt/answer, immutable snapshots, Examiner assignment và Host-trigger scoring/review/publish.
- [ ] Kiểm tra UUID reference, JSON snapshot và polymorphic target; phân loại đúng thay vì suy diễn FK từ tên field.
- [ ] Kiểm chứng các phát hiện audit cụ thể: `User` roles dùng `@ElementCollection` enum; `BaseEntity` phân biệt Long ID với UUID public ID; question có tối đa một audio/image prompt ref mỗi loại; unique `(attempt_id, pinned_item_id)` giới hạn một answer trong attempt cho mỗi pinned item; ExaminerAnswerScore và ScoringAnswer uniqueness giới hạn current score record theo answer; report uniqueness theo attempt UUID và published JSON snapshot.
- [ ] Kiểm tra `Session` snapshot UUID nullable và `ExamForm` snapshot UUID riêng; không suy ra reverse 1:1 hoặc physical FK nếu không có uniqueness/constraint. Đối chiếu cả prose lẫn marker Mermaid hiện tại để ghi contradiction optionality.
- [ ] Validate bốn gap scanner; mở rộng semantic/contradiction register, ghi kết luận `confirmed`, `not applicable` hoặc `needs decision` kèm bằng chứng.
- [ ] Ghi discrepancy register và đề xuất disposition cho từng xung đột; review trước phase 02.

## Design Constraints

Không sửa production code/migration hoặc tái định nghĩa rule SRS để khớp code. Code là implementation evidence; SRS là target evidence. Quan hệ thiếu bằng chứng giữ thành issue chưa quyết định, không tự gán cardinality. Lưu assignment/enrollment/history có trạng thái, thời gian hoặc ownership; phân biệt với pure join. Không truy xuất credential hay dữ liệu cá nhân thực để audit mô hình.

## Acceptance Criteria

1. Mỗi entity dự kiến có owner, source và trạng thái implemented/target/proposed.
2. Mỗi relationship có reference type và min/max hai chiều hoặc issue cụ thể phải giải quyết trước authoring.
3. Tenant–Organization, Role, snapshot, ownership và Host publish có bảng đối chiếu riêng.
4. Bốn gap scanner có verdict có căn cứ; semantic contradiction được ghi và không bị chỉnh ngầm.
5. Baseline chỉ ra version/working-tree boundary; không tuyên bố HEAD là toàn bộ nội dung đang làm việc.

## Deliverables và evidence

`domain-inventory.md`, `relationship-dictionary.md` bản nháp, `discrepancy-register.md`; mỗi nguồn có path + line/section và loại nguồn. Technical FK evidence cần migration/entity mapping, không chỉ tên `...Id`.

## Quality and Testing State

- Quality: **not evaluated**.
- Testing: **not started**.
- Unit tests: không yêu cầu cho documentation scope.
- Planned validation: kiểm tra inventory coverage, source location và adjudication của mọi conflict ảnh hưởng cardinality; ghi kết quả khi thực hiện.
- Cook optional checks: chưa chọn; ghi quyết định trước phase khi có yêu cầu cook.

## Exit và handoff

Chuyển phase 02 khi không còn ambiguity về ownership/cardinality ảnh hưởng mô hình; issue ngoài scope có disposition rõ. Review tài liệu không cấp phép thay database.
