# Spec: Chỉnh mô hình và cách trình bày ERD PTE Org

**Ngày:** 2026-10-03
**Trạng thái:** Draft — đủ cơ sở lập plan, chưa triển khai sơ đồ.
**Nguồn yêu cầu:** `projects/templates/pte-prep-srs-erd-guide.md` và ảnh mẫu người dùng cung cấp.

## Problem Statement

Guide hiện tại dùng sơ đồ bảng Mermaid Crow’s Foot, trong khi người dùng muốn entity hình chữ nhật, relationship hình thoi và attribute hình oval. Guide còn trộn khái niệm nghiệp vụ, bảng lưu trữ, tham chiếu UUID và foreign key; một số cardinality không còn khớp source hiện tại. Cần rà soát ý tưởng sản phẩm và kiến trúc trước khi viết lại hướng dẫn và vẽ sơ đồ.

## User Stories

- **[P1] US-01:** Người đọc SRS hiểu các thực thể và quan hệ bằng hình thức như ảnh mẫu. Chấp nhận khi mọi trang có legend, entity chữ nhật, relationship hình thoi có động từ, attribute oval và cardinality hai đầu.
- **[P1] US-02:** Người phụ trách nghiệp vụ đối chiếu ERD với ownership, kỳ thi, bài làm và kết quả. Chấp nhận khi toàn bộ quan hệ trong bộ sơ đồ có min/max hai chiều, nguồn dẫn chứng và trạng thái hiện có/đề xuất/chưa xác minh.
- **[P1] US-03:** Người phát triển phân biệt mô hình nghiệp vụ với database. Chấp nhận khi có bảng ánh xạ entity/relationship → class/table/enum/JSON/UUID reference, không gọi UUID reference là FK nếu chưa có constraint.
- **[P2] US-04:** Người viết tài liệu chỉnh sửa và xuất sơ đồ. Chấp nhận khi mỗi hình có nguồn `.drawio`, bản SVG và PNG, caption và cùng mã entity/relationship trong dictionary.
- **[P3] Ngoài phạm vi:** Sửa database, API, Flutter/web, chuyển kiến trúc, thêm actor hoặc chức năng sản phẩm.

## Functional Requirements

1. **FR-01:** Dùng hình Chen kết hợp ký hiệu đầu nối Crow’s Foot theo ảnh mẫu; gọi rõ đây là quy ước kết hợp của tài liệu, không gọi là Chen thuần. Entity cyan, relationship xanh đậm, attribute magenta; không phụ thuộc màu để hiểu hình.
2. **FR-02:** Không dùng mũi tên quy trình cho quan hệ ER. Cardinality ở đầu entity biểu thị số entity ở đầu đó ứng với một entity đối diện; dictionary phải có câu diễn giải cả hai chiều và min/max.
3. **FR-03:** Conceptual overview biểu diễn Organization thống nhất cho khái niệm tổ chức; phần mapping giữ Tenant và Organization riêng, ghi rõ provisioning và uniqueness. Host là role của User, không là entity tổ chức.
4. **FR-04:** Cho phép relationship M:N ở conceptual model; chỉ giữ assignment/membership/enrollment thành entity khi có dữ liệu, vòng đời hoặc lịch sử nghiệp vụ riêng. Logical/physical appendix giải thích bảng liên kết tương ứng.
5. **FR-05:** Giữ sáu human role, kho câu hỏi và template thuộc platform, package thuộc tổ chức, Student thuộc một tổ chức, nội dung kỳ thi cố định, Host kiểm soát chấm/review/publication.
6. **FR-06:** Tạo một overview và sáu nhóm chi tiết: Identity/Organization/Learning; Content/Template; Billing; Exam Setup; Delivery/Attempt; Proctoring/Scoring/Reporting. Tách trang có hậu tố nếu vượt giới hạn đọc. Audit/notification ở nhóm liên quan và dictionary, không kéo toàn bộ dây vào overview.
7. **FR-07:** Phân biệt database FK, UUID logical reference, polymorphic reference và derived projection. `ScoringAnswer.answer_public_id` chỉ trỏ một loại Answer nên không tự động là polymorphic.
8. **FR-08:** Tách sơ đồ quan hệ khỏi sơ đồ lifecycle. Các chuỗi Question → snapshot → pinned content → Answer và Answer → nguồn điểm → lựa chọn nguồn → Report là đường truy xuất dữ liệu cần đối chiếu, không mặc định mỗi bước là một FK trực tiếp.

