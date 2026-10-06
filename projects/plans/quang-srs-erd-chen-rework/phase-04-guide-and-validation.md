# Phase 04 — Cập nhật guide và validation cuối

**Status:** planned. **Depends on:** phase 03. **Stories:** US-01, US-02, US-03, US-04.

## Mục tiêu

Thay guide bằng hướng dẫn đọc/vẽ đúng convention đã chốt, dẫn tới bộ hình và dictionary đã được kiểm chứng.

## Tasks

- [ ] Rewrite section notation theo hybrid Chen–Crow's Foot; giải thích ba shapes/màu, attribute và marker optionality.
- [ ] Thay đề xuất ERD entity-table bằng conceptual diagrams đã tạo; nếu giữ physical mapping minh họa, đưa vào appendix và gắn nhãn rõ.
- [ ] Sửa yêu cầu “M:N bắt buộc bảng liên kết” thành quy tắc conceptual M:N vs business associative entity vs pure physical join.
- [ ] Điều chỉnh Tenant/Organization và Role theo evidence/disposition, ghi ranh giới implemented/target khi cần.
- [ ] Cập nhật cấu trúc 1 overview + 6 domain pages và split suffix; tách rõ exam setup khỏi exam delivery.
- [ ] Thêm entity/relationship dictionary và technical appendix; ghi ownership, nguồn, UUID/logical/polymorphic reference, snapshot và constraint liên quan.
- [ ] Gắn đường dẫn tương đối tới `.drawio`, SVG/PNG và tài liệu kèm; mô tả cách sửa source/xuất lại, tránh export lệch revision.
- [ ] Đối chiếu guide với SRS actors, FR/BR, exam lifecycle, retry/failure, visibility và NFR baseline; không tạo yêu cầu ngoài scope.
- [ ] Chạy checks tài liệu, XML/manifest/cross-reference, UTF-8 và `git diff --check`; review toàn bộ diff đúng phạm vi.
- [ ] Kiểm tra link local, render Markdown và xem từng hình ở kích thước in; sửa lỗi đọc/xuất trước khi bàn giao.
- [ ] Ghi validation report, hạn chế và trạng thái từng criterion; cập nhật phase state dựa trên bằng chứng thực tế.

## Design Constraints

Chỉ sửa guide/bộ tài liệu ERD đã xác định, bảo toàn unrelated worktree changes. Không thay SRS hoặc code để che conflict phát hiện khi viết guide. Không trộn thời điểm target/conceptual với “production đã chứng minh”. External service chỉ ở Context/Integration Diagram khi phù hợp, không ép thành dữ liệu nội bộ. Giữ audit/history để truy vết hành động và nội dung đề/điểm đã dùng.

## Acceptance Criteria

1. Guide gọi convention hybrid đúng tên và chỉ tới bộ hình editable + exports; mọi relative link tồn tại.
2. Không còn yêu cầu mọi M:N phải thành pure join trong conceptual ERD; không còn role table/physical FK claim không có bằng chứng.
3. Mỗi quan hệ đã vẽ có dictionary và evidence đủ hai chiều; owner/participation condition thống nhất trên các trang.
4. Tenant–Organization, organization entitlement, platform question bank, immutable snapshot, Host-trigger scoring/review/publish được mô tả nhất quán với disposition.
5. Structural, visual và diff checks có receipt; không claim database, HTTP authorization, Windows client behavior hoặc tải hệ thống đã được kiểm thử.
6. Chỉ scope tài liệu có thay đổi; final report chỉ rõ file nào đã đổi, checks đã chạy và issue còn mở.

## Deliverables và evidence

Guide cập nhật tại `projects/templates/pte-prep-srs-erd-guide.md`; bộ `erd/`, dictionary/appendix; `validation-report.md` với command/công cụ, output summary, revision và manual review evidence. Nếu còn issue ảnh hưởng business/cardinality thì báo chưa đủ điều kiện hoàn tất, không đặt passed bằng suy luận.

## Quality and Testing State

- Quality: **not evaluated**.
- Testing: **not started**.
- Unit tests: không yêu cầu.
- Planned checks: Markdown/link validation, XML/manifest, dictionary coverage, A3 visual inspection, `git diff --check`, final scoped review.
- `ck:quality`/cook optional choices: chưa chọn; ghi actual result khi chạy, không đặt approved ở thời điểm plan.

## Exit và bàn giao

Bàn giao bộ tài liệu đã đối chiếu và validation report. Cập nhật completion chỉ khi tiêu chí chấp nhận có bằng chứng; plan này chưa chạy phase nào và chưa thay guide.
