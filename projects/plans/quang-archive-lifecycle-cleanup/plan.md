# Plan: Archive lifecycle cleanup

Ngày: 2026-10-05. Cook mode: Standard với tests=yes, quality=yes, checks-all-phases do user xác nhận; không có --tdd. Status: phases01–04 completed; phase05 executed, incomplete due to full-regression baseline failures and live E2E limitation.

## Cook consent và progress

User yêu cầu chạy cả5 phase rồi kiểm tra sau; không dừng xin lựa chọn lại từng phase. Không commit/push/deploy.

- [x] Phase01: contract/provenance [tests: passed (3); quality: approved; decision: user_confirmed_all_phases]
- [x] Phase02: Plan lifecycle [tests: passed (29); quality: approved; decision: user_confirmed_all_phases]
- [x] Phase03: Question lifecycle [tests: passed (37); quality: approved; decision: user_confirmed_all_phases]
- [x] Phase04: web actions [tests: passed (381 client + 21 mocked browser checks); quality: approved; decision: user_confirmed_all_phases]
- [ ] Phase05: regression [scoped tests: passed; full regression: FAILED, 11 reproduced baseline failures; quality of changes: approved; live E2E: unverified; decision: user_confirmed_all_phases]

## Scope challenge và chất lượng spec

- Exists: Plan/Question archive và Program/Class soft removal đã có; question client có delete helper nhưng backend chưa có DELETE. Plan delete chưa có.
- Minimum: giữ retirement, thêm guarded soft Delete draft, bỏ Archive ở draft/pending khi có cleanup thay thế, đổi enrollment text. Không xây trash/restore hoặc workflow mới.
- Complexity: nhiều repository/module/UI, revision provenance, legacy schema và concurrency → Hard.
- Spec có stories P1/P2, acceptance đo được và non-goals. Verdict: PASS sau khi user chốt lifecycle-only, soft delete + audit, guard mã lưu hành. Không dùng spec kiểm thử 45 case làm spec implementation cho đợt này. Phase01 đóng băng chi tiết kỹ thuật trước viết endpoints.

Đầu vào: [spec](spec.md), [archive assessment](../quang-admin-commercialization-unhappy-cases/archive-assessment.md), [research và red-team](design-review.md).

## Quy tắc mục tiêu

| Resource/state | Action sau thay đổi | Guard |
|---|---|---|
| Plan DRAFT | Edit, Activate, Delete draft | Delete chỉ khi chưa dùng và không bất kỳ reference, kể cả reference cũ/hết hạn. |
| Plan ACTIVE | Edit, Archive | Đợt tối thiểu chặn archive/entitlement edit nếu mã ISSUED còn hạn; khóa/check thống nhất với issue. |
| Plan ARCHIVED | Read-only | Không delete/activate/edit; không sửa legacy rows. |
| Question DRAFT proven-unused | Edit, Submit, Delete draft | Provenance NEVER_PUBLISHED và không revision/reference cần giữ. |
| Question DRAFT restored/history/unknown | Edit/Submit theo rule hiện tại; Archive chỉ cho known history nếu cần | Không Delete; UNKNOWN không tự nâng thành unused; cleanup unknown cần xác minh riêng. |
| Question PENDING_APPROVAL | Approve/Reject theo role | Không Archive/Delete; author giữ Submit/Edit policy hiện có, không mở Withdraw. |
| Question APPROVED | Edit qua revision, Archive | Giữ auto-archive superseded và lịch sử; không destructive delete. |
| Question ARCHIVED | Read và restore nếu rule hiện tại cho phép | Không thay các hạn chế restore revision hiện có. |
| Program/Class | Activate/Inactive/Suspend/Remove | Remove vẫn soft delete; giữ guard con/membership hiện có. |

Plan soft-delete read filtering và Question deletion filtering là thay đổi thực sự, không chỉ gỡ nút. DRAFT Question phải phân biệt new draft và restored draft; entity hiện đã có version, không thêm version thứ hai.

## Phases / dependencies

