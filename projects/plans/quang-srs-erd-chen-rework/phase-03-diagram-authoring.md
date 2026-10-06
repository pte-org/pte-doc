# Phase 03 — Authoring và xuất bộ ERD

**Status:** planned. **Depends on:** phase 02. **Stories:** US-01, US-02, US-04.

## Mục tiêu

Tạo bộ hình chỉnh sửa được, có bản xuất nhất quán và đọc được khi in.

## Tasks

- [ ] Tạo một trang mẫu draw.io theo legend; kiểm tra entity, diamond relationship, attribute ellipse và cardinality sát entity.
- [ ] Vẽ overview trước; giới hạn 12 core entities và phân biệt owner bằng nhãn/ghi chú rõ, không chỉ bằng màu.
- [ ] Vẽ exam setup và delivery để kiểm tra chỗ nối roster, fixed form, attempt/answer và snapshot.
- [ ] Review ba trang đầu tại A3; chỉnh routing/layout trước khi nhân rộng style.
- [ ] Vẽ các trang còn lại theo page manifest; tách `-a`, `-b` khi hơn 12 entity, giữ ID/cross-reference.
- [ ] Gắn relationship IDs/legend hoặc bảng tham chiếu cạnh hình để tra được dictionary mà không nhồi evidence lên connector.
- [ ] Xuất `.svg`, `.png` từ chính revision `.drawio` XML; ghi version công cụ, page size, font và revision trong manifest.
- [ ] Reopen XML trong draw.io; kiểm tra page count, entity count và chỉnh sửa label được.
- [ ] Kiểm tra từng trang ở kích thước in A3: font ít nhất 11 pt, không label overlap, không connector đi xuyên shape không liên quan.
- [ ] Kiểm tra không có flow arrow, relationship không thiếu endpoint/diamond, cardinality không bị nhầm vị trí.
- [ ] Ghi visual review receipt và export consistency trước phase 04.

## Design Constraints

Không dùng raster image thay XML source editable. PNG/SVG chỉ là exports; cập nhật source trước khi xuất lại. Không rút bỏ ownership/history để có hình đẹp. Relationship diamond dùng động từ nghiệp vụ; connector biểu thị liên kết dữ liệu, không biểu thị thứ tự quy trình. Có thể routing khác nhau giữa trang nhưng notation/cardinality phải giống nhau.

## Acceptance Criteria

1. Tất cả trang manifest có XML `.drawio`, `.svg`, `.png` cùng revision; mở lại XML không lỗi.
2. Overview ≤12 core entities; detail ≤12 entities/trang hoặc đã split; detail có 3–6 attribute/entity.
3. 100% relationship có ID dictionary, evidence và min/max hai chiều; hình khớp dictionary.
4. A3 font ≥11 pt, không label overlap; không connector xuyên shape không liên quan và không arrow đầu nối.
5. Mẫu đầu và bộ cuối có visual review record; file presence/XML parse không được báo là đủ bằng chứng readability.

## Deliverables và evidence

Thư mục dự kiến `erd/` gồm `00-overview.*`, `01-identity-organization.*`, `02-content-scoring-template.*`, `03-billing-entitlement.*`, `04-exam-setup.*`, `05-exam-delivery.*`, `06-proctoring-scoring-reporting.*` và các split suffix nếu cần. `export-manifest.md`, `visual-review.md` ghi revision, công cụ, counts và từng điểm kiểm tra.

## Quality and Testing State

- Quality: **not evaluated**.
- Testing: **not started**.
- Unit tests: không yêu cầu.
- Planned validation: XML parse/reopen, manifest/export coverage, comparison với dictionary, visual inspection A3. Không chứng minh authorization/runtime/SQL bằng những check này.
- Cook optional checks: chưa chọn; check đã chạy phải có command/công cụ và kết quả trong receipt.

## Exit và handoff

Bộ hình có receipt cho cả structural và visual checks; tiếp tục phase 04 để rewrite guide và cross-link tài liệu SRS.
