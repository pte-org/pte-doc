# Phase 07: Student review, progress, Study-Pack và feedback

Status: planned. Dependencies: 03..06; D03, D05 và D08 cho policy phụ thuộc. Stories: US-07, US-08, US-11. Requirements: PR-13..15.

## Screens và work packages

1. Session completion: tổng kết submitted/skipped; từng item có review link và persisted objective/evaluation/AI status. Không chỉ đếm số câu rồi kết thúc. Thêm route result/review có deep link và server authorization, refresh truy vấn canonical result.
2. Item review: prompt/media snapshot, Student response/recording playback, verified objective answer/reference cho phép hiển thị, standard explanation đã duyệt, criterion feedback/evidence/limitations, AI label và generated version/time. Replay recording sau submit qua facade read-only, không giữ live upload grant. Không expose internal prompts hay sibling item keys chưa nộp.
3. Nút “Giải thích bài của tôi” tạo POST on-demand khi eligible, language theo D05 pin identity; existing AVAILABLE trả stored result. WAITING_EVIDENCE/QUEUED/RUNNING có feedback và bounded polling/backoff; failure category/canRetry/cooldown quyết định action POST rõ. Readiness unavailable/budget-limited và coverage limited không lẫn job state. Refresh/focus đọc lại, không generate. AI lỗi vẫn cho xem answer/objective/standard explanation và luyện tiếp.
4. Progress sửa `ProgressView` từ speaking-centric sang 4 kỹ năng; tách activity/submitted count, confidence tự đánh giá, objective accuracy theo task/policy, rubric levels và AI availability. Không tổng hợp mixed raw scores thành official band hoặc numeric Writing/Speaking chưa calibrated. Cursor pagination thực: hasMore/cursor, load-more failure/retry; resume cho in-progress, review cho submitted. Empty/loading/unavailable/locked/context states có nguồn backend thật.
5. Study-Pack theo D03 đã xác nhận là **nhóm luyện nhanh có filter** dẫn catalog và session create đúng skill/task/readiness; difficulty chỉ khi canonical metadata hỗ trợ. CTA không cùng dẫn về catalog chung. Không triển khai curated ordered pack, persisted pack membership hay completion riêng trong scope này.
6. Feedback US-11 là P2 có gate D08: đề xuất Student report category CONTENT_INCORRECT/MEDIA_BROKEN/EXPLANATION_INCORRECT/OTHER, immutable question/submission/explanation reference, owner/context permissions, optional comment, rate limit và moderation. Academic Staff triage nội dung/AI, Academic Manager quyết định revision/publish; quyền Manager/Host hỗ trợ chỉ theo policy. Không tự đưa bài của Student cho mọi Host/teacher. Nếu chưa duyệt, ghi deferred rõ và giữ core P1 release độc lập.
7. Academic triage screen nếu được duyệt: list filters/status, evidence snapshot theo quyền, internal notes, acknowledge/in-review/resolved/rejected, reason và audit. Sửa content/rubric tạo revision mới, không sửa personalized history ngầm; Student notification theo approved scope. Nội dung feedback là untrusted, không được đưa vào prompt instruction.

## Proposed files

`pte-practice/features/practice/{PracticeSessionView.tsx,api.ts,contracts.ts}`, proposed result/review components và actual Next route theo project conventions; `features/progress/ProgressView.tsx`, `features/studyPack/StudyPackView.tsx`, home/catalog links. Backend `PracticeProgressService.java`, progress/result DTO/controllers; proposed report/triage domain chỉ khi D08 duyệt. Vendor academic routes/components/API clients và RBAC matching existing navigation.

## Failure paths

Expired entitlement khi request AI vs permitted historical read; deleted/retained audio; pending forever báo recovery/return path; invalid/foreign review URL; changed context; browser tab resume; API pagination duplicate entries; AI limited transcript; Student report spam; unauthorized academic access. UI không dùng raw backend message thay consistent codes/copy.

## Design Constraints

Persisted GET là truth; không rerun AI vì rerender. Polling bounded, abort khi unmount/context switch và không tạo work. D03 đã xác nhận nhóm luyện nhanh: UI cần filter/start thực thay cho pack links giả. Feedback phải có handler lifecycle trước mở submit form.

## Tests to Consider

Navigation completion→review→progress, reload same explanation ID/hash; 20 GET zero provider calls; all AI states/retry cooldown; no pre-submit key exposure; audio playback access; cursor load more; four-skill empty/mixed results; current entitlement POST vs history GET; feedback RBAC/rate limiting nếu enabled. Accessibility/keyboard/mobile/recording devices theo actual supported browsers. Chưa thực hiện.

## Exit criteria

Student hoàn thành vòng luyện→kết quả→giải thích→luyện tiếp; không placeholder performance hoặc fake pack links. History/progress phản ánh nguồn persisted, lỗi AI không chặn review. Feedback pending được ghi deferred thay tuyên bố đã có.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn; optional ck:test/quality chờ cook. Required web compile/lint theo standards; UI interaction checks là đề xuất chưa chạy.
