# Phase 01: quyết định, task matrix và contracts

Status: planned. Dependencies: không. Stories: US-01, US-02, US-03, US-09. Requirements: PR-01..04, PR-08, PR-15.

## Mục tiêu và work packages

1. Đọc standards và supporting IAM/API docs; ghi exact file đọc trước code. Audit API routes/controller → service → storage → frontend caller; inventory auth, entitlement, catalog, sessions, media, progress. Ghi implementation/gap thay vì dựa Report 3 để đánh dấu completed.
2. Tạo task matrix có một dòng cho từng canonical task type thực sự tồn tại trong registry. Mỗi dòng: ID/tên/kỹ năng/product applicability/source, content shape, media/timing, answer shape, safe/restricted fields, evaluator policy, rubric/reference revisions, renderer, AI evidence, fixture và release gate. D01 đã chọn các dạng bài Academic hiện có; đối chiếu inventory 23 types với ngân hàng/registry và readiness thực tế, không mở catalog Core riêng.
3. Family mapping để thiết kế: text writing; single/multiple choice; reading/listening blanks; reorder paragraphs; highlight incorrect words; selected missing word; write from dictation; read aloud/repeat sentence/describe image/retell lecture/answer short question; Summarize Group Discussion/Respond to Situation theo canonical registry. Personal Introduction unscored. WRITE_EMAIL/video chưa có contract thì ngoài scope, không tạo tên task giả.
4. Dùng `decisions.md`: D01–D03/D05–D06 đã được user xác nhận, không hỏi lại. VI mặc định/EN tùy chọn, qualitative writing/speaking feedback trước, numeric AI sau calibration. On-demand AI vẫn là thiết kế đề xuất cần cụ thể hóa policy. D08 phải tách feedback handler, historical read, data handling và budget; resolved phần nào ghi phần đó.
5. Chốt additive DTOs: stable questionRevisionId/optionId/blankId/tokenId; safe content schemaVersion; submitted response/evaluation/explanation trạng thái tách biệt; version conflict và idempotency. Version payload canonicalization xử lý set khác ordered sequence. Lập allowed actions matrix cho session/item thay vì thay state machine tùy màn hình.
6. IAM: giữ `PracticeIdentityService`, email challenge/session/entitlement canonical. Thực hiện D02 đã chốt: một verified email có thể chọn các organization memberships được phép, giữ Student profile/ownership theo context, không auto-merge. Thiết kế chuyển context/logout hủy cached drafts/query data của account khác. POST start/submit/generate check current access; GET history policy thuộc D08, vẫn yêu cầu owner/context và không tạo side effect.

## Proposed files / ownership

- Hiện có: `pte-practice/features/practice/{contracts.ts,api.ts,session-state.ts,session-storage.ts}`, `features/catalog/PracticeTestsView.tsx`; backend `practice/internal/controller/Practice{Auth,Catalog,Session,Progress,Entitlement}Controller.java`, corresponding services; `identity/PracticeIdentityService.java`.
- Đề xuất artifacts: task/permission/state matrices dưới canonical reports folder, contract fixtures do test choice quyết định; DTOs theo package hiện tại. Không thêm cross-module repository dependencies.

## Failure paths

Expired/reused OTP, throttling, email enumeration, suspended membership, expired subscription giữa phiên, context không thuộc Student, stale version, two-tab submit, unknown task/content version và empty bank phải có code/message/action rõ. Không tự chuyển về context đầu tiên hay mock catalog khi backend unavailable.

## Design Constraints

- D01/D02 đã xác nhận; reading/contract/migration gates vẫn phải thực hiện, không coi confirmation là runtime evidence.
- Không trả restricted answer keys, hidden transcripts, worked solutions trong pre-submit DTO/HTML/local storage.
- Account/context namespaces phải nhất quán backend/frontend; authorization không phụ thuộc client-supplied studentId.

## Tests to Consider

Contract shape và no-key-leak fixtures; auth expired/reused/rate limit; authorized vs foreign context; migration compatibility; canonical answer hashing cho arrays/set; two tabs/version conflict; reload/logout/shared-PC cleanup. Đây là đề xuất, chưa viết hoặc chạy.

## Exit criteria

Task matrix có row completeness và owner cho mỗi gap; state/permission/API contract được review; D01/D02 có approval trước thay behavior; quyết định chưa chốt được đánh dấu block đúng phase. Không gọi inventory đầy đủ là delivery hoàn tất.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn. `ck:cook` xác nhận optional test/quality trước phase; mandatory standards checks vẫn áp dụng khi có code. Không có runtime/live-provider bằng chứng trong phase plan.
