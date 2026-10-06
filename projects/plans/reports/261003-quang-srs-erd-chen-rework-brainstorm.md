# Rà soát và brainstorm: ERD PTE Org theo ảnh mẫu

**Ngày:** 2026-10-03
**Phạm vi:** Đề xuất và kế hoạch tài liệu, chưa thay guide hoặc vẽ bộ hình.

## User's Direction

Người dùng muốn xem lại kiến trúc và ý tưởng hệ thống, rồi đưa ra plan mới cho `pte-prep-srs-erd-guide.md`; hình mẫu gồm thực thể chữ nhật, quan hệ hình thoi và thuộc tính oval. Hướng trình bày đã được cung cấp rõ, không cần mở lại việc chọn giữa hình bảng và hình Chen.

## Ideas Explored

1. Chỉ đổi màu/shape của Mermaid ERD: ít công nhưng vẫn giữ bảng và FK làm trung tâm; không đạt ảnh mẫu.
2. Chen thuần với số min/max thay đầu nối: phù hợp conceptual nhưng khác ký hiệu cardinality trong ảnh.
3. **Đề xuất:** hình Chen + đầu nối Crow’s Foot theo ảnh, có legend và dictionary min/max hai chiều; conceptual là hình chính, database mapping là phần riêng.
4. Vẽ một trang đủ tất cả bảng: gây quá tải vì mỗi attribute cần một oval; bỏ hướng này.
5. Chỉ conceptual, bỏ mọi mapping kỹ thuật: dễ đọc nhưng khó giải thích snapshot/assignment/UUID reference; giữ mapping để đối chiếu.
6. Thiết kế lại schema theo hình mới: vượt yêu cầu, có nguy cơ đổi nghiệp vụ vì lý do trình bày; không nằm trong plan.

## Kiến trúc và ý tưởng hệ thống cần giữ

PTE Org bán quyền sử dụng cho tổ chức; Student dùng tài khoản do tổ chức cấp. Platform quản lý kho câu hỏi, task type, Score Template và Plan. Host quản lý roster, chương trình/lớp, mua/kích hoạt gói, chuẩn bị kỳ thi, phân công và công bố kết quả. Proctor/Examiner có phạm vi theo assignment; Student có phạm vi theo bài làm và báo cáo của mình.

Kiến trúc được ADR mô tả là modular monolith: Spring Boot theo bounded context; module giao tiếp qua facade trong tiến trình, RabbitMQ hỗ trợ công việc chậm như AI/email. ERD mô tả dữ liệu và ownership, không biến module, queue hoặc dịch vụ thành entity. Web quản trị và Windows exam client là kênh truy cập, không là bảng dữ liệu. Đây là mô tả thiết kế từ ADR/spec; không phải chứng nhận runtime hay độ tuân thủ toàn source.

Nội dung cần bảo toàn gồm revision câu hỏi, nội dung exam đã khóa, nội dung pin cho lượt thi và câu trả lời thực tế. Chấm điểm và publication là vòng đời riêng: submit không mặc định chấm; Host kích hoạt chấm, duyệt/chọn nguồn rồi publish. Điểm không được coi là cột trạng thái trong Attempt chỉ vì xuất hiện sau Attempt trong luồng nghiệp vụ.

## Step 2 Gap Scan — xác thực cảnh báo

| Cảnh báo scanner | Đánh giá theo nội dung thật | Việc đưa vào plan |
|---|---|---|
| P1 thiếu error handling | Không đúng ở mức hệ thống: spec BR-044–048 mô tả callback lặp, AI retry, media hết hạn, notification lỗi; guide đã nhắc callback | Bổ sung traceability lỗi → dữ liệu trạng thái, dedup, audit; không tự thêm error entity |
| P1 thiếu permissions | Không đúng: guide §3/§8 và spec BR-001–006 có role/ownership | Làm rõ global User có tenant null, User tenant-scoped, access qua assignment và publication |
| P2 thiếu concurrency | Spec BR-021/026 và NFR-02/03 đã có; guide chưa thể hiện đủ ràng buộc liên quan | Ghi invariant redeem/callback/enrollment/assignment/answer; phân biệt cardinality với uniqueness và transaction protection |
| P2 thiếu NFR baseline | Spec §7 có 17 baseline, một số còn TBD | Liên kết mục tiêu capacity/security/audit/recovery; không tuyên bố ERD chứng minh đạt mục tiêu |