| Phase | Nội dung | Phụ thuộc | Story |
|---|---|---|---|
| [01](phase-01-contract-and-provenance.md) | Contract, provenance, reference inventory, schema | Validation answers | P1/P2 |
| [02](phase-02-plan-lifecycle.md) | Plan guarded delete, archive narrowing, issuance guard | 01 | P1 |
| [03](phase-03-question-lifecycle.md) | Question safe draft delete, archive policy, deleted readers | 01 | P1 |
| [04](phase-04-web-actions-and-remove-labels.md) | API client, actions, confirmations, tenant Remove text | 02 + 03 | P1/P2 |
| [05](phase-05-regression-and-handoff.md) | PostgreSQL races, browser regression, migration rehearsal | 01–04 | P1/P2 |

02/03 có thể làm song song khi contract 01 đóng băng; 04 không nối DELETE vào server chưa có. Mỗi phase có Design Constraints và Quality/Testing State riêng để tiếp tục theo ck:cook.

## Proposed HTTP contract

- `DELETE /api/v1/plans/{publicId}`: PLATFORM_ADMIN, guarded draft soft delete.
- `DELETE /api/v1/questions/{publicId}`: PLATFORM_ADMIN/PLATFORM_AUTHOR theo write policy hiện tại, guarded draft soft delete.
- Success:204 no body đề xuất; API client `Promise<void>` cần contract test parser204 trước áp dụng. Nếu client không support204, dùng envelope successnull nhất quán app và ghi rõ quyết định phase01.
- Authorized repeat DELETE đã soft-deleted:204/no-op, không audit lần hai; missing/wrong scope404; forbidden403; invalid state/history/reference409 với error code riêng.
- Giữ POST archive/unarchive endpoints nhưng BE thu hẹp state; không đổi `ARCHIVED` enum hoặc schema history để đổi nhãn.
- Additive capabilities cho Plan/Question response: canDeleteDraft, canArchive, reasonCodes; owner service tính theo guard. Legacy/missing capabilities UI fail closed, không suy từ DRAFT. Không N+1 checks trên list; aggregate batched usage lookup.
- Confirmation gửi version/expectedState nếu contract cần concurrency; dùng Question version hiện có. Plan chọn locking/version phù hợp, không thêm vào BaseEntity toàn app.

## Migration / rollout

Flyway và ddl-auto validate đang có. Chọn số migration tiếp theo **tại thời điểm code**, không cố định filename từ snapshot hôm nay. Không sửa migration cũ.

Expand: thêm provenance nullable/additive fields cần thiết; legacy không biết history → UNKNOWN. New Question tạo NEVER_PUBLISHED; publish/approve đổi EVER_PUBLISHED một chiều, unarchive không reset. APPROVED legacy có bằng chứng published, còn ARCHIVED có thể từng archive từ draft nên không suy bừa.

Server capability/new DELETE deploy trước hoặc cùng UI. Rollback UI không xóa columns/data mới; lưu ý client cũ vẫn gọi archive draft và sẽ409 — release notes và stale-tab refresh. Không disable guard để phục vụ client cũ. Không backfill deleted hoặc delete legacy hàng loạt.

## Risks / stop conditions

- DRAFT không chứng minh chưa dùng; không có inventory/provenance rõ thì fail closed.
- Guard reference check có race nếu writer tham chiếu không dùng chung locking/state contract. Phase01 phải tìm mọi writer, không chỉ check tại DELETE.
- Full snapshot policy sẽ mở rộng phase02 và spec; không tự implement lén dưới label archive cleanup.
- Deadlock khi kết hợp revision/plan/entitlement locks: một thứ tự lock, kiểm thử overlapping writers; không self-deadlock outer lock + REQUIRES_NEW insert.
- Persisted native generation queries cần review deleted filters, không chỉ JPA list.

## Quality and Testing State

- Quality: all five phases have APPROVED reports/receipts for reviewed changes. Inline review, not an independent agent. Full-suite failure is not waived by quality approval.
- Testing: targeted backend/client/PostgreSQL/browser checks passed; full backend regression FAILED on 11 errors/failures reproduced on clean HEAD. Details and commands in [test report](test-report.md).
- All test/quality choices were explicitly confirmed for all five phases. No TDD claim. Phase05 is not marked complete.

## Handoff

Implementation is uncommitted and not deployed. See [checklist](checklist.md), [release notes](release-notes.md), [code review](code-review.md) and [test report](test-report.md).

Next decision: user reviews UI/behavior. Fixing unrelated full-suite baseline failures requires separate scope approval. Authenticated E2E and a green full-suite gate are still required before a release-ready claim. Commit/push/deploy require explicit authorization.
