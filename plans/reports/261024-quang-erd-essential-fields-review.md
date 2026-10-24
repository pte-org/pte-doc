# Mermaid essential-fields review — 2026-10-24

Theo yêu cầu cuối cùng của người dùng, chỉ bổ sung field thực sự quan trọng, không đưa toàn bộ cột database vào ERD. Tác vụ tạo/lưu Draw.io đã dừng. Không sửa các slide Canva đã lưu hoặc code/schema ứng dụng.

## Deliverable

[Bộ source Mermaid được khuyến nghị để Review 2](../quang-pte-org-review2-erd/mermaid-essential-fields/README.md).

Giữ đúng ba nhóm: core, business details, technical mapping. Có 20 logical Mermaid views và một conceptual overview được giữ nguyên. Hai core logical views bao phủ 21 bảng khác nhau; các domain views bao phủ 93 bảng. Không tính bảng lặp lại là bảng mới.

## Field selection

- 772/1443 cột source được giữ trên 93 bảng; đây là lựa chọn thiết yếu, không phải full schema.
- Giữ id/public_id, toàn bộ các tuple tham chiếu đã kiểm chứng và các khóa unique ghép không điều kiện có tên cột đơn giản.
- Bổ sung tên/mã nghiệp vụ, tenant/owner cần thiết, trạng thái và mốc thời gian thực hiện nghiệp vụ; giữ payload/điểm/nguồn chấm/snapshot báo cáo khi cần giải thích luồng thi.
- Lược bỏ audit lặp lại, lease/claim/fingerprint/runtime metadata ngoài nhu cầu giải thích từng bảng. Auth, log và job vẫn giữ các field thể hiện chức năng chính của chính chúng.
- Không tạo field không tồn tại, không gắn nhãn FK cho logical UUID reference, không biến khóa unique ghép thành uniqueness của từng thành phần.
- Mỗi bảng dùng cùng một tập field tại mọi logical view. File field-selection.md/JSON liệt kê toàn bộ field giữ/lược bỏ.

## Verification

- Replay inventory vào thư mục tạm từ source hiện tại, so sánh bằng nhau với inventory hiện có: 90 JPA entities, 93 tables; backend HEAD 0b80426bcbed4874bb7d78d90c086373b005585f.
- Đối chiếu từng tên cột, kiểu SQL, nullable, PK/UK/FK và tập field của từng bảng.
- Đối chiếu 188 relationship instances trong 20 logical views với register, bao gồm cardinality và mọi thành phần tuple liên kết.
- Mermaid 12.2.0 parser chấp nhận cả 21 nguồn. Xem [validation.json](assets/261024-quang-essential-fields/validation.json).
- Independent review: APPROVED, không còn blocking findings; reviewer kiểm tra semantic/key selection và xác minh bundle mới không ảnh hưởng baseline. Baseline validator vẫn PASS 18 diagrams/36 exports/93 dispositions. Parser PASS do main agent thực thi, reviewer không chạy lặp lại.
- Không render toàn bộ bản essential ra ảnh trong tác vụ này vì người dùng yêu cầu Mermaid code. Không chạy application tests hoặc live DB checks.

Sau yêu cầu dọn file ngày 2026-10-24, Mermaid được giữ local và không commit; các script Python, ảnh/SVG, Draw.io, ZIP và receipt cũ đã được xóa. Các kết quả parser/render phía trên là lịch sử kiểm tra trước khi dọn. Tài liệu và metadata vẫn được giữ để đối chiếu nguồn. Dictionary/model metadata đã cập nhật cùng tập 772 field thiết yếu.

## Kiểm tra sau khi dọn

- 115 file đã rà soát được chuyển vào Thùng rác; 44 Mermaid local giữ nguyên SHA256 và được Git bỏ qua theo quy tắc có phạm vi.
- Dictionary và model metadata khớp 93 bảng, 772 field được chọn và 135 tuple quan hệ.
- Kiểm tra 437 liên kết tài liệu đều hợp lệ; không còn ảnh, SVG, Draw.io, ZIP, Python hoặc cache Python trong phạm vi bàn giao.
- Không đổi backend, migration hoặc Canva trong đợt dọn. Repository chỉ giữ tài liệu và metadata; clone mới không có các file Mermaid local.
