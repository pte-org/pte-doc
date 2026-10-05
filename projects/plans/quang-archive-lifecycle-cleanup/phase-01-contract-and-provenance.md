# Phase 01: Contract, provenance và schema

Status: completed (contract/schema/policy). Stories: P1 safe deletion/history, P2 clear lifecycle. Implementation of readers/writers belongs to phases02/03. PostgreSQL migration rehearsal is phase05.

## Tasks

- [x] User xác nhận ba lựa chọn: lifecycle-only; soft delete + audit; outstanding-code guard thay snapshot. Chưa bắt đầu implementation.
- [x] Đóng băng transition table trong plan; define deleted, known-history, never-published, unknown và allowed role.
- [x] Inventory writer/readers Plan: list/get/update/activate/archive, issue/redeem, order creation/payment activation, subscription lookup. Inventory Question: create/edit/revision/submit/approve/publish/archive/unarchive, list/stats/get/freeze, assessment blueprint/snapshot/generation.
- [x] Xác định reference contract: mọi trạng thái order/subscription/license ngăn Delete plan; Question revision/blueprint/snapshot source references ngăn delete theo policy. Không chỉ active references; history cũng quan trọng.
- [x] Dùng public facade cho assessment reference query; kiểm tra graph dependency/module tests trước khi để itembank phụ thuộc ngược assessment. Nếu tạo cycle, dùng interface policy port hoặc guard orchestration ở boundary hợp lệ, không import internals.
- [x] Chọn Question provenance marker tri-state: nullable everPublished tương đương UNKNOWN/false/true, hoặc enum được chuẩn hóa. New row false; approve/publish true; unarchive giữ true. Migration legacy APPROVED true; các state thiếu bằng chứng giữ null. Không default false cho legacy drafts.
- [x] Xác định thêm marker có cần cho Plan không: hiện lifecycle không có ARCHIVED→DRAFT nhưng vẫn phải kiểm tra references; không thêm history schema không cần thiết.
- [x] Chọn migration Flyway tiếp theo sau khi kiểm tra toàn repo/branch; additive nullable column và indexes phục vụ guards, không mass state rewrite.
- [x] Đóng contract DELETE204/envelope, error constants, capabilities và batch guard lookup. Định nghĩa repeat delete + role/scope checks và no duplicate audit.
- [x] Chọn thống nhất lock order cho tất cả reference writers; delete guard đơn lẻ không đủ chống TOCTOU.
- [x] Chốt audit fields actor/resource/reason/action/time; không token/password/media secret.

## Files / surfaces

`Question.java`, `QuestionRepository.java`, `QuestionResponse.java`; billing Plan/response/repositories; module public facades; shared API client parser. `app/src/main/resources/db/migration` cho migration mới. Constants thuộc module itembank/billing/enrollment.

Không chốt tên class mới của reference policy trước khi inventory chứng minh dependency graph.

## Design Constraints

Preflight: Spring constructor DI, module-owned DomainException/constants, AuditLogService in originating transaction; Question already has @Version. Assessment writers freeze APPROVED/current questions, so a proven never-published draft cannot acquire an assessment reference through existing APIs; no reverse module dependency added. Selected DELETE204; raw-response parser supports empty body. Consent: tests=yes, quality=yes across all phases; standard cook, not TDD.

- UNKNOWN fail closed với Delete; DRAFT không thay thế provenance.
- Không hard-delete, không trash/restore, không delete Cloudinary media; Question đã có @Version.
- Không circular module dependency; không thêm generic lifecycle framework cho toàn platform.
- Chỉ thêm fields/index thực sự cần, không sao chép original database credentials vào fixture.

## Tests to Write First (đề xuất TDD)

1. Migration trên legacy APPROVED/DRAFT/ARCHIVED giữ đúng known/unknown, không mất rows.
2. New draft neverPublished; publish rồi archive/unarchive không mất history marker.
3. Capabilities mất/unknown ⇒ UI/server không mở Delete.
4. Client parser204 hoặc envelope đúng contract đã chọn; existing endpoints không đổi.
5. Module boundary test không cycle khi thêm usage-query facade/port.

## Exit Criteria

Contract + inventory + migration policy được duyệt; mọi reference writer có phương án serialization; ba lựa chọn không còn unresolved. Nếu chưa đủ, không code destructive endpoints.

## Quality and Testing State

- User test choice: yes, all phases; standard cook without --tdd.
- Quality: approved; [report](quality/phase-01-contract-and-provenance-quality-report.json), [receipt](quality/phase-01-contract-and-provenance-receipt.json).
- Testing: passed, 3 policy tests; [report](tests/phase-01-contract-and-provenance-test-report.json). Compile passed. Migration/integration gate remains phase05.
