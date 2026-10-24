# Discrepancy register — mô hình đã đối chiếu

Ngày: 2026-10-23. Status các quyết định dưới đây: current-source. Không dùng phán đoán từ sơ đồ cũ làm evidence.

| ID | Điểm dễ hiểu sai | Quyết định ERD | Nguồn trong pte-api |
|---|---|---|---|
| D01 | Tenant có nhiều Organization vì JPA ManyToOne | Tenant 1 -> Organization 0..1 ở storage; conceptual Organization gộp hai lớp | V3__tenancy.sql:33; V33__provision_single_organization_per_tenant.sql:34 |
| D02 | Student/Host/Role là các bảng độc lập | Student/Host là roles của User; user_roles là ElementCollection | identity/domain/User.java:77–82; V2__identity.sql:40 |
| D03 | public_id là PK hoặc mọi UUID là FK | id BIGINT PK; public_id UUID UK, FK phải có REFERENCES | shared/domain/BaseEntity.java:32–39; V2__identity.sql:10–11 |
| D04 | Mỗi ca/học sinh chỉ có một attempt | Cho phép nhiều attempt_number; uniqueness cũ đã drop | V65__exam_scope_retry_and_attempt_numbering.sql:30–43 |
| D05 | Ca luôn có snapshot từ khi tạo | snapshot_public_id nullable từ V42; ExamForm có snapshot riêng; core chỉ mô tả main snapshot reference | V42__exam_orchestration_core.sql:1–3,79–105 |
| D06 | Answer nối trực tiếp Question hiện tại | Answer -> PinnedItem -> PinnedExamSnapshot; provenance của snapshot qua source_question_public_id | V9__attempt.sql:33–95; V7__assessment.sql:47–55; attempt/internal/service/SnapshotPinService.java:80–99 |
| D07 | ScoringAnswer.answer_public_id là đa hình hoặc DB FK | Là UUID logical reference tới AttemptAnswer; unique một bản chấm/answer; ingest lấy SubmittedAnswerView | V10__scoring.sql:12; scoring/internal/service/ScoringIngestService.java:54–80 |
| D08 | Một answer có nhiều ExaminerAnswerScore | Unique answer_public_id giới hạn 0..1; quan hệ composite tới ScoringAnswer là physical FK | V58__examiner_scoring_foundation.sql:86; V59__enforce_examiner_scoring_references.sql:24–40 |
| D09 | Report là FK trực tiếp tới từng bản điểm | Report tham chiếu attempt; report_snapshot_json là projection công bố, không sinh bảng mới | V13__reporting.sql:13; V62__examiner_score_selection_and_report_snapshots.sql:13–23; reporting/internal/service/ReportService.java:89–96 |
| D10 | Chỉ cần CREATE TABLE đầu tiên để suy cardinality | Replay drop constraint/index, nullable changes, composite unique; partial uniqueness không dùng như global unique | V40/V44/V49/V51/V65/V90/V92/V107; inventory.json giữ đầy đủ evidence |
| D11 | Nét đứt là logical UUID, nét liền là FK | Mermaid nét đứt là non-identifying. Vì entity có surrogate ID độc lập, dùng nét đứt; loại FK/logical xem register và key FK | https://mermaid.js.org/syntax/entityRelationshipDiagram.html |

Logical detail dùng bounds của storage: parent min=0 cho reference không có DB FK; service nghiệp vụ thường yêu cầu parent tồn tại, nhưng UUID NOT NULL riêng lẻ không chứng minh điều này. Không diễn giải min=0 thành permission tạo dữ liệu orphan. Với NOT VALID FK, giữ thông tin có constraint nhưng không giả định dữ liệu cũ đã validate.

Audit aggregate_type/id và audience source_type/id là polymorphic references, giữ mapping thay vì nối tới tất cả targets. Từ bổ sung ngày 2026-10-24, notification, support và các bảng kỹ thuật khác được vẽ trong 7 trang riêng ở nhóm 03. Practice/rubric thuộc business detail; kỹ thuật job/outbox không đưa vào overview.

TBD: dữ liệu live có orphan/legacy chưa validate hay không; không kiểm tra production DB trong phạm vi này. Không còn quan hệ chưa xác minh được vẽ như baseline.
