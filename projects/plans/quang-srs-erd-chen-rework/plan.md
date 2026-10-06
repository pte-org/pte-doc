# Plan thay đổi ERD SRS theo mẫu người dùng

**Ngày:** 2026-10-03
**Trạng thái:** planned — chỉ lập kế hoạch; chưa chạy `ck:cook`, chưa thay guide, chưa tạo sơ đồ.
**Phạm vi:** `projects/templates/pte-prep-srs-erd-guide.md` và bộ tài liệu ERD mới trong `pte-doc`.
**Đặc tả đầu vào:** [spec.md](spec.md). Báo cáo audit đi kèm đặc tả là căn cứ đối chiếu, không phải quyền tự động thay kiến trúc.

## 1. Kết quả cần đạt

Guide hiện mô tả ERD bằng entity dạng bảng, FK/PK và các sơ đồ Mermaid. Plan chuyển phần trình bày SRS sang hình chữ nhật cho entity, hình thoi cho relationship và ellipse cho attribute như ảnh người dùng. Mẫu dùng hình học Chen kết hợp cardinality Crow's Foot; tài liệu phải gọi đây là **quy ước hybrid Chen–Crow's Foot**, không khẳng định là Chen thuần.

Đổi notation phải đi cùng kiểm tra ý nghĩa dữ liệu: quyền sở hữu tổ chức/nền tảng, Tenant–Organization, vai trò, kỳ thi, lượt làm bài, snapshot và kết quả công bố. Mục tiêu là một mô hình nghiệp vụ dễ đọc và có bằng chứng, không phải migration database hay thiết kế lại backend.

## 2. Baseline và ranh giới

| Nguồn | Vai trò |
|---|---|
| `projects/pte-org-srs/spec.md` | Ý tưởng sản phẩm và yêu cầu SRS hiện hành |
| `projects/templates/pte-prep-srs-erd-guide.md` | Tài liệu cần thay ở giai đoạn thực hiện |
| `pte-api/app/src/main/java` và migration | Implementation hiện tại, kiểm chứng entity và quan hệ |
| `pte-web`, `pte-app` | Kiểm chứng actor, quyền truy cập và Windows exam client khi cần |
| Ảnh người dùng gửi | Chuẩn hình học và cách trình bày, không phải mô hình nghiệp vụ PTE |

HEAD khi lập plan: `pte-doc` = `7c51ad08a8fccd764a549913369c77afb7dde5d3`; `pte-api` = `09476d53d854bc39bd3e1c3a21d5f958496d7103`. Đây là baseline tham chiếu; phải ghi thêm working-tree changes liên quan khi thực hiện, vì HEAD không chứng minh nội dung chưa commit.

Kiến trúc nền giữ modular monolith và ba kênh: Organization web portal, Platform administration portal, Windows exam client. Sáu role là Platform Admin, Platform Author, Host, Proctor, Examiner, Student. Gói/quyền sử dụng thuộc tổ chức; question bank thuộc nền tảng. Nội dung đề và quy tắc chấm được cố định bằng snapshot. Host khởi chạy bước chấm, duyệt và công bố theo SRS; quyền của Proctor/Examiner phải được đối chiếu riêng.

Không sửa API, frontend, Flutter, SQL schema hay migration trong plan này. Không tự đổi nguồn SRS khi source code khác yêu cầu. Mọi khác biệt phải ghi trong discrepancy register, gắn `implemented`, `target` hoặc `proposed` và đưa ra quyết định tài liệu rõ ràng.

## 3. Bộ sơ đồ dự kiến

| Trang | Phạm vi |
|---|---|
| 00-overview | Tối đa 12 entity lõi và quan hệ cấp nghiệp vụ |
| 01-identity-organization | User, vai trò, Tenant/Organization, chương trình, lớp và membership |
| 02-content-scoring-template | Question bank, question/version, media, task type và score template |
| 03-billing-entitlement | Plan catalog, order, payment, subscription/license và quota |
| 04-exam-setup | Kỳ thi, nội dung cố định, form, roster/enrollment và phân công |
| 05-exam-delivery | Attempt, answer, giao nhận/sync và snapshot đã dùng |
| 06-proctoring-scoring-reporting | Giám sát, phân công Examiner, điểm/revision, duyệt/công bố, report và audit |

Đây là 1 overview + 6 domain pages ban đầu. Trang chi tiết quá 12 entity phải tách hậu tố `-a`, `-b`; đặc biệt trang 06 được phép tách theo giám sát, chấm/công bố, hỗ trợ/audit. Tên chuẩn và ID entity/relationship giữ thống nhất giữa các trang; entity xuất hiện lại mang cross-reference.

Mỗi trang có `.drawio` XML chỉnh sửa được, `.svg` và `.png`. XML là nguồn authoring; SVG/PNG là bản xuất cùng revision. Entity/relationship dictionary và technical mapping appendix là tài liệu đi kèm, không nhồi vào hình.

## 4. Quy ước và tiêu chí chấp nhận chung