## Non-Functional Requirements

- Chất lượng hình: overview tối đa 12 entity nghiệp vụ; mỗi trang chi tiết tối đa 12 entity, 3–6 attribute chính/entity, font tối thiểu 11 pt ở bản in A3; không chồng nhãn hoặc connector lên node không liên quan. Trang vượt giới hạn phải chia tiếp.
- Tính truy vết: 100% entity và relationship có mã, nguồn, mức mô hình và trạng thái xác minh. Không đưa credential/token thật vào hình.
- Baseline sản phẩm được tham chiếu từ spec §7: 1.000 active attempts, 100 answer/giây, p95 phản hồi thông thường ≤0,5 giây, availability 99,9%; đây là mục tiêu SRS, không phải kết quả kiểm thử hoặc tải sinh ra bởi việc sửa ERD.
- Thời hạn lưu trữ, AI provider, recovery khi tạo đề lỗi và kế hoạch vận hành giữ các TBD của spec. RPO tối đa 15 phút và RTO tối đa 1 giờ vẫn là mục tiêu đã chốt tại NFR-06/07; cách chứng minh đạt mục tiêu chưa được chốt. Không tự chọn retention, nhà cung cấp hoặc cam kết vận hành mới.

## Success Criteria

- [ ] Không còn quan hệ Tenant 1:N Organization trong baseline mới; phân biệt DB cho phép Tenant chưa có Organization với invariant sau onboarding thành công.
- [ ] 100% quan hệ có câu đọc hai chiều và loại liên kết; cardinality theo lifecycle được giải thích.
- [ ] Không thể hiện Role enum, JSON policy hoặc projection thành bảng có thật nếu không có bằng chứng.
- [ ] Mọi hình tuân thủ FR-01/02 và tiêu chí đọc; có bản chỉnh sửa và bản xuất.
- [ ] Có coverage Feature 1–12, BR liên quan và cross-cutting permissions/error/concurrency/NFR.
- [ ] Guide mới liên kết bộ hình, dictionary và mapping; Mermaid cũ không còn là định dạng chính.

## Out of Scope

Không triển khai code, chạy migration, viết lại toàn SRS, đổi multi-tenancy, thêm nhiều Organization cho một Tenant, thêm multi-examiner scoring hay đưa dịch vụ bên ngoài/Redis/RabbitMQ thành entity nghiệp vụ.

## Assumptions

Ảnh mẫu là yêu cầu về hình thức; quan hệ của ví dụ bán hàng không phải mẫu nghiệp vụ PTE. Đề xuất công cụ là draw.io và SVG/PNG, có thể đổi công cụ mà giữ model. Kế hoạch thay đổi tài liệu trước; mọi conflict cần thay đổi nghiệp vụ/database phải thành quyết định và plan riêng. Tên sản phẩm dùng PTE Org theo spec, tên file guide hiện tại giữ ổn định để tránh đứt liên kết.

## Cơ sở thiết kế

- [Microsoft: Chen notation](https://support.microsoft.com/en-us/visio/create-a-diagram-with-chen-s-database-notation) xác nhận các hình entity/relationship/attribute.
- [draw.io: Crow’s Foot](https://www.drawio.com/docs/tutorials/crows-foot-notation/) giải thích đầu nối cardinality. Quy ước kết hợp ở FR-01 được suy ra từ ảnh mẫu, không là yêu cầu của hai tài liệu nguồn.
- Nguồn dự án: `projects/pte-org-srs/spec.md`, ADR-001/002/006/007/008/009/010/011 và source `pte-api/app/src/main/java/com/pte` tại thời điểm rà soát.
