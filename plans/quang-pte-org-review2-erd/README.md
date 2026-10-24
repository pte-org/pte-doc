# PTE Org — ERD Review 2

Bộ tài liệu đối chiếu ERD với source PTE Org: 90 JPA entities, 93 bảng và 135 quan hệ đã đăng ký. Bộ field thiết yếu giữ 772/1443 cột source để giải thích nghiệp vụ và các khóa liên kết.

## Tài liệu chính

- [Field thiết yếu và cách đọc ERD](mermaid-essential-fields/README.md).
- [Field được giữ/lược bỏ của từng bảng](mermaid-essential-fields/field-selection.md) và [metadata lựa chọn](mermaid-essential-fields/field-selection.json).
- [Dictionary entity và quan hệ](artifacts/dictionary.md).
- [Class/table/source mapping](artifacts/technical-mapping.md).
- [Quy ước PK/UK/FK, cardinality và logical reference](artifacts/notation.md).
- [Các điểm đã đối chiếu để tránh hiểu sai](artifacts/discrepancy-register.md).
- [Phạm vi core/detail](artifacts/scope-decisions.md).
- [Source baseline](artifacts/source-baseline.md), [inventory](artifacts/inventory.json) và [relationship register](artifacts/relationships.json).
- [Kết quả kiểm tra field thiết yếu](../reports/261024-quang-erd-essential-fields-review.md).
- [Bàn giao Canva](../reports/261024-quang-canva-erd-review.md).

## Phân nhóm

| Nhóm | Phạm vi |
|---|---|
| Core | Một conceptual overview 11 khái niệm; một view 8 bảng; hai core logical views bao phủ 21 bảng khác nhau |
| Business details | 10 view, 62 bảng nghiệp vụ khác nhau |
| Technical mapping | 7 view, 31 bảng kỹ thuật khác nhau |

Entity lặp lại giữa các view là cùng một bảng, không cộng thêm vào tổng số bảng. Conceptual Organization gộp Tenant/Organization chỉ ở mức khái niệm; logical ERD giữ hai bảng riêng.

## File lưu local

Theo yêu cầu commit ngày 2026-10-24, các file Mermaid `.mmd` được giữ nguyên ở máy và loại khỏi Git bằng quy tắc có phạm vi trong `.gitignore`. Folder `mermaid-essential-fields/` ở máy có 21 nguồn được khuyến nghị sử dụng; folder `artifacts/groups/` giữ các nguồn trình bày trước đó.

Repository chỉ lưu tài liệu và metadata đối chiếu. Các bản render SVG/PNG, ảnh chụp Canva, file Draw.io, ZIP, script Python, cache, plan cũ và receipt kiểm tra trung gian đã được dọn. Clone repository sẽ không có Mermaid local hoặc các file sinh ra này.

## Giới hạn kiểm tra

Metadata được đối chiếu source migration/JPA tại baseline; đây không phải kết quả xác minh live database. Logical UUID reference không tự chứng minh target row tồn tại. Các field nghiệp vụ quan trọng và toàn bộ tuple liên kết đã được giữ; các field lược bỏ vẫn tồn tại trong database. Không thay đổi backend, schema hoặc nội dung Canva khi dọn file.
