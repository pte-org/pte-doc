# Research alternatives và red-team của plan

Ngày: 2026-10-05. Review kiểu manual, dựa local source; không có researcher/planner/reviewer subagent tool trong session, không claim independent agent approval. Chưa review implementation vì chưa code.

## Primary: lifecycle-specific guarded soft delete

Giữ enums/routes archive để bảo toàn lịch sử và giảm breaking change; thêm DELETE draft với capability + exact server guards; Program/Class đổi wording nhưng giữ persistence. Hợp với modularmonolith và inherited deleted column.

Trade-off: phải audit deleted filtering toàn read/write surface; legacy historyunknown fail closed. Guards ngăn mã lưu hành khiến admin cần xử lý outstanding codes trước retirement. Đây là lựa chọn user đã chốt trong đợt này, không snapshot mới.

## Alternative: generic trash/restore và hard delete

Trash+restore tạo thêm lifecycle, retention, permissions, media cleanup và revision restoration, vượt nhu cầu bỏ archive dư. Hard delete ít rows hơn nhưng tăng rủi ro mất provenance/media/reference lịch sử. Không chọn; có thể đề xuất sau với spec riêng.

Snapshot issuance giải quyết outstanding entitlement tốt hơn dài hạn nhưng cần schema/activation/backfilllegacy rộng hơn. Đợt này user chọn dependency guard, không mở rộng snapshot.

## Red-team findings / adjudication

| ID | Finding | Adjudication / plan response |
|---|---|---|
| R01 | DRAFT sau unarchive không chứng minh chưa publish. | ACCEPTED: tri-state provenance, UNKNOWN block, no false backfill; phase01/03. |
| R02 | Question đã có @Version, thêm version global sẽ gây thay đổi rộng. | ACCEPTED: reuse entityversion, không sửa BaseEntity; phase03. |
| R03 | List exclude deleted nhưng directget/freeze/publish vẫn cho đọc/sửa lại. | ACCEPTED: inventory tất cả writers/readers và nativequeries; phase01/02/03. |
| R04 | Reference exists check không đủ nếu writer tạo reference cùng lúc. | ACCEPTED: coherent locking/state contract ở mọi involvedwriter; racegate phase05. |
| R05 | Plan eligibilitycheck ngoài REQUIRES_NEW save không bao phủ issue/archive race. | ACCEPTED: transaction boundary collisionretry ngoài failedtx; phase02. |
| R06 | itembank gọi assessment có thể tạo modulecycle vì assessment đang dùng itembank. | ACCEPTED: public policyport/orchestration hợp graph, modulegate phase01. Nếu chưa giải quyết, phase03 stop. |
| R07 | Archived legacy không chắc từngpublish, cũng có thể archive draft. | ACCEPTED: không backfilltrue theo ARCHIVED đơn thuần; UNKNOWN policy. |
| R08 | Gỡ Archive draft trước có DELETE làm mất cleanup. | ACCEPTED: backend/contracts trướcUI; rollout order và clientlegacy409. |
| R09 | Program/Class Archive là softremoval, bỏ action sẽ mất cleanup. | ACCEPTED: textRemove, giữ routes/data semantics. |
| R10 | DELETE204 parser có thể sai với ApiResponse app. | ACCEPTED: phase01 contracttest; dùng envelope nếu required, không tự khẳng định204 đãsupported. |
| R11 | Ba app/module cleanup có thể nở thành sửa toàn45 unhappycases. | ACCEPTED: dedicatedspec/out-of-scope; user đãchọn lifecycle-only. |
| R12 | Conservative revisionguard cản delete revision draft chưadùng. | NOTED: limitation cóchủđích phase đầu; không rewiring graph khôngđượcduyệt. Mở support sau nếu cóusecase rõ. |

## Nguồn khảo sát

- [Question.java](../../../../pte-api/app/src/main/java/com/pte/itembank/domain/Question.java): version, revisiongroup/supersedes, chưa có publishprovenance riêng.
- [ItembankService.java](../../../../pte-api/app/src/main/java/com/pte/itembank/ItembankService.java): publish/approve, autoarchive, unarchive → DRAFT, freeze requiresAPPROVED/current.
- [QuestionRepository.java](../../../../pte-api/app/src/main/java/com/pte/itembank/internal/repository/QuestionRepository.java): list/count deletedfilters và nativegenerationqueries cần rà đồng bộ.
- [PlanRepository.java](../../../../pte-api/app/src/main/java/com/pte/billing/internal/repository/PlanRepository.java): adminlist/activelist chưa lọcdeleted theo tên method.
- [AssessmentService.java](../../../../pte-api/app/src/main/java/com/pte/assessment/AssessmentService.java), [BlueprintService.java](../../../../pte-api/app/src/main/java/com/pte/assessment/internal/service/BlueprintService.java): dependencygraph/referencewriters.
- [question client](../../../../pte-web/packages/api-client/src/requests/question/index.ts): deletehelper đã có nhưng controller cần implement; [QuestionController.java](../../../../pte-api/app/src/main/java/com/pte/itembank/internal/controller/QuestionController.java): platformadmin/author authorization.
- [archive assessment](../quang-admin-commercialization-unhappy-cases/archive-assessment.md): enrollment softremove guards/history.

## Validation

User đã trả lời: lifecycle-only; softdelete+audit/noRestoreUI; guard outstandingcodes, khôngsnapshot. Những lựa chọn này đã phản ánh vào plan. Implementation choices về module graph, schema/APIparser vẫn phải được giải quyết bằng phase01 evidence, không bắt user chọn chi tiết framework trước khi inventory.
