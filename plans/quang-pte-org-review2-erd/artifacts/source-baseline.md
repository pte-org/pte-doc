# Source baseline — PTE Org ERD

Ngày kiểm tra: 2026-10-23 (Asia/Bangkok).

| Repository | Branch | SHA | Worktree trước triển khai |
|---|---|---|---|
| pte-api | dev | 0b80426bcbed4874bb7d78d90c086373b005585f | Untracked .playwright-mcp/ |
| pte-doc | dev | 0e147a22f96745d84a5792e3b8eda759dc54bd63 | Xóa spec/plan ERD cũ theo yêu cầu; bundle mới, artifact/quality cũ untracked |

Đã đọc ../AGENTS.md, spec mới, mẫu guide ERD hiện có và report verification khác để giữ convention. Backend chỉ được đọc. Không có code, migration hay database được thay đổi.

Source roots đã xác nhận: ../pte-api/app/src/main/java/com/pte và ../pte-api/app/src/main/resources/db/migration.

Inventory mới: 90 JPA entities, 93 bảng tồn tại theo source DDL, 126 migration files, phiên bản cao nhất V129. Không giả định số phiên bản bằng số file. Ba bảng không có @Entity: user_roles, exam_session_selected_skills, notification_inbox_snapshots. Không entity nào thiếu CREATE TABLE còn tồn tại.

Scanner áp dụng CREATE/ALTER/DROP và UNIQUE INDEX theo thứ tự số migration; giữ nguyên định nghĩa và vị trí nguồn. Hai bảng nghiệp vụ đã drop và hai bảng seed tạm được ghi riêng. DO blocks được đánh dấu conditional_file để đối chiếu thủ công; đây không phải kết quả chạy migration trên PostgreSQL. Không có xác minh database live.

Sau đợt dọn ngày 2026-10-24, script Python và artifact render không còn được giữ theo yêu cầu người dùng. Inventory và evidence source vẫn được lưu để đối chiếu; Mermaid chỉ giữ local.
