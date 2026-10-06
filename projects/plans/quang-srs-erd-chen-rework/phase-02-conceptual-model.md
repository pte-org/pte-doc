# Phase 02 — Thiết kế conceptual model và notation

**Status:** planned. **Depends on:** phase 01. **Stories:** US-01, US-02, US-03.

## Mục tiêu

Chốt mô hình nghiệp vụ, page manifest và legend hybrid trước khi vẽ toàn bộ bộ hình.

## Tasks

- [ ] Viết `notation-and-layout.md`: rectangle cyan, diamond blue, ellipse magenta; Crow's Foot cardinality sát entity, connector không có flow arrow.
- [ ] Chốt legend `0..1`, `1..1`, `0..N`, `1..N`; tạo một ví dụ đọc được cả hai chiều và liên kết dictionary.
- [ ] Chốt 1 overview + 6 domain pages; tách exam setup khỏi exam delivery. Trang quá 12 entity tách suffix, giữ canonical IDs.
- [ ] Chọn tối đa 12 core entity overview theo chuỗi Organization → entitlement → exam → attempt → published result; tránh biến overview thành bản sao mọi bảng.
- [ ] Chọn 3–6 attribute nghiệp vụ mỗi entity trên detail; định danh conceptual có thể gạch dưới nếu legend quy định, PK/FK/SQL detail chuyển appendix.
- [ ] Biểu diễn M:N thuần bằng relationship diamond; giữ enrollment/assignment/history thành entity khi có dữ liệu nghiệp vụ độc lập.
- [ ] Hoàn thiện dictionary: mỗi relation có hai cách đọc, min/max hai đầu, participation condition, owner, reference type và evidence.
- [ ] Viết technical mapping appendix: conceptual entity ↔ implementation entity/table/enum; physical FK, application UUID, JSON snapshot và polymorphic reference được phân biệt.
- [ ] Tạo page manifest/cross-reference; ghi entity lặp là cùng một entity, không tạo mô hình riêng trên từng trang.
- [ ] Review semantic model và mẫu legend trước phase 03.

## Design Constraints

Không dùng cột FK để giả lập attributes conceptual trên mọi shape. Không vẽ sáu role như sáu entity người dùng. Role catalog phải được gắn là conceptual/enum nếu chưa có persisted table. Không biến target 1:1 Tenant–Organization thành claim runtime đã kiểm thử. Snapshot là nội dung đã khóa; relation đến nguồn gốc không cho phép hiểu rằng sửa question/template sẽ thay dữ liệu đề đã khóa.

## Acceptance Criteria

1. Notation khớp ba nhóm hình học và màu người dùng, có nhãn hybrid chính xác và không dùng connector arrow.
2. Dictionary bao phủ 100% quan hệ sẽ vẽ, đủ min/max hai chiều và reference type.
3. Page manifest có overview + 6 domain pages; mọi trang có quy tắc split khi hơn 12 entity.
4. Assignment/history có ý nghĩa nghiệp vụ không bị mất khi giản lược join table.
5. FK/PK/SQL appendix tách khỏi visual conceptual; mọi implementation mapping có evidence.
6. Review được ghi nhận với issue/disposition; không còn conflict chặn vẽ diagram.

## Deliverables và evidence

`conceptual-model.md`, `notation-and-layout.md`, `page-manifest.md`, `relationship-dictionary.md` cập nhật, `technical-mapping-appendix.md`. Evidence từ phase 01 giữ nguyên source/status hoặc được cập nhật có lý do.

## Quality and Testing State

- Quality: **not evaluated**.
- Testing: **not started**.
- Unit tests: không yêu cầu.
- Planned validation: completeness dictionary, page bounds, mapping owner/reference types; review mẫu notation ở kích thước A3.
- Cook optional checks: chưa chọn; chỉ ghi kết quả sau khi thực hiện.

## Exit và handoff

Mô hình semantic và notation được review; chuyển phase 03 để tạo một bộ diagram cùng revision. Chưa cập nhật guide trước khi mẫu visual đọc được.