## Pattern 7 — contradictions và semantic gaps

| Mức | Vấn đề | Cách xử lý |
|---|---|---|
| P1 | Guide §5.1 và overview nói Tenant 1:N Organization, source có unique `organizations.tenant_id` | Baseline nghiệp vụ một tổ chức; mapping tối đa một Organization/Tenant, onboarding thành công tạo đủ cặp |
| P1 | Bắt buộc tách mọi M:N thành entity và hiển thị PK/FK ở conceptual | Chỉ bắt buộc bảng liên kết ở relational mapping; assignment có lifecycle riêng vẫn là entity nghiệp vụ |
| P1 | Guide cho `AttemptAnswer 1:N ExaminerAnswerScore`, source unique `answer_public_id` | Mô tả tối đa một điểm Examiner hiện hành/answer; nhiều assignment không đồng nghĩa nhiều bản điểm; lịch sử ở audit/revision khi có bằng chứng |
| P1 | Chain dữ liệu bị trình bày như quan hệ trực tiếp hoặc thứ tự xử lý | Lập relationship register để phân biệt provenance, FK, UUID reference và projection; vẽ lifecycle riêng nếu cần |
| P2 | `Role` được mô tả như bảng dù source dùng enum và `user_roles` element collection | Có thể giữ Role ở conceptual; mapping ghi enum + collection, không hứa bảng roles |
| P2 | Dictionary gọi `public_id` là PK database | Tách business/public identifier khỏi internal SQL primary key; BaseEntity có cả hai |
| P2 | UUID reference một loại dữ liệu được đặt chung dưới polymorphic | Chỉ `type + id` có nhiều target mới là polymorphic; UUID sang Answer/User là logical reference |
| P2 | Một số tên như `QuestionRevision`, `LoginCredential`, `ExamPolicy` có thể chỉ là abstraction hoặc dữ liệu nhúng | Kiểm chứng tồn tại, cách lưu và vòng đời trước khi gọi là entity hoặc table hiện có |
| P2 | `1:N` ở danh sách quan hệ so với `0..N` trong Mermaid, không gắn lifecycle | Ghi min/max cả hai chiều cho draft/active/published khi khác nhau; không bắt entity cha mới tạo phải có con |
| P2 | ADR cũ có actor Lecturer/ProgramCoordinator, class branch và mô tả identity đã thay đổi | Spec hiện hành và source phải được ghi cạnh nhau; không tự đưa actor/chi nhánh cũ về baseline |
| P2 | Overview gộp quá nhiều bảng kỹ thuật | Một overview + sáu nhóm domain, chia thêm trang nếu cần; dictionary giữ chi tiết |

## Open Questions

Không có câu hỏi chặn việc viết plan. Mặc định bám đúng hình mẫu, dùng draw.io, tách conceptual và mapping. Retention, AI provider, recovery khi tạo đề lỗi và kế hoạch vận hành còn TBD; RPO tối đa 15 phút và RTO tối đa 1 giờ là mục tiêu đã chốt, chưa có bằng chứng đạt được. Các TBD không phải lý do trì hoãn bản kế hoạch. Conflict giữa ý tưởng nhiều Examiner và uniqueness điểm hiện hành phải ghi nhận trước khi vẽ phần scoring; không suy diễn thành yêu cầu schema mới.

## Source evidence và sửa đổi cụ thể cần đưa vào inventory

Các đường dẫn source dưới đây tính từ root `pte-org`; spec/guide tính từ `pte-doc`. Line là vị trí tại ngày rà soát, phải đọc lại khi thực hiện nếu source đã đổi.