- Entity: rectangle cyan; relationship: diamond blue; attribute: ellipse magenta. Nhãn đủ tương phản, legend gồm hình học, màu và cardinality.
- Connector không dùng mũi tên chỉ luồng. Crow's Foot phải đặt ở đầu nối sát entity; relationship diamond chứa động từ nghiệp vụ. Legend giải thích rõ `0..1`, `1..1`, `0..N`, `1..N`.
- Mỗi relationship có ID, hai entity tham gia, cách đọc cả hai chiều, min/max mỗi đầu, owner, nguồn và loại: physical FK, logical application reference, snapshot reference hoặc polymorphic reference. Đánh dấu này trong dictionary/appendix, tránh suy diễn UUID thành FK.
- Conceptual M:N có thể thể hiện trực tiếp qua diamond. Chỉ giữ entity trung gian khi có ý nghĩa nghiệp vụ như enrollment, assignment, history, trạng thái hoặc thời gian hiệu lực; pure join kỹ thuật đưa sang appendix.
- `Role` là catalog khái niệm/enum nếu source hiện tại như vậy; không vẽ như bảng persisted khi chưa có bằng chứng. Target Tenant–Organization 1:1 phải đối chiếu onboarding và nguồn constraint; optionality ở thời điểm đăng ký/phê duyệt được ghi riêng.
- Overview tối đa 12 core entities. Mỗi trang chi tiết tối đa 12 entity trước khi tách; mỗi entity chi tiết chọn 3–6 attribute nghiệp vụ nổi bật. ID/PK/FK và kiểu SQL đầy đủ thuộc appendix.
- Bản in A3 có font tối thiểu 11 pt, không label overlap, không connector đi xuyên shape không liên quan; tất cả relationship phải có bằng chứng và cardinality min/max hai chiều. Kiểm tra khả năng đọc ở kích thước in thực tế, không chỉ zoom trên màn hình.

## 5. Các phase và dependencies

| Phase | File | Phụ thuộc | User story dự kiến | Trạng thái |
|---|---|---|---|---|
| 01 | [phase-01-domain-reconciliation.md](phase-01-domain-reconciliation.md) | spec/audit | US-02 | planned |
| 02 | [phase-02-conceptual-model.md](phase-02-conceptual-model.md) | 01 | US-01, US-02, US-03 | planned |
| 03 | [phase-03-diagram-authoring.md](phase-03-diagram-authoring.md) | 02 | US-01, US-02, US-04 | planned |
| 04 | [phase-04-guide-and-validation.md](phase-04-guide-and-validation.md) | 03 | US-01, US-02, US-03, US-04 | planned |

Mapping theo spec: US-01 format; US-02 ownership/evidence/domain; US-03 tách conceptual model khỏi physical/logical implementation mapping; US-04 editable source và exports. Readability và guide validation là acceptance criteria xuyên suốt.

Review theo tầng: (1) entity/relationship inventory và discrepancy register; (2) conceptual model + mẫu notation một trang; (3) overview và hai trang phức tạp setup/delivery; (4) toàn bộ bộ hình và guide. Layout review không đồng nghĩa phê duyệt thay database.

## 6. Gap scan cần xác minh

| Gap từ scanner | Cách xử lý trong plan |
|---|---|
| Error handling P1 | Kiểm tra payment callback, answer sync/retry, scoring failure có trạng thái/history đúng scope; không thêm entity chỉ để chữa từ khóa thiếu |
| Permissions P1 | Lập ownership và visibility matrix theo sáu role; examiner blind scoring, Student result visibility, tenant boundary |
| Concurrency P2 | Kiểm tra uniqueness, retry/idempotency, assignment và revision là constraint nghiệp vụ/technical appendix; không vẽ lock kỹ thuật nếu SRS không yêu cầu |
| NFR baseline P2 | Trỏ tới baseline hiệu năng/availability trong SRS; không tuyên bố ERD chứng minh đạt tải hoặc uptime |
| Contradiction/semantic gap | Tenant–Organization, role catalog, quyền sở hữu package/question, snapshot, Host-trigger publish và UUID reference phải có evidence/disposition |

Scanner là điểm khởi đầu, không phải kết luận thiếu chức năng. Đánh giá gap theo nguồn và mức ảnh hưởng đến mô hình ERD.

## Design Constraints

Giữ dữ liệu lịch sử và quan hệ owner rõ ràng; không xóa assignment/history để đạt giới hạn hình. Không đưa dịch vụ ngoài (PayOS, Cloudinary, email, AI provider) thành user hoặc entity nội bộ nếu chỉ là actor tích hợp. Audit `aggregate_type`/`aggregate_id` là polymorphic reference; Notification `recipient_user_public_id` đến User là logical reference một loại target. Không biến những tham chiếu này thành physical FK khi chưa có constraint. Chỉ sửa file trong phạm vi cook được chọn, bảo toàn thay đổi unrelated.

## Quality and Testing State

| Hạng mục | Trạng thái |
|---|---|
| Implementation | not started |
| Quality gate trên thay đổi guide/hình | not evaluated |
| Testing | not started |
| `ck:cook` | not run |

Đây là documentation scope: không cần viết/chạy unit test cho backend. Khi thực hiện cần structural check XML, cross-reference, relation completeness, export consistency và visual inspection. Không dùng các check này làm bằng chứng database/runtime. Quyết định chạy `ck:quality` và các check tài liệu được ghi trước mỗi phase theo cook; lựa chọn tùy chọn không chặn việc lập plan hiện tại.

## 7. Rủi ro và lựa chọn

Hybrid notation dễ đọc sai optionality nếu marker đặt gần diamond thay vì entity: giảm bằng dictionary hai chiều và legend thống nhất. Conceptual model có thể khác implementation: giảm bằng nhãn source/status và appendix. Trang chấm/giám sát có thể dày: tách trang theo ngưỡng 12 entity. XML export phụ thuộc công cụ: ghi version draw.io và manifest revision khi thực hiện.

Mặc định đề xuất dùng draw.io, nhãn entity English nhất quán với source, mô tả/relationship tiếng Việt dễ đọc; A3 landscape. Có thể điều chỉnh ngôn ngữ nhãn, palette và bố cục sau khi người dùng xem mẫu trang. Những lựa chọn thẩm mỹ không làm trì hoãn plan này.

Handoff khi người dùng yêu cầu thực hiện: `/ck:cook --hard projects/plans/quang-srs-erd-chen-rework/plan.md`. Lệnh là đề xuất cho lượt sau; chưa được chạy trong lượt lập plan.
