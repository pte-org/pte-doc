# Phase 04: immutable submissions, objective result và evidence reads

Status: planned. Dependencies: 02,03. Stories: US-03, US-05, US-08. Requirements: PR-04,06,07,08,13,15.

## Work packages

1. Submit transaction xác thực owner/context/version/state/deadline/media binding và lưu immutable response cùng canonical hash, question/rubric/reference/evaluator revision. Phân biệt save draft, submitted, evaluated, AI readiness; AI lỗi không rollback submission. Two-tab/retry cùng answer trả canonical outcome; khác payload sau submit trả conflict.
2. Khảo sát `scoring/internal/service/ObjectiveScoringService.java`, extract pure deterministic evaluator thành **public scoring facade/API** với input snapshot + response, output credit/errors/evidence/policy version. Practice không import `scoring.internal`, không gọi exam workflow để tạo attempts/reports giả. Giữ exam scorer behavior và có regression coverage proposal.
3. Evaluator matrix: single choice; multiple choice penalty/zero floor; blanks per stable blank ID và accepted alternatives/normalization; reorder exact/adjacency/partial theo approved task policy; highlight IDs với penalty policy; dictation token matching/normalization theo approved rule. Không tự sáng tạo quy tắc vì tên task giống nhau. Unsupported policy phải explicit unavailable, không cho Gemini chấm thay.
4. Public read-only media evidence facade cho **submitted** audio: verify owner/context/submission binding và bounded signed read/access; worker service authorization chỉ đọc snapshot evidence. Giữ nguyên live upload guard IN_PROGRESS/PENDING; không nới upload sau submit để AI đọc được. Historical Student playback chịu D08 access/retention, không dùng raw provider URL vĩnh viễn.
5. Result API đọc persisted deterministic evaluation cùng response và references được phép tiết lộ **sau nộp từng item**. Lọc sibling unsubmitted keys/reference; GET không trigger evaluator/Gemini side effects. Objective result, qualitative rubric result, confidence và AI state độc lập. Immutable session snapshots bảo đảm question edit không đổi điểm cũ.
6. Tách ba identities: immutable submission ID/hash (raw answer/media + question pins); deterministic evaluation ID (submission + restricted key/reference/evaluator policy, không prompt/model/language); explanation resolver slot theo owner/context/submission/language/generation sequence và full frozen fingerprint theo AI contract. Dùng canonical JSON hash version, set/order semantics từ task matrix. Prompt/model đổi không tự rescore objective hoặc regenerate explanation. Explicit new evaluation/regeneration có reason/quyền/lineage, giữ result cũ.
7. Validate restricted reference/key completeness **trước** evaluator. Existing objective scorer có branches trả zero cho malformed/missing reference; practice adapter phải trả `NOT_ASSESSABLE/CONTENT_ISSUE` cho broken source, không đánh Student zero. Empty/mistaken Student response vẫn theo legitimate task policy. Current internal 0..100 scale không có Pearson equivalence.
8. Legacy sessions chỉ pin source UUID/prompt/options không đủ evidence chấm mới. Backfill chỉ khi immutable source/hash chứng minh đúng original revision; không dùng current keys/rubric thay bằng chứng cũ. Thiếu provenance → `LEGACY_EVIDENCE_UNAVAILABLE`, giữ old answers read-only, không xóa hoặc fabricate historical result.
9. Derived ASR/transcript/assessment artifacts phải immutable revision/hash, lưu assessor policy/version/config và evidence provenance trong evaluation input. Chưa có evidence → `WAITING_EVIDENCE` với deadline/recovery bounded rồi `NOT_ASSESSABLE` nếu thiếu. Retry explanation không tự chạy lại ASR/assessor; explicit reassessment phải tạo lineage/version mới.

## Proposed files

`practice/internal/service/PracticeSessionItemService.java`, persistence/domain/repository/controller DTOs; proposed practice evaluation/result query services. `scoring/` public evaluator facade và owned internal adapter; `PracticeMediaBindingService.java` public read seam hoặc media facade module phù hợp. Migration cho submission/evaluation snapshot/version/indexes dựa schema hiện tại, không tạo duplicate tables vô lý.

## Failure paths

Duplicate submit, changed payload, missing/deleted recording, expired media URL, stale content revision, malformed option/token IDs, zero-credit answer, unsupported evaluator, revoked access giữa submit/read, retired rubric vẫn pin historical. Result read không tự lấy current question key thay restricted snapshot.

## Design Constraints

Server là nguồn correctness; Gemini chỉ giải thích evaluator. Published answer keys chỉ ở restricted snapshot đến đủ điều kiện post-submit. Personal Introduction không tổng điểm. Không diễn giải Student confidence thành score; không convert raw practice accuracy thành PTE official band.

## Tests to Consider

Gold cases mọi objective policy và edge normalization/partial/penalty; unknown IDs; two-tab/version conflict; submit idempotency khác header; immutable historical key/rubric; answer-key leak fixtures; post-submit media read authorized vs upload forbidden; foreign owner/context; exam scorer regression qua public facade. Chưa viết/chạy.

## Exit criteria

Objective gold fixtures khớp 100% policy được duyệt; immutable result truy vấn được sau AI disabled; pre-submit no-key leak và post-submit audio ownership được chứng minh trong implementation checks. No `practice → scoring.internal` dependency.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn; recommend evaluator/immutability/authorization-first khi user chọn. Cook xác nhận optional checks, required compile/module checks theo standards.