| Quan hệ/khái niệm | Bằng chứng hiện tại | Kết luận cho kế hoạch |
|---|---|---|
| Tenant/Organization | `pte-api/app/src/main/java/com/pte/tenancy/domain/Organization.java:29`; `tenancy/internal/service/TenantLifecycleService.java:87` dưới cùng package root | Unique tenant_id giới hạn tối đa một Organization; lifecycle provisioning tạo đúng một. Không lấy `@ManyToOne` làm bằng chứng cho 1:N khi còn unique constraint |
| User/Role | `pte-api/app/src/main/java/com/pte/identity/domain/User.java:69–72`; `identity/domain/Role.java` | Role là enum, collection table `user_roles`; Role conceptual không tương đương bảng roles |
| Identifier | `pte-api/app/src/main/java/com/pte/shared/domain/BaseEntity.java:30–34` | SQL PK Long id; public UUID là identifier bên ngoài, không tráo hai khái niệm |
| Question/Media | `pte-api/app/src/main/java/com/pte/itembank/domain/Question.java:98–102` | Tách “uses audio prompt” và “uses image prompt”, mỗi Question 0..1 reference mỗi loại; chiều media có thể được nhiều Question dùng, không vẽ danh sách media tùy ý |
| Question revision | `pte-api/app/src/main/java/com/pte/itembank/domain/Question.java:69–79` | Revision hiện nằm trên row Question bằng group/number/supersedes/current; abstraction phải ghi mapping |
| Session/Form/Snapshot | `pte-api/app/src/main/java/com/pte/session/domain/ExamSession.java:62`; `session/domain/ExamForm.java:25–30` dưới cùng package root | Session và Form có snapshot reference; Form có FK tới Session. Cần kiểm tra generation/reuse policy trước khi chốt chiều ngược; UUID nullable không chứng minh 1:1 |
| Pinned item/Answer | `pte-api/app/src/main/java/com/pte/attempt/domain/AttemptAnswer.java:27–28`; `attempt/domain/PinnedItem.java:34–35` dưới cùng package root | Unique attempt + pinned item, item thuộc nội dung pin của một attempt: 0..1 answer/item trong đúng owner scope; không đọc ManyToOne thành được trả lời nhiều lần |
| Attempt/Pin | `pte-api/app/src/main/java/com/pte/attempt/domain/PinnedExamSnapshot.java:35–36` | Pin thuộc một Attempt; thời điểm trước khi bắt đầu có thể chưa có pin cần đối chiếu lifecycle |
| Answer/Examiner score | `pte-api/app/src/main/java/com/pte/scoring/domain/ExaminerAnswerScore.java:26` | 0..1 current Examiner score/Answer; nhiều assignment không tự tạo mô hình nhiều bản điểm |
| Answer/Scoring record | `pte-api/app/src/main/java/com/pte/scoring/domain/ScoringAnswer.java:46–47` | Bổ sung logical Answer → 0..1 ScoringAnswer; ghi owner tenant/session/attempt, không gọi là JPA FK |
| Attempt/Report | `pte-api/app/src/main/java/com/pte/reporting/domain/AttemptReport.java:35–36,59–60,71–87` | 0..1 report/Attempt; report lưu snapshot và publication metadata, không phải view tính lại từ điểm live |

Nguồn spec để trace gap scanner: `projects/pte-org-srs/spec.md:512–517` permissions, `:541,549` idempotency/concurrency, `:579–583` errors, `:585–605` NFR. Các dòng này chứng minh có yêu cầu, không chứng minh đã triển khai đầy đủ.

Các mâu thuẫn cần reconcile bổ sung: guide Program thuộc Organization nhưng Mermaid nối Tenant; Snapshot và Pin có optionality khác nhau giữa prose và Mermaid; license/subscription phải đọc được cả purchase và redeem path; platform user có tenant null; report phải giữ nguồn điểm và publication snapshot. ADR-007 cũ còn tên role ngoài sáu role hiện hành và mô tả identity/import đã thay đổi, nên chỉ dùng phần được spec/source hiện tại xác nhận.

## Risks

- Hình oval làm tăng diện tích: dùng giới hạn entity và attribute, chia trang thay vì thu font.
- Nhiều nguồn có tuổi khác nhau: ghi path/line và commit khi chốt inventory; không coi ADR cũ là mô tả runtime hiện tại.
- Công cụ export có thể đảo cardinality hoặc bỏ font: rà XML, preview SVG/PNG và câu đọc hai chiều.

## Review kế hoạch — 2026-10-03

Independent red-team/code-review: **APPROVED cho phạm vi bản kế hoạch** sau khi sửa mapping US-03/US-04 và làm rõ recovery TBD khác với mục tiêu RPO/RTO đã chốt. Không còn finding MEDIUM/HIGH/BLOCKER trong bản được review. Đây không phải quality approval cho guide hoặc sơ đồ tương lai; các phase vẫn planned, quality chưa đánh giá và testing chưa bắt đầu.

Spec: `projects/plans/quang-srs-erd-chen-rework/spec.md`. Plan cùng thư mục. Chỉ triển khai tài liệu và bộ sơ đồ sau khi chuyển sang bước thực hiện; không có thay đổi database/API trong kế hoạch này.
